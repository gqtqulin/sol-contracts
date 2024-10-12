// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CrowdToken is ERC20 {

    uint256 private _totalSupply;

    constructor(uint256 _initialSupply) ERC20("SomeCrowdToken", "SCT") {
        _mint(msg.sender, _initialSupply);
    }

}