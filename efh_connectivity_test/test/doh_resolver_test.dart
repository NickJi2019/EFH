import 'dart:convert';

import 'package:efh_connectivity_test/connectivity/doh_resolver.dart';
import 'package:efh_connectivity_test/ui/run_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses A and AAAA answers from a DoH JSON response', () {
    final decoded = jsonDecode('''
{"Status":0,"Answer":[
  {"name":"example.com","type":5,"data":"example.com.cdn.cloudflare.net."},
  {"name":"example.com","type":1,"data":"93.184.216.34"},
  {"name":"example.com","type":28,"data":"2606:2800:220:1:248:1893:25c8:1946"}
]}''');

    expect(parseDohAnswers(decoded, dohTypeA), ['93.184.216.34']);
    expect(parseDohAnswers(decoded, dohTypeAaaa), [
      '2606:2800:220:1:248:1893:25c8:1946',
    ]);
    expect(parseDohAnswers(null, dohTypeA), isEmpty);
    expect(parseDohAnswers({'Answer': 'nope'}, dohTypeA), isEmpty);
    expect(parseDohAnswers({'Status': 2}, dohTypeA), isEmpty);
  });

  test('accepts only absolute http(s) DoH urls', () {
    expect(
      RunController.isValidDohUrl('https://cloudflare-dns.com/dns-query'),
      isTrue,
    );
    expect(
      RunController.isValidDohUrl('http://127.0.0.1:8053/dns-query'),
      isTrue,
    );
    expect(RunController.isValidDohUrl(''), isFalse);
    expect(RunController.isValidDohUrl('example.com'), isFalse);
    expect(RunController.isValidDohUrl('ftp://example.com/dns-query'), isFalse);
  });
}
