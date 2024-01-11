// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./MerkleProof.sol";

contract ClimateCubes is ERC721Enumerable, Ownable {
  using Counters for Counters.Counter;

  enum MintType { STANDARD, RESERVED }
  
  Counters.Counter private _standardTokenIds;
  Counters.Counter private _reservedTokenIds;
  uint256 private standardSupply;
  uint256 private reservedSupply;
  string private baseUri;
  uint256 public whitelistCost = 0.02 ether;
  uint256 public openCost = 0.03 ether;
  string private _contractUri;

  bytes32 public merkleRoot;

  bool public whitelistActive = false;
  bool public paused = true;
    
  constructor(string memory name_,
              string memory symbol_,
              string memory baseUri_,
              uint256 standardSupply_,
              uint256 reservedSupply_,
              uint256 whitelistCost_,
              uint256 openCost_)
    ERC721(name_, symbol_) {
    baseUri = baseUri_;
    standardSupply = standardSupply_;
    reservedSupply = reservedSupply_;
    whitelistCost = whitelistCost_;
    openCost = openCost_;
  }

  modifier onlyWhitelisted(bytes32[] memory proof) {
    require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Only Whitelisted Addresses");
    _;
  }

  modifier notPaused() {
    require(paused == false, "Minting Is Paused");
    _;
  }

  modifier notWhitelistPeriod() {
    require(whitelistActive == false, "Whitelist Period Is Active");
    _;
  }

  modifier whitelistPeriod() {
    require(whitelistActive == true, "Whitelist Period Not Active");
    _;
  }
  
  function setMerkleRoot(bytes32 root_) external onlyOwner {
    merkleRoot = root_;
  }

  function setWhitelistActive(bool status_) external onlyOwner {
    if(status_ == true && merkleRoot == bytes32(0)){
      revert("MerkleRoot must be set");
    }
    whitelistActive = status_;
  }

  function setPauseStatus(bool status_) external onlyOwner {
    paused = status_;
  }
  
  function setBaseUri(string memory baseUri_) external onlyOwner {
    baseUri = baseUri_;
  }
  
  function _baseURI() internal view override returns(string memory) {
     return baseUri;
  }

  function setContractUri(string memory uri) external onlyOwner {
    _contractUri = uri;
  }

  function contractURI() external view returns(string memory) {
    return _contractUri;
  }
  
  function setWhitelistCost(uint256 amount_) external onlyOwner {  
    whitelistCost = amount_;
  }

  function setOpenCost(uint256 amount_) external onlyOwner {  
    openCost = amount_;
  }

  function mintStandard(address tokenOwner) internal returns(uint256){
    if(_standardTokenIds.current() + 1 > standardSupply){
      return 0;
    }
    _standardTokenIds.increment();
    uint256 tokenId = _standardTokenIds.current();
    _mint(tokenOwner, tokenId);
    return tokenId;
  }

  function mintReserved(address tokenOwner) internal returns(uint256){
    if(_reservedTokenIds.current() + 1 > reservedSupply){
      return 0;
    }
    _reservedTokenIds.increment();
    uint256 tokenId = _reservedTokenIds.current() + standardSupply;
    _mint(tokenOwner, tokenId);
    return tokenId;
  }
  
  function totalSupply() public override view returns(uint256){
    return _standardTokenIds.current() + _reservedTokenIds.current();
  }

  function mintStandardBatch(uint256 numberOfTokens, address tokensOwner) internal returns(uint256, uint256[] memory) {
    uint256[] memory generatedTokens = new uint256[](numberOfTokens);
    uint256 generatedCount = 0;
    for(uint256 i = 0; i < numberOfTokens; i++){
      generatedTokens[i] = mintStandard(tokensOwner);
      if(generatedTokens[i] > 0){
        generatedCount += 1;
      }
    }
    return (generatedCount, generatedTokens);
  }

  function checkPaymentAndRefund(uint256 generatedCount, bool isWhitelistMint) internal {
    uint256 requiredPayment = generatedCount * (isWhitelistMint ? whitelistCost : openCost);
    require(msg.value >= requiredPayment, "Invalid payment");
    if(msg.value > requiredPayment){
      payable(msg.sender).transfer(msg.value - requiredPayment);
    }
  }
  
  function mint(uint256 numberOfTokens) external payable notPaused notWhitelistPeriod returns(uint256[] memory){
    (uint256 generatedCount, uint256[] memory generatedTokens) = mintStandardBatch(numberOfTokens, msg.sender);
    checkPaymentAndRefund(generatedCount, false);
    return generatedTokens;
  }
  
  function exists(uint256 tokenId) external view returns(bool) {
    return _exists(tokenId);
  }

  function adminMint(uint256 count, uint256 mintType, address tokenOwner) public onlyOwner returns(uint256[] memory) {
    uint256[] memory generatedTokens = new uint256[](count);
    if(mintType == uint256(MintType.STANDARD)){
      for(uint256 i = 0; i < count; i++){
        generatedTokens[i] = mintStandard(tokenOwner);
      }
    } else if(mintType == uint256(MintType.RESERVED)){
      for(uint256 i = 0; i < count; i++){
        generatedTokens[i] = mintReserved(tokenOwner);
      }
    }
    return generatedTokens;
  }

  function adminMint(uint256 count, uint256 mintType) external onlyOwner returns(uint256[] memory) {
    return adminMint(count, mintType, msg.sender);
  }

  function adminMint(uint256 count) external onlyOwner returns(uint256[] memory) {
    return adminMint(count, uint256(MintType.RESERVED), msg.sender);
  }

  function adminMint() external onlyOwner returns(uint256[] memory) {
    return adminMint(1, uint256(MintType.RESERVED), msg.sender);
  }

  function whitelistMint(uint256 numberOfTokens, bytes32[] memory merkleProof)
    external
    payable
    notPaused
    whitelistPeriod
    onlyWhitelisted(merkleProof)
    returns(uint256[] memory){
    
    (uint256 generatedCount, uint256[] memory generatedTokens) = mintStandardBatch(numberOfTokens, msg.sender);
    checkPaymentAndRefund(generatedCount, true);
    return generatedTokens;
    
  }
  
  function withdraw()
    external
    onlyOwner {
    
    uint256 available = address(this).balance;
    require(available > 0, "NB");

    payable(msg.sender).transfer(available);
    
  }

  receive() external payable {
  }
  
  fallback() external payable {
  }
  
}
