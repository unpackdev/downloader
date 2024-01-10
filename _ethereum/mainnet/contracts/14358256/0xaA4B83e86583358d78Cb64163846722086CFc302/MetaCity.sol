// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

interface IBucks {
    function balanceOf(address owner) external view returns (uint);
    function burn(address account, uint amount) external;
}

interface IBank {
    function randomTaxmanOwner() external returns (address);
    function addTokensToStake(address account, uint16[] calldata tokenIds) external;
}

contract MetaCity is ERC721, Ownable, ReentrancyGuard {

  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint16 public phase = 1;
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxSecondarySupply = 1;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  mapping(uint16 => uint) public phasePrice;
  mapping(uint16 => bool) private _isTaxman;
  mapping(uint16 => bool) private _isTierb;
  mapping(uint16 => bool) private _isTierc;
  mapping(uint16 => bool) private _isTierd;


  IBank public bank;
  IBucks public bucks;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    setHiddenMetadataUri(_hiddenMetadataUri);
    _safeMint(msg.sender, 0);
    
    phasePrice[2] = 500 ether;
    phasePrice[3] = 500 ether;
    phasePrice[4] = 500 ether;
    phasePrice[5] = 500 ether;
    phasePrice[6] = 500 ether;
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");

    if (phase == 1) {
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
    } else {
      require(supply.current() + _mintAmount <= maxSecondarySupply, "Max supply exceeded!");
      _;
    }
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, "The whitelist sale is not enabled!");
    require(!whitelistClaimed[msg.sender], "Address already claimed!");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

    whitelistClaimed[msg.sender] = true;
    _mintLoop(msg.sender, _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    _mintLoop(msg.sender, _mintAmount);
  }

  function mintWithBucks(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(phase != 1);
    require(!paused, "The contract is paused!");
    uint totalPennyCost = 0;

    require(msg.value == 0, "Now minting is done via Penny");
    totalPennyCost = bucksMintPrice(_mintAmount);
    require(bucks.balanceOf(msg.sender) >= totalPennyCost, "Not enough Penny");
    _mintLoop(msg.sender, _mintAmount);

    if (totalPennyCost > 0) {
      bucks.burn(msg.sender, totalPennyCost);
        }
  }
  
  function bucksMintPrice(uint _amount) public view returns (uint) {
        return _amount * phasePrice[phase];
    }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
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

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSecondarySupply) {
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

  function setMaxSecondarySupply(uint256 _maxSecondarySupply) public onlyOwner {
    maxSecondarySupply = _maxSecondarySupply;
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
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function switchToSalePhase(uint16 _phase) public onlyOwner {
    phase = _phase;
  }

  function setTaxmanIds(uint16[] calldata ids) external onlyOwner {
      for (uint i = 0; i < ids.length; i++) {
          _isTaxman[ids[i]] = true;
      }
  }

  function setTierbIds(uint16[] calldata ids) external onlyOwner {
      for (uint i = 0; i < ids.length; i++) {
           _isTierb[ids[i]] = true;
      }
  }

  function setTiercIds(uint16[] calldata ids) external onlyOwner {
      for (uint i = 0; i < ids.length; i++) {
           _isTierc[ids[i]] = true;
      }
  }

  function setTierdIds(uint16[] calldata ids) external onlyOwner {
      for (uint i = 0; i < ids.length; i++) {
           _isTierd[ids[i]] = true;
      }
  }

  function setBank(address _bank) external onlyOwner {
      bank = IBank(_bank);
  }

  function setBucks(address _bucks) external onlyOwner {
      bucks = IBucks(_bucks);
  }

  function changePhasePrice(uint16 _phase, uint _weiPrice) external onlyOwner {
      phasePrice[_phase] = _weiPrice;
  }

  function transferFrom(address from, address to, uint tokenId) public virtual override {
      // Hardcode the Manager's approval so that users don't have to waste gas approving
      if (_msgSender() != address(bank))
          require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
      _transfer(from, to, tokenId);
  }

  function isTaxman(uint16 id) public view returns (bool) {
      return _isTaxman[id];
  }

  function isTierb(uint16 id) public view returns (bool) {
      return _isTierb[id];
  }

  function isTierc(uint16 id) public view returns (bool) {
      return _isTierc[id];
  }

  function isTierd(uint16 id) public view returns (bool) {
      return _isTierd[id];
  }
}
