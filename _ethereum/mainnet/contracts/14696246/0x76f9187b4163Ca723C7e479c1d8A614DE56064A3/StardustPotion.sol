// SPDX-License-Identifier: MIT

// ░██████╗████████╗░█████╗░██████╗░██████╗░██╗░░░██╗░██████╗████████╗
// ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██║░░░██║██╔════╝╚══██╔══╝
// ╚█████╗░░░░██║░░░███████║██████╔╝██║░░██║██║░░░██║╚█████╗░░░░██║░░░
// ░╚═══██╗░░░██║░░░██╔══██║██╔══██╗██║░░██║██║░░░██║░╚═══██╗░░░██║░░░
// ██████╔╝░░░██║░░░██║░░██║██║░░██║██████╔╝╚██████╔╝██████╔╝░░░██║░░░
// ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░░╚═════╝░╚═════╝░░░░╚═╝░░░

// ██████╗░░█████╗░████████╗██╗░█████╗░███╗░░██╗
// ██╔══██╗██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║
// ██████╔╝██║░░██║░░░██║░░░██║██║░░██║██╔██╗██║
// ██╔═══╝░██║░░██║░░░██║░░░██║██║░░██║██║╚████║
// ██║░░░░░╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║
// ╚═╝░░░░░░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract StardustPotion is ERC721, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;

  uint256 public cost = 0 ether;
  uint256 public maxMintAmountPerTx = 1;
  uint256 public maxNFTPerAccount = 1;
  mapping(address => uint256) public addressMintedBalance;
  mapping(uint256 => uint8) public tokenHouse;
  bytes32 public whitelistMerkleRoot;
  uint256 private hNounce = 0;

  bool public ALpaused = true;
  bool public revealed = false;

  constructor() ERC721("Stardust Potion NFT", "SPN") {
    setHiddenMetadataUri("ipfs://QmSUA72mGbz3cKZyC1X5dv2AS9wjWGDdb41H8QyPweXsrN/hidden.json");
  }

// Modifier 
  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(_mintAmount + addressMintedBalance[msg.sender] <= maxNFTPerAccount, "You reach maximum NFTs per address!");
    _;
  }

  modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in Allow list."
        );
        _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function mintAllowList(uint256 _mintAmount , bytes32[] calldata merkleProof) 
    public 
    payable 
    nonReentrant 
    isValidMerkleProof(merkleProof, whitelistMerkleRoot) 
  {
    require(!ALpaused, "The contract is paused!");
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
 
    require(
      ownerMintedCount + _mintAmount <= maxNFTPerAccount,
      "Max POTION per address exceeded for Allow list."
    );
    require(msg.value >= cost * _mintAmount, "Allow list : insufficient funds.");
    require(
      _mintAmount <= maxMintAmountPerTx,
      "Max mint amount per transaction exceeded."
    );

    _mintLoop(msg.sender, _mintAmount, merkleProof);
  }

  function processRandom(bytes32[] memory proof, uint256 _nounce) internal view returns (uint8) {
    uint256 computedHash;
    bytes32 proofElement;
    for (uint256 i = 0; i < proof.length; i++) {
      proofElement = proof[i];
    }
    computedHash = uint256(keccak256(abi.encodePacked(proofElement, block.timestamp, block.difficulty, msg.sender, _nounce)));
    uint8 randomHouse = uint8((computedHash % 5) + 1);
    return randomHouse;
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver, bytes32[] calldata merkleProof) public onlyOwner {
    _mintLoop(_receiver, _mintAmount, merkleProof);
  }

  function burnPotion(uint256 tokenId) public { 
     require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;
  
    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= supply.current()) {
      if (_exists(currentTokenId)) {
        address currentTokenOwner = ownerOf(currentTokenId);

        if (currentTokenOwner == _owner) {
          ownedTokenIds[ownedTokenIndex] = currentTokenId;

          ownedTokenIndex++;
        }
      } 
      
      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }
    uint256 keyType = uint256(tokenHouse[_tokenId]);
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, keyType.toString(), uriSuffix))
        : "";
  }

// SETTING parameter

  function setRevealed(bool _state) external onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) external onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) external onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxNFTPerAccount(uint256 _maxNFT) external onlyOwner {
    maxNFTPerAccount = _maxNFT;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) external onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) external onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setALPaused(bool _state) external onlyOwner {
    ALpaused = _state;
  }

  function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
  }


  function withdraw() public onlyOwner {
    // =============================================================================
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }

  function _mintLoop(address _receiver, uint256 _mintAmount, bytes32[] calldata _proof) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      addressMintedBalance[_receiver]++;
      hNounce += 1;
      uint8 getHouse = processRandom(_proof, hNounce);
      tokenHouse[supply.current()] = uint8(getHouse);
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}