// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import "./IGovernanceStrategy.sol";
import "./IGovernancePowerDelegationERC20.sol";
import "./GovernancePowerDelegationERC20Mixin.sol";

interface IDydxToken {
  function _totalSupplySnapshots(uint256) external view returns (GovernancePowerDelegationERC20Mixin.Snapshot memory);
  function _totalSupplySnapshotsCount() external view returns (uint256);
}

/**
 * @title Governance Strategy contract
 * @dev Smart contract containing logic to measure users' relative power to propose and vote.
 * User Power = User Power from DYDX token + User Power from staked-DYDX token.
 * User Power from Token = Token Power + Token Power as Delegatee [- Token Power if user has delegated]
 * Two wrapper functions linked to DYDX tokens's GovernancePowerDelegationERC20Mixin.sol implementation
 * - getPropositionPowerAt: fetching a user Proposition Power at a specified block
 * - getVotingPowerAt: fetching a user Voting Power at a specified block
 * @author dYdX
 **/
contract GovernanceStrategy is IGovernanceStrategy {
  address public immutable DYDX_TOKEN;
  address public immutable STAKED_DYDX_TOKEN;

  /**
   * @dev Constructor, register tokens used for Voting and Proposition Powers.
   * @param dydxToken The address of the DYDX token contract.
   * @param stakedDydxToken The address of the staked-DYDX token Contract
   **/
  constructor(address dydxToken, address stakedDydxToken) {
    DYDX_TOKEN = dydxToken;
    STAKED_DYDX_TOKEN = stakedDydxToken;
  }

  /**
   * @dev Get the supply of proposition power, for the purpose of determining if a proposing
   *  threshold was reached.
   * @param blockNumber Block number at which to evaluate
   * @return Returns token supply at blockNumber.
   **/
  function getTotalPropositionSupplyAt(uint256 blockNumber) public view override returns (uint256) {
    return _getTotalSupplyAt(blockNumber);
  }

  /**
   * @dev Get the supply of voting power, for the purpose of determining if quorum or vote
   *  differential tresholds were reached.
   * @param blockNumber Block number at which to evaluate
   * @return Returns token supply at blockNumber.
   **/
  function getTotalVotingSupplyAt(uint256 blockNumber) public view override returns (uint256) {
    return _getTotalSupplyAt(blockNumber);
  }

  /**
   * @dev Returns the Proposition Power of a user at a specific block number.
   * @param user Address of the user.
   * @param blockNumber Blocknumber at which to fetch Proposition Power
   * @return Power number
   **/
  function getPropositionPowerAt(address user, uint256 blockNumber)
    public
    view
    override
    returns (uint256)
  {
    return
      _getPowerByTypeAt(user, blockNumber, IGovernancePowerDelegationERC20.DelegationType.PROPOSITION_POWER);
  }

  /**
   * @dev Returns the Vote Power of a user at a specific block number.
   * @param user Address of the user.
   * @param blockNumber Blocknumber at which to fetch Vote Power
   * @return Vote number
   **/
  function getVotingPowerAt(address user, uint256 blockNumber)
    public
    view
    override
    returns (uint256)
  {
    return _getPowerByTypeAt(user, blockNumber, IGovernancePowerDelegationERC20.DelegationType.VOTING_POWER);
  }

  function _getPowerByTypeAt(
    address user,
    uint256 blockNumber,
    IGovernancePowerDelegationERC20.DelegationType powerType
  ) internal view returns (uint256) {
    return
      IGovernancePowerDelegationERC20(DYDX_TOKEN).getPowerAtBlock(user, blockNumber, powerType) +
      IGovernancePowerDelegationERC20(STAKED_DYDX_TOKEN).getPowerAtBlock(user, blockNumber, powerType);
  }

  /**
   * @dev Returns the total supply of DYDX token at a specific block number.
   * @param blockNumber Blocknumber at which to fetch DYDX token supply.
   * @return Total DYDX token supply at block number.
   **/
  function _getTotalSupplyAt(uint256 blockNumber) internal view returns (uint256) {
    IDydxToken dydxToken = IDydxToken(DYDX_TOKEN);
    uint256 snapshotsCount = dydxToken._totalSupplySnapshotsCount();

    // Iterate in reverse over the total supply snapshots, up to index 1.
    for (uint256 i = snapshotsCount - 1; i != 0; i--) {
      GovernancePowerDelegationERC20Mixin.Snapshot memory snapshot = dydxToken._totalSupplySnapshots(i);
      if (snapshot.blockNumber <= blockNumber) {
        return snapshot.value;
      }
    }

    // If blockNumber was on or after the first snapshot, then return the initial supply.
    // Else, blockNumber is before token launch so return 0.
    GovernancePowerDelegationERC20Mixin.Snapshot memory firstSnapshot = dydxToken._totalSupplySnapshots(0);
    if (firstSnapshot.blockNumber <= blockNumber) {
      return firstSnapshot.value;
    } else {
      return 0;
    }
  }
}
