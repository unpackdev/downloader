// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./ERC721.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./IERC2981.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////
//───────────────────────────────────────────────────────────────────────────────────────────────────────//
//─██████████████─██████──────────██████─████████──████████─████████████───██████████████─██████████████─//
//─██░░░░░░░░░░██─██░░██████████──██░░██─██░░░░██──██░░░░██─██░░░░░░░░████─██░░░░░░░░░░██─██░░░░░░░░░░██─//
//─██░░██████░░██─██░░░░░░░░░░██──██░░██─████░░██──██░░████─██░░████░░░░██─██░░██████░░██─██░░██████░░██─//
//─██░░██──██░░██─██░░██████░░██──██░░██───██░░░░██░░░░██───██░░██──██░░██─██░░██──██░░██─██░░██──██░░██─//
//─██░░██████░░██─██░░██──██░░██──██░░██───████░░░░░░████───██░░██──██░░██─██░░██████░░██─██░░██──██░░██─//
//─██░░░░░░░░░░██─██░░██──██░░██──██░░██─────████░░████─────██░░██──██░░██─██░░░░░░░░░░██─██░░██──██░░██─//
//─██░░██████░░██─██░░██──██░░██──██░░██───────██░░██───────██░░██──██░░██─██░░██████░░██─██░░██──██░░██─//
//─██░░██──██░░██─██░░██──██░░██████░░██───────██░░██───────██░░██──██░░██─██░░██──██░░██─██░░██──██░░██─//
//─██░░██──██░░██─██░░██──██░░░░░░░░░░██───────██░░██───────██░░████░░░░██─██░░██──██░░██─██░░██████░░██─//
//─██░░██──██░░██─██░░██──██████████░░██───────██░░██───────██░░░░░░░░████─██░░██──██░░██─██░░░░░░░░░░██─//
//─██████──██████─██████──────────██████───────██████───────████████████───██████──██████─██████████████─//
//───────────────────────────────────────────────────────────────────────────────────────────────────────//
///////////////////////////////////////////////////////////////////////////////////////////////////////////

