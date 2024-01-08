// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Domain.sol";
import "./Utils.sol";
import "./Settings.sol";

contract Donations is Ownable{
  using SafeMath for uint256;

  bool public initialized;

  Settings settings;
  mapping(bytes32=>uint256) domainsFund;
  event DonationReceived(address fromAddress,
                         uint256 tokenId,
                         bytes32 domainHash,
                         string domainName,
                         uint256 amount);
  
  event TokenFundWithdraw(uint256 tokenId,
                          address destinationAddress,
                          uint256 amount); 
  
  constructor(){

  }

  
  function initialize(Settings _settings) public onlyOwner {
    require(!initialized, "Contract instance has already been initialized");
    initialized = true;
    settings = _settings;
  }
  
  function setSettingsAddress(Settings _settings) public onlyOwner {
      settings = _settings;
  }
  function domainToken() public view returns(Domain){
      return Domain(settings.getNamedAddress("DOMAIN"));
  }
  function availableFunds(bytes32 domainHash) public view returns(uint256){
    return domainsFund[domainHash];
  }
  function tokenAvailableFunds(uint256 tokenId) public view returns(uint256){
      if(domainToken().tokenExists(tokenId)){
          (,,,bytes32 domainHash,) = domainToken().getTokenInfo(tokenId);
      return availableFunds(domainHash);
    }
    return 0;
  }
  function giveFundsToTokenId(uint256 tokenId) public payable {
      require(domainToken().tokenExists(tokenId), "Token does not exist");
      giveFunds(domainToken().getDomainName(tokenId));
  }
  function giveFunds(string memory domainName) public payable {
    require(msg.value > 0, "Must be a positive value");
    bytes32 domainHash = domainToken().registryDiscover(domainName);
    domainsFund[domainHash] = domainsFund[domainHash].add(msg.value);
    emit DonationReceived(msg.sender,
                          domainToken().tokenOfDomain(domainName),
                          domainHash,
                          domainName,
                          msg.value
                          );
  }
  function withdrawTokenFunds(uint256 tokenId) public {
    require(domainToken().ownerOf(tokenId) == msg.sender, "Not owner of token");
    (,,,bytes32 domainHash,) = domainToken().getTokenInfo(tokenId);
    require(availableFunds(domainHash) > 0, "Nothing to withdraw");
    uint256 amount = domainsFund[domainHash];
    domainsFund[domainHash] = 0;
    address payable ownerOfToken = payable(msg.sender);
    if(ownerOfToken.send(amount)){
      emit TokenFundWithdraw(tokenId, msg.sender, amount);
    }
  }
}
