//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./PaymentSplitter.sol";
import "./PresaleList.sol";

// @author numbco.art
// @title Minting Miracles
contract MintingMiracles is
  ERC721,
  ERC721Enumerable,
  Ownable,
  PaymentSplitter,
  PresaleList
{
  address[] private payeeAddresses;

  uint256 private mintPrice = 0.06 ether;
  mapping(address => bool) public presaleMinted; // Mapping of addresses who have minted in presale
  mapping(address => bool) public partnerMinted; // Mapping of addresses who have minted partner tokens

  bool public presaleIsActive = false;
  bool public saleIsActive = false;
  bool public partnerGiveawayIsActive = false;

  string private _baseURIextended;

  uint16 private constant MAX_SUPPLY = 3000;
  uint16 private constant MINT_LIMIT = 10;

  uint16 private tokensGiven;

  uint16 private partnerTokensGiven;
  uint16 private tokensPartner = 378; // Not a constant. If not all partners mint, set to 0

  bytes32[] private merkleRoots;
  uint16[] private presaleCounts;

  event MintPresale(address indexed claimer, uint256 indexed tokenId);
  event MintGiveaway(address indexed claimer, uint256 indexed tokenId);
  event MintPublic(address indexed claimer, uint256 indexed tokenId);
  event MintPartner(address indexed claimer, uint256 indexed tokenId);

  constructor(
    address[] memory _payeeAddresses,
    uint256[] memory payeeShares,
    bytes32[] memory _merkleRoots,
    uint16[] memory _presaleCounts
  )
    ERC721("Minting Miracles", "MM")
    PaymentSplitter(_payeeAddresses, payeeShares)
    PresaleList()
  {
    payeeAddresses = _payeeAddresses;
    merkleRoots = _merkleRoots;
    presaleCounts = _presaleCounts;
  }

  function setActiveStates(
    bool _presaleIsActive,
    bool _saleIsActive,
    bool _partnerGiveawayIsActive
  ) public onlyOwner {
    presaleIsActive = _presaleIsActive;
    saleIsActive = _saleIsActive;
    partnerGiveawayIsActive = _partnerGiveawayIsActive;
  }

  function setTokensPartner(uint16 _tokensPartner) public onlyOwner {
    tokensPartner = _tokensPartner;
  }

  function getTokensPartner() public view onlyOwner returns (uint16) {
    return tokensPartner;
  }

  function setBaseURI(string memory baseURI_) public onlyOwner {
    _baseURIextended = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIextended;
  }

  function mintPresale(bytes32[] memory merkleProof, uint16 _count)
    external
    payable
  {
    uint256 ts = totalSupply();
    require(presaleIsActive, "presaleIsActive");
    require(_count <= presaleCounts[0], "TRANSACTION_LIMIT");
    require(ts + _count <= MAX_SUPPLY, "MAX_SUPPLY");
    require(msg.value >= mintPrice * _count, "mintPrice");
    require(!presaleMinted[msg.sender], "presaleMinted");
    require(isOnList(merkleRoots[0], merkleProof, msg.sender), "presaleList");

    presaleMinted[msg.sender] = true;
    for (uint16 i = 0; i < _count; i++) {
      _mint(msg.sender, ts);
      emit MintPresale(msg.sender, ts);
      ts++;
    }
  }

  function mintPartner(bytes32[] memory merkleProof, uint16 _count) external {
    uint256 ts = totalSupply();
    require(partnerGiveawayIsActive, "partnerGiveawayIsActive");
    require(_count <= presaleCounts[1], "TRANSACTION_LIMIT");
    require(ts + _count <= MAX_SUPPLY, "MAX_SUPPLY");
    require(!partnerMinted[msg.sender], "partnerMinted");
    require(isOnList(merkleRoots[1], merkleProof, msg.sender), "partnerList");

    partnerMinted[msg.sender] = true;
    for (uint16 i = 0; i < _count; i++) {
      _mint(msg.sender, ts);
      emit MintPartner(msg.sender, ts);
      ts++;
    }
  }

  function mint(uint16 _count) public payable {
    uint256 ts = totalSupply();
    require(saleIsActive, "saleIsActive");
    require(_count <= MINT_LIMIT, "MINT_LIMIT");
    require(ts + _count <= MAX_SUPPLY, "MAX_SUPPLY");
    require(msg.value >= mintPrice * _count, "mintPrice");

    for (uint16 i = 0; i < _count; i++) {
      _mint(msg.sender, ts);
      emit MintPublic(msg.sender, ts);
      ts++;
    }
  }

  function mintGiveaway(uint16 _count) public onlyOwner {
    uint256 ts = totalSupply();
    require(ts + _count <= MAX_SUPPLY, "MAX_SUPPLY");
    require(
      ts + _count <= (MAX_SUPPLY - tokensPartner),
      "ts with tokensPartner"
    );
    for (uint16 i = 0; i < _count; i++) {
      tokensGiven++;
      _mint(msg.sender, ts);
      emit MintGiveaway(msg.sender, ts);
      ts++;
    }
  }

  function withdraw() external {
    require(address(this).balance > 0, "balance");

    release(payable(msg.sender));
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
