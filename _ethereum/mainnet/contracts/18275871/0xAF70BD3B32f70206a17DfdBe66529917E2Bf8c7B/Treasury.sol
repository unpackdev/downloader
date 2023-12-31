// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./TreasuryLib.sol";
import "./AccessControl.sol";
import "./Initializable.sol";

interface IRevenue {
    function report(
        uint32 uid,
        address token,
        uint256 amount,
        bool isAdd
    ) external;

    function isReportable(
        address token,
        uint32 uid
    ) external view returns (bool);

    function refundFee(address to, address token, uint256 amount) external;

    function feeOf(uint32 uid, bool isMaker) external returns (uint32 feeNum);
}

/// @author Hyungsuk Kang <hskang9@github.com>
/// @title Standard Membership Treasury to exchange membership points with rewards
contract Treasury is AccessControl, IRevenue {
    using TreasuryLib for TreasuryLib.Storage;

    bytes32 public constant REPORTER_ROLE = keccak256("REPORTER_ROLE");

    TreasuryLib.Storage private _treasury;
    address private _membership;

    error InvalidRole(bytes32 role, address sender);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    function set(address membership, address accountant, address sabt) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert InvalidRole(DEFAULT_ADMIN_ROLE, msg.sender);
        }
        _membership = membership;
        _treasury.accountant = accountant;
        _treasury.sabt = sabt;
    }

    function report(
        uint32 uid,
        address token,
        uint256 amount,
        bool isAdd
    ) external override {
        IRevenue(_treasury.accountant).report(uid, token, amount, isAdd);
    }

    function isReportable(
        address token,
        uint32 uid
    ) external view override returns (bool) {
        return IRevenue(_membership).isReportable(token, uid);
    }

    function feeOf(uint32 uid, bool isMaker) external override returns (uint32 feeNum) {
        return IRevenue(_treasury.accountant).feeOf(uid, isMaker);
    }

    /// @dev For subscribers, exchange point to reward
    function exchange(address token, uint32 nthEra, uint32 uid, uint64 point) external {
        _treasury._exchange(token, nthEra, uid, point);
    }

    /// @dev for investors, claim the reward with allocated revenue percentage
    function claim(address token, uint32 nthEra, uint32 uid) external {
        _treasury._claim(token, nthEra, uid);
    }

    /// @dev for dev, settle the revenue with allocated revenue percentage
    function settle(address token, uint32 nthEra, uint32 uid) external {
        _treasury._settle(token, nthEra, uid);
    }

    function setClaim(uint32 uid, uint32 num) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert InvalidRole(DEFAULT_ADMIN_ROLE, msg.sender);
        }
        _treasury._setClaim(uid, num);
    }

    function setSettlement(uint32 uid) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert InvalidRole(DEFAULT_ADMIN_ROLE, msg.sender);
        }
        _treasury._setSettlement(uid);
    }

    function refundFee(address to, address token, uint256 amount) external {
        if (!hasRole(REPORTER_ROLE, msg.sender)) {
            revert InvalidRole(REPORTER_ROLE, msg.sender);
        }
        TransferHelper.safeTransfer(token, to, amount);
    }

    function getReward(address token, uint32 nthEra, uint256 point) external view returns (uint256) {
        return _treasury._getReward(token, nthEra, point);
    }

    function getClaim(address token, uint32 uid, uint32 nthEra) external view returns (uint256) {
        return _treasury._getClaim(token, uid, nthEra);
    }

    function getSettlement(address token, uint32 nthEra) external view returns (uint256) {
        return _treasury._getSettlement(token, nthEra);
    }
}
