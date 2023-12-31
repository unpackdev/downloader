// SPDX-License-Identifier: MIT

/**
Samuel Benjamin Bankman-Fried, or SBF, is an American entrepreneur and investor.
Bankman-Fried was the founder and CEO of the cryptocurrency exchange FTX and associated trading firm Alameda Research!
Both of which experienced a high-profile collapse resulting in chapter 11 bankruptcy in late 2022.
Born: March 6, 1992 (age 31 years), Stanford, CA
**/

pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

contract SAMSONETH is ERC20, Ownable {
    constructor(address initialOwner)
        ERC20("SAM ON ETH", "SAM")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 1992 * 10 ** decimals());
    }
}