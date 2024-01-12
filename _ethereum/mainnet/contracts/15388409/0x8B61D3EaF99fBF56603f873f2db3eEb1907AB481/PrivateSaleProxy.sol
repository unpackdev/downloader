// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IPrivateSaleProxy.sol";
import "./Address.sol";

import "./OnApprove2.sol";
import "./PrivateSaleStorage.sol";

import "./IWTON.sol";
import "./IPrivateSale.sol";

import "./ProxyAccessCommon.sol";

contract PrivateSaleProxy is 
    PrivateSaleStorage, 
    ProxyAccessCommon,
    OnApprove2,
    IPrivateSaleProxy
{

    event Upgraded(address indexed implementation);

    event SetAliveImplementation(address indexed impl, bool alive);
    event SetSelectorImplementation(bytes4 indexed selector, address indexed impl);

     /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor () {
        _setRoleAdmin(PROJECT_ADMIN_ROLE, PROJECT_ADMIN_ROLE);
        _setupRole(PROJECT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setProxyPause(bool _pause) external override onlyOwner {
        pauseProxy = _pause;
    }

    /// @dev returns the implementation
    function implementation() external override view returns (address) {
        return _implementation2(0);
    }

    /// @notice Set implementation contract
    /// @param impl New implementation contract address
    function upgradeTo(address impl) external override onlyProxyOwner {
        require(impl != address(0), "input is zero");
        require(
            _implementation2(0) != impl,
            "same addr"
        );
        _setImplementation2(impl, 0, true);
        emit Upgraded(impl);
    }

    function implementation2(uint256 _index) external view returns (address) {
        return _implementation2(_index);
    }

    function setImplementation2(
        address newImplementation,
        uint256 _index,
        bool _alive
    ) external override onlyProxyOwner {
        _setImplementation2(newImplementation, _index, _alive);
    }

    function setAliveImplementation2(address newImplementation, bool _alive)
        public 
        override
        onlyProxyOwner
    {
        _setAliveImplementation2(newImplementation, _alive);
    }

    function setSelectorImplementations2(
        bytes4[] calldata _selectors,
        address _imp
    ) public override onlyProxyOwner {
        require(
            _selectors.length > 0,
            "Proxy: _selectors's size is zero"
        );
        require(aliveImplementation[_imp], "Proxy: _imp is not alive");

        for (uint256 i = 0; i < _selectors.length; i++) {
            require(
                selectorImplementation[_selectors[i]] != _imp,
                "LiquidityVaultProxy: same imp"
            );
            selectorImplementation[_selectors[i]] = _imp;
            emit SetSelectorImplementation(_selectors[i], _imp);
        }
    }

    /// @dev set the implementation address and status of the proxy[index]
    /// @param newImplementation Address of the new implementation.
    /// @param _index index of proxy
    /// @param _alive alive status
    function _setImplementation2(
        address newImplementation,
        uint256 _index,
        bool _alive
    ) internal {
        require(
            Address.isContract(newImplementation),
            "Proxy: not contract address"
        );
        if (_alive) proxyImplementation[_index] = newImplementation;
        _setAliveImplementation2(newImplementation, _alive);
    }

    /// @dev set alive status of implementation
    /// @param newImplementation Address of the new implementation.
    /// @param _alive alive status
    function _setAliveImplementation2(address newImplementation, bool _alive)
        internal
    {
        aliveImplementation[newImplementation] = _alive;
        emit SetAliveImplementation(newImplementation, _alive);
    }

    /// @dev view implementation address of the proxy[index]
    /// @param _index index of proxy
    /// @return impl address of the implementation
    function _implementation2(uint256 _index)
        internal
        view
        returns (address impl)
    {
        return proxyImplementation[_index];
    }

    function getSelectorImplementation2(bytes4 _selector)
        public
        override 
        view
        returns (address impl)
    {
        if (selectorImplementation[_selector] == address(0))
            return proxyImplementation[0];
        else if (aliveImplementation[selectorImplementation[_selector]]){
            return selectorImplementation[_selector];
        }
        else return proxyImplementation[0];
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
        address _impl = getSelectorImplementation2(msg.sig);

        require(
            _impl != address(0) && !pauseProxy,
            "Proxy: impl OR proxy is false"
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
    /// @param _wton wtonAddress
    /// @param _saleToken saleTokenAddress
    /// @param _getToken tonAddress(usually)
    /// @param _getTokenOwner TON get Address
    function initialize(
        address _wton,
        address _saleToken,
        address _getToken,
        address _getTokenOwner
    ) external  onlyProxyOwner {
        wton = _wton;
        saleToken = IERC20(_saleToken);
        getToken = IERC20(_getToken);
        getTokenOwner = _getTokenOwner;
    }
}
