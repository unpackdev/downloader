// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./ERC721.sol";
import "./WhitelistExchangesProxy.sol";
import "./MixinOwnable.sol";

contract HashBaseV2 is Ownable, ERC721 {

    WhitelistExchangesProxy public immutable exchangesProxy;
    string public baseMetadataURI;
    string public contractURI;

    constructor (
      string memory name_,
      string memory symbol_,
      address exchangesProxy_
    ) ERC721(name_, symbol_) {
      exchangesProxy = WhitelistExchangesProxy(exchangesProxy_);
    }

    function setBaseMetadataURI(string memory _baseMetadataURI) public onlyOwner {
      baseMetadataURI = _baseMetadataURI;
    }

    function setContractURI(string calldata newContractURI) external onlyOwner {
        contractURI = newContractURI;
    }

    function _baseURI() override internal view virtual returns (string memory) {
      return baseMetadataURI;
    }

    function isApprovedForAllExchangesProxy(address spender) public view returns (bool) {
      return exchangesProxy.isAddressWhitelisted(spender);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) override internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender)) || isApprovedForAllExchangesProxy(spender);
    } 
}