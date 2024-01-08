// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IStakeUniswapV3Proxy.sol";
import "./IStakeCoinageFactory.sol";
import "./IStakeRegistry.sol";

import "./StakeUniswapV3Storage.sol";
import "./AccessibleCommon.sol";
import "./ProxyBase.sol";
import "./CoinageFactorySLOT.sol";

/// @title Proxy for stake based coinage contract
contract StakeUniswapV3Proxy is
    StakeUniswapV3Storage,
    AccessibleCommon,
    ProxyBase,
    CoinageFactorySLOT,
    IStakeUniswapV3Proxy
{
    event Upgraded(address indexed implementation);
    event SetCoinageFactory(address indexed coinageFactory);

    /// @dev constructor of Stake1Proxy
    /// @param _logic the logic address that used in proxy
    constructor(address _logic, address _coinageFactory) {
        assert(
            IMPLEMENTATION_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );

        require(_logic != address(0), "StakeUniswapV3Proxy: logic is zero");

        _setImplementation(_logic);
        _setCoinageFactory(_coinageFactory);

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
    function upgradeTo(address impl) external override onlyOwner {
        require(impl != address(0), "StakeUniswapV3Proxy: impl is zero");
        require(_implementation() != impl, "same");
        _setImplementation(impl);
        emit Upgraded(impl);
    }

    /// @dev returns the implementation
    function implementation() public view override returns (address) {
        return _implementation();
    }

    function setCoinageFactory(address _newCoinageFactory) external onlyOwner {
        _setCoinageFactory(_newCoinageFactory);
        emit SetCoinageFactory(_newCoinageFactory);
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
        address _impl = implementation();
        require(
            _impl != address(0) && !pauseProxy,
            "StakeUniswapV3Proxy: impl is zero OR proxy is false"
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

    /// @dev set initial storage
    /// @param _addr  [tos, 0, vault,  ,   ]
    /// @param _registry teh registry address
    /// @param _intdata [cap, rewardPerBlock, 0]
    function setInit(
        address[4] memory _addr,
        address _registry,
        uint256[3] memory _intdata
    ) external override onlyOwner {
        require(
            token == address(0),
            "StakeUniswapV3Proxy: already initialized"
        );
        require(_addr[0] != address(0), "StakeUniswapV3Proxy: setInit fail");
        token = _addr[0];
        vault = _addr[2];

        stakeRegistry = _registry;
    }

    function deployCoinage() external override onlyOwner {
        require(
            coinage == address(0),
            "StakeUniswapV3Proxy: alerady set coinage"
        );
        require(
            _coinageFactory() != address(0),
            "StakeUniswapV3Proxy: _coinageFactory is zero"
        );
        coinage = IStakeCoinageFactory(_coinageFactory()).deploy(address(this));

        require(
            coinage != address(0),
            "StakeUniswapV3Proxy: deployed coinage is zero"
        );
    }

    /// @dev set pool information
    /// @param uniswapInfo [NonfungiblePositionManager,UniswapV3Factory,token0,token1]
    function setPool(address[4] memory uniswapInfo)
        external
        override
        onlyOwner
        nonZeroAddress(uniswapInfo[0])
        nonZeroAddress(uniswapInfo[1])
        nonZeroAddress(uniswapInfo[2])
        nonZeroAddress(uniswapInfo[3])
    {
        nonfungiblePositionManager = INonfungiblePositionManager(
            uniswapInfo[0]
        );
        uniswapV3FactoryAddress = uniswapInfo[1];
        poolToken0 = uniswapInfo[2];
        poolToken1 = uniswapInfo[3];
    }
}
