// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721AQueryable.sol";

/*
FUD Frog Force
Fighting the FUD
2022
https://fudfrogs.wtf
*/

contract FudFrogForce is ERC721AQueryable, Ownable {
  using Strings for uint256;

  uint256 public constant TOTAL_MAX_SUPPLY = 8888;
  uint256 public totalFreeMints = 4000;
  uint256 public teamAmount = 888;
  uint256 public maxFreeMintPerWallet = 2;
  uint256 public maxPublicMintPerWallet = 10;
  uint256 public publicTokenPrice = .0069 ether;
  string _contractURI;

  bool public saleStarted = false;
  uint256 public freeMintCount;

  mapping(address => uint256) public freeMintClaimed;

  string private _baseTokenURI;

  constructor() ERC721A('FUD Force Frogs', 'FFF') {}

  modifier callerIsUser() {
    require(tx.origin == msg.sender, 'FudFrogForce: Ribbit.. The caller is another contract');
    _;
  }

  modifier underMaxSupply(uint256 _quantity) {
    require(
      _totalMinted() + _quantity <= TOTAL_MAX_SUPPLY - teamAmount,
      'FudFrogForce: Ribbit.. Purchase would exceed max supply'
    );
    _;
  }

  function mint(uint256 _quantity) external payable callerIsUser underMaxSupply(_quantity) {
    require(balanceOf(msg.sender) < maxPublicMintPerWallet, "FudFrogForce: Caller's token amount exceeds the limit.");
    require(saleStarted, 'FudFrogForce: Ribbit.. sale not yet started. ');
    if (_totalMinted() < (TOTAL_MAX_SUPPLY - teamAmount)) {
      if (freeMintCount >= totalFreeMints) {
        require(msg.value >= _quantity * publicTokenPrice, 'FudFrogForce: Ribbit.. Need send more ETH!');
        _mint(msg.sender, _quantity);
      } else if (freeMintClaimed[msg.sender] < maxFreeMintPerWallet) {
        uint256 _mintableFreeQuantity = maxFreeMintPerWallet - freeMintClaimed[msg.sender];
        if (_quantity <= _mintableFreeQuantity) {
          freeMintCount += _quantity;
          freeMintClaimed[msg.sender] += _quantity;
        } else {
          freeMintCount += _mintableFreeQuantity;
          freeMintClaimed[msg.sender] += _mintableFreeQuantity;
          require(
            msg.value >= (_quantity - _mintableFreeQuantity) * publicTokenPrice,
            'FudFrogForce: Ribbit.. Need send more ETH!'
          );
        }
        _mint(msg.sender, _quantity);
      } else {
        require(msg.value >= (_quantity * publicTokenPrice), 'FudFrogForce: Ribbit.. Need send more ETH!');
        _mint(msg.sender, _quantity);
      }
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function ownerMint(uint256 _numberToMint) external onlyOwner underMaxSupply(_numberToMint) {
    _mint(msg.sender, _numberToMint);
  }

  function ownerMintToAddress(address _recipient, uint256 _numberToMint)
    external
    onlyOwner
    underMaxSupply(_numberToMint)
  {
    _mint(_recipient, _numberToMint);
  }

  function setFreeMintCount(uint256 _count) external onlyOwner {
    totalFreeMints = _count;
  }

  function setTeamAmount(uint256 _count) external onlyOwner {
    teamAmount = _count;
  }

  function setMaxFreeMintPerWallet(uint256 _count) external onlyOwner {
    maxFreeMintPerWallet = _count;
  }

  function setMaxPublicMintPerWallet(uint256 _count) external onlyOwner {
    maxPublicMintPerWallet = _count;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  // Storefront metadata
  // https://docs.opensea.io/docs/contract-level-metadata
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory _URI) external onlyOwner {
    _contractURI = _URI;
  }

  function withdrawFunds() external onlyOwner {
    (bool success, ) = msg.sender.call{ value: address(this).balance }('');
    require(success, 'FudFrogForce: Ribbit.. Transfer failed.');
  }

  function withdrawFundsToAddress(address _address, uint256 amount) external onlyOwner {
    (bool success, ) = _address.call{ value: amount }('');
    require(success, 'FudFrogForce: Ribbit.. Transfer failed.');
  }

  function flipSaleStarted() external onlyOwner {
    saleStarted = !saleStarted;
  }
}
