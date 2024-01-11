//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Address.sol";
import "./Math.sol";
import "./ERC721A.sol";

contract TOC is ERC721A, Ownable {
    using Address for address;

    uint256 private constant MAX_SUPPLY = 33;

    /// @notice base uri for token metadata
    string private _baseURIExtended;

    constructor() ERC721A("The Owners Club: First Edition 1/1 NFTs", "TOC") {
        _safeMint(msg.sender, MAX_SUPPLY);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIExtended;
    }

    function mint(uint256 quantity) external onlyOwner {
        _safeMint(msg.sender, quantity);
    }

    /**
     * @dev update base uri of nft contract
     * @param baseURI_ new base uri string
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }
}
