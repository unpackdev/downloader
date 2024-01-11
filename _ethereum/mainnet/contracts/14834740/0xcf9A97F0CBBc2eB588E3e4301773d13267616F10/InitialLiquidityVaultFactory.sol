//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./VaultFactory.sol";

import "./InitialLiquidityVaultProxy.sol";
import "./IEventLog.sol";
import "./IInitialLiquidityVaultFactory.sol";

// import "./console.sol";

interface IIInitialLiquidityVaultAction {

    /// @dev Set the uniswapV3 contract address.
    /// @param poolfactory UniswapV3Factory address
    /// @param npm NonfungiblePositionManager address
    function setUniswapInfo(
        address poolfactory,
        address npm
        )
        external;

    /// @dev Set the token address and fee information of the pool you want to create.
    /// @param tos tos address
    /// @param _fee _fee ( 3000 )
    function setTokens(
            address tos,
            uint24 _fee
        )
        external;

}

/// @title A factory that creates a Vault
contract InitialLiquidityVaultFactory is VaultFactory, IInitialLiquidityVaultFactory {

    address public uniswapV3Factory;
    address public nonfungiblePositionManager;
    address public tos;
    uint24 public fee;

    constructor() {}

    /// @inheritdoc IInitialLiquidityVaultFactory
    function setUniswapInfoNTokens(
        address[2] calldata addrs,
        address _tos,
        uint24 _fee
    )   external override
        onlyOwner
        nonZeroAddress(addrs[0])
        nonZeroAddress(addrs[1])
        nonZeroAddress(_tos)
    {
        uniswapV3Factory = addrs[0];
        nonfungiblePositionManager = addrs[1];
        tos = _tos;
        fee = _fee;
    }

    /// @inheritdoc IInitialLiquidityVaultFactory
    function create(
        string calldata _name,
        address _token,
        address _admin,
        uint256 tosPrice,
        uint256 tokenPrice
    )
        external override
        nonZeroAddress(vaultLogic)
        nonZeroAddress(upgradeAdmin)
        returns (address)
    {
        require(bytes(_name).length > 0,"name is empty");

        InitialLiquidityVaultProxy _proxy = new InitialLiquidityVaultProxy();

        require(
            address(_proxy) != address(0),
            "InitialLiquidityVaultProxy zero"
        );

        _proxy.addProxyAdmin(upgradeAdmin);
        _proxy.addAdmin(upgradeAdmin);
        _proxy.setImplementation2(vaultLogic, 0, true);
        _proxy.setLogEventAddress(logEventAddress, true);

        _proxy.setBaseInfoProxy(
            _name,
            _token,
            _admin,
            tosPrice,
            tokenPrice
        );

        IIInitialLiquidityVaultAction(address(_proxy)).setUniswapInfo(uniswapV3Factory, nonfungiblePositionManager);
        IIInitialLiquidityVaultAction(address(_proxy)).setTokens(tos, fee);

        _proxy.removeAdmin();
        // _proxy.removeProxyAdmin();

        createdContracts[totalCreatedContracts] = ContractInfo(address(_proxy), _name);
        totalCreatedContracts++;

        IEventLog(logEventAddress).logEvent(
            keccak256("InitialLiquidityVaultFactory"),
            keccak256("CreatedInitialLiquidityVault"),
            address(this),
            abi.encode(address(_proxy), _name));


        emit CreatedInitialLiquidityVault(address(_proxy), _name);

        return address(_proxy);
    }

}