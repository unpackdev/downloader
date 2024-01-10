//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./console.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract WEARKey is ERC721A, Ownable {
  // events
  event WhitelistMint(address sender, uint256 count);
  event Mint(address sender, uint256 count);
  event SetMerkleRoot(bytes32 merkleRoot);
  event SetBaseURI(string baseURI);
  event Pause();
  event Unpause();
  event ToggleSale(bool saleIsOpen);
  event Withdraw(uint256 balance);

  string public _baseTokenURI;

  bool public saleIsOpen;
  bool public paused;
  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  uint256 public constant PUBLIC_PRICE = 0.35 ether;
  uint256 public constant PRESALE_PRICE = 0.15 ether;
  uint256 public constant START_TOKEN_ID = 1;
  uint256 public constant MAX_SUPPLY = 1000; // max supply 1000
  uint256 public constant MAX_PER_USER = 15; // max 15 for user
  uint256 public constant MAX_PER_WHITELIST = 1; // max 1 for whitelisted user

  modifier notPaused() {
    if (_msgSender() != owner()) {
      require(!paused, 'Pausable: paused');
    }
    _;
  }

  modifier onlySaleOpen() {
    require(saleIsOpen, 'Public sale is not started yet');

    _;
  }

  modifier onlyWhitelistedUser(bytes32[] calldata _merkleProof) {
    address _caller = _msgSender();
    bytes32 leaf = keccak256(abi.encodePacked(_caller));

    require(whitelistClaimed[_caller] == false, 'Address has already claimed');
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof');
    _;
  }

  constructor(string memory baseTokenURI_) ERC721A('WEARKey', 'WEARKEY') {
    _baseTokenURI = baseTokenURI_;
  }

  function mint(uint256 _count) external payable onlySaleOpen notPaused {
    address _caller = _msgSender();

    require(
      balanceOf(_caller) + _count < MAX_PER_USER + 1,
      'You are not allowed to mint this many!'
    );

    _mint(_count);

    emit Mint(_msgSender(), _count);
  }

  function whitelistMint(uint256 _count, bytes32[] calldata _merkleProof)
    external
    payable
    notPaused
    onlyWhitelistedUser(_merkleProof)
  {
    address _caller = _msgSender();

    require(
      balanceOf(_caller) + _count < MAX_PER_WHITELIST + 1,
      'You are not allowed to mint this many!'
    );

    _mint(_count);

    whitelistClaimed[_caller] = true;

    emit WhitelistMint(_msgSender(), _count);
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    emit SetMerkleRoot(_merkleRoot);

    merkleRoot = _merkleRoot;
  }

  function price(uint256 _count) public view returns (uint256) {
    if (saleIsOpen == false) {
      return PRESALE_PRICE * _count;
    } else {
      return PUBLIC_PRICE * _count;
    }
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;

    emit SetBaseURI(baseURI);
  }

  // https://docs.opensea.io/docs/1-structuring-your-smart-contract#creature-erc721-contract
  function baseTokenURI() public view returns (string memory) {
    return _baseTokenURI;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function pause() public onlyOwner {
    paused = true;

    emit Pause();
  }

  function unpause() public onlyOwner {
    paused = false;

    emit Unpause();
  }

  function toggleSale() public onlyOwner {
    saleIsOpen = !saleIsOpen;

    emit ToggleSale(saleIsOpen);
  }

  // widthdraw fund from the contract
  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;

    require(balance > 0, 'Balance is 0');

    (bool sent, ) = payable(owner()).call{ value: balance }('');

    require(sent, 'Failed to send Ether');

    emit Withdraw(balance);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return START_TOKEN_ID;
  }

  function _mint(uint256 _count) private {
    address _caller = _msgSender();
    uint256 maxItemId = MAX_SUPPLY + START_TOKEN_ID;

    require(_currentIndex + _count < maxItemId + 1, 'Exceeds max supply');
    require(msg.value >= price(_count), 'Value below price');
    require(_count > 0, 'No 0 mints');
    require(tx.origin == _caller, 'No contracts');

    _safeMint(_caller, _count);
  }
}
