// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./ERC20.sol";
import "./Address.sol";
import "./IPublicEndStakeable.sol";
import "./IExternalPerpetualFilter.sol";
import "./HSIStakeManager.sol";
import "./IGasReimberser.sol";

contract MaximusStakeManager is HSIStakeManager {
  using Address for address payable;
  address public externalPerpetualSetter;
  address public externalPerpetualFilter;
  mapping(address perpetual => bool isPerpetual) public perpetualWhitelist;
  /**
   * bytes32 is a key made up of the perpetual whitelist address + the iteration of the stake found at
   */
  mapping(address perpetual => mapping(uint256 period => address to)) public rewardsTo;
  /**
   * emitted when a contract is added to the whitelist
   * @param perpetual the perpetual contract added to the whitelist
   */
  event AddPerpetual(address indexed perpetual);
  /**
   * collect a reward from a given perpetual within a period
   * @param perpetual the perpetual contract being targeted
   * @param period the period, managed internally by the perpetual
   * @param token the token being rewarded
   * @param amount the amount of a token being rewarded
   */
  event CollectReward(
    address indexed perpetual,
    uint256 indexed period,
    address indexed token,
    uint256 amount
  );
  /**
   * a list of known perpetual contracts is set during constructor
   */
  constructor() {
    _addPerpetual(0x0d86EB9f43C57f6FF3BC9E23D8F9d82503f0e84b); // maxi
    _addPerpetual(0x6b32022693210cD2Cfc466b9Ac0085DE8fC34eA6); // deci
    _addPerpetual(0x6B0956258fF7bd7645aa35369B55B61b8e6d6140); // lucky
    _addPerpetual(0xF55cD1e399e1cc3D95303048897a680be3313308); // trio
    _addPerpetual(0xe9f84d418B008888A992Ff8c6D22389C2C3504e0); // base
    externalPerpetualSetter = msg.sender;
  }
  /**
   * sets the extended perpetual filter to allow for other perpetual contracts
   * to pass through the filter and added at a later date
   * @param _externalPerpetualFilter the extended perpetual filter set by the creator of this contract
   */
  function setExternalPerpetualFilter(address _externalPerpetualFilter) external {
    if (msg.sender != externalPerpetualSetter) revert NotAllowed();
    externalPerpetualSetter = address(0);
    externalPerpetualFilter = _externalPerpetualFilter;
  }
  /**
   * check if a given contract can pass through the perpetual filter
   * @param perpetual the perpetual contract to check
   * @return isPerpetual when address has passed through the filter or extended filter
   */
  function checkPerpetual(address perpetual) external returns(bool isPerpetual) {
    return _checkPerpetual({
      perpetual: perpetual
    });
  }
  /**
   * check if a given contract can pass through the perpetual filter
   * @param perpetual the perpetual contract to check
   * @return isPerpetual when address has passed through the filter or extended filter
   * after passing through extended filter, the result is cached
   */
  function _checkPerpetual(address perpetual) internal returns(bool isPerpetual) {
    if (perpetualWhitelist[perpetual]) return true;
    address _externalPerpetualFilter = externalPerpetualFilter;
    if (_externalPerpetualFilter == address(0)) return false;
    bool result = IExternalPerpetualFilter(_externalPerpetualFilter).verifyPerpetual({
      perpetual: perpetual
    });
    if (result) {
      _addPerpetual(perpetual);
      return true;
    }
    return false;
  }
  /**
   * adds new perpetual contract to the whitelist
   * Once a perpetual is whitelisted it cannot be removed
   * @param perpetual the perpetual address to add to the persistent mapping
   */
  function _addPerpetual(address perpetual) internal {
    perpetualWhitelist[perpetual] = true;
    emit AddPerpetual(perpetual);
  }
  /**
   * end a stake on a known perpetual
   * @param rewarded the address to reward with tokens
   * @param perpetual the perpetual to end a stake on
   * @param stakeId the stake id to end
   */
  function stakeEndAs(address rewarded, address perpetual, uint256 stakeId) external {
    if (!_checkPerpetual(perpetual)) revert NotAllowed();
    IPublicEndStakeable endable = IPublicEndStakeable(perpetual);
    // STAKE_END_DAY is locked + staked days - 1 so > is correct in this case
    if (_checkEndable(endable)) {
      endable.mintHedron(ZERO, uint40(stakeId));
      endable.endStakeHEX(ZERO, uint40(stakeId));
      // by now we have incremented by 1 since the start of this function
      uint256 currentPeriod = endable.getCurrentPeriod();
      rewardsTo[perpetual][currentPeriod] = rewarded;
      // add 1 because the period will increment at the next stake start (1 week's time)
      // so this contract should also recognize that range until the end
      rewardsTo[perpetual][currentPeriod + 1] = rewarded;
    }
  }
  /**
   * checks if a given perpetual is endable
   * @param endable the endable perpetual contract
   * @return isEndable denotes whether or not the stake is endable
   */
  function _checkEndable(IPublicEndStakeable endable) internal view returns(bool isEndable) {
    if (_currentDay() > endable.STAKE_END_DAY()) {
      return endable.STAKE_IS_ACTIVE();
    }
  }
  /**
   * checks if a given perpetual is endable
   * @param endable the endable perpetual contract
   * @return isEndable verifies that the provided address is endable
   */
  function checkEndable(address endable) external view returns(bool isEndable) {
    return _checkEndable(IPublicEndStakeable(endable));
  }
  /**
   * flush erc20 tokens into this contract
   * @param gasReimberser the address to collect gas reimbursement from
   * @param perpetual the perpetual pool to call flush on
   * @param period the period that the token collects against
   * @param tokens the token addresses to flush into this contract
   * @notice this assumes that only one token is flushed at a time
   * accounting will be lost if this patterns is broken by distribution tokens
   * or perpetual sending more than one token at a time
   * @dev this method should not be chained to a stake end - it should be done in a separate transaction
   */
  function flush(
    address gasReimberser,
    address perpetual,
    uint256 period,
    address[] calldata tokens
  ) external {
    if (!perpetualWhitelist[perpetual]) revert NotAllowed();
    if (IPublicEndStakeable(perpetual).getCurrentPeriod() != period) {
      return;
    }
    uint256 len = tokens.length;
    uint256 i;
    do {
      address token = tokens[i];
      uint256 bal = _getTokenBalance({
        token: token
      });
      if (token == address(0)) {
        IGasReimberser(payable(gasReimberser)).flush();
      } else {
        IGasReimberser(payable(gasReimberser)).flush_erc20(token);
      }
      // bal now represents delta
      bal = _getTokenBalance({
        token: token
      }) - bal;
      address to = rewardsTo[perpetual][period];
      emit CollectReward(perpetual, period, token, bal);
      unchecked {
        withdrawableBalanceOf[token][to] += bal;
        attributed[token] += bal;
        ++i;
      }
    } while (i < len);
  }
}
