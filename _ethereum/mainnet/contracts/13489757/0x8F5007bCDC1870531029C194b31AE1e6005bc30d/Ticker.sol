//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Interfaces.sol";

contract Ticker {
    ENSRegistryWithFallback ens;

    constructor() {
        ens = ENSRegistryWithFallback(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e); 
        // The ens registry address is shared across testnets and mainnet
    }

    // Enter 'uni' to lookup uni.tkn.eth
    function addressFor(string calldata _name) public view returns (address) {
        bytes32 namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked('eth')))
        );
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked('tkn')))
        );
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked(_name)))
        );
        address resolverAddr = ens.resolver(namehash);
        PublicResolver resolver = PublicResolver(resolverAddr);
        return resolver.addr(namehash);
    }

    struct Metadata {
        address contractAddress;
        string name;
        string url;
        string avatar;
        string description;
        string notice;
        string twitter;
        string github;
    }

    function infoFor(string calldata _name) public view returns (Metadata memory) {
        bytes32 namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked('eth')))
        );
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked('tkn')))
        );
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked(_name)))
        );
        address resolverAddr = ens.resolver(namehash);
        PublicResolver resolver = PublicResolver(resolverAddr);
        return Metadata(
            resolver.addr(namehash),
            resolver.text(namehash, "name"),
            resolver.text(namehash, "url"),
            resolver.text(namehash, "avatar"),
            resolver.text(namehash, "description"),
            resolver.text(namehash, "notice"),
            resolver.text(namehash, "com.twitter"),
            resolver.text(namehash, "com.github")
        );

    }
    
    // Calculate the namehash offchain using eth-ens-namehash to save gas costs.
    // Better for write queries that require gas
    // Library: https://npm.runkit.com/eth-ens-namehash
    function gasEfficientFetch(bytes32 namehash) public view returns (address) {
        address resolverAddr = ens.resolver(namehash);
        PublicResolver resolver = PublicResolver(resolverAddr);
        return resolver.addr(namehash);
    }
        
    // Get an account's balance using a ticker symbol
    function balanceWithTicker(address user, string calldata tickerSymbol) public view returns (uint) {
        IERC20 tokenContract = IERC20(addressFor(tickerSymbol));
        return tokenContract.balanceOf(user);
    }
}