// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract Frog is ERC721URIStorage, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  string private _customBaseURI;
  uint256 private _price;
  uint256 private _maxMintable;

  address private _chainlink;
  address private _aleph;

  string private _contractURI;

  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  constructor(string memory customBaseURI_, uint256 maxMintable_, address chainlink_, address aleph_) ERC721("Amphibian Outlaws", "OUTLAW") {
    _customBaseURI = customBaseURI_;
    _price = 0.07 ether;
    _maxMintable = maxMintable_;

    _chainlink = chainlink_;
    _aleph = aleph_;
    _contractURI = 'https://nfts.amphibianoutlaws.com/api/contract_overview';
  }

  function setBaseURI(string memory customBaseURI_) public onlyOwner {
    _customBaseURI = customBaseURI_;
  }

  function getPrice(address account) public view returns (uint256) {
    IERC20 chainlink = IERC20(_chainlink);
    IERC20 aleph = IERC20(_aleph);

    if (chainlink.balanceOf(account) >= 100 ether) {
      return 0;
    } else if (aleph.balanceOf(account) >= 2000 ether) {
      return 0;
    } else {
      return _price;
    }
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory contractURI_) public onlyOwner {
    _contractURI = contractURI_;
  }

  function purchase(uint256 quantity) public payable {
    uint256 price = getPrice(msg.sender);
    require(msg.value >= (price * quantity), "Not enough ETH sent.");
    require(quantity <= 7, "Can't mint more than 7 at a time.");

    if (price > 0) {
      payable(owner()).transfer(price * quantity);
    }

    for(uint i = 0; i < quantity; i++) {
      mintForPurchase(msg.sender);
    }
  }

  function currentSupply() public view returns (uint256) {
    return _tokenIds.current();
  }

  function mintForPurchase(address recipient) private {
    _tokenIds.increment();
    require(_tokenIds.current() <= _maxMintable, "Project is finished minting.");

    uint256 newItemId = _tokenIds.current();
    _mint(recipient, newItemId);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _customBaseURI;
  }

  function royaltyInfo(
    uint256 _tokenId, 
    uint256 _salePrice
  ) external view returns (address receiver, uint256 royaltyAmount) {
    return (owner(), ((_salePrice * 750) / 10000));
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    if (interfaceId == _INTERFACE_ID_ERC2981) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  } 
}