// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

//Standard NFT
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

//Proof of Signature
import "./MerkleProof.sol";
import "./ECDSA.sol";

//Royalty
import "./ERC2981.sol";

contract NewSticksOnTheBlock is ERC721, Ownable, ERC2981 {
  using Strings for uint256;
  using Counters for Counters.Counter;
  using ECDSA for bytes32;

  uint256 public constant T1SUPPLY = 111; //Legendary supply
  uint256 public constant T2SUPPLY = 222; //Guardian supply
  uint256 public constant T3SUPPLY = 555; //Keeper supply
  uint256 public constant MAXGUARDIANSUPPLY = T1SUPPLY + T2SUPPLY;
  uint256 public constant MAXKEEPERSUPPLY = T1SUPPLY + T2SUPPLY + T3SUPPLY;
  uint256 public constant GUARDIANCOST = 0.12 ether;
  uint256 public constant KEEPERCOST = 0.08 ether;
  uint256 public constant MAXMINTAMOUNT = 1;

  Counters.Counter private supply;
  address private t1 = 0x1D372AfE7e797d3Bb0B734768DCBcceF0dc13679; //Treasury wallet
  string private _contractURI = "https://animagine.mypinata.cloud/ipfs/QmYcvij8uY9nZPLFgCT5v3RCbRKH3TTBBExxFJiQqZKzzy";

  string public baseURI = "https://animagine.mypinata.cloud/ipfs/QmUSadNAmu9Awgp2TAXv7ujvLNB21D8b7QEQ4wY3RgptA9/";
  bool public paused = false;

  enum PeriodMintStatus {
    CLOSED,
    GUARDIAN,
    OPENGUARDIAN,
    KEEPER,
    OPENKEEPER
  }
  PeriodMintStatus public _periodMintStatus = PeriodMintStatus.CLOSED;

  //Guardian Whitelist
  bytes32 public gMerkleRoot = 0x2f727751776094c84affb0688430a674ada76ec5a6e76f94f5efce19c6a1ce7c;
  mapping(address => bool) public gWhitelistClaimed;

  //Keeper Whitelist
  bytes32 public kMerkleRoot = 0x260e992552beffbe02cdf04037d1ec096940d8a0ad14f71b200c43e6bee3dcce;
  mapping(address => bool) public kWhitelistClaimed;

  constructor() ERC721("NewSticksOnTheBlock", "NSOTB") {
    //Contract interprets 10,000 as 100%.
    setDefaultRoyalty(t1, 500); //5%
   }

//*** INTERNAL FUNCTION ***//
  function isValidSignature(bytes memory _signature) public view returns (bool) {
    bytes32 hash = keccak256(abi.encodePacked(msg.sender, address(this)));
    bytes32 signedHash = hash.toEthSignedMessageHash();
    return signedHash.recover(_signature) == msg.sender;
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

//*** PUBLIC FUNCTION ***//
  function guardianSaleMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable {
    require(!paused);
    require(_periodMintStatus == PeriodMintStatus.GUARDIAN, "CP: Minting status invalid.");
    require(msg.sender == tx.origin, "CP: We like real users.");
    require(_mintAmount > 0 && _mintAmount <= MAXMINTAMOUNT, "Out of mint amount limit.");
    require(supply.current() + _mintAmount <= MAXGUARDIANSUPPLY, "Out of guardian supply.");

    if (msg.sender != owner()) {
      require(!gWhitelistClaimed[msg.sender], "Address has already claimed.");

      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      require(MerkleProof.verify(_merkleProof, gMerkleRoot, leaf), "Invalid proof.");
      
      gWhitelistClaimed[msg.sender] = true;
        
      require(msg.value >= GUARDIANCOST * _mintAmount, "Insufficient Eth.");
    }

    _mintLoop(msg.sender, _mintAmount);
  }

  function guardianPublicSaleMint(uint256 _mintAmount, bytes memory _signature) public payable {
    require(!paused);
    require(_periodMintStatus == PeriodMintStatus.OPENGUARDIAN, "CP: Minting status invalid.");
    require(msg.sender == tx.origin, "CP: We like real users.");
    require(_mintAmount > 0 && _mintAmount <= MAXMINTAMOUNT, "Out of mint amount limit.");
    require(supply.current() + _mintAmount <= MAXGUARDIANSUPPLY, "Out of guardian supply.");

    if (msg.sender != owner()) {
      require(isValidSignature(_signature), "CP: Invalid signature.");

      require(msg.value >= GUARDIANCOST * _mintAmount, "Insufficient Eth.");
    }

    _mintLoop(msg.sender, _mintAmount);
  }

  function keeperSaleMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable {
    require(!paused);
    require(_periodMintStatus == PeriodMintStatus.KEEPER, "CP: Minting status invalid.");
    require(msg.sender == tx.origin, "CP: We like real users.");
    require(_mintAmount > 0 && _mintAmount <= MAXMINTAMOUNT, "Out of mint amount limit.");
    require(supply.current() + _mintAmount <= MAXKEEPERSUPPLY, "Out of supply.");

    if (msg.sender != owner()) {
      require(!kWhitelistClaimed[msg.sender], "Address has already claimed.");

      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      require(MerkleProof.verify(_merkleProof, kMerkleRoot, leaf), "Invalid proof.");
      
      kWhitelistClaimed[msg.sender] = true;
        
      require(msg.value >= KEEPERCOST * _mintAmount, "Insufficient Eth.");
    }

    _mintLoop(msg.sender, _mintAmount);
  }

  function keeperPublicSaleMint(uint256 _mintAmount, bytes memory _signature) public payable {
    require(!paused);
    require(_periodMintStatus == PeriodMintStatus.OPENKEEPER, "CP: Minting status invalid.");
    require(msg.sender == tx.origin, "CP: We like real users.");
    require(_mintAmount > 0 && _mintAmount <= MAXMINTAMOUNT, "Out of mint amount limit.");
    require(supply.current() + _mintAmount <= MAXKEEPERSUPPLY, "Out of supply.");

    if (msg.sender != owner()) {
      require(isValidSignature(_signature), "CP: Invalid signature.");

      require(msg.value >= KEEPERCOST * _mintAmount, "Insufficient Eth.");
    }

    _mintLoop(msg.sender, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAXKEEPERSUPPLY) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token.");

    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json")) : "";
  }

  // Returns the URI for the contract-level metadata of the contract.
  function contractURI() public view returns (string memory) {
      return _contractURI;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

//*** ONLY OWNER FUNCTION **** //
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMintStatus(uint256 status) public onlyOwner {
    require(status <= uint256(PeriodMintStatus.OPENKEEPER), "CP: Out of bounds.");

    _periodMintStatus = PeriodMintStatus(status);
  }

  function setGMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    gMerkleRoot = _merkleRoot;
  }

  function setKMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    kMerkleRoot = _merkleRoot;
  }

  function mintAllLegendary() public onlyOwner {
    require(!paused);
    require(_periodMintStatus == PeriodMintStatus.CLOSED, "CP: Minting status invalid.");
    uint256 mintAmount = T1SUPPLY - supply.current();
    require(mintAmount > 0 && supply.current() + mintAmount <= T1SUPPLY, "Out of legendary supply.");

    _mintLoop(t1, mintAmount);
  }

  function mintAllGuardian() public onlyOwner {
    require(!paused);
    require(_periodMintStatus == PeriodMintStatus.OPENGUARDIAN, "CP: Minting status invalid.");
    uint256 mintAmount = MAXGUARDIANSUPPLY - supply.current();
    require(mintAmount > 0 && supply.current() + mintAmount <= MAXGUARDIANSUPPLY, "Out of guardian supply.");

    _mintLoop(t1, mintAmount);
  }

  function mintAllKeeper() public onlyOwner {
    require(!paused);
    require(_periodMintStatus == PeriodMintStatus.OPENKEEPER, "CP: Minting status invalid.");
    uint256 _mintAmount = MAXKEEPERSUPPLY - supply.current();
    require(_mintAmount > 0 && supply.current() + _mintAmount <= MAXKEEPERSUPPLY, "Out of supply.");

    _mintLoop(t1, _mintAmount);
  }

  function bulkAirDropLegendary(address[] calldata _airDropAddresses) public onlyOwner {
    require(!paused);
    require(_periodMintStatus == PeriodMintStatus.CLOSED, "CP: Minting status invalid.");
    require(supply.current() + _airDropAddresses.length <= T1SUPPLY, "Out of legendary supply.");

    for (uint256 i = 0; i < _airDropAddresses.length; i++) {
      supply.increment();
      _safeMint(_airDropAddresses[i], supply.current());
    }
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(t1).call{value: address(this).balance}("");
    require(os);
  }

  // Sets contract URI for the contract-level metadata of the contract.
  function setContractURI(string calldata _URI) public onlyOwner {
      _contractURI = _URI;
  }

  function setDefaultRoyalty(address _receiver, uint96 _royaltyPercent) public onlyOwner {
      _setDefaultRoyalty(_receiver, _royaltyPercent);
  }

//REQUIRED OVERRIDE FOR ERC721 & ERC2981
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}