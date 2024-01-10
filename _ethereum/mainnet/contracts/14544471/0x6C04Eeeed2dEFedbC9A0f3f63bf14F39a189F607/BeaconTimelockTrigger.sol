// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "./IDrawBeacon.sol";
import "./IDrawBuffer.sol";
import "./Manageable.sol";
import "./IBeaconTimelockTrigger.sol";
import "./IPrizeDistributionFactory.sol";
import "./IDrawCalculatorTimelock.sol";

/**
  * @title  PoolTogether V4 BeaconTimelockTrigger
  * @author PoolTogether Inc Team
  * @notice The BeaconTimelockTrigger smart contract is an upgrade of the L1TimelockTimelock smart contract.
            Reducing protocol risk by eliminating off-chain computation of PrizeDistribution parameters. The timelock will
            only pass the total supply of all tickets in a "PrizePool Network" to the prize distribution factory contract.
*/
contract BeaconTimelockTrigger is IBeaconTimelockTrigger, Manageable {
    /* ============ Global Variables ============ */

    /// @notice PrizeDistributionFactory reference.
    IPrizeDistributionFactory public immutable prizeDistributionFactory;

    /// @notice DrawCalculatorTimelock reference.
    IDrawCalculatorTimelock public immutable timelock;

    /* ============ Constructor ============ */

    /**
     * @notice Initialize BeaconTimelockTrigger smart contract.
     * @param _owner The smart contract owner
     * @param _prizeDistributionFactory PrizeDistributionFactory address
     * @param _timelock DrawCalculatorTimelock address
     */
    constructor(
        address _owner,
        IPrizeDistributionFactory _prizeDistributionFactory,
        IDrawCalculatorTimelock _timelock
    ) Ownable(_owner) {
        prizeDistributionFactory = _prizeDistributionFactory;
        timelock = _timelock;
        emit Deployed(_prizeDistributionFactory, _timelock);
    }

    /// @inheritdoc IBeaconTimelockTrigger
    function push(IDrawBeacon.Draw memory _draw, uint256 _totalNetworkTicketSupply)
        external
        override
        onlyManagerOrOwner
    {
        timelock.lock(_draw.drawId, _draw.timestamp + _draw.beaconPeriodSeconds);
        prizeDistributionFactory.pushPrizeDistribution(_draw.drawId, _totalNetworkTicketSupply);
        emit DrawLockedAndTotalNetworkTicketSupplyPushed(
            _draw.drawId,
            _draw,
            _totalNetworkTicketSupply
        );
    }
}
