// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IterMapping {

    mapping(string => uint256) ages;
    string[] public keys;
    mapping(string => bool) isInserted;

    function set(string memory _name, uint256 _age) public {
        ages[_name] = _age;

        if (!isInserted[_name]) {
            keys.push(_name);
            isInserted[_name] = true;
        }
    }

    function length() public view returns (uint256) {
        return keys.length;
    }

    function get(uint256 _index) public view returns (uint256) {
        string memory key = keys[_index];
        return ages[key];
    }

    function values() public view returns (uint256[] memory) {
        uint256[] memory vals = new uint256[](keys.length);

        for (uint i = 0; i < keys.length; i++) {
            vals[i] = ages[keys[i]];
        }

        return vals;
    }

}