// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAipFactory.sol";
import "./AipPoolDeployer.sol";
import "./Ownable.sol";
import "./NoDelegateCall.sol";
import "./PoolAddress.sol";

contract AipFactory is IAipFactory, AipPoolDeployer, NoDelegateCall {
    address public override owner;
    address public override swapManager;
    address public override DAI;
    address public override USDC;
    address public override USDT;
    address public override WETH9;
    bool public override enabled;

    mapping(address => PoolAddress.PoolInfo) public override getPoolInfo;
    mapping(address => mapping(address => mapping(uint8 => address)))
        public
        override getPool;

    constructor() {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);
    }

    function createPool(
        address token0,
        address token1,
        uint8 frequency
    ) external override noDelegateCall returns (address pool) {
        require(enabled, "Not enabled");
        require(
            token0 != token1 && token0 != address(0) && token1 != address(0)
        );
        require(frequency > 0 && frequency <= 30, "Invalid date");
        require(
            token0 == DAI || token0 == USDC || token0 == USDT,
            "Only DAI, USDC, USDT accepted"
        );
        require(getPool[token0][token1][frequency] == address(0));
        pool = deploy(
            address(this),
            swapManager,
            WETH9,
            token0,
            token1,
            frequency
        );
        getPool[token0][token1][frequency] = pool;
        getPoolInfo[pool] = PoolAddress.PoolInfo({
            token0: token0,
            token1: token1,
            frequency: frequency
        });
        emit PoolCreated(token0, token1, frequency, pool);
    }

    function enable(
        address _swapManager,
        address _DAI,
        address _USDC,
        address _USDT,
        address _WETH9
    ) external override {
        require(!enabled, "Enabled");
        require(msg.sender == owner, "Not owner");
        require(
            _swapManager != address(0) &&
                _DAI != address(0) &&
                _USDC != address(0) &&
                _USDT != address(0) &&
                _WETH9 != address(0)
        );
        enabled = true;
        swapManager = _swapManager;
        DAI = _DAI;
        USDC = _USDC;
        USDT = _USDT;
        WETH9 = _WETH9;
        emit Enabled(swapManager, DAI, USDC, USDT, WETH9);
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner);
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }
}
