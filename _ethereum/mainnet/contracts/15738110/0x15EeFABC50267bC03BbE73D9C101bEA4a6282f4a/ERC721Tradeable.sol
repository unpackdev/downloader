// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";
import "./ERC721Royalty.sol";


import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";
                                                                 
contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract ERC721Tradeable is ERC721, ERC721Royalty, ContextMixin, NativeMetaTransaction, Ownable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  //Price is 0.001 ETH OR 0.01 for 10 OR 0.02 for 20
  uint256 internal PRICE = 10000000;
  string public _contractURI;
  string internal _baseTokenURI;
  bool internal _isActive;
  string internal name_;
  string internal symbol_;
  uint256 internal MAX_FREE = 1;
  address proxyRegistryAddress;
  uint256 internal constant MAX_SUPPLY = 3000;
  uint256 internal constant MAX_PER_TX = 20;
  uint256 internal constant MAX_PER_WALLET = 40;
  Counters.Counter internal _nextTokenId;
     
    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _nextTokenId.increment();
        _initializeEIP712(_name);
        name_ = _name;
        symbol_ = _symbol; 
        _setDefaultRoyalty(address(this), 750);
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal override {
      _safeMint(to, tokenId, data);
    }

    function updateRoyalties(address newAddress, uint96 bps) public onlyOwner {
      _setDefaultRoyalty(newAddress, bps);
    }

    event Received(address, uint);
    
    receive() external payable {
      emit Received(msg.sender, msg.value);
    }

    function name() public view virtual override(ERC721) returns (string memory) {
        return name_;
    }

    function setFreePerWallet(uint256 amount) public onlyOwner {
      MAX_FREE = amount;
    }

    function setMintPriceInGWei(uint256 price) public onlyOwner {
      PRICE = price;
    }

    function symbol() public view virtual override(ERC721) returns (string memory) {
        return symbol_;
    }

    function mintPriceInWei() public view virtual returns (uint256) {
        return SafeMath.mul(PRICE, 1e9);
    }

    function maxFree() public view virtual returns (uint256) {
        return MAX_FREE;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721) {
      return super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) pure internal override(ERC721Royalty, ERC721) {
        revert("not supported");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Royalty, ERC721) returns (bool) {
      return super.supportsInterface(interfaceId);
    }
    
}
