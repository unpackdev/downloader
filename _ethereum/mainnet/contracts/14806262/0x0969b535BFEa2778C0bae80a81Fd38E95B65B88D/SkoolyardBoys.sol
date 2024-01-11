// SPDX-License-Identifier: MIT



/*
  ___________                .__                          .___ __________                     
 /   _____/  | ______   ____ |  | ___.__._____ _______  __| _/ \______   \ ____ ___.__. ______
 \_____  \|  |/ /  _ \ /  _ \|  |<   |  |\__  \\_  __ \/ __ |   |    |  _//  _ <   |  |/  ___/
 /        \    <  <_> |  <_> )  |_\___  | / __ \|  | \/ /_/ |   |    |   (  <_> )___  |\___ \ 
/_______  /__|_ \____/ \____/|____/ ____|(____  /__|  \____ |   |______  /\____// ____/____  >
        \/     \/                 \/          \/           \/          \/       \/         \/ 
*/

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

pragma solidity >=0.8.9 <0.9.0;

contract SkoolyardBoys is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;

  string public uriPrefix;
  string public uriSuffix = ".json";
  
  // hidden uri
  string public hiddenMetadataUri = "ipfs://QmdoPFX2Gox2mmunF1W2C4conNyrHPPYySGeSQMw5aJioN/hidden.json";
  
  // prices
  uint256 public price = 0.075 ether;
  uint256 public Wlprice = 0.07 ether;
  
  // supply
  uint256 public maxSupply = 3333;
  
  // max per tx 
  uint256 public maxMintAmountPerTx = 25;
  uint256 public WLmaxMintAmountPerTx = 2;

  // max per wallet
  uint256 public maxLimitPerWallet = 2;
  
  // enabled
  bool public whitelistSale = false;
  bool public publicSale = false;
  
  // reveal
  bool public revealed = false;

  constructor(
    string memory _uriPrefix
  ) ERC721A("Skoolyard Boys", "SYB")  {
    setUriPrefix(_uriPrefix);
  }

  modifier WLmintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= WLmaxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require(balanceOf(msg.sender) + _mintAmount <= maxLimitPerWallet, "Max mint per wallet exceeded!");
    _;
  }

  modifier WLmintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= Wlprice * _mintAmount, 'Insufficient funds!');
    _;
  }

    modifier PublicCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    _;
  }

    modifier PublicPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= price * _mintAmount, 'Insufficient funds!');
    _;
  }

  function WhitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable WLmintCompliance(_mintAmount) WLmintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistSale, 'The whitelist sale is paused!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
    _safeMint(_msgSender(), _mintAmount);
  }

  function PublicMint(uint256 _mintAmount) public payable PublicCompliance(_mintAmount) PublicPriceCompliance(_mintAmount) {
    require(publicSale, 'The PublicSale is paused!');
    require(!whitelistSale, 'Whitelist Mint is going on, Please wait for public sale to open');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function Airdrop(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }

      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
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

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setWlprice(uint256 _Wlprice) public onlyOwner {
    Wlprice = _Wlprice;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setWLmaxMintAmountPerTx(uint256 _WLmaxMintAmountPerTx) public onlyOwner {
    WLmaxMintAmountPerTx = _WLmaxMintAmountPerTx;
  }

  function setmaxLimitPerWallet(uint256 _maxLimitPerWallet) public onlyOwner {
    maxLimitPerWallet = _maxLimitPerWallet;
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

  function setpublicSale(bool _publicSale) public onlyOwner {
    publicSale = _publicSale;
  }

  function setmaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setwhitelistSale(bool _state) public onlyOwner {
    whitelistSale = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    //owner withdraw
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
