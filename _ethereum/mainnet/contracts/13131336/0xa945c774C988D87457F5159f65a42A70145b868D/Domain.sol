// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SafeMath.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Utils.sol";
import "./Signature.sol";
import "./User.sol";
import "./Registry.sol";
import "./Settings.sol";

contract Domain is  ERC721Enumerable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;
  
  Settings settings;
  Counters.Counter private _tokenIds;
  struct DomainInfo {
      bytes32 domainHash;
      uint256 expireTimestamp;
      uint256 transferCooloffTime;
      bool active;
      uint256 canBurnAfter;
      bool burnRequest;
      bool burnRequestCancel;
      bool burnInit;
  }
  
  address private _owner;

  mapping(uint256=>DomainInfo) public domains;
  mapping(bytes32=>uint256) public domainHashToToken;
  mapping(address=>mapping(address=>mapping(uint256=>uint256))) public offchainTransferConfirmations;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  event DomainDeactivated(uint256 tokenId);
  event DomainActivated(uint256 tokenId);
  event InitBurnRequest(uint256 tokenId);
  event BurnInitiated(uint256 tokenId);
  event InitCancelBurn(uint256 tokenId);
  event BurnCancel(uint256 tokenId);
  event Burned(uint256 tokenId, bytes32 domainHash);
   
  string public _custodianBaseUri;
  
  constructor(string memory baseUri, Settings _settings) ERC721("Domain Name Token", "DOMAIN") {
    _owner = msg.sender;
    _custodianBaseUri = baseUri;
    settings = _settings;
  }
  
  function _baseURI()
    internal
    view
    virtual
    override
    returns (string memory) {
    return _custodianBaseUri;
  }
  
  
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    
    string memory baseURI = _baseURI();
    string memory domainName = getDomainName(tokenId);
    return string(abi.encodePacked(baseURI, "/", "api" "/","info","/","domain","/",domainName,".json"));
    
  }
  
  function owner() public view virtual returns (address) {
    return _owner;
  }
  modifier onlyOwner() {
    require(owner() == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function setSettingsAddress(Settings _settings) public onlyOwner {
      settings = _settings;
  }

  function burnRestrictionWindow() public view returns(uint256){
      return settings.getNamedUint("BURN_RESTRICTION_WINDOW");
  }
  
  function changeOwner(address nextOwner) public onlyOwner {
    address previousOwner = _owner;
    _owner = nextOwner;
    emit OwnershipTransferred(previousOwner, nextOwner);
  }

  function user() public view returns(User){
      return User(settings.getNamedAddress("USER"));
  }
  function registry() public view returns(Registry){
      return Registry(settings.getNamedAddress("REGISTRY"));
  }
  
  function isDomainActive(uint256 tokenId)
    public
    view
    returns (bool){
    
    return _exists(tokenId) && domains[tokenId].active && domains[tokenId].expireTimestamp > block.timestamp;
  }
  
  function isDomainNameActive(string memory domainName)
    public
    view
    returns (bool){
    return isDomainActive(tokenOfDomain(domainName));
  }
  function getDomainName(uint256 tokenId)
    public
    view
    returns (string memory){
      return registry().reveal(domains[tokenId].domainHash);
  }

  function getHashOfTokenId(uint256 tokenId) public view returns(bytes32){
      return domains[tokenId].domainHash;
  }
  
  function registryDiscover(string memory name) public returns(bytes32){
      return registry().discover(name);
  }
  function registryReveal(bytes32 key) public view returns(string memory){
      return registry().reveal(key);
  }
  
  function tokenOfDomain(string memory domainName)
    public
    view
    returns (uint256){
    
    bytes32 domainHash = Utils.hashString(domainName);
    return domainHashToToken[domainHash];
    
  }
  
  function getTokenId(string memory domainName)
    public
    view
    returns (uint256){
    
    return tokenOfDomain(domainName);
  }
  
  function getExpirationDate(uint256 tokenId)
    public
    view
    returns(uint256){
    return domains[tokenId].expireTimestamp;
  }
  
  function extendExpirationDate(uint256 tokenId, uint256 interval) public onlyOwner {
    require(_exists(tokenId), "Token id does not exist");
    domains[tokenId].expireTimestamp = domains[tokenId].expireTimestamp.add(interval);
  }
  
  function extendExpirationDateDomainHash(bytes32 domainHash, uint256 interval) public onlyOwner {
    extendExpirationDate(domainHashToToken[domainHash], interval);
  }
  
  function getTokenInfo(uint256 tokenId)
    public
    view
    returns(uint256, // tokenId
            address, // ownerOf tokenId
            uint256, // expireTimestamp
            bytes32, // domainHash
            string memory // domainName
            ){
    return (tokenId,
            ownerOf(tokenId),
            domains[tokenId].expireTimestamp,
            domains[tokenId].domainHash,
            registry().reveal(domains[tokenId].domainHash));
  }
  function getTokenInfoByDomainHash(bytes32 domainHash)
    public
    view
    returns (
             uint256, // tokenId
             address, // ownerOf tokenId
             uint256, // expireTimestamp
             bytes32, // domainHash
             string memory // domainName
             ){
    if(_exists(domainHashToToken[domainHash])){
      return getTokenInfo(domainHashToToken[domainHash]);
    }else{
      return (
              0,
              address(0x0),
              0,
              bytes32(0x00),
              ""
              );
    }
  }

  
  function claim(address domainOwner, bytes32 domainHash, uint256 expireTimestamp) public onlyOwner returns (uint256){
    require(domainHashToToken[domainHash] == 0, "Token already exists");
    require(user().isActive(domainOwner), "Domain Owner is not an active user");
    _tokenIds.increment();
    uint256 tokenId = _tokenIds.current();
    
    domains[tokenId] = DomainInfo(domainHash,
                                  expireTimestamp,
                                  0,
                                  true,
                                  block.timestamp.add(burnRestrictionWindow()),
                                  false,
                                  false,
                                  false);
    domainHashToToken[domainHash] = tokenId;
    _mint(domainOwner, tokenId); 
    return tokenId;
  }

  function transferCooloffTime() public view returns (uint256){
    return settings.getNamedUint("TRANSFER_COOLOFF_WINDOW");
  }
  
  function _deactivate(uint256 tokenId) internal {
      domains[tokenId].active = false;
      emit DomainDeactivated(tokenId);
  }

  function _activate(uint256 tokenId) internal {
      domains[tokenId].active = true;
      emit DomainActivated(tokenId);
  }
  
  function deactivate(uint256 tokenId) public onlyOwner {
    require(_exists(tokenId), "Token does not exist");
    require(domains[tokenId].active, "Token is already deactivated");
    _deactivate(tokenId);
  }
  function activate(uint256 tokenId) public onlyOwner {
    require(_exists(tokenId), "Token does not exist");
    require(!domains[tokenId].active, "Token is already activated");
    _activate(tokenId);
  }
  function isInBurnCycle(uint256 tokenId) public view returns(bool){
      return _exists(tokenId)
          &&
          (
           domains[tokenId].burnRequest
           || domains[tokenId].burnRequestCancel
           || domains[tokenId].burnInit
           );
  }
  
  function canBeTransferred(uint256 tokenId) public view returns(bool){
      return user().isActive(ownerOf(tokenId))
        && domains[tokenId].active
        && domains[tokenId].transferCooloffTime <= block.timestamp
        && domains[tokenId].expireTimestamp > block.timestamp
        && !isInBurnCycle(tokenId);
  }

  function canBeBurned(uint256 tokenId) public view returns(bool){
      return domains[tokenId].canBurnAfter < block.timestamp;
  }
  
  function canTransferTo(address _receiver) public view returns(bool){
      return user().isActive(_receiver);
  }
  function extendCooloffTimeForToken(uint256 tokenId, uint256 window) public onlyOwner {
    if(_exists(tokenId)){
      domains[tokenId].transferCooloffTime = block.timestamp.add(window);
    }
  }
  function extendCooloffTimeForHash(bytes32 hash, uint256 window) public onlyOwner {
    uint256 tokenId = tokenIdForHash(hash);
    if(_exists(tokenId)){
      domains[tokenId].transferCooloffTime = block.timestamp.add(window);
    }
  }
  function offchainConfirmTransfer(address from, address to, uint256 tokenId, uint256 validUntil, uint256 custodianNonce, bytes memory signature) public {
    bytes32 message = keccak256(abi.encode(from,
                                           to,
                                           tokenId,
                                           validUntil,
                                           custodianNonce));
    address signer = Signature.recoverSigner(message, signature);
    require(settings.hasNamedRole("CUSTODIAN", signer), "Signer is not a registered custodian");
    require(_exists(tokenId), "Token does not exist");
    require(_isApprovedOrOwner(from, tokenId), "Is not token owner");
    require(isDomainActive(tokenId), "Token is not active");
    require(user().isActive(to), "Destination address is not an active user");
    offchainTransferConfirmations[from][to][tokenId] = validUntil;
  }
  function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721){
    require(canBeTransferred(tokenId), "Token can not be transfered now");
    require(user().isActive(to), "Destination address is not an active user");
    if(settings.getNamedUint("OFFCHAIN_TRANSFER_CONFIRMATION_ENABLED") > 0){
      require(offchainTransferConfirmations[from][to][tokenId] > block.timestamp, "Transfer requires offchain confirmation");
    }
    domains[tokenId].transferCooloffTime = block.timestamp.add(transferCooloffTime());
    super.transferFrom(from, to, tokenId);
  }
  
  function adminTransferFrom(address from, address to, uint256 tokenId) public onlyOwner {
    require(_exists(tokenId), "Token does not exist");
    require(_isApprovedOrOwner(from, tokenId), "Can not transfer");
    require(user().isActive(to), "Destination address is not an active user");
    _transfer(from, to, tokenId);
  }
  
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
  function tokenExists(uint256 tokenId) public view returns(bool){
    return _exists(tokenId);
  }
  function tokenForHashExists(bytes32 hash) public view returns(bool){
    return tokenExists(tokenIdForHash(hash));
  }
  function tokenIdForHash(bytes32 hash) public view returns(uint256){
      return domainHashToToken[hash];
  }
  
    
  function initBurn(uint256 tokenId) public {
      require(canBeBurned(tokenId), "Domain is in burn restriction period");
      require(!isInBurnCycle(tokenId), "Domain already in burn cycle");
      require(_exists(tokenId), "Domain does not exist");
      require(ownerOf(tokenId) == msg.sender, "Must be owner of domain");

      domains[tokenId].burnRequest = true;
      _deactivate(tokenId);
      
      emit InitBurnRequest(tokenId);
  }
  
  function cancelBurn(uint256 tokenId) public {
      require(_exists(tokenId), "Domain does not exist");
      require(ownerOf(tokenId) == msg.sender, "Must be owner of domain");
      require(domains[tokenId].burnRequest, "No burn initiated");

      domains[tokenId].burnRequestCancel = true;
      emit InitCancelBurn(tokenId);
  }

  function burnInit(uint256 tokenId) public onlyOwner {
      require(_exists(tokenId), "Token does not exist");
      
      domains[tokenId].burnRequest = true;
      domains[tokenId].burnRequestCancel = false;
      domains[tokenId].burnInit = true;
      _deactivate(tokenId);
      emit BurnInitiated(tokenId);
  }

  function burnCancel(uint256 tokenId) public onlyOwner {
      require(_exists(tokenId), "Token does not exist");
      domains[tokenId].burnRequest = false;
      domains[tokenId].burnRequestCancel = false;
      domains[tokenId].burnInit = false;
      _activate(tokenId);
      emit BurnCancel(tokenId);
  }
  
  function burn(uint256 tokenId) public onlyOwner {
      require(_exists(tokenId), "Token does not exist");
      bytes32 domainHash = domains[tokenId].domainHash;
      delete domainHashToToken[domainHash];
      delete domains[tokenId];
      _burn(tokenId);
      emit Burned(tokenId, domainHash);    
  }
  
}
