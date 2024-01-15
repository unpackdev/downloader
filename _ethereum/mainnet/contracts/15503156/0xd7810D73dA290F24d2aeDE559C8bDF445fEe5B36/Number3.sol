// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

// $$\   $$\               $$$$$$\         $$$$$$\                                          $$\           
// $$$\  $$ |             $$ ___$$\       $$  __$$\                                         \__|          
// $$$$\ $$ | $$$$$$\     \_/   $$ |      $$ /  \__| $$$$$$\  $$$$$$$\   $$$$$$\   $$$$$$$\ $$\  $$$$$$$\ 
// $$ $$\$$ |$$  __$$\      $$$$$ /       $$ |$$$$\ $$  __$$\ $$  __$$\ $$  __$$\ $$  _____|$$ |$$  _____|
// $$ \$$$$ |$$ /  $$ |     \___$$\       $$ |\_$$ |$$$$$$$$ |$$ |  $$ |$$$$$$$$ |\$$$$$$\  $$ |\$$$$$$\  
// $$ |\$$$ |$$ |  $$ |   $$\   $$ |      $$ |  $$ |$$   ____|$$ |  $$ |$$   ____| \____$$\ $$ | \____$$\ 
// $$ | \$$ |\$$$$$$  |$$\\$$$$$$  |      \$$$$$$  |\$$$$$$$\ $$ |  $$ |\$$$$$$$\ $$$$$$$  |$$ |$$$$$$$  |
// \__|  \__| \______/ \__|\______/        \______/  \_______|\__|  \__| \_______|\_______/ \__|\_______/ 

contract Number3 is ERC721AQueryable, Ownable, ReentrancyGuard {
    
  using SafeMath for uint256;
  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;
  
  mapping(uint256 => address) private _royaltyReceivers;
  
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
    _safeMint(0xA669b2527921cEAb31a872a907C539004660d239, 6);
    _safeMint(0x27A114207756DB5731AA30e415BC837e5547CD60, 6);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }
  
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    uint256 amount = _salePrice.mul(750).div(10000);
    address royaltyAddress = address(this);
    address royaltyReceiver = _royaltyReceivers[_tokenId] != address(0) ? _royaltyReceivers[_tokenId] : royaltyAddress;
    return (royaltyReceiver, amount);
  }
  
  function addRoyaltyReceiverForTokenId(address receiver, uint256 tokenId) public onlyOwner {
    _royaltyReceivers[tokenId] = receiver;
  }

  function withdrawCosts() public onlyOwner nonReentrant {
    uint tenPercent = address(this).balance * 10 / 100;
    (bool no3, ) = payable(0xA669b2527921cEAb31a872a907C539004660d239).call{value: tenPercent}("");
    require(no3);
    (bool tps, ) = payable(0x27A114207756DB5731AA30e415BC837e5547CD60).call{value: tenPercent}("");
    require(tps);
  }

  function withdrawToDAO() public onlyOwner nonReentrant {
    (bool dao, ) = payable(0xa806CeB142E158d8d804372Dd5713807bccf3cb5).call{value: address(this).balance}("");
    require(dao);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
