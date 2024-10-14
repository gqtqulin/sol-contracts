// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**

        Sherlock + John + Mary + Lestrade
                        6

        Sherlock + John   Mary + Lestrade
                4              5
        
    Sherlock    John    Mary    Lestrade
        0         1      2         3

 */

contract Tree {
    bytes32[] public hashes;
    // 4 условных начальных узла (по условию их кол-во равно 2 в степени n)
    string[4] heroes = ["Sherlock", "John", "Mary", "Lestrade"];

    constructor() {
        // считаем для первых блоков хеш, добавляем их в массив bytes32
        for (uint i = 0; i < heroes.length; i++) {
            hashes.push(
                keccak256(abi.encode(heroes[i]))
            );
        }

        uint n = heroes.length;
        uint offset = 0;

        // запускаем цикл, чтобы сделать "ветку" хешей из каждый 2-х блоков
        while (n > 0) {

            // для каждого второго (начиная с 0) до длины массива - 1
            // мы знаем, что последние два собираются в ветку из первого из них
            for (uint i = 0; i < n - 1; i += 2) {
                bytes32 newHash = keccak256(
                    abi.encodePacked(
                        // *** -> 1 итерация while
                        // 1 итерация for = хеш 0-го, хеш 1-го элемента
                        // 2 итерация for = хеш 2-го, хеш 3-го элемента
                        // *** -> 2 итерация while
                        // 1 итерация for = хеш 4-го, хеш 5-го элемента
                        // *** -> 2 итерация while
                        // не запустилось по условию
                        hashes[i + offset], hashes[i + offset + 1]
                    )
                );
                hashes.push(newHash);
            }

            // первые 4 числа - начальные ветки, чтобы их скипать, а после
            // последующие ветки - делаем offset, который равен добавляемым хешам в
            // этой итерации цикла
            // 1 итерация = 4
            // 2 итерация = 6
            // 3 итерация = 7
            offset += n;

            // делим на 2 тк идем через 1 (соединяем 2 ветки в 1)
            // 1 итерация = 2
            // 2 итерация = 1
            // 3 итерация = 0 (усечение дробной части)
            n = n / 2;
        }
    }

    /**
        получить
     */
    function getRoot() public view returns(bytes32) {
        return hashes[hashes.length - 1];
    }

    /**
        @notice проверка что указанный хеш есть в дереве
        @param root корень (самый верхний хеш)
        @param leaf хеш который нужно проверить (есть он или нет в дереве)
        @param index где находится хеш leaf
        @param proof массив хешей, нужных для проверки
     */
    function verify(
        bytes32 root, bytes32 leaf,
        uint index, bytes32[] memory proof
    ) public pure returns(bool) {
        bytes32 hash = leaf;
        // для каждого элемента дерева
        for (uint i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i]; // получаем текущий
            // если число четное - второе число для ветки берем справа
            if (index % 2 == 0) {
                hash = keccak256(abi.encodePacked(
                    hash, proofElement
                ));
            } else {
                hash = keccak256(abi.encodePacked(
                    proofElement, hash
                ));
            }
            index = index / 2;
        }

        return hash == root;
    }

}