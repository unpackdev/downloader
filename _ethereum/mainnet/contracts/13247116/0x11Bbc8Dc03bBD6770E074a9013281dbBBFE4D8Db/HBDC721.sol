// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./ERC721.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract HBDC is ERC721, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    string public contractMetaURI;
    address proxyRegistryAddress;

    constructor(
      string memory _name,
      string memory _symbol,
      string memory _contractMetaURI,
      string memory _baseTokenMetaURI,
      address _proxyRegistryAddress
    )
      ERC721(_name, _symbol)
    {
      _setBaseURI(_baseTokenMetaURI);
      contractMetaURI = _contractMetaURI;
      proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setContractURI(string memory _contractMetaURI) public onlyOwner{
        contractMetaURI = _contractMetaURI;
    }

    function contractURI() public view returns (string memory) {
        return contractMetaURI;
    }

    function updateTokenURI(string memory _baseTokenMetaURI) public onlyOwner {
      _setBaseURI(_baseTokenMetaURI);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId), "HBDC::tokenURI: URI query for nonexistent token");
      return string(abi.encodePacked(baseURI(), _tokenId.toString(), ".json"));
    }

    function mint(address _recipient) public onlyOwner {
      uint256 nextId = totalSupply().add(1);
      _safeMint(address(_recipient), nextId);
    }

    function mintBatch(address _recipient, uint256 _amount) public onlyOwner {
      for (uint i = 0; i < _amount; i++) {
        uint256 nextId = totalSupply().add(i);
        _safeMint(address(_recipient), nextId);
      }
    }

    /**
      Override isApprovedForAll to whitelist user's OpenSea proxy accounts to
      enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}
