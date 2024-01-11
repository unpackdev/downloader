// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./ERC721A.sol";

// @title Test Contract
contract SimpleTest is Ownable, ERC721A {
    bool public isSaleActive = false;

    // @notice Constructor
    constructor() ERC721A("Simple Test", "TEST") {}
    
    // @notice The function sets the isSaleActive variable to false.
    function flipSaleState() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    // @notice The function returns the value of the isSaleActive variable.
    function saleState() public view returns (bool) {
        return isSaleActive;
    }
}