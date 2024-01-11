// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract SuccessMetaCityMetaBots is ERC721A, Ownable {
  using Strings for uint256;

  bytes32 public whitelistMerkleRoot;
  bytes32 public freeMintMerkleRoot;
  mapping(address => bool) public whitelistClaimed;
  mapping(address => bool) public freeMintClaimed;

  string public uriPrefix;
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public baseCost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public airdropTeamReserve = 300;
  uint256 public freeMintReserve = 50;
  
  // FreeMint
  uint256 public dutchPriceAdditional; // record the additional price of dutch and deduct
  uint256 public dutchStartTime; // record the start time
  uint256 public dutchDuration; // record the duration
  uint256 public dutchEndTime; // record the end time

  bool public paused = true;
  bool public revealed = false;
  bool public MintIsEnded = false;
  bool public whitelistMintEnabled = false;
  bool public freeMintEnabled = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _baseCost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setBaseCost(_baseCost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount + airdropTeamReserve + freeMintReserve <= maxSupply, "Max supply exceeded!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= getCurrentPrice() * _mintAmount, "Insufficient funds!");
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(whitelistMintEnabled, "The whitelist sale is not enabled!");
    require(!whitelistClaimed[_msgSender()], "Address already claimed!");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), "Invalid proof!");

    whitelistClaimed[_msgSender()] = true;

    _safeMint(_msgSender(), _mintAmount);
  }

  function freeMint(bytes32[] calldata _merkleProof) public mintCompliance(1)  {
    require(freeMintEnabled, "The freeMint is not enabled!");
    require(!freeMintClaimed[_msgSender()], "Address already claimed!");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, freeMintMerkleRoot, leaf), "Invalid proof!");
    
    freeMintClaimed[_msgSender()] = true;
    freeMintReserve -= 1;

    _safeMint(_msgSender(), 1);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    require(block.timestamp >= dutchStartTime, "The Auction has not started yet");
  
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner mintCompliance(_mintAmount) {
    airdropTeamReserve -= _mintAmount;

    _safeMint(_receiver, _mintAmount);
  }

  function setDutchAuction(uint256 dutchPriceAdditional_, uint256 dutchStartTime_, uint256 dutchDuration_) public onlyOwner {
    dutchPriceAdditional = dutchPriceAdditional_;
    dutchStartTime = dutchStartTime_;
    dutchDuration = dutchDuration_;
    dutchEndTime = dutchStartTime + dutchDuration;
  }

  function getTimeElapsed() public view returns (uint256) {
    return dutchStartTime > 0 ? (dutchStartTime + dutchDuration) >= block.timestamp ? (block.timestamp - dutchStartTime) : dutchDuration : 0;
  }

  function getTimeRemaining() public view returns (uint256) {
    return dutchDuration - getTimeElapsed();
  }

  function getCurrentPrice() public view returns (uint256) {
    if (paused) {
      return baseCost;
    }

    return baseCost + ((dutchDuration - getTimeElapsed()) * dutchPriceAdditional / dutchDuration);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned) {
        if (ownership.addr != address(0)) {
          latestOwnerAddress = ownership.addr;
        }

        if (latestOwnerAddress == _owner) {
          ownedTokenIds[ownedTokenIndex] = currentTokenId;

          ownedTokenIndex++;
        }
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

  function burnMetaBot(uint256 tokenId) external {
    require(MintIsEnded, "Mint is still in progress");
    require(_exists(tokenId), "Inexistant Token");
    require(msg.sender == ownerOf(tokenId), "Not Owner");

    _burn(tokenId);
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setBaseCost(uint256 _baseCost) public onlyOwner {
    baseCost = _baseCost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _newuriPrefix) public onlyOwner {
    uriPrefix = _newuriPrefix;
  }

  function setUriSuffix(string memory _newuriSuffix) public onlyOwner {
    uriSuffix = _newuriSuffix;
  }

  function setAirdropTeamReserve(uint256 _newairdropTeamReserve) public onlyOwner {
    airdropTeamReserve = _newairdropTeamReserve;
  }  

  function setFreeMintReserve(uint256 _newfreeMintReserve) public onlyOwner {
    freeMintReserve = _newfreeMintReserve;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function setFreeMintEnabled(bool _state) public onlyOwner {
    freeMintEnabled = _state;
  }

  function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) public onlyOwner {
    whitelistMerkleRoot = _whitelistMerkleRoot;
  }

  function setFreeMintMerkleRoot(bytes32 _freeMintMerkleRoot) public onlyOwner {
    freeMintMerkleRoot = _freeMintMerkleRoot;
  }

  function setMintIsEnded(bool _state) public onlyOwner {
    MintIsEnded = _state;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
