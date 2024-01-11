//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract ASociety is ERC721A, Ownable {
  // events
  event Mint(address sender, uint256 count);
  event SetMerkleRoot(bytes32 merkleRoot);
  event SetBaseURI(string baseURI);
  event SetPrice(uint256 price);
  event Pause();
  event Unpause();
  event ToggleSale(bool saleIsOpen);
  event Withdraw(uint256 balance);

  string public _baseTokenURI;

  bool public saleIsOpen;
  bool public paused;
  uint256 public basePrice = 0.1 ether;

  uint256 public constant START_TOKEN_ID = 1;
  uint256 public constant MAX_SUPPLY = 5000; // max supply 5000
  uint256 public constant MAX_PER_USER = 15; // max 15 for user

  modifier notPaused() {
    if (_msgSender() != owner()) {
      require(!paused, 'Pausable: paused');
    }
    _;
  }

  constructor(string memory baseTokenURI_) ERC721A('Lousy & A.Society', 'LOUSYASOCIETY') {
    _baseTokenURI = baseTokenURI_;
  }

  function mint(uint256 _count) external payable notPaused {
    address _caller = _msgSender();

    require(
      balanceOf(_caller) + _count < MAX_PER_USER + 1,
      'You are not allowed to mint this many!'
    );

    _mint(_count);

    emit Mint(_msgSender(), _count);
  }

  function price(uint256 _count) public view returns (uint256) {
    return basePrice * _count;
  }

  function setPrice(uint256 _price) public onlyOwner {
    require(_price > 0, 'Price must be greater than 0');

    emit SetPrice(_price);

    basePrice = _price;
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
