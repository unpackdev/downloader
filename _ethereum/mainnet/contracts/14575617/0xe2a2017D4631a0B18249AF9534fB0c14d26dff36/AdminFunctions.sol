//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
import "./AccessControl.sol";
import "./Ownable.sol";
import "./IEscrow.sol";

/**
 * @title IEscrow
 * @author Protofire
 * @dev Ilamini Dagogo for Protofire.
 *
 */

contract AdminFunctions is AccessControl {
    address internal escrow;
    uint256 public feeAmount = 3 * 10**24;
    uint256 public constant BPSNUMBER = 10**27;
    uint256 public constant DECIMAL = 18;
    address internal feeAddress;
    address internal tokenListManagerAddress;
    address internal permissionAddress;
    bytes32 public constant dOTC_Admin_ROLE = keccak256("dOTC_ADMIN_ROLE");
    bytes32 public constant ESCROW_MANAGER_ROLE = keccak256("ESCROW_MANAGER_ROLE");
    bytes32 public constant PERMISSION_SETTER_ROLE = keccak256("PERMISSION_SETTER_ROLE");
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");

    /**
     * @dev Grants dOTC_Admin_ROLE to `_dOTCAdmin`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setdOTCAdmin(address _dOTCAdmin) external {
        grantRole(dOTC_Admin_ROLE, _dOTCAdmin);
    }

    function setEscrowAddress(address _address) public returns (bool status) {
        require(hasRole(ESCROW_MANAGER_ROLE, _msgSender()), "Not allowed");
        escrow = _address;
        return true;
    }

    function setEscrowLinker() external returns (bool status) {
        require(hasRole(ESCROW_MANAGER_ROLE, _msgSender()), "Not allowed");
        if (IEscrow(escrow).setdOTCAddress(address(this))) {
            return true;
        }
        return false;
    }

    function freezeEscrow() external isAdmin returns (bool status) {
        if (IEscrow(escrow).freezeEscrow(msg.sender)) {
            return true;
        }
        return false;
    }

    /**
     *    @dev unFreezeEscrow
     *    Requirement : caller must have admin role
     *   @return status bool
     */
    function unFreezeEscrow() external isAdmin returns (bool status) {
        if (IEscrow(escrow).unFreezeEscrow(msg.sender)) {
            return true;
        }
        return false;
    }

    function setTokenListManagerAddress(address _contractAddress) external isAdmin returns (bool status) {
        tokenListManagerAddress = _contractAddress;
        return true;
    }

    function setPermissionAddress(address _permissionAddress) external isAdmin returns (bool status) {
        require(hasRole(PERMISSION_SETTER_ROLE, _msgSender()), "account not permmited");
        permissionAddress = _permissionAddress;
        return true;
    }

    function setFeeAddress(address _newFeeAddress) external isAdmin returns (bool status) {
        require(hasRole(FEE_MANAGER_ROLE, _msgSender()), "account not permmited");
        feeAddress = _newFeeAddress;
        return true;
    }

    function setFeeAmount(uint256 _feeAmount) external isAdmin returns (bool status) {
        require(hasRole(FEE_MANAGER_ROLE, _msgSender()), "account not permmited");
        feeAmount = _feeAmount;
        return true;
    }

    /**
     *   @dev check if sender has admin role
     */
    modifier isAdmin() {
        require(hasRole(dOTC_Admin_ROLE, _msgSender()), "must have dOTC Admin role");
        _;
    }
    // Limit
    // Fee Manager
}
