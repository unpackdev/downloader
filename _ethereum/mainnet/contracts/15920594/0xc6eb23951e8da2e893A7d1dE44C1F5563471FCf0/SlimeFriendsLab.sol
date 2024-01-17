//      /@@@@@@@       @@@@@@           @@@@@ @@@@@@@          @@@@@@@ @@@@@@@@@@@@@@@@
//  @@@@@@@@@@@@@@@@@  @@@@@@           @@@@@ @@@@@@@@&       @@@@@@@@ @@@@@@@@@@@@@@@@
// @@@@@,              @@@@@@           @@@@@ @@@@@@@@@@    &@@@@@@@@@ @@@@@@
// /@@@@@@@@@@@@@@@@@  @@@@@@           @@@@@ @@@@@@@@@@@/ @@@@@@@@@@@ @@@@@@@@@@@@@@@@
//              @@@@@@ @@@@@@           @@@@@ @@@@@@ @@@@@@@@@@ @@@@@@ @@@@@@
// @@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@ @@@@@ @@@@@@   @@@@@@@  @@@@@@ @@@@@@@@@@@@@@@@
//    %@@@@@@@@@@&     @@@@@@@@@@@@@@@@ @@@@@ @@@@@@    @@@@    @@@@@@ @@@@@@@@@@@@@@@@
//
//@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@     &@@@@@ @@@@@@@@@@@@@@@@ @@@@@@@@      /@@@@@ @@@@@@@@@@@@@            /@@@@@@@
//@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@  &@@@@@ @@@@@@@@@@@@@@@@ @@@@@@@@@/    /@@@@@ @@@@@@@@@@@@@@@@@.   @@@@@@@@@@@@@@@@&
//@@@@@@            @@@@@%     &@@@@@ &@@@@@ @@@@@@           @@@@@@@@@@@.  /@@@@@ @@@@@@      @@@@@@  @@@@@,
//@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@ &@@@@@ @@@@@@@@@@@@@@@@ @@@@@@.@@@@@@ /@@@@@ @@@@@@       @@@@@@  @@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@  &@@@@@ @@@@@@           @@@@@@  /@@@@@@@@@@@ @@@@@@       @@@@@@              @@@@@@
//@@@@@@            @@@@@    @@@@@@&  &@@@@@ @@@@@@@@@@@@@@@@ @@@@@@    #@@@@@@@@@ @@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@
//@@@@@@            @@@@@      @@@@@@ &@@@@@ @@@@@@@@@@@@@@@@ @@@@@@      &@@@@@@@ @@@@@@@@@@@@@@#        &@@@@@@@@@@@%

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract SlimeFriendsLab is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;

  //important
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  bool public reserved = false;
  uint256 public reserveAmount = 99;

  address public owallet = 0xc6d864875B21C09FED42Fa84644b003994F7D7f7;

  uint256 public numLids = 104;
  uint256[] public idLids = new uint256[](numLids);

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    setHiddenMetadataUri(_hiddenMetadataUri);
    _safeMint(msg.sender, reserveAmount);

    bool IsUnique;
    uint256 indexCounter = 0;
    uint256 loop = 1;
    while (indexCounter < numLids) {
      uint256 rand = (uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, loop))) %
        _maxSupply) + 1;

      if (indexCounter < 1) {
        idLids[indexCounter] = rand;
        indexCounter++;
      } else {
        IsUnique = true;
        for (uint256 i = 0; i < indexCounter; i++) {
          if (idLids[i] == rand) {
            IsUnique = false;
          }
        }

        if (IsUnique) {
          idLids[indexCounter] = rand;
          indexCounter++;
        }
      }
      loop++;
    }
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

  function backUpReserve(uint256 amount) public mintCompliance(reserveAmount) onlyOwner {
    _safeMint(msg.sender, amount);
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
    public
    payable
    mintCompliance(_mintAmount)
    mintPriceCompliance(_mintAmount)
  {
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
    return
      bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) : '';
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
    uint256 bal = address(this).balance;

    (bool succ, ) = payable(owallet).call{value: bal}('');
    require(succ, 'transfer failed');
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
