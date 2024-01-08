pragma solidity ^0.5.11;

import "./ERC1155Tradable.sol";
import "./FAMEToken.sol";

/**
 * @title FAMECollectible
 * FAMECollectible - a contract for my semi-fungible tokens.
 */
contract FAMECollectible is ERC1155Tradable {

  struct conversionRatio {
    bool active;
    uint256 multiplier;
    uint256 divisor;
  }

  address public legacyTokenAddress;
  mapping(bytes32 => conversionRatio) availableConversions;

  constructor(address _proxyRegistryAddress, address _legacyTokenAddress) //0x190e569bE071F40c704e15825F285481CB74B6cC on live net
  ERC1155Tradable(
    "FAMECollectible",
    "MCB",
    _proxyRegistryAddress
  ) public {
    _setBaseMetadataURI("https://metadata.battledrome.io/api/erc1155-fame/");
    legacyTokenAddress = _legacyTokenAddress;
  }

  function contractURI() public pure returns (string memory) {
    return "https://metadata.battledrome.io/contract/erc1155-fame";
  }

  //Function to import legacy FAME ERC20 tokens into the current format (ERC1155 on token id 0 which is Founders Credits)
  function legacyImport() public
  {
    require(_exists(1),"NOT_READY");
    FAMEToken legacyToken = FAMEToken(legacyTokenAddress);
    uint16 legacy_zeros = 12;
    uint256 convertingBalance = legacyToken.balanceOf(msg.sender);
    uint256 allowance = legacyToken.allowance(address(this),msg.sender);
    require(allowance>=convertingBalance,"INSUFFICIENT_ALLOWANCE");
    legacyToken.transferFrom(msg.sender,address(this),convertingBalance);
    uint256 mintAmount = convertingBalance / (uint256(10)**legacy_zeros);
    _mint(msg.sender, 1, mintAmount, "");
  }

  function setConversion(uint256 sourceID, uint256 targetID, uint256 multiplier, uint256 divisor) public onlyOwner
  {
    require(_exists(sourceID),"INVALID_SOURCE");
    require(_exists(targetID),"INVALID_TARGET");
    availableConversions[keccak256(abi.encodePacked(sourceID,targetID))] = conversionRatio(true,multiplier,divisor);
  }

  function deactivateConversion(uint256 sourceID, uint256 targetID) public onlyOwner
  {
    require(_exists(sourceID),"INVALID_SOURCE");
    require(_exists(targetID),"INVALID_TARGET");
    require(availableConversions[keccak256(abi.encodePacked(sourceID,targetID))].active,"INVALID_CONVERSION");
    availableConversions[keccak256(abi.encodePacked(sourceID,targetID))].active = false;
  }

  function convert(uint256 sourceID, uint256 targetID, uint256 sourceAmount) public 
  {
    require(_exists(sourceID),"INVALID_SOURCE");
    require(_exists(targetID),"INVALID_TARGET");
    require(availableConversions[keccak256(abi.encodePacked(sourceID,targetID))].active,"INVALID_CONVERSION");
    require(balanceOf(msg.sender,sourceID)>=sourceAmount,"INSUFFICIENT_BALANCE");
    conversionRatio memory conversion = availableConversions[keccak256(abi.encodePacked(sourceID,targetID))];
    uint256 targetAmount = (sourceAmount * conversion.multiplier) / conversion.divisor;
    uint256 burnAmount = (targetAmount * conversion.divisor) / conversion.multiplier;
    require(targetAmount>0,"INSUFFICIENT_EXCHANGE");
    require(burnAmount>0,"BURN_ERROR");
    _burn(msg.sender,sourceID,burnAmount);
    _mint(msg.sender,targetID,targetAmount,"");
  }

}
