<?php
// PHP Memory Touch Test (CLI only)

$sizeMB = 512;
$size   = $sizeMB * 1024 * 1024;
$page   = 4096;

// PHPのメモリ制限を解除（念のため）
ini_set('memory_limit', '-1');

$buf = str_repeat("\0", $size);

$touched = 0;

for ($i = 0; $i < $size; $i += $page) {
    // 4KBごとに確実に書き込み
    $buf[$i] = "\x01";
    $touched += $page;

    if (($touched % (10 * 1024 * 1024)) === 0) {
        echo "Touched " . ($touched / 1024 / 1024) . " MB\n";
    }
}

echo "Touch finished. Sleeping...\n";
sleep(600);
