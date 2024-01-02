// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";
import "./Ownable.sol";

contract MEMESLA is ERC20, ERC20Burnable, ERC20Permit, Ownable {

    mapping(address => bool) public hasReceivedToken;

    address address1 = 0xAab5915d0aAb5129b91Ac0639F4fACDee4eb93d6;
    address address2 = 0x781A0c3B1C5e7788F33B583027d1290a96Ca72E0;
    address address3 = 0xb05317781c6b215c1DE17f5fa0202179B0715925;
    address address4 = 0xa0Bf017Beb88e39354213F137A31991694CAa3b3;
    address address5 = 0x963D13E07Ef80C7C11682b5e025D7cbA43C30035;

    constructor(address initialOwner)
        ERC20("MEMESLA", "MEMESLA")
        ERC20Permit("MEMESLA")
        Ownable(initialOwner)
    {
        uint256 totalSupply = 1000000000 * 10 ** decimals();
        _mint(address(this), totalSupply);
        
        _transfer(address(this), address1, totalSupply * 10 / 100); // 10%
        _transfer(address(this), address2, totalSupply * 8 / 100); // 8%
        _transfer(address(this), address3, totalSupply * 5 / 100); // 5%
        _transfer(address(this), address4, totalSupply * 65 / 100); // 65%
        _transfer(address(this), address5, totalSupply * 12 / 100); // 12%

    }

}

