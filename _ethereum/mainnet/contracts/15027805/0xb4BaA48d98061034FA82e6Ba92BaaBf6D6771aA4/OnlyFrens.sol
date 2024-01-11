//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Strings.sol";
import "./Ownable.sol";

/**
    This is a collection with no max limit, made for frens and made by your fren in GohanGo!!
 */
contract OnlyFrens is ERC721A, Ownable {
    using Strings for uint256;
    string public baseURI = "";

    constructor(string memory _baseURI) ERC721A("OnlyFrens", "ONLYFRENS") {
        baseURI = _baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token not existed");
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function airdrop(address[] calldata addresses, uint256 _quantity)
        external
        onlyOwner
    {
        for (uint256 i; i < addresses.length; i++) {
            _safeMint(addresses[i], _quantity);
        }
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function withdraw(address payable to) external onlyOwner {
        to.transfer(address(this).balance);
    }
}
