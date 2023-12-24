// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20.sol";

import "./IZkBridgeNativeTokenVault.sol";
import "./Factory.sol";
import "./IPool.sol";
import "./Bridge.sol";

contract Router is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    Factory public factory;
    Bridge public bridge;
    address public zkBridgeNativeTokenVault;
    uint256 public nativeTokenPoolId;
    // provider => poolid => bool
    mapping(address => mapping(uint256 => bool)) public liquidityProviders;

    //-------------------------------------EVENTS--------------------------------------
    event NewBridge(address bridge);
    event NewFactory(address factory);
    event NewNativeTokenVault(address nativeTokenVault);
    event AddedLiquidityProvider(address nativeTokenVault, uint256 poolId);
    event RemovedLiquidityProvider(address nativeTokenVault, uint256 poolId);

    // MODIFIERS
    modifier onlyBridge() {
        require(msg.sender == address(bridge), "Router: Caller must be Bridge.");
        _;
    }

    modifier onlyProvider(uint256 poolId_) {
        require(liquidityProviders[msg.sender][poolId_], "Router: Caller must be liquidity provider.");
        _;
    }

    /**
     * @dev Initialize pool contract function.
     */
    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function setBridge(Bridge bridge_) external onlyOwner {
        require(address(bridge_) != address(0), "Router: Bridge cannot be zero address");
        require(address(bridge_.router()) == address(this), "Router: Invalid bridge");

        bridge = bridge_;
        emit NewBridge(address(bridge));
    }

    function setFactory(Factory factory_) external onlyOwner {
        require(address(factory_) != address(0), "Router: Factory cannot be zero address");
        require(factory_.router() == address(this), "Router: Invalid factory");

        factory = factory_;
        emit NewFactory(address(factory));
    }

    function setNativeTokenVault(address vault_) external onlyOwner {
        require(address(vault_) != address(0), "Router: NativeTokenVault cannot be zero address");

        zkBridgeNativeTokenVault = vault_;
        emit NewNativeTokenVault(address(zkBridgeNativeTokenVault));
    }

    function setNativeTokenPoolId(uint256 nativeTokenPoolId_) external onlyOwner {
        _getPool(nativeTokenPoolId_);

        nativeTokenPoolId = nativeTokenPoolId_;
    }

    function addLiquidityProvider(address liquidityProvider_, uint256 poolId_) external onlyOwner {
        require(liquidityProvider_ != address(0), "Router: liquidityProvider cannot be zero address");

        liquidityProviders[liquidityProvider_][poolId_] = true;
        emit AddedLiquidityProvider(liquidityProvider_, poolId_);
    }

    function removeLiquidityProvider(address liquidityProvider_, uint256 poolId_) external onlyOwner {
        require(liquidityProvider_ != address(0), "Router: liquidityProvider cannot be zero address");

        liquidityProviders[liquidityProvider_][poolId_] = false;
        emit RemovedLiquidityProvider(liquidityProvider_, poolId_);
    }

    function _getPool(uint256 poolId_) internal view returns (IPool pool) {
        pool = factory.pools(poolId_);
        require(address(pool) != address(0), "Router: Pool does not exist");
    }

    function addLiquidity(uint256 poolId_, uint256 amount_, address recipient_)
        public
        onlyProvider(poolId_)
        nonReentrant
    {
        IPool pool = _getPool(poolId_);
        uint256 convertRate = pool.convertRate();
        amount_ = (amount_ / convertRate) * convertRate;

        IERC20(pool.token()).safeTransferFrom(msg.sender, address(pool), amount_);
        pool.addLiquidity(recipient_, amount_);
    }

    function addLiquidityETH(uint256 poolId_) external payable onlyProvider(poolId_) nonReentrant {
        require(msg.value > 0, "Router: Insufficient balance");
        IPool pool = _getPool(poolId_);
        require(pool.token() == zkBridgeNativeTokenVault, "Router: Invalid pool");

        uint256 convertRate = pool.convertRate();
        uint256 amount = (msg.value / convertRate) * convertRate;

        // wrap the ETH into WETH
        IZkBridgeNativeTokenVault(zkBridgeNativeTokenVault).deposit{value: amount}();

        IERC20(pool.token()).transfer(address(pool), amount);
        pool.addLiquidity(msg.sender, amount);
        uint256 refundAmount = msg.value - amount;
        if (refundAmount > 0) {
            payable(msg.sender).transfer(refundAmount);
        }
    }

    function removeLiquidity(uint256 poolId_, uint256 amount_) external onlyProvider(poolId_) nonReentrant {
        IPool pool = _getPool(poolId_);
        if (pool.token() == zkBridgeNativeTokenVault) {
            pool.removeLiquidityTo(msg.sender, amount_, address(this));
            IZkBridgeNativeTokenVault(zkBridgeNativeTokenVault).withdraw(amount_);
            payable(msg.sender).transfer(amount_);
        } else {
            pool.removeLiquidity(msg.sender, amount_);
        }
    }

    function transferETH(
        uint16 dstChainId_,
        uint256 dstPoolId_,
        uint256 amount_,
        address recipient_,
        bytes calldata adapterParams_
    ) external payable nonReentrant {
        uint256 fee = estimateFee(dstChainId_, nativeTokenPoolId, dstPoolId_, amount_, recipient_, adapterParams_);
        require(msg.value >= amount_ + fee, "Router: insufficient msg.value");
        IPool pool = _getPool(nativeTokenPoolId);
        uint256 convertRate = pool.convertRate();
        amount_ = (amount_ / convertRate) * convertRate;
        require(amount_ > 0, "Router: amount too small");
        // wrap the ETH into WETH
        IZkBridgeNativeTokenVault(zkBridgeNativeTokenVault).deposit{value: amount_}();

        IERC20(pool.token()).transfer(address(pool), amount_);

        uint256 amountSD = pool.deposit(msg.sender, amount_);
        bridge.send{value: fee}(
            dstChainId_, nativeTokenPoolId, dstPoolId_, amountSD, msg.sender, recipient_, adapterParams_
        );

        uint256 refundAmount = msg.value - amount_ - fee;
        if (refundAmount > 0) {
            payable(msg.sender).transfer(refundAmount);
        }
    }

    function transferToken(
        uint16 dstChainId_,
        uint256 srcPoolId_,
        uint256 dstPoolId_,
        uint256 amount_,
        address recipient_,
        bytes calldata adapterParams_
    ) external payable nonReentrant {
        IPool pool = _getPool(srcPoolId_);
        uint256 convertRate = pool.convertRate();
        amount_ = (amount_ / convertRate) * convertRate;

        require(amount_ > 0, "Router: amount too small");
        IERC20(pool.token()).safeTransferFrom(msg.sender, address(pool), amount_);
        uint256 amountSD = pool.deposit(msg.sender, amount_);

        bridge.send{value: msg.value}(
            dstChainId_, srcPoolId_, dstPoolId_, amountSD, msg.sender, recipient_, adapterParams_
        );
    }

    function withdraw(uint256 poolId_, uint256 amount_, address recipient_) external nonReentrant onlyBridge {
        IPool pool = _getPool(poolId_);
        if (pool.token() == zkBridgeNativeTokenVault) {
            uint256 amount = pool.withdraw(address(this), amount_);
            IZkBridgeNativeTokenVault(zkBridgeNativeTokenVault).withdraw(amount);
            payable(recipient_).transfer(amount);
        } else {
            pool.withdraw(recipient_, amount_);
        }
    }

    function estimateFee(
        uint16 dstChainId_,
        uint256 srcPoolId_,
        uint256 dstPoolId_,
        uint256 amount_,
        address recipient_,
        bytes calldata adapterParams_
    ) public view returns (uint256) {
        return bridge.estimateFee(dstChainId_, srcPoolId_, dstPoolId_, amount_, recipient_, adapterParams_);
    }

    // this contract needs to accept ETH
    receive() external payable {}
}
