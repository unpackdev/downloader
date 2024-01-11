// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";
import "./SafeMath.sol";

/*
* Date: 2022-04-18
* Author: Hyperagon
* Version: 3B
*/

contract EarlyValentines is ERC721A, Ownable, ReentrancyGuard, IERC2981 {
  using Strings for uint256;

  bytes32 public merkleRoot;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri = '';

  uint256 public cost = 1000000000000000000; // 1 ETH | 1 ETH = 1.000.000.000 GWEI = 1.000.000.000.000.000.000 WEI
  uint256 public burnReward = 20000000000000000; // 0.02 ETH
  uint256 public maxSupply = 1; // To avoid getting "Sold Out" by default
  uint256 public maxMintAmountPerTx; // = 0;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  uint public revealed; // = 0;
  uint public phase; // = 0;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    //cost = _cost;
    //maxSupply = _maxSupply;
    //maxMintAmountPerTx = _maxMintAmountPerTx;
    setHiddenMetadataUri("https://myvalentine.neocities.org/early/0.json"); //_hiddenMetadataUri);
    setUriPrefix("https://myvalentine.neocities.org/early/");
  }
  
  function setPhase(uint8 _phase, bool _paused, uint256 _cost, uint256 _maxSupply, uint256 _maxMintAmountPerTx, uint _revealed, string memory _uri)
    public onlyOwner
  {
    phase = _phase;
    if(paused != _paused) { setPaused(_paused); }
    if(_cost > 0) { setCost(_cost); }
    if(_maxSupply > 0) { setMaxSupply(_maxSupply); }
    if(_maxMintAmountPerTx > 0) { setMaxMintAmountPerTx(_maxMintAmountPerTx); }
    if(_revealed > 0) { revealed = _revealed; }
    if(bytes(_uri).length > 0) { setUriPrefix(_uri); }
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    _safeMint(_msgSender(), _mintAmount);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }
  
  function reserve(uint256 _mintAmount)
    public onlyOwner
  {
    _safeMint(_msgSender(), _mintAmount);
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
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

    if (revealed < _tokenId) {
      return hiddenMetadataUri;
    }

    return string(abi.encodePacked(uriPrefix, _tokenId.toString(), uriSuffix));
  }
  
  function reveal(uint256 upto) public onlyOwner {
    revealed = upto;
  }

  function setRevealed(bool _state) public onlyOwner {
    if(_state) { reveal(maxSupply); }
    else { reveal(0); }
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }
  
  function setBurnReward(uint256 _burnReward)
    public onlyOwner
  {
  burnReward = _burnReward;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }
  
  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
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

  // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
  function _isApprovedOrOwner(address spender, uint256 _tokenId)
    internal view virtual
    returns (bool)
  {
    if(_exists(_tokenId)) {
      require(_exists(_tokenId), "isApprovedOrOwner: Nonexistent token");
      address owner = ERC721A.ownerOf(_tokenId);
      return (spender == owner || isApprovedForAll(owner, spender) || getApproved(_tokenId) == spender);
    }
    return false;
  }
  
  function burn(uint256 _tokenId, bool withReward)
    public nonReentrant
  {
      require(_exists(_tokenId), "burn: Nonexistent token");
      require(_isApprovedOrOwner(_msgSender(), _tokenId) || msg.sender == owner(), "Caller is not owner nor approved");
            
      super._burn(_tokenId);
      require(!_exists(_tokenId), "burn: Token still exists!");
      
      if(withReward) {
        pay(msg.sender, burnReward);
      }
  }

  function withdraw()
    public onlyOwner nonReentrant
  {
    //(bool ok, ) = payable(0x...).call{value:  * 10 / 100}('');
    //(bool ok, ) = payable(0x...).call{value: SafeMath.div(SafeMath.mul(address(this).balance, 10), 100))}('');
    //require(ok);
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os, "Unable to Withdraw");
  }

  function pay(address who, uint256 value)
    public onlyOwner nonReentrant
  {
    require(value < address(this).balance, "Can't pay more than is in this Address");
    (bool os, ) = payable(who).call{value: value}('');
    require(os, "Unable to Pay");
    
    (bool ok, ) = payable(who).call{value: value}('');
    require(ok);
  }
  
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
      external view override
      returns (address receiver, uint256 royaltyAmount)
  {
      require(_exists(_tokenId), "royaltyInfo: Nonexistent token");

      return (address(this), SafeMath.div(SafeMath.mul(_salePrice, 5), 100));
  }
}
