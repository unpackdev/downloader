// SPDX-License-Identifier: MIT
// ░██╗░░░░░░░██╗██╗░░██╗░█████╗░████████╗  ░█████╗░██████╗░███████╗  ██╗░░░██╗░█████╗░██╗░░░██╗
// ░██║░░██╗░░██║██║░░██║██╔══██╗╚══██╔══╝  ██╔══██╗██╔══██╗██╔════╝  ╚██╗░██╔╝██╔══██╗██║░░░██║
// ░╚██╗████╗██╔╝███████║███████║░░░██║░░░  ███████║██████╔╝█████╗░░  ░╚████╔╝░██║░░██║██║░░░██║
// ░░████╔═████║░██╔══██║██╔══██║░░░██║░░░  ██╔══██║██╔══██╗██╔══╝░░  ░░╚██╔╝░░██║░░██║██║░░░██║
// ░░╚██╔╝░╚██╔╝░██║░░██║██║░░██║░░░██║░░░  ██║░░██║██║░░██║███████╗  ░░░██║░░░╚█████╔╝╚██████╔╝
// ░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░  ╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝  ░░░╚═╝░░░░╚════╝░░╚═════╝░

// ██████╗░░█████╗░██╗███╗░░██╗░██████╗░  ██╗███╗░░██╗  ██╗░░██╗███████╗██████╗░███████╗
// ██╔══██╗██╔══██╗██║████╗░██║██╔════╝░  ██║████╗░██║  ██║░░██║██╔════╝██╔══██╗██╔════╝
// ██║░░██║██║░░██║██║██╔██╗██║██║░░██╗░  ██║██╔██╗██║  ███████║█████╗░░██████╔╝█████╗░░
// ██║░░██║██║░░██║██║██║╚████║██║░░╚██╗  ██║██║╚████║  ██╔══██║██╔══╝░░██╔══██╗██╔══╝░░
// ██████╔╝╚█████╔╝██║██║░╚███║╚██████╔╝  ██║██║░╚███║  ██║░░██║███████╗██║░░██║███████╗
// ╚═════╝░░╚════╝░╚═╝╚═╝░░╚══╝░╚═════╝░  ╚═╝╚═╝░░╚══╝  ╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚══════╝

// ███████╗░██████╗██████╗░███████╗███╗░░██╗░█████╗░
// ██╔════╝██╔════╝██╔══██╗██╔════╝████╗░██║██╔══██╗
// █████╗░░╚█████╗░██████╔╝█████╗░░██╔██╗██║╚═╝███╔╝
// ██╔══╝░░░╚═══██╗██╔═══╝░██╔══╝░░██║╚████║░░░╚══╝░
// ███████╗██████╔╝██║░░░░░███████╗██║░╚███║░░░██╗░░

// What the fuck did you just fucking say about me, you little bitch? 
// I'll have you know I graduated top of my class in the Navy Seals, 
// and I've been involved in numerous secret raids on Al-Quaeda, and I have over 300 confirmed kills. 
// I am trained in gorilla warfare and I'm the top sniper in the entire US armed forces. 
// You are nothing to me but just another target. 
// I will wipe you the fuck out with precision the likes of which has never been seen before on this Earth, mark my fucking words. 
// You think you can get away with saying that shit to me over the Internet? 
// Think again, fucker. 
// As we speak I am contacting my secret network of spies across the USA and your IP is being traced right now so you better prepare for the storm, maggot.
// The storm that wipes out the pathetic little thing you call your life. You're fucking dead, kid.
// I can be anywhere, anytime, and I can kill you in over seven hundred ways, and that's just with my bare hands. 
// Not only am I extensively trained in unarmed combat, but I have access to the entire arsenal of the United States Marine Corps
// and I will use it to its full extent to wipe your miserable ass off the face of the continent, you little shit.
// If only you could have known what unholy retribution your little "clever" comment was about to bring down upon you,
// maybe you would have held your fucking tongue. But you couldn't, you didn't, and now you're paying the price, you goddamn idiot.
// I will shit fury all over you and you will drown in it. You're fucking dead, kiddo.

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract EspenBachelorVIPParty is ERC721A, Ownable, ReentrancyGuard {

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

  function withdraw() public onlyOwner nonReentrant {
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
