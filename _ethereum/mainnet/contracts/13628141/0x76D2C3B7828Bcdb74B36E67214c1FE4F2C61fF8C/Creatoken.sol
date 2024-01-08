// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Creatoken is ERC721, Ownable {
  using Strings for uint256;

  bool public saleIsActive = false;
  address private _ethRecipient;
  string private _baseURL;

  mapping(uint256 => uint256) private MAX_PER_TIER;
  mapping(uint256 => uint256) private _tier;

  constructor(address ethRecipient, uint256[] memory tierStart , uint256[] memory tierEnds) ERC721("Creatoken", "CTK") {

    _ethRecipient = ethRecipient;

    _tier[0] = tierStart[0];
    _tier[1] = tierStart[1];
    _tier[2] = tierStart[2];
    _tier[3] = tierStart[3];
    _tier[4] = tierStart[4];
    _tier[5] = tierStart[5];

    MAX_PER_TIER[0] = tierEnds[0];
    MAX_PER_TIER[1] = tierEnds[1];
    MAX_PER_TIER[2] = tierEnds[2];
    MAX_PER_TIER[3] = tierEnds[3];
    MAX_PER_TIER[4] = tierEnds[4];
    MAX_PER_TIER[5] = tierEnds[5];

  }

  function toggleSaleState() external onlyOwner returns (bool) {

    saleIsActive = !saleIsActive;
    return saleIsActive;
  
  }

  function adminMint() external onlyOwner {

    require(tierCheck(5), "We're out of stock for this tier.");

    _tier[5] += 1;

    _safeMint(owner(), _tier[5]);

  }

  function adminMintTo(address to) external onlyOwner {

    require(tierCheck(5), "We're out of stock for this tier.");

    _tier[5] += 1;

    _safeMint(to, _tier[5]);

  }

  function mint(uint8 tier) external payable {

    require(saleIsActive, "Sale not active yet.");
    require(tier >= 0 && tier <= 5, "Tier out of range.");
    require(tierCheck(tier), "We're out of stock for this tier.");
    require(msg.value == getTokenPrice(tier), "The amount of ether sent is wrong.");

    _tier[tier] += 1;
    _safeMint(msg.sender, _tier[tier]);
    transferEthereum(msg.value);

  }

  function tierCheck(uint256 tier) internal view returns (bool) {
    return MAX_PER_TIER[tier] > _tier[tier];
  }

  function getTokenPrice(uint256 tier) internal pure returns (uint256) {

    if (tier == 0) {
      return 11110000000000000000;  // 11,11 ETH - Space 
    } else if (tier == 1) {
      return 777700000000000000;    // 0,7777 ETH - Tinte 
    } else if(tier == 2) {
      return 333300000000000000;    // 0,3333 ETH - Gold
    } else if(tier == 3){ 
      return 111100000000000000;    // 0,1111 ETH - Silber 
    } else if(tier == 4){ 
      return 77770000000000000;     //  0,07777 ETH - Wood 
    } else { 
      return 33330000000000000;     //  0,03333 ETH - Black 
    }

  }

  function setEthRecipient(address ethRecipient) external onlyOwner {
    _ethRecipient = ethRecipient;
  }

  function setBaseUrl(string calldata url) external onlyOwner {
    _baseURL = url;
  }

  function _baseURI() internal view override(ERC721) returns (string memory) {
    return _baseURL;
  }

  function transferEthereum(uint sentValue) internal {
    (bool sent, ) = _ethRecipient.call{value: sentValue}("");
    require(sent, "Failed to send ETH");
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    (bool sent, ) = _ethRecipient.call{value: balance}("");
    require(sent, "Failed to send ETH");
  }
}
