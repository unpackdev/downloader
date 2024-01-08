// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IStakeProxy.sol";
import "./Address.sol";

import "./AccessibleCommon.sol";
import "./StakeProxyStorage.sol";

//import "./ProxyBase.sol";

/// @title The proxy of TOS Plaform
/// @notice Admin can createVault, createStakeContract.
/// User can excute the tokamak staking function of each contract through this logic.
contract Stake1Proxy is StakeProxyStorage, AccessibleCommon, IStakeProxy {
    event Upgraded(address indexed implementation, uint256 _index);

    /// @dev constructor of Stake1Proxy
    constructor(address _logic) {
        //assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));

        require(_logic != address(0), "Stake1Proxy: logic is zero");

        _setImplementation(_logic, 0, true);

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, address(this));
    }

    /// @dev Set pause state
    /// @param _pause true:pause or false:resume
    function setProxyPause(bool _pause) external override onlyOwner {
        pauseProxy = _pause;
    }

    /// @dev Set implementation contract
    /// @param impl New implementation contract address
    /// @param _index index of proxy
    function upgradeTo(address impl, uint256 _index)
        external
        override
        onlyOwner
    {
        require(impl != address(0), "input is zero");
        require(_implementation(_index) != impl, "same");

        setAliveImplementation(_implementation(_index), false);
        _setImplementation(impl, _index, true);

        emit Upgraded(impl, _index);
    }

    /// @dev view implementation address of the proxy[index]
    /// @param _index index of proxy
    /// @return address of the implementation
    function implementation(uint256 _index)
        external
        view
        override
        returns (address)
    {
        return _implementation(_index);
    }

    /// @dev set the implementation address and status of the proxy[index]
    /// @param newImplementation Address of the new implementation.
    /// @param _index index
    /// @param _alive _alive
    function setImplementation(
        address newImplementation,
        uint256 _index,
        bool _alive
    ) external override onlyOwner {
        _setImplementation(newImplementation, _index, _alive);
    }

    /// @dev set alive status of implementation
    /// @param newImplementation Address of the new implementation.
    /// @param _alive alive status
    function setAliveImplementation(address newImplementation, bool _alive)
        public
        override
        onlyOwner
    {
        _setAliveImplementation(newImplementation, _alive);
    }

    /// @dev set selectors of Implementation
    /// @param _selectors being added selectors
    /// @param _imp implementation address
    function setSelectorImplementations(
        bytes4[] calldata _selectors,
        address _imp
    ) public override onlyOwner {
        require(
            _selectors.length > 0,
            "Stake1Proxy: _selectors's size is zero"
        );
        require(aliveImplementation[_imp], "Stake1Proxy: _imp is not alive");

        for (uint256 i = 0; i < _selectors.length; i++) {
            require(
                selectorImplementation[_selectors[i]] != _imp,
                "Stake1Proxy: same imp"
            );
            selectorImplementation[_selectors[i]] = _imp;
        }
    }

    /// @dev set the implementation address and status of the proxy[index]
    /// @param newImplementation Address of the new implementation.
    /// @param _index index of proxy
    /// @param _alive alive status
    function _setImplementation(
        address newImplementation,
        uint256 _index,
        bool _alive
    ) internal {
        require(
            Address.isContract(newImplementation),
            "ProxyBase: Cannot set a proxy implementation to a non-contract address"
        );
        if (_alive) proxyImplementation[_index] = newImplementation;
        _setAliveImplementation(newImplementation, _alive);
    }

    /// @dev set alive status of implementation
    /// @param newImplementation Address of the new implementation.
    /// @param _alive alive status
    function _setAliveImplementation(address newImplementation, bool _alive)
        internal
    {
        aliveImplementation[newImplementation] = _alive;
    }

    /// @dev view implementation address of the proxy[index]
    /// @param _index index of proxy
    /// @return impl address of the implementation
    function _implementation(uint256 _index)
        internal
        view
        returns (address impl)
    {
        return proxyImplementation[_index];
    }

    /// @dev view implementation address of selector of function
    /// @param _selector selector of function
    /// @return impl address of the implementation
    function getSelectorImplementation(bytes4 _selector)
        public
        view
        override
        returns (address impl)
    {
        if (selectorImplementation[_selector] == address(0))
            return proxyImplementation[0];
        else if (aliveImplementation[selectorImplementation[_selector]])
            return selectorImplementation[_selector];
        else return proxyImplementation[0];
    }

    /// @dev receive ether
    receive() external payable {
        _fallback();
    }

    /// @dev fallback function , execute on undefined function call
    fallback() external payable {
        _fallback();
    }

    /// @dev fallback function , execute on undefined function call
    function _fallback() internal {
        address _impl = getSelectorImplementation(msg.sig);
        require(_impl != address(0) && !pauseProxy, "impl OR proxy is false");

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
