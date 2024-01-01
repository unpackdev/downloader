// SPDX-License-Identifier: MIT
// Forked from OpenZeppelin Contracts (last updated v4.7.0) (utils/escrow/Escrow.sol)
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./Address.sol";

error ClaimPeriodPoolNotAllowed();

/**
 * @title ProteusPool
 * @author dev [at] proteus dot fyi
 * @notice A fork of the OpenZeppelin base Escrow contract.
 *         Holds pooled funds designated for a period until the max contributor of the period
 *         is permitted to withdraw fees for said period.
 */
contract ProteusPool is Ownable {
    using Address for address payable;

    event ContributeFees(
        address indexed payee,
        uint256 indexed period,
        uint256 weiAmount
    );
    event ClaimPeriodPool(
        address indexed payee,
        uint256 indexed period,
        uint256 weiAmount
    );

    uint256 public constant PERIOD_DURATION = 30 days;
    uint256 public immutable startTime;

    mapping(address => mapping(uint256 => uint256)) private _userPeriodFees;
    mapping(uint256 => uint256) public periodTotal;
    mapping(uint256 => address) public periodLeader;

    constructor() {
        startTime = block.timestamp;
    }

    function periodFeesOf(
        address payee,
        uint256 period
    ) public view returns (uint256) {
        return _userPeriodFees[payee][period];
    }

    function getCurrentPeriod() public view returns (uint256) {
        return ((block.timestamp - startTime) / PERIOD_DURATION);
    }

    function contributeFor(address payee) public payable onlyOwner {
        uint256 amount = msg.value;
        uint256 currPeriod = getCurrentPeriod();

        // add balance to period
        _userPeriodFees[payee][currPeriod] += amount;

        address periodLead = periodLeader[currPeriod];

        // If no current leader, default become leader
        if (periodLead == address(0)) {
            periodLeader[currPeriod] = payee;
        } else {
            // NOTE: greater than or equal, so if tie, the last to change will win.
            if (
                _userPeriodFees[payee][currPeriod] >=
                _userPeriodFees[periodLead][currPeriod]
            ) {
                periodLeader[currPeriod] = payee;
            }
        }
        periodTotal[currPeriod] += amount;
        emit ContributeFees(payee, currPeriod, amount);
    }

    function claimPeriodPoolAllowed(
        address payee,
        uint256 period
    ) public view returns (bool) {
        uint256 currPeriod = getCurrentPeriod();
        if (currPeriod <= period) return false;
        return payee == periodLeader[period];
    }

    function claimPeriodPool(
        address payable payee,
        uint256 period
    ) public onlyOwner {
        if (!claimPeriodPoolAllowed(payee, period))
            revert ClaimPeriodPoolNotAllowed();

        uint256 payment = periodTotal[period];
        // reset periodTotal and periodLeader
        periodTotal[period] = 0;
        periodLeader[period] = address(0);
        payee.sendValue(payment);

        emit ClaimPeriodPool(payee, period, payment);
    }
}
