// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.12;
import "./ERC20.sol";

contract MultiSwapToken is ERC20 {
  uint256 constant PRESALE_FUND = 5_000_000 ether;
  uint256 constant LGE_FUND = 5_000_000 ether;
  uint256 constant FOUNDERS_FUND = 15_000_000 ether;
  uint256 constant FUNDRAISING_FUND = 5_000_000 ether;
  uint256 constant GENERAL_FUND = 5_000_000 ether;
  uint256 constant COMMUNITY_FUND = 65_000_000 ether;

  constructor (string memory name, string memory symbol, address presaleFund, address lgeFund, address foundersFund, address fundraisingFund, address generalFund, address communityFund ) ERC20(name, symbol) public {
    _mint(presaleFund, PRESALE_FUND);
    _mint(lgeFund, LGE_FUND);
    _mint(foundersFund, FOUNDERS_FUND);
    _mint(fundraisingFund, FUNDRAISING_FUND);
    _mint(generalFund, GENERAL_FUND);
    _mint(communityFund, COMMUNITY_FUND);
  }

}
