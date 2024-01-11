// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./PaymentSplitter.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract CryptoRacersGenesis is ERC721A, Ownable, PaymentSplitter, ReentrancyGuard {
 /*
    *  .  . *       *    .        .   .      *   *    .      .        .            *
    *.   ..    *    .      *  .   *      *        *    .
           .      ________  ___  ____________  ____  .      .
                 / ___/ _ \/ _ |/ ___/ __/ _ \/ __/
       *        / /__/ , _/ __ / /__/ _// , _/\ \      *
   *            \___/_/|_/_/ |_\___/___/_/|_/___/   .
.        .   .      *   *    .      .        .            *
    *.   ..    *    .      *  .   *      *        *    .
                      ___   __
    .         .   .    \ \__\ \___      .            .         *
        *           ###[-( )_  ___>    .     *        .
  *       *      *    _/_/  /_/ ___   __     .      * *    *           
   .         .                   \ \__\ \___                   .
              .     .   *     ###[-( )_  ___>     * *   *
        *        *              _/_/  /_/         .              .
.    *        . .      *   *   .      .        .          *    .      *  .  ..  *
 .      *   * *    *            .      *   *
  */
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  bytes32 public merkleRoot;

  mapping(address => bool) public freeMintClaimed; //Free mint limit is 1 per address on the FreeMintList

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost = 50000000000000000; //0.05 ETH per mint
  
  uint256 public maxSupply;
  uint256 public maxSupplyFM;
  uint256 public maxMintAmountPerTx;
  uint256 public maxMintAmountPerWallet;

  bool public pausedFM = true;
  bool public paused = true;
  bool public revealed = false;

  struct Account {
      uint mintedNFTs;
  }

  mapping(address => Account) public accounts;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri,
    address[] memory payeeAddrs, 
    uint256[] memory payeeShares_,
    uint256 _maxSupplyFM,
    uint256 _maxMintAmountPerWallet
  ) ERC721A(_tokenName, _tokenSymbol) PaymentSplitter(payeeAddrs,payeeShares_){
    cost = _cost;
    maxSupply = _maxSupply;
    maxSupplyFM = _maxSupplyFM;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    maxMintAmountPerWallet = _maxMintAmountPerWallet;
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!"); //no limit on mint amount for normal mints
    require(_currentIndex  + _mintAmount <= maxSupply, "Max supply exceeded!");
    require((_mintAmount + accounts[msg.sender].mintedNFTs) <= maxMintAmountPerWallet, "Sorry, purchase would exceed max mints per wallet!");
    _;
  }
  modifier mintComplianceFM(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!"); //limit whitelist mints to two per tx
    require(_currentIndex  + _mintAmount <= maxSupplyFM, "Max presale supply exceeded!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _;
  }

  function getFreeMintListAmountMinted(address addr) public view returns (bool) {
    return freeMintClaimed[addr];
  }

  //Limited at 1 free mint per address
  function claimFreeMint(bytes32[] calldata _merkleProof) public payable  mintComplianceFM(1)  {
    // Verify free mint requirements
    require(!pausedFM, "The presale is paused!");
    require(freeMintClaimed[msg.sender] == false, "Address already claimed!");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");
    freeMintClaimed[msg.sender] = true;
    _mintLoop(msg.sender, 1);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");


    _mintLoop(msg.sender, _mintAmount);
    accounts[msg.sender].mintedNFTs += _mintAmount;
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }
  
  function mintForAddresses(uint256[] memory _mintAmounts , address[] memory _receivers ) public onlyOwner {
    for (uint i=0; i<_receivers.length; i++) {
        _mintLoop(_receivers[i], _mintAmounts[i]);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 0;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
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

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
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
  
  function setMaxMintAmountPerWallet(uint256 _maxMintAmountPerWallet) public onlyOwner {
    maxMintAmountPerWallet = _maxMintAmountPerWallet;
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
  function setPausedFM(bool _state) public onlyOwner {
    pausedFM = _state;
  }

  //whitelist for discount
  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
      _safeMint(_receiver, _mintAmount);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
