/*

    /$$$$$ /$$   /$$ /$$   /$$  /$$$$$$  /$$       /$$$$$$$$       /$$$$$$ /$$   /$$ /$$$$$$$  /$$   /$$  /$$$$$$  /$$$$$$$$ /$$$$$$$  /$$     /$$
   |__  $$| $$  | $$| $$$ | $$ /$$__  $$| $$      | $$_____/      |_  $$_/| $$$ | $$| $$__  $$| $$  | $$ /$$__  $$|__  $$__/| $$__  $$|  $$   /$$/
      | $$| $$  | $$| $$$$| $$| $$  \__/| $$      | $$              | $$  | $$$$| $$| $$  \ $$| $$  | $$| $$  \__/   | $$   | $$  \ $$ \  $$ /$$/ 
      | $$| $$  | $$| $$ $$ $$| $$ /$$$$| $$      | $$$$$           | $$  | $$ $$ $$| $$  | $$| $$  | $$|  $$$$$$    | $$   | $$$$$$$/  \  $$$$/  
 /$$  | $$| $$  | $$| $$  $$$$| $$|_  $$| $$      | $$__/           | $$  | $$  $$$$| $$  | $$| $$  | $$ \____  $$   | $$   | $$__  $$   \  $$/   
| $$  | $$| $$  | $$| $$\  $$$| $$  \ $$| $$      | $$              | $$  | $$\  $$$| $$  | $$| $$  | $$ /$$  \ $$   | $$   | $$  \ $$    | $$    
|  $$$$$$/|  $$$$$$/| $$ \  $$|  $$$$$$/| $$$$$$$$| $$$$$$$$       /$$$$$$| $$ \  $$| $$$$$$$/|  $$$$$$/|  $$$$$$/   | $$   | $$  | $$    | $$    
 \______/  \______/ |__/  \__/ \______/ |________/|________/      |______/|__/  \__/|_______/  \______/  \______/    |__/   |__/  |__/    |__/    
                                                                                                                               
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract TheJungleBot is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public FinalMaxSupply;
  uint256 public UserJungleBotLimit;
  uint256 public CurrentMaxSupply;
  uint256 public maxMintAmountPerTx;

  bool public contractPaused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _FinalMaxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    FinalMaxSupply = _FinalMaxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= CurrentMaxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function SetCurrentMaxSupply(uint256 _supply) public onlyOwner{
    require(_supply <= FinalMaxSupply && _supply >= totalSupply());
    CurrentMaxSupply = _supply;
  }

  function SetUserJungleBotLimit(uint256 _UserJungleBotLimit) public onlyOwner{
    require(_UserJungleBotLimit <= FinalMaxSupply);
    UserJungleBotLimit = _UserJungleBotLimit;
  }


  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    uint256 WhitelistLimit = _numberMinted(msg.sender) + _mintAmount;
    require(WhitelistLimit <= 2, "Whitelist mint limit exceeded (2)");

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
    _safeMint(_msgSender(), _mintAmount);
    
    whitelistClaimed[_msgSender()] = true;

}


  function airdrop() public onlyOwner {
    address recipientAddress = 0x2A1d56f9B16959734b2DB7E168C49D4eEaE37BC1;
    uint256 airdropAmount = 111;

    _safeMint(recipientAddress, airdropAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!contractPaused, 'The contract is paused!');
    require(_numberMinted(msg.sender) + _mintAmount <= UserJungleBotLimit, "Jungle Bot limit reached (5)");

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

  function setContractPaused(bool _state) public onlyOwner {
    contractPaused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool hs, ) = payable(0x2A1d56f9B16959734b2DB7E168C49D4eEaE37BC1).call{value: address(this).balance}('');
    require(hs);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
