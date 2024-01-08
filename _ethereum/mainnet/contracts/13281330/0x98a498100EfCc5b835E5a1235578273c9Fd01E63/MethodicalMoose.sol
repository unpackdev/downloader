// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MethodicalMooseTradable.sol";

/**
 * @title MethodicalMoose
 * MethodicalMoose - NFT contract for MethodicalMoose
 */
contract MethodicalMoose is MethodicalMooseTradable {

    string public _provenanceHash = "";
    address _proxyRegistryAddress;

    constructor(address proxyRegistryAddress) ERC721("MethodicalMoose", "MMOOSE") {
        _proxyRegistryAddress = proxyRegistryAddress;
    }

    function baseTokenURI() override public pure returns (string memory) {
        return "https://methodicalmoose.s3.amazonaws.com/api/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://methodicalmoose.s3.amazonaws.com/api/contract-metadata.json";
    }
    
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner
    {
        _provenanceHash = provenanceHash;
    }

     /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}