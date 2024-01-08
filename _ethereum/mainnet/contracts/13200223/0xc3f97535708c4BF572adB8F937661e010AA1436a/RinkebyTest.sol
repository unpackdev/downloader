// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./PaymentSplitter.sol";
import "./Pausable.sol";

contract LootToad is ERC721, PaymentSplitter, Ownable, Pausable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;
  string private _api_entry;
  uint256 private _itemPrice;
  uint256 private _maxNftAtOnce = 1;
  bool public saleIsActive = false;

  // 100 reserve and giveaways / promo
  uint256 public constant MAXNFT = 9000;

  mapping(uint256 => uint256) private _totalSupply;
  Counters.Counter private _tokenIdCounter;

  address[] private _team = [
    0xe5857AEC3a9A7FfB1F49ceeC2f01c02e4eA5fb47 // 100
  ];

  uint256[] private _team_shares = [100];

  constructor()
    PaymentSplitter(_team, _team_shares)
    ERC721('Loot Toads', unicode'TOADS🐸')
  {
    _api_entry = 'https://loottoadsnft.com/metadata/';

    setItemPrice(50000000000000000);
  }

  function mineReserves(uint256 _amount) public onlyOwner {
    for (uint256 x = 0; x < _amount; x++) {
      master_mint();
    }
  }

  // --------------------------------------------------------------------

  function flipSaleState() public onlyOwner {
    saleIsActive = !saleIsActive;
  }

  function _baseURI() internal view override returns (string memory) {
    return _api_entry;
  }

  function setBaseURI(string memory _uri) public onlyOwner {
    _api_entry = _uri;
  }

  function getOneNFT() public payable {
    require(saleIsActive, 'Sale must be active to mint');
    require(msg.value == getItemPrice(), 'insufficient ETH');
    require(
      _tokenIdCounter.current() <= MAXNFT,
      'Purchase would exceed max supply'
    );
    master_mint();
  }

  function getMultipleNFT(uint256 _howMany) public payable {
    require(saleIsActive, 'Sale must be active to mint');
    require(_howMany <= _maxNftAtOnce, "to many NFT's at once");
    require(getItemPrice().mul(_howMany) == msg.value, 'insufficient ETH');
    require(
      _tokenIdCounter.current().add(_howMany) <= MAXNFT,
      'Purchase would exceed max supply'
    );
    for (uint256 i = 0; i < _howMany; i++) {
      master_mint();
    }
  }

  function master_mint() private {
    _safeMint(msg.sender, _tokenIdCounter.current() + 1);
    _tokenIdCounter.increment();
  }

  function totalSupply() public view virtual returns (uint256) {
    return _tokenIdCounter.current();
  }

  function getotalSupply(uint256 id) public view virtual returns (uint256) {
    return _totalSupply[id];
  }

  function exists(uint256 id) public view virtual returns (bool) {
    return getotalSupply(id) > 0;
  }

  function mintID(address to, uint256 id) public onlyOwner {
    require(_totalSupply[id] == 0, 'this NFT is already owned by someone');
    _tokenIdCounter.increment();
    _mint(to, id);
  }

  function safeMint(address to) public onlyOwner {
    _safeMint(to, _tokenIdCounter.current());
    _tokenIdCounter.increment();
  }

  // set nft price
  function getItemPrice() public view returns (uint256) {
    return _itemPrice;
  }

  function setItemPrice(uint256 _price) public onlyOwner {
    _itemPrice = _price;
  }

  // maximum purchaseable items at once
  function getMaxNftAtOnce() public view returns (uint256) {
    return _maxNftAtOnce;
  }

  function setMaxNftAtOnce(uint256 _items) public onlyOwner {
    _maxNftAtOnce = _items;
  }

  function withdrawParitial() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }

  function withdrawAll() public onlyOwner {
    for (uint256 i = 0; i < _team.length; i++) {
      address payable wallet = payable(_team[i]);
      release(wallet);
    }
  }
}