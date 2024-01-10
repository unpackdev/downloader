// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./MerkleProof.sol";

contract MetaBrawlers is ERC721Enumerable, Ownable {
  using Strings for uint;
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  uint256 public constant MAX_ELEMENTS = 500;
  uint256 public constant WLPRICE = 14 * 10**16;
  uint256 public constant PRICE = 16 * 10**16;
  uint256 public nftPerAddressLimit = 2;

  bytes32 public merkleRoot;

  address public constant artistAddress = 0x31F1e7284db96D01397f202C6638396Baf08068a;
  address public constant devAddress = 0x070D57F47c8Acced103B215692b72C102A672E72;

  bool public onlyWhiteListed = true;
  bool public revealed;
  bool private PAUSE = true;

  mapping(address => bool) public whitelistClaimed;

  Counters.Counter private _tokenIdTracker;

  string public baseTokenURI;
  string public notRevealedURI;
  string public baseExtension;

  event brawlerBirth(uint256 indexed id);
  event pauseEvent(bool pause);

  constructor(string memory _baseURI, string memory _baseExtension, string memory _notRevealedURI) ERC721("MetaBrawlers","BRAWL"){
    setBaseURI(_baseURI, _baseExtension);
    setNotRevealedURI(_notRevealedURI);
  }

  modifier saleIsOpen {
    require(tokenCount() <= MAX_ELEMENTS, "None Left!");
    require(!PAUSE, "Sale paused");
    _;
  }

  modifier publicSale {
    require(!onlyWhiteListed, "Mint is currently whitelist only");
    _;
  }

  function setNftPerAddressLimit(uint256 _limit) public onlyOwner() {
    nftPerAddressLimit = _limit;
  }

  function setBaseURI(string memory _baseURI, string memory _baseExtension) public onlyOwner {
    require(PAUSE, "Not paused");

    baseTokenURI = _baseURI;
    baseExtension = _baseExtension;
  }

  function tokenCount() public view returns (uint256) {
    return _tokenIdTracker.current();
  }

  function _generateMerkleLeaf(address account) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(account));
  }

  function whitelistMint(bytes32[] calldata proof) public payable saleIsOpen {

    uint256 total = tokenCount() + 1;
    require(!whitelistClaimed[msg.sender], "Whitelist address has already claimed.");
    require(1 + balanceOf(msg.sender) <= nftPerAddressLimit, "Exceeds personal limit");
    require(total + 1 <= MAX_ELEMENTS, "Over Supply Limit");
    require(msg.value >= WLPRICE, "Insufficient funds");
    require(MerkleProof.verify(proof, merkleRoot, _generateMerkleLeaf(msg.sender)), "Address does not exist in whitelist");


    address wallet = _msgSender();

    whitelistClaimed[msg.sender] = true;
    
    _mintNFT(wallet, total);
  }
  

  function mint(uint256 _count) public payable saleIsOpen publicSale {

    uint256 total = tokenCount() + 1;
    require(_count + balanceOf(msg.sender) <= nftPerAddressLimit, "Exceeds personal limit");
    require(total + _count <= MAX_ELEMENTS, "Over Supply Limit");
    require(msg.value >= price(_count), "Insufficient funds");

    address wallet = _msgSender();

      for(uint256 i=0; i < _count; i++){
            _mintNFT(wallet, total + i);
    }
  }

  function _mintNFT(address _to, uint256 _tokenId) private {

    _tokenIdTracker.increment();
    _safeMint(_to, _tokenId);

    emit brawlerBirth(_tokenId);

  }

  function price(uint256 _count) public pure returns (uint256) {
    return PRICE.mul(_count);
  }

    function wlprice() public pure returns (uint256) {
    return WLPRICE.mul(1);
  }

  function walletOfOwner(address _owner) external view returns (uint256[] memory) {
    uint256 tokensOwned = balanceOf(_owner);

    uint256[] memory tokensId = new uint256[](tokensOwned);
    for(uint256 i=0; i < tokensOwned; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }

    return tokensId;
  }

  function setOnlyWhitelisted(bool _state) public onlyOwner{
    onlyWhiteListed = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner{
    merkleRoot = _merkleRoot;
  }

  function pause(bool _pause) public onlyOwner{
    PAUSE = _pause;
    emit pauseEvent(PAUSE);
  }

  function withdrawAll() public onlyOwner {
    uint256 balance = address(this).balance;
    require(balance>0);
    _withdraw(artistAddress, balance.mul(50).div(100));
    _withdraw(devAddress, address(this).balance);
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value:_amount}("");
    require(success, "Transfer failed.");
  }

  function tokenURI(uint tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    if(!revealed) {
        return notRevealedURI;
    }
    return bytes(baseTokenURI).length > 0
        ? string(abi.encodePacked(baseTokenURI, tokenId.toString(), baseExtension)): "";
  }

  function setRevealed(bool _revealed) public onlyOwner() {
      revealed = _revealed;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedURI = _notRevealedURI;
  }

  function mintUnsoldTokens(uint256 mintCount) public onlyOwner {

    require(PAUSE, "Not paused");
    uint256 total = tokenCount() + 1;
    require(total + mintCount <= MAX_ELEMENTS, "Over Supply Limit");

    address wallet = _msgSender();

    for(uint256 i=0; i < mintCount; i++){
      _mintNFT(wallet, total + i);
  }
}
}

