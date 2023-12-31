// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721A.sol";

contract DigiDogs is ERC721A {
    constructor() ERC721A("DigiDogs", "DD") {}

    function mint(uint256 quantity) external payable {
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(msg.sender, quantity);
    }

    function _baseURI() override internal view virtual returns (string memory) {
        return "ipfs://QmSdhAuC3PadgPQhjePwvSL1dzxfjFQSCH53DWsRiSHLhb/";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}