use strict;
use warnings;
use utf8;
use Test::More; # Perl標準の最強テストモジュール

# 1. テスト対象のデーモンスクリプトを読み込む
# (末尾に「1;」があれば、これで中の関数が自由に呼び出せるようになります)
require './files/usr/local/sbin/mackerel-micro-daemon';

# 2. テストを実行する
# is( 実際の値, 期待する値, "テストの名前" );

# テストA: 通常の文字列（エスケープ不要なもの）
is(escape_json("hello"), "hello", "通常の文字列はそのまま出力されること");

# テストB: 改行コードのエスケープ
is(escape_json("\n"), "\\n", "改行が \\n に変換されること");

# テストC: 今回パッチで修正した「バックスペース（\b）」のエスケープ
is(escape_json("\b"), "\\u0008", "バックスペースが \\u0008 に変換されること");

# テストD: タブ（\t）のエスケープ
is(escape_json("\t"), "\\t", "タブが \\t に変換されること");

# 3. テストの終了を宣言する
done_testing();