contract Any is ERC721, IERC2981, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  Counters.Counter private _tokenIds;

  uint256 public constant MAX_SUPPLY = 10000;
  uint256 public constant MAX_PERMINT = 10;
  string public constant COLLECTION_NAME = "ANY";
  string public constant COLLECTION_SYMBOL = "ANY";
  uint256 public constant ROYALTY = 1000; // 10%
  uint256 public periodMaxSupply = 1;
  string private _baseTokenURI;
  bool private _isPublicSale = false;
  bool private _isPreSale = false;
  address payable private _withdrawWallet;
  address payable private _royaltyWallet;
  bytes32 public merkleRoot;

  uint256 public publicMintPrice = 0;
  uint256 public preMintPrice = (publicMintPrice.mul(5)).div(10);

  mapping(address => bool) public preMintClaimed;

  modifier isEnoughNFTs(uint256 _count) {
    uint256 totalMinted = _tokenIds.current();
    require(totalMinted.add(_count) <= MAX_SUPPLY && totalMinted.add(_count) <= periodMaxSupply, "Not enough NFTs!");
    _;
  }

  modifier isEnoughCount(uint256 _count) {
    require(_count > 0 && _count <= MAX_PERMINT, "Cannot mint specified number of NFTs.");
    _;
  }

  modifier isAmountSufficient(uint256 _amount, uint256 _count, uint256 _mintPrice) {
    require(_amount >= _mintPrice.mul(_count), 'Please submit the asking price in order to continue');
    _;
  }

  constructor(address payable withdrawWallet_, address payable royaltyWallet_, string memory baseTokenURI_, uint256 publicMintPrice_) ERC721(COLLECTION_NAME, COLLECTION_SYMBOL) {
    _withdrawWallet = withdrawWallet_;
    _royaltyWallet = royaltyWallet_;
    setBaseURI(baseTokenURI_);
    publicMintPrice = publicMintPrice_;
    preMintPrice = (publicMintPrice.mul(7)).div(10);
  }

  function switchPublicMintSale() external onlyOwner {
    _isPreSale = false;
    _isPublicSale = true;
  }

  function switchPreMintSale() external onlyOwner {
    _isPublicSale = false;
    _isPreSale = true;
  }

  function fnishSale() external onlyOwner {
    _isPublicSale = false;
    _isPreSale = false;
  }

  function publicMintStatus() external view returns(bool) {
    return _isPublicSale;
  }

  function preMintStatus() external view returns(bool) {
    return _isPreSale;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function totalSupply() external view returns (uint256) {
    return _tokenIds.current();
  }

  function setBaseURI(string memory _newURI) public onlyOwner {
    _baseTokenURI = _newURI;
  }

  function setPeriodMaxSupply(uint256 _value) external onlyOwner {
    periodMaxSupply = _value;
  }

  function setPublicMintPrice(uint256 publicMintPrice_) external onlyOwner {
    publicMintPrice = publicMintPrice_;
  }

  function setPreMintPrice(uint256 preMintPrice_) external onlyOwner {
    preMintPrice = preMintPrice_;
  }

  function memberDrop(address[] calldata receivers) external onlyOwner nonReentrant isEnoughNFTs(receivers.length) returns(uint256) {
    for (uint256 i; i < receivers.length; i++) {
      _mintNFT(receivers[i], 1);
    }

    return _tokenIds.current();
  }

  function ownerMint(uint256 _count) external onlyOwner isEnoughNFTs(_count) returns(uint256) {
    _mintNFT(msg.sender, _count);

    return _tokenIds.current();
  }

  function publicMint(uint256 _count) external payable nonReentrant isEnoughNFTs(_count) isEnoughCount(_count) isAmountSufficient(msg.value, _count, publicMintPrice) returns(uint256) {
    require(_isPublicSale, 'Sorry. Not yet on sale.');
    _mintNFT(msg.sender, _count);

    return _tokenIds.current();
  }

  function preMint(uint256 _count, bytes32[] calldata _merkleProof) external payable nonReentrant isEnoughNFTs(_count) isEnoughCount(_count) isAmountSufficient(msg.value, _count, preMintPrice) returns(uint256) {
    require(_isPreSale, 'Sorry. Not yet on sale.');
    require(_verify(msg.sender, _merkleProof), "Sorry, you are not on the whitelist.");
    require(!preMintClaimed[msg.sender], "You need to be whitelisted");
    require(preMintPrice != 0 ether, 'Sorry. No price has been set yet.');

    _mintNFT(msg.sender, _count);

    preMintClaimed[msg.sender] = true;

    return _tokenIds.current();
  }

  function _mintNFT(address _receiver, uint256 _count) private {
    for(uint256 i = 0; i < _count; i++) {
      _safeMint(_receiver, _tokenIds.current());
      _tokenIds.increment();
    }
  }

  function setRoyaltyWallet(address payable royaltyWallet_) external onlyOwner {
    _royaltyWallet = royaltyWallet_;
  }

  function getRoyaltyWallet() external view onlyOwner returns(address) {
    return _royaltyWallet;
  }

  function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
    require(_exists(tokenId), "Token does not exist");
    return (payable(_royaltyWallet), uint((salePrice * ROYALTY) / 10000));
  }

  function _verify(address _addr, bytes32[] calldata _merkleProof) private view returns(bool) {
    bytes32 leaf = _getLeaf(_addr);
    return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
  }

  function verify(address _addr, bytes32[] calldata _merkleProof) external view returns(bool) {
    return _verify(_addr, _merkleProof);
  }

  function _getLeaf(address addr) private pure returns(bytes32)  {
    return keccak256(abi.encodePacked(addr));
  }

  function setWithdrawalWallet(address payable withdrawWallet_) external onlyOwner {
    _withdrawWallet = withdrawWallet_;
  }

  function getWithdrawalWallet() external view onlyOwner returns(address) {
    return _withdrawWallet;
  }

  function withdraw() external payable onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No ether left to withdraw");

    (bool success,) = payable(_withdrawWallet).call{value: balance}("");

    require(success, "Transfer failed.");
  }
}
