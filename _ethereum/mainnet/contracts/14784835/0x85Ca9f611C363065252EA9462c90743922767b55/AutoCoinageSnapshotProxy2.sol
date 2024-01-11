// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutoCoinageSnapshotStorage2.sol";
import "./ProxyBase.sol";

import "./Address.sol";

contract AutoCoinageSnapshotProxy2 is
    AutoCoinageSnapshotStorage2,
    ProxyBase
{
    event Upgraded(address indexed implementation);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor() {
        assert(
            IMPLEMENTATION_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        snashotAggregatorTotal = 0;
        // _registerInterface(ERC20_RECEIVED);

        decimals = 27;
    }

    function setNameSymbolDecimals(string memory name_, string memory symbol_, uint256 decimals_) external onlyRole(ADMIN_ROLE) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }


    function addOwner(address _owner)
        external
        onlyRole(ADMIN_ROLE)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(ADMIN_ROLE, _owner);
    }

    /// @notice Set pause state
    /// @param _pause true:pause or false:resume
    function setProxyPause(bool _pause) external onlyRole(ADMIN_ROLE) {
        pauseProxy = _pause;
    }

    /// @notice Set implementation contract
    /// @param impl New implementation contract address
    function upgradeTo(address impl) public  onlyRole(ADMIN_ROLE) {
        require(impl != address(0), "input is zero");
        require(_implementation() != impl, "same");
        _setImplementation(impl);
        emit Upgraded(impl);
    }

    /// @dev returns the implementation
    function implementation() public view  returns (address) {
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
            "impl OR proxy is false"
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

}
