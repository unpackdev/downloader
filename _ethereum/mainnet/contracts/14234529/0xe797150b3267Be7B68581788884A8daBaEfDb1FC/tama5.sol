// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721EP.sol";

contract Tama5 is ERC721EP {
    constructor()
    ERC721EP("tama5", "T5ARTC", address(0xF59AB3a52cBd6d37Ad6eAB5eB19Ba96F8B774076)) {
        enableAutoFreez();
        setMintFee(0.03 ether);
        
        address payable[] memory thisAddressInArray = new address payable[](1);
        thisAddressInArray[0] = payable(address(this));
        uint256[] memory royaltyWithTwoDecimals = new uint256[](1);
        royaltyWithTwoDecimals[0] = 1000;
        _setCommonRoyalties(thisAddressInArray, royaltyWithTwoDecimals);
    }
}

