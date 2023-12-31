// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
import "./AccessControl.sol";

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

contract Revenue is IRevenue, AccessControl {

    address private _treasury;
    address private _accountant;
    address private _membership;

    error InvalidRole(bytes32 role, address sender);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function set(address membership, address accountant, address treasury) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert InvalidRole(DEFAULT_ADMIN_ROLE, msg.sender);
        }
        _membership = membership;
        _accountant = accountant;
        _treasury = treasury;
    }

    function report(
        uint32 uid,
        address token,
        uint256 amount,
        bool isAdd
    ) external override {
        IRevenue(_accountant).report(uid, token, amount, isAdd);
    }

    function isReportable(
        address token,
        uint32 uid
    ) external view override returns (bool) {
        return IRevenue(_membership).isReportable(token, uid);
    }

    function refundFee(address to, address token, uint256 amount) external override {
        return IRevenue(_treasury).refundFee(to, token, amount);
    }

    function feeOf(uint32 uid, bool isMaker) external override returns (uint32 feeNum) {
        return IRevenue(_accountant).feeOf(uid, isMaker);
    }
}