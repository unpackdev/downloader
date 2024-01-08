// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ILockTOSProxy.sol";
import "./Address.sol";

import "./AccessibleCommon.sol";
import "./LockTOSStorage.sol";
import "./ProxyBase.sol";

/// @title The proxy of TOS Plaform
/// @notice Admin can createVault, createStakeContract.
/// User can excute the tokamak staking function of each contract through this logic.
contract LockTOSProxy is
    LockTOSStorage,
    AccessibleCommon,
    ProxyBase,
    ILockTOSProxy
{
    event Upgraded(address indexed implementation);

    /// @dev constructor of StakeVaultProxy
    /// @param _impl the logic address of StakeVaultProxy
    constructor(address _impl, address _admin) {
        assert(
            IMPLEMENTATION_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );

        require(_impl != address(0), "LockTOSProxy: logic is zero");

        _setImplementation(_impl);

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, _admin);
        lockIdCounter = 0;
        cumulativeEpochUnit = 0;
        cumulativeTOSAmount = 0;
    }

    /// @notice Set pause state
    /// @param _pause true:pause or false:resume
    function setProxyPause(bool _pause) external override onlyOwner {
        pauseProxy = _pause;
    }

    /// @notice Set implementation contract
    /// @param impl New implementation contract address
    function upgradeTo(address impl) external override onlyOwner {
        require(impl != address(0), "LockTOSProxy: input is zero");
        require(_implementation() != impl, "LockTOSProxy: same");
        _setImplementation(impl);
        emit Upgraded(impl);
    }

    /// @dev returns the implementation
    function implementation() public view override returns (address) {
        return _implementation();
    }

    /// @dev receive ether
    receive() external payable {
        revert("cannot receive Ether");
    }

    /// @dev fallback function , execute on undefined function call
    fallback() external payable {
        _fallback();
    }

    /// @dev fallback function , execute on undefined function call
    function _fallback() internal {
        address _impl = _implementation();
        require(
            _impl != address(0) && !pauseProxy,
            "LockTOSProxy: impl OR proxy is false"
        );

        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
                // delegatecall returns 0 on error.
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    /// @dev Initialize
    function initialize(
        address _tos,
        uint256 _epochUnit,
        uint256 _maxTime
    ) external override onlyOwner {
        require(tos == address(0), "Already initialized");
        tos = _tos;
        epochUnit = _epochUnit;
        maxTime = _maxTime;
    }
}
