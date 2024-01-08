// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./Signature.sol";
import "./Utils.sol";
import "./TLD.sol";
import "./Domain.sol";
import "./User.sol";
import "./Locker.sol";
import "./Settings.sol";
import "./Ordering.sol";

contract Manager is  Ownable {
    using SafeMath for uint256;
    bool public initialized;
    Settings settings;
    
    mapping(bytes32=>uint256) domainHashToToken;
    mapping(uint256=>bytes32) tokenToDomainHash;
        
    event TokenClaim(bytes32 domainHash,
                     uint256 tokenId,
                     string domainName);
    
    constructor()  {
      
    }
    
    function initialize(Settings _settings) public onlyOwner {
      require(!initialized, "Contract instance has already been initialized");
      initialized = true;
      settings = _settings;
    }

    modifier onlyCustodian() {
        require(settings.hasNamedRole("CUSTODIAN", _msgSender()),
                "Must be a custodian");
        _;
    }
    
    modifier onlyNamedRole(string memory _name) {
        require(settings.hasNamedRole(_name, _msgSender()),
                "Does not have required role");
        _;
    }
    
    function setSettingsAddress(Settings _settings) public onlyOwner {
        settings = _settings;
    }

    function tld() public view returns(TLD){
      return TLD(payable(settings.getNamedAddress("TLD")));
    }

    function domainToken() public view returns(Domain){
      return Domain(settings.getNamedAddress("DOMAIN"));
    }
    
    function initTLD(uint256 initialGasUsed, uint256 averageLength, uint256 basePriceMultiplier) public payable onlyOwner{
        
      tld().init{value: msg.value}(initialGasUsed, averageLength, basePriceMultiplier);
    }
    function callNamedContract(string memory _name, bytes memory data) public payable onlyOwner returns(bool, bytes memory){
      address _contract = settings.getNamedAddress(_name);
      (bool success, bytes memory response) = _contract.call{value: msg.value}(data);
      return (success, response);
    }
    function callContract(address _contract, bytes memory data) public payable onlyOwner returns(bool, bytes memory){
      (bool success, bytes memory response) = _contract.call{value: msg.value}(data);
      return (success, response);
    }
    function reimbursedOrdering(bytes memory data) public returns(bool, bytes memory){
      require(owner() == _msgSender() || settings.hasNamedRole("CUSTODIAN", _msgSender()), "must be custodian");
      (bool success, bytes memory response) = settings.getNamedAddress("ORDERING").call(data);
      return (success, response);
    }
    function registerCustodian(address custodianAddress)
      public onlyOwner{
      require(custodianAddress != address(0), "Custodian address must be a valid address");
      require(!settings.hasNamedRole("CUSTODIAN", custodianAddress), "Address is already a custodian");
      settings.registerNamedRole("CUSTODIAN", custodianAddress);      
    }
    
    function unregisterCustodian(address custodianAddress)
      public onlyOwner{
      require(settings.hasNamedRole("CUSTODIAN", custodianAddress), "Not a custodian");
      settings.unregisterNamedRole("CUSTODIAN", custodianAddress);
    }
    
    function changeSettingsAdmin(address adminAddress)
      public onlyOwner{
      require(adminAddress != address(0), "New admin must be a valid address");
      settings.changeAdmin(adminAddress);
    }

    function ordering() public view returns(Ordering){
      return Ordering(settings.getNamedAddress("ORDERING"));
    }
    function acceptExtension(bytes32 domainHash) public onlyCustodian {
    
      string memory domainName = domainToken().registryReveal(domainHash);
      uint256 extensionTime = ordering().getAcquisitionYears(domainHash).mul(365 days);
      ordering().acquisitionSuccessful(domainName);
      domainToken().extendExpirationDate(domainToken().tokenIdForHash(domainHash),
                                         extensionTime);
    }
    
    function claimToken(bytes32 domainHash)
      public
      payable
      returns (uint256) {
      
      require(ordering().canClaim(domainHash), "Can not claim token");
        
      uint256 requiredTokenCreationFee = ordering().tokenCreationFee(domainHash);
      
      require(msg.value >= requiredTokenCreationFee,
              "Must pay token creation fee");
      
      address requester = ordering().orderRequester(domainHash);
      uint256 tokenId = domainToken().claim(requester,
                                            domainHash,
                                            ordering().computedExpirationDate(domainHash));
      tokenToDomainHash[tokenId] = domainHash;
      domainHashToToken[domainHash] = tokenId;
      uint256 mintedTLD = tld().mint{value: msg.value}(ordering().tldOrderReservedId(domainHash));
      uint256 userTLD = Utils.calculatePercentageCents(mintedTLD,
                                                       settings.getNamedUint("TLD_DISTRIBUTION_COMMUNITY_PERCENTAGE"));
      uint256 networkTLD = Utils.calculatePercentageCents(mintedTLD,
                                                          settings.getNamedUint("TLD_DISTRIBUTION_NETWORK_MAINTENANCE_PERCENTAGE"));
      uint256 devTLD = mintedTLD.sub(userTLD).sub(networkTLD);
      ordering().finishOrder(domainHash);
      if(userTLD > 0){
        tld().transfer(requester, userTLD);
      }
      if(devTLD > 0){
        tld().transfer(settings.getNamedAddress("DEVELOPER"), devTLD);
      }
      emit TokenClaim(domainHash, tokenId, domainToken().registryReveal(domainHash));
      return tokenId;
    }
    
    function spendTLD(uint256 amount, address toAddress) public onlyOwner {
      tld().transfer(toAddress, amount);
    }
    function locker() public view returns(Locker){
      return Locker(payable(settings.getNamedAddress("LOCKER")));
    }
    function startDepositsRound(uint256 depositsWindow) public {
        require(settings.hasNamedRole("SKIMMER", _msgSender()), "Caller is skimmer");
        if(locker().isExtractionsOpen() && locker().extractionAmount(address(this)) > 0){
          uint256 extracted = locker().extract();
          if(extracted > 0){
            payable(_msgSender()).transfer(extracted);
          }
        }
        if(locker().balanceOf(address(this)) > 0){
          locker().withdrawAll();
        }
        locker().startDeposit(depositsWindow);
    }
    function startExtractionsRound(uint extractionsWindow) public {
        require(settings.hasNamedRole("SKIMMER", _msgSender()), "Caller is not skimmer");
        if(locker().isDepositsOpen() &&  tld().overflow() > 0){
          uint256 totalTldFunds = tld().balanceOf(address(this));
          if(totalTldFunds > 0){
            tld().approve(address(locker()), totalTldFunds);
            locker().deposit(totalTldFunds);
          }
        }
        uint256 skimmedAmount = tld().skim(address(this));
        locker().startExtraction{value: skimmedAmount}(extractionsWindow);
        if(locker().isExtractionsOpen() && locker().extractionAmount(address(this)) > 0){
          uint256 extracted = locker().extract();
          if(extracted > 0){
            payable(_msgSender()).transfer(extracted);
          }
        }
        if(locker().balanceOf(address(this)) > 0){
          locker().withdrawAll();
        }

    }
    function user() public view returns(User){
      return User(settings.getNamedAddress("USER"));
    }
    function registerUser(address _userAddress) public onlyOwner{

      require(!user().isRegistered(_userAddress), "Address already registered");
      user().register(_userAddress);
    }
    function activateUser(address _userAddress) public onlyOwner{

      require(user().isRegistered(_userAddress), "Address is not registered");
      require(!user().isActive(_userAddress), "Address is already an active user");
      user().activateUser(_userAddress);

    }
    function deactivateUser(address _userAddress) public onlyOwner{

      require(user().isRegistered(_userAddress), "Address is not registered");
      require(user().isActive(_userAddress), "Address is not an active user");
      user().deactivateUser(_userAddress);

    }

    function initBurn(bytes32 hash) public onlyCustodian{
        uint256 tokenId = domainToken().tokenIdForHash(hash);
        require(domainToken().tokenExists(tokenId), "Token does not exist");
        domainToken().burnInit(tokenId);
    }

    function cancelBurn(bytes32 hash) public onlyCustodian{
        uint256 tokenId = domainToken().tokenIdForHash(hash);
        require(domainToken().tokenExists(tokenId), "Token does not exist");
        domainToken().burnCancel(tokenId);
    }

    function acceptBurn(bytes32 hash) public onlyOwner{

        uint256 tokenId = domainToken().tokenIdForHash(hash);
        require(domainToken().tokenExists(tokenId), "Token does not exist");
        domainToken().burn(tokenId);

    }
    
    receive() external payable {

    }
}
