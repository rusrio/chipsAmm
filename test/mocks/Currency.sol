// SPDX License Identifier: MIT

pragma solidity ^0.8.13;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract Currency is ERC20 {

    error Currency_NotOwner();

    address owner;

    constructor(string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol, decimals) {
        owner = msg.sender;
    }

    function mint(address to, uint256 amount) public {
        if(msg.sender != owner) {revert Currency_NotOwner();}
        _mint(to, amount);
    }

}