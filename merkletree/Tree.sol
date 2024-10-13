// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



contract Tree {
    bytes32[] public hashes;
    string[4] heroes = ["Sherlock", "John", "Mary", "Lestrade"];

    constructor() {
        for (uint i = 0; i < heroes.length; i++) {
            hashes.push(
                keccak256(abi.encode(heroes[i]))
            );
        }

        uint n = heroes.length;
        uint offset = 0;

        while (n > 0) {
            for (uint i = 0; i < n - 1; i += 2) {
                bytes32 newHash = keccak256(
                    abi.encodePacked(
                        hashes[i + offset], hashes[i + offset + 1]
                    )
                );
                hashes.push(newHash);
            }
            offset += n;
            n = n / 2;
        }
    }
}