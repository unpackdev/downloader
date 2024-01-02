// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./AccessControl.sol";
import "./IOracleNetwork.sol";
import "./Utils.sol";

contract StakeStarOracleStrict is
    IOracleNetwork,
    AccessControl
{
    uint32 private _currentEpoch;
    uint96 private _currentBalance;

    uint64 public _zeroEpochTimestamp;
    uint32 _epochUpdateTimePeriodInSeconds;
    bool public _strictEpochMode;

    uint8 constant ORACLES_COUNT_MAX = 3;
    uint8 constant ORACLES_COUNT_MIN = 2;

    struct OracleData {
        uint32 next_epoch;
        uint96 next_balance;
    }

    mapping(address => uint32) private _oracleNo;
    mapping(uint32 => OracleData) private _oracleProposal;

    constructor (uint64 zeroEpochTimestamp) {
        _setupRole(Utils.DEFAULT_ADMIN_ROLE, msg.sender);
        _zeroEpochTimestamp = zeroEpochTimestamp;
        setEpochUpdatePeriod(uint32(24 * 3600) / Utils.EPOCH_DURATION);
    }

    event Saved(uint32 epoch, uint256 totalBalance);
    event Proposed(uint32 epoch, uint256 totalBalance, uint32 oracleBit);

    function latestTotalBalance()
        public
        view
        returns (uint256 totalBalance, uint64 timestamp)
    {
        require(_currentEpoch > 0, "not initialized");
        totalBalance = _currentBalance;
        timestamp = epochToTimestamp(_currentEpoch);
    }

    function epochToTimestamp(uint32 epoch) public view returns (uint64) {
        assert(_zeroEpochTimestamp > 0);
        return _zeroEpochTimestamp + uint64(Utils.EPOCH_DURATION) * uint64(epoch);
    }

    function timestampToEpoch(uint64 timestamp) public view returns (uint32) {
        assert(_zeroEpochTimestamp > 0);
        return uint32((timestamp - _zeroEpochTimestamp) / uint64(Utils.EPOCH_DURATION));
    }

    function nextEpochToPublish() public view returns (uint32) {
        uint64 consensusTimestamp = epochToTimestamp(_currentEpoch);
        uint64 nextEpochTimestamp = (uint64(block.timestamp) - consensusTimestamp - 1)
                                        / _epochUpdateTimePeriodInSeconds
                                        * _epochUpdateTimePeriodInSeconds
                                    + consensusTimestamp;
        return timestampToEpoch(nextEpochTimestamp);
    }

    function save(uint32 epoch, uint256 totalBalance) public {
        uint32 oracleNo = _oracleNo[msg.sender];
        require(oracleNo > 0, "oracle role required");

        uint64 timestamp = epochToTimestamp(epoch);
        require(timestamp < uint64(block.timestamp), "epoch from the future");

        if (_strictEpochMode) {
            require(
                epoch == nextEpochToPublish(),
                "only nextEpochToPublish() allowed"
            );
        } else {
            require(epoch >= _currentEpoch, "epoch must increase");
        }

        if (epoch == _currentEpoch) {
            if (totalBalance == _currentBalance) {
                // already in consensus, just ignore the same data
                emit Proposed(
                    epoch,
                    totalBalance,
                    uint32(1) << (uint32(23) + oracleNo)
                );
                return;
            } else {
                revert("balance not equals");
            }
        }

        OracleData storage info = _oracleProposal[oracleNo];

        emit Proposed(
            epoch,
            totalBalance,
            uint32(1) << (uint32(23) + oracleNo)
        );

        uint32 confirmations = 1;
        for (uint32 no = 1; no <= ORACLES_COUNT_MAX; ++no) {
            if (no == oracleNo) continue;

            if (
                _oracleProposal[no].next_epoch == epoch &&
                _oracleProposal[no].next_balance == totalBalance
            ) {
                ++confirmations;
            }
        }

        if (confirmations >= ORACLES_COUNT_MIN) {
            _currentEpoch = epoch;
            _currentBalance = uint96(totalBalance);
            emit Saved(epoch, totalBalance);
        } else {
            info.next_epoch = epoch;
            info.next_balance = uint96(totalBalance);
        }
    }

    // oracle_no in [0..ORACLES_COUNT)
    function setOracle(
        address oracle,
        uint8 oracle_no
    ) public onlyRole(Utils.DEFAULT_ADMIN_ROLE) {
        require(oracle_no < ORACLES_COUNT_MAX, "invalid oracle number");
        _oracleNo[oracle] = oracle_no + 1;
    }

    function setStrictEpochMode(
        bool strictEpochMode
    ) public onlyRole(Utils.DEFAULT_ADMIN_ROLE) {
        _strictEpochMode = strictEpochMode;
    }

    function setEpochUpdatePeriod(
        uint32 period_in_epochs
    ) public onlyRole(Utils.DEFAULT_ADMIN_ROLE) {
        require(period_in_epochs >= 1, "invalid period");
        _epochUpdateTimePeriodInSeconds = period_in_epochs * Utils.EPOCH_DURATION;
    }

    function getCurrentProposal(
        address oracle
    ) public view returns (uint32 proposed_epoch, uint256 proposed_balance) {
        uint32 oracleNo = _oracleNo[oracle];
        require(oracleNo > 0, "invalid oracle");

        OracleData storage info = _oracleProposal[oracleNo];
        proposed_epoch = info.next_epoch;
        proposed_balance = info.next_balance;
    }
}
