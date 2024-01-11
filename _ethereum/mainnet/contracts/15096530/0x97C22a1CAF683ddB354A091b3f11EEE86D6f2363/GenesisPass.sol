// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Royalty.sol";

contract TimeBlock{

    uint public blockPerDay;

    event NFTTransfer(address indexed from, address indexed to, uint indexed id,uint blocknumber);
    event Mint(address indexed owner);

    constructor(uint _blockPerDay){
        blockPerDay = _blockPerDay;
    }

    function setblockPerDay(uint _blockPerDay)public{
        blockPerDay = _blockPerDay;
    }

    function blockPerWeek() public view returns(uint){
        return blockPerDay*7;
    }

    function blockNDays(uint ndays) public view returns(uint){
        return blockPerDay*ndays;
    }
}

contract GenesisPass is ERC721A, Ownable, ReentrancyGuard, TimeBlock {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  mapping (address => uint) public supplyClain;
  mapping (uint => uint) public blocknumber;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint public daysTransfer;
  uint public maxClain;
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  uint  public max_supply_wave1 = 150;
  uint  public max_supply_wave2 = 450;
  uint  public max_supply_wave3 = 400;

  uint public price_batch1 = 2 * 10**17;
  uint public price_batch2 = 4 * 10**17;
  uint public price_batch3 = 6**18;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  bool public isWave2;
  bool public isWave3;

  address private wallet;

  error Failcost(uint _totalSupply);

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) TimeBlock(6400) {
    setMaxClain(2);
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier specialSupply{
    require(totalSupply() <= maxSupply + 100, "Max Supply for Special Mint is 100");
    _;
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= costBatch() * _mintAmount, 'Insufficient funds!');
    _;
  }
  modifier TimeCheck(uint _index){
    require(blockPerDay* daysTransfer <= (block.number - blocknumber[_index]));
    _;
  }

    function setisWave2(bool _isWave2) public onlyOwner{
        isWave2 = _isWave2;
    }

    function setisWave3(bool _isWave3) public onlyOwner{
        isWave3 = _isWave3;
    }
    
    function setPriceBatch1(uint _price_batch1) public onlyOwner{
      price_batch1 = _price_batch1;
    }

    function setPriceBatch2(uint _price_batch2) public onlyOwner{
      price_batch2 = _price_batch2;
    }

    function setPriceBatch3(uint _price_batch2) public onlyOwner{
      price_batch2 = _price_batch2;
    }
    
    function  setSupplyWave1(uint _max_supply_wave1) public onlyOwner{
      max_supply_wave1 = _max_supply_wave1;
    }

    function  setSupplyWave2(uint _max_supply_wave2) public onlyOwner{
      max_supply_wave2 = _max_supply_wave2;
    }

    function  setSupplyWave3(uint _max_supply_wave3) public onlyOwner{
      max_supply_wave3 = _max_supply_wave3;
    }

  function costBatch() public view returns(uint){
    uint _totalSupply = totalSupply();
    if(_totalSupply <= max_supply_wave1){
      return price_batch1;
    }
    else if((_totalSupply <= max_supply_wave2) && (max_supply_wave1 < _totalSupply)){
      return price_batch2;
    }
    else if (_totalSupply >= max_supply_wave2){
      return price_batch3;
    }
    else if(isWave2){
      return price_batch2;
    }
    else if(isWave3){
      return price_batch3;
    }
    else{
        revert Failcost(_totalSupply);
    }
  }


  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
    emit Mint(msg.sender);
  }

  function setMaxClain(uint clain) public{
    maxClain = clain;
  }

  function setWallet(address _wallet) public onlyOwner{
    wallet = _wallet;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    require(supplyClain[msg.sender]< maxClain, "Max mint per address is 2");
    supplyClain[msg.sender]++;
    _safeMint(_msgSender(), _mintAmount);
    emit Mint(msg.sender);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public specialSupply onlyOwner {
    _safeMint(_receiver, _mintAmount);
    emit Mint(msg.sender);
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

  function setDaysTransfer(uint _daysTransfer) public onlyOwner{
    daysTransfer = _daysTransfer;
  }


  function withdraw() public onlyOwner nonReentrant {

    (bool os, ) = payable(wallet).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function transferFrom(address from,address to,uint256 tokenId) public virtual override TimeCheck(_currentIndex) {
    blocknumber[_currentIndex] = block.number;
    ERC721A.transferFrom(from, to, tokenId);
    emit NFTTransfer(from, to, tokenId, block.number);
  }

  function safeTransferFrom(address from,address to,uint256 tokenId) public virtual override TimeCheck(_currentIndex) {
    blocknumber[_currentIndex] = block.number;
    ERC721A.safeTransferFrom(from, to, tokenId);
    emit NFTTransfer(from, to, tokenId, block.number);
  }

  function safeTransferFrom(address from,address to,uint256 tokenId, bytes memory _data) public virtual override TimeCheck(_currentIndex) {
    blocknumber[_currentIndex] = block.number;
    ERC721A.safeTransferFrom(from, to, tokenId, _data);
    emit NFTTransfer(from, to, tokenId, block.number);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}