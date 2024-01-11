// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
pragma abicoder v2;

import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

contract RecoveryContractEthereum is ReentrancyGuard, AccessControl {
    //--------------------------------------------------
    // Variables
    //--------------------------------------------------
    uint256 adminCounter = 1;

    //--------------------------------------------------
    // Events
    //--------------------------------------------------
    event Withdrawn(uint256 amount, address receiver);
    event WithdrawnToken(address token, uint256 amount, address receiver);

    //--------------------------------------------------
    // Constructor
    //--------------------------------------------------
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    //--------------------------------------------------
    // Withdrawals
    //--------------------------------------------------
    function withdraw(address receiver)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        uint256 contractBalance = address(this).balance;
        require(
            contractBalance > 0,
            'RecoveryContractEthereum: cannot withdraw zero balance'
        );
        require(
            receiver != address(0),
            'RecoveryContractEthereum: cannot withdraw to address zero'
        );
        require(
            receiver != address(this),
            'RecoveryContractEthereum: cannot withdraw to this contract'
        );

        (bool success, ) = payable(receiver).call{value: contractBalance}('');
        require(
            success,
            'RecoveryContractEthereum: transfer contract balance to receiver failed'
        );

        emit Withdrawn(contractBalance, receiver);
    }

    function withdrawToken(address token, address receiver)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        uint256 contractBalance = IERC20(token).balanceOf(address(this));
        require(
            contractBalance > 0,
            'RecoveryContractEthereum: cannot withdraw zero balance'
        );
        require(
            receiver != address(0),
            'RecoveryContractEthereum: cannot withdraw to address zero'
        );
        require(
            receiver != address(this),
            'RecoveryContractEthereum: cannot withdraw to this contract'
        );

        bool success = IERC20(token).transfer(receiver, contractBalance);
        require(
            success,
            'RecoveryContractEthereum: transfer contract balance to receiver failed'
        );

        emit WithdrawnToken(token, contractBalance, receiver);
    }

    //--------------------------------------------------
    // Permissions
    //--------------------------------------------------
    function grantAdminRole(address admin)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        require(
            admin != address(0),
            'RecoveryContractEthereum: account cannot be a zero address'
        );
        adminCounter += 1;
        grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function revokeAdminRole(address admin)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        require(
            adminCounter > 1,
            'RecoveryContractEthereum: Cannot revoke admin role from last admin'
        );

        adminCounter -= 1;
        revokeRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function hasAdminRole(address admin) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, admin);
    }
}
