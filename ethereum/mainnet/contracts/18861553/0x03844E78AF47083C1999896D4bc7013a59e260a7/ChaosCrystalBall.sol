// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "./ERC721ChaosCoinClub.sol";

contract OwnableDelegateProxy {}
contract OpenSeaProxyRegistry {mapping(address => OwnableDelegateProxy) public proxies;}

/**
 * @title Chaos Crystal Ball
 * Chaos Crystal Ball - a contract for non-fungible tokens
 */
contract ChaosCrystalBall is ERC721ChaosCoinClub {

    string public _contractURI = "https://nftstorage.link/ipfs/bafybeicseras7t4lxqh3mfrtsaxt3hi7ftybo4dib7bhu23oegul4enct4/chaoscrystalball";
    string public _baseTokenURI = "ipfs://bafybeigpogkte6j3t5wzyg62yq2eazltjuifz5y4zy2fbxoucvrheg5wxm/"; 
    address public proxyRegistryAddress;

    mapping(address => bool) projectProxy;
    constructor()
    ERC721ChaosCoinClub("Chaos Crystal Ball", "CHAOSCRYSTALBALL", 25000000000000000, 333, 10, 25 * 10 ** 18)
    {
        proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    }
    
    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner
    {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function enableProxyState(address proxyAddress) external onlyOwner
    {
        projectProxy[proxyAddress] = true;
    }

    function disableProxyState(address proxyAddress) external onlyOwner
    {
        projectProxy[proxyAddress] = false;
    }

    function checkProxyState(address proxyAddress) public view returns (bool)
    {
        return projectProxy[proxyAddress];
    }

    function baseTokenURI() public override view returns (string memory) 
    {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string calldata newBaseTokenURI) public onlyOwner 
    {
        _baseTokenURI = newBaseTokenURI;
    }
    

    function setContractURI(string calldata newContractURI) public onlyOwner 
    {
        _contractURI = newContractURI;
    }


    function contractURI() public view returns (string memory) 
    {
        return _contractURI;
    }


    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */

    function isApprovedForAll(address owner, address operator) public view override returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator || projectProxy[operator]) return true;

        return super.isApprovedForAll(owner, operator);
    }


}
