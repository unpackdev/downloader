//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC721Tradable.sol";

contract Pyramids is ERC721Tradable {
  address payable private immutable _sink;

  uint256 private constant PRICE = 0.05 ether;

  uint256 private constant TIER_1 = 100;
  uint256 private constant TIER_2 = 500;
  uint256 private constant TIER_3 = 1000;
  uint256 private constant TIER_4 = 5000;
  uint256 private constant TIER_5 = 8888;

  // uint256 private constant PERCENT_1 = 100;
  uint256 private constant PERCENT_2 = 875;
  uint256 private constant PERCENT_3 = 750;
  uint256 private constant PERCENT_4 = 625;
  uint256 private constant PERCENT_5 = 500;

  uint256 private constant PERCENT = 1000;

  constructor(address _proxyRegistryAddress, address payable sink)
    ERC721Tradable("Pyramids", "PYR", _proxyRegistryAddress)
  {
    _sink = sink;
  }

  function baseTokenURI() public pure override returns (string memory) {
    return "ipfs://bafybeihjxzfawu7iv4gebc5uvylfi4rtfh7amqe4ga2rpop6ia3lveaszm/metadata/";
  }

  function mint(address payable referral) public payable {
    require(totalSupply() <= TIER_5, "Unavailable");
    _purchase(referral);
    mintTo(msg.sender);
  }

  function _getReferralValue(address referral, uint256 value) internal view returns (uint256) {
    if (referral == address(0)) {
      return 0;
    } else if (balanceOf(referral) == 0) {
      return 0;
    } else {
      uint256 nextTokenId = totalSupply() + 1;
      if (nextTokenId <= TIER_1) {
        return value;
      } else if (nextTokenId <= TIER_2) {
        return (value * PERCENT_2) / PERCENT;
      } else if (nextTokenId <= TIER_3) {
        return (value * PERCENT_3) / PERCENT;
      } else if (nextTokenId <= TIER_4) {
        return (value * PERCENT_4) / PERCENT;
      } else {
        // is TIER_5
        return (value * PERCENT_5) / PERCENT;
      }
    }
  }

  function _purchase(address payable referral) internal {
    require(msg.value >= PRICE, "Price not met");
    require(msg.sender != referral, "Cannot refer yourself");

    uint256 sinkValue = msg.value;
    uint256 referralValue = _getReferralValue(referral, msg.value);
    sinkValue = msg.value - referralValue;

    if (referralValue != 0) {
      // solhint-disable-next-line avoid-low-level-calls
      (bool _successReferral, ) = referral.call{value: referralValue}("");
      require(_successReferral, "Could not pay referral");
    }
    if (sinkValue != 0) {
      // solhint-disable-next-line avoid-low-level-calls
      (bool _successSink, ) = _sink.call{value: sinkValue}("");
      require(_successSink, "Could not pay sink");
    }
  }

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}

  function withdraw() public {
    require(balanceOf(msg.sender) > 0, "Not a Pyramids holder");
    uint256 balance = address(this).balance;
    uint256 senderBalance = balance / 2;
    uint256 sinkBalance = balance - senderBalance;

    // split contract balance between msg.sender and sink
    payable(msg.sender).transfer(senderBalance);
    payable(_sink).transfer(sinkBalance);
  }
}
