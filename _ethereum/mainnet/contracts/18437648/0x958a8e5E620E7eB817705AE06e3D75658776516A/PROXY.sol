// SPDX-License-Identifier: GPL-3.0
// presented by Wildxyz

pragma solidity ^0.8.17;

import "./Strings.sol";
import "./Base64.sol";
import "./Math.sol";

import "./IERC721A.sol";
import "./ERC721A.sol";

import "./WildNFTA.sol";

contract PROXY is WildNFTA {
    constructor(address _minter, uint256 _maxSupply, string memory _baseURI, address[] memory _payees, uint256[] memory _shares, uint96 _feeNumerator) WildNFTA('PROXY', 'PROXY', _minter, _maxSupply, _baseURI, _payees, _shares, _feeNumerator) {}

    // update 2981 royalty
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function tokenURI(uint256 _tokenId) public view override(IERC721A, ERC721A) tokenExists(_tokenId) returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), '.json'));
    }
}
