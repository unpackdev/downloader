// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./IERC20.sol";
import "./PrivateDistribution.sol";
import "./Ownable.sol";

contract TokenManagerInternal is Ownable {
  IERC20 private _pmonToken;
  PrivateDistribution private _privateDistributionContract;
  mapping(address => uint256) public withdrawn;
  mapping(address => bool) public whitelist;

  event WithdrawnTokens(address indexed investor, uint256 value);

  address public _sourceOfFunds;

  constructor(
    address _token,
    address _privateDistribution,
    address sourceOfFunds
  ) {
    _pmonToken = IERC20(_token);
    _privateDistributionContract = PrivateDistribution(_privateDistribution);
    _sourceOfFunds = sourceOfFunds;
  }

  function addToWhitelist(address[] memory investors) public onlyOwner {
    for (uint256 i = 0; i < investors.length; i++) {
      require(whitelist[investors[i]] == false, 'Already whitelisted');
      whitelist[investors[i]] = true;
    }
  }

  function removeFromWhitelist(address investor) public onlyOwner {
    require(whitelist[investor] == true, 'Investor not on whitelist');
    whitelist[investor] = false;
  }

  function claimAllocation() external {
    // if the investor is not whitelisted here, they should not withdraw
    require(whitelist[msg.sender] == true, 'Investor not on whitelist');

    // fetch the withdrawable tokens for the investor
    uint256 withdrawAmount = _calculateWithdrawableTokens(msg.sender);

    // increase the withdrawn amount for the investor
    withdrawn[msg.sender] = withdrawn[msg.sender] + withdrawAmount;

    // transfer the tokens and emit
    _pmonToken.transferFrom(_sourceOfFunds, msg.sender, withdrawAmount);
    emit WithdrawnTokens(msg.sender, withdrawAmount);
  }

  function _calculateWithdrawableTokens(address investor)
    internal
    returns (uint256 withdrawableTokens)
  {
    uint256 withdrawableTokens =
      _privateDistributionContract.withdrawableTokens(investor);

    return withdrawableTokens - withdrawn[investor];
  }
}
