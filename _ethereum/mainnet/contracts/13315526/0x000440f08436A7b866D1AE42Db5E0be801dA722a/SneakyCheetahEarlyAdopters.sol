// SPDX-License-Identifier: MIT

/*
 */

pragma solidity ^0.8.0;

import "./console.sol";
import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Supply.sol";

contract SneakyCheetahEarlyAdopters is ERC1155Supply, Ownable  {
    uint constant EA_TOKEN_ID = 1;
    address[] public EARLY_ADOPTERS;
    address public AMANDA = 0x477406df302096d6CF6F5386f6aa0035912e1792;

    constructor(string memory uri, address[] memory early_adopters) ERC1155(uri) {
        EARLY_ADOPTERS = early_adopters;
        reserve(10);
        mintInitial();
    }

    function reserve(uint256 num) public onlyOwner {
       _mint(AMANDA, EA_TOKEN_ID, num, "");
    }

    function mintInitial() public onlyOwner {
        for(uint i = 0; i < EARLY_ADOPTERS.length; i++){
            _mint(EARLY_ADOPTERS[i], EA_TOKEN_ID, 1, "");
        }
    }

    function mintEA(address _to, uint256 num) public onlyOwner {
        _mint(_to, EA_TOKEN_ID, num, "");
    }

    function changeURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }
    
}