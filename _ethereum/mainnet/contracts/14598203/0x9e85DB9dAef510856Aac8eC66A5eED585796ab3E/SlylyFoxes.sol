 // SPDX-License-Identifier: MIT

/*..............................................................................
..........................*@@,..................................................
........................@@@,,..............................@@@..................
............................................................,@@@................
............................/@#@@@@,..................%@@#,.....................
...........................@@    @@@@..............,@   (@@@....................
........................../@@   @  @@..............@@    @@@@...................
..........................&@@@@@@@@@@,............&@@@@@#  @@,..................
...........................@@@@@@@@@&.............,@@@@@@@@@@...................
............................@@@@@@@................@@@@@@@@@....................
.....................................................@@@@@,.....................
................................................................................
..............,.,...............................................................
.....@@@@@@@@@@@&(................@@@@@@,.@@@@@@@@.............@@@@@@@&#*.......
........,,.@@@@@@............/@@...,@&,.........@@@..............,....,.*%&.....
......@@@@@..................@@&...............,@@@.............%@@@@@@@,,......
..............................@@@@@@@@@@......,@@@.....................,@@......
...................................,...@@@@@@@@&................................
..............................................................................*/

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract SlylyFoxes is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => uint256) public addressPresaleMintedBalance;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;

  uint256 public price = 0.02 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmountPerTx = 10;
  uint256 public addressLimitPresale = 3;
  uint256 public reservedMarketingAndTeam = 250;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor() ERC721A("SlylyFoxes", "SLYLY") {
    setHiddenMetadataUri("ipfs://Qmdrf5MHTv5aB9KEPbiZMps2xZBAZc1MLXeHM2yTCwmMDS/hidden.json");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0, "Must mint at least one!");
    require(_mintAmount <= maxMintAmountPerTx, "Cannot purchase this many tokens in a transaction");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= price * _mintAmount, "Not enough Ether!");
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, "The whitelist sale is not enabled!");
    uint256 ownerMintedCount = addressPresaleMintedBalance[_msgSender()];
    require(ownerMintedCount + _mintAmount <= addressLimitPresale, "Maximum NFTs per address exceeded");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

    addressPresaleMintedBalance[_msgSender()] += _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");

   _safeMint(_msgSender(), _mintAmount);
  }

  function mintForAddress(uint256 _mintAmount, address _to) public mintCompliance(_mintAmount) onlyOwner {
   _safeMint(_to, _mintAmount);
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

  function toggleRevealed() public onlyOwner {
    revealed = !revealed;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setAddressLimitPresale(uint256 _newAddressLimitPresale) public onlyOwner {
   addressLimitPresale = _newAddressLimitPresale;
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

  function togglePaused() public onlyOwner {
    paused = !paused;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function toggleWhitelistMintEnabled() public onlyOwner {
    whitelistMintEnabled = !whitelistMintEnabled;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}