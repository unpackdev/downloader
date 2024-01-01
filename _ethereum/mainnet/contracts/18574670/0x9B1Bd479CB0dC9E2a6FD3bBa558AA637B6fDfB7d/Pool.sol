// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20.sol";
import "./Address.sol";

import "./Admin.sol";

abstract contract Pool is ReentrancyGuardUpgradeable, Admin {
    using SafeERC20 for IERC20;

    struct DstChainInfo {
        bool enabled; // Whether dstChain is enabled for this pool
        uint128 staticFee; // Static fee when sending tokens to dstChain
        uint256 maxTransferLimit; // Limit of a single transfer
    }

    struct PoolInfo {
        // Whether this pool is enabled
        bool enabled;
        // Should be (local decimals - shared decimals)
        // e.g. If local decimals is 18 and shared decimals is 6, this number should be 12
        // Local decimals is the decimals of the underlying ERC20 token
        // Shared decimals is the common decimals across all chains
        uint8 convertRateDecimals;
        // ERC20 token address. Should be address(0) for native token pool
        address token;
        // Token balance of this pool
        // This should be tracked via a variable because this contract also hold fees
        // Also, an attacker may force transfer tokens to this contract to reach maxLiquidity
        uint256 balance;
        // The liquidity of this pool when the remote pool is exhausted
        // Only works when there are two chains
        // When there are >= 3 chains, this does not work and should be set to type(uint256).max
        uint256 maxLiquidity;
    }

    // poolId -> dstChainId -> DstChainInfo
    mapping(uint256 => mapping(uint16 => DstChainInfo)) internal _dstChains;

    // Native token pool ID
    uint256 public immutable NATIVE_TOKEN_POOL_ID;

    // poolId -> PoolInfo
    // poolId needs to be the same across different chains for the same token
    mapping(uint256 => PoolInfo) internal _poolInfo;

    event AddLiquidity(uint256 indexed poolId, uint256 amount);
    event RemoveLiquidity(uint256 indexed poolId, uint256 amount);
    event DstChainStatusChanged(uint256 indexed poolId, uint16 indexed dstChainId, bool indexed enabled);
    event NewMaxTransferLimit(uint256 indexed poolId, uint16 indexed dstChainId, uint256 maxTransferLimit);
    event NewMaxLiquidity(uint256 indexed poolId, uint256 maxLiquidity);
    event NewStaticFee(uint256 indexed poolId, uint16 indexed dstChainId, uint256 staticFee);
    event ClaimedFees(address to, uint256 amount);

    constructor(uint256 NATIVE_TOKEN_POOL_ID_) {
        NATIVE_TOKEN_POOL_ID = NATIVE_TOKEN_POOL_ID_;
    }

    function poolInfo(uint256 poolId) public view returns (PoolInfo memory) {
        return _poolInfo[poolId];
    }

    function dstChains(uint256 poolId, uint16 dstChainId) public view returns (DstChainInfo memory) {
        return _dstChains[poolId][dstChainId];
    }

    function convertRate(uint256 poolId) public view returns (uint256) {
        return 10 ** _poolInfo[poolId].convertRateDecimals;
    }

    /// @dev ensure amount is a multiple of convertRate
    function _checkConvertRate(uint256 poolId, uint256 amount) internal view {
        require(amount % convertRate(poolId) == 0, "Pool: amount is not a multiple of convert rate");
    }

    function _checkPool(uint256 poolId) internal view {
        require(_poolInfo[poolId].enabled, "Pool: pool ID not enabled");
    }

    function _checkDstChain(uint256 poolId, uint16 dstChainId) internal view {
        _checkPool(poolId);
        require(_dstChains[poolId][dstChainId].enabled, "Pool: pool ID or dst chain ID not enabled");
    }

    function getFee(uint256 poolId, uint16 dstChainId) public view returns (uint256) {
        return uint256(_dstChains[poolId][dstChainId].staticFee);
    }

    /// @notice The main function for adding liquidity of ERC20 tokens
    function addLiquidity(uint256 poolId, uint256 amount) public onlyPoolManager nonReentrant {
        _checkPool(poolId);
        _checkConvertRate(poolId, amount);
        IERC20(_poolInfo[poolId].token).safeTransferFrom(msg.sender, address(this), amount);
        _poolInfo[poolId].balance += amount;
        emit AddLiquidity(poolId, amount);
    }

    /// @notice The main function for adding liquidity of native token
    function addLiquidityETH() public payable onlyPoolManager nonReentrant {
        uint256 poolId = NATIVE_TOKEN_POOL_ID;
        _checkPool(poolId);
        _checkConvertRate(poolId, msg.value);
        _poolInfo[poolId].balance += msg.value;
        emit AddLiquidity(poolId, msg.value);
    }

    /// @notice The main function for adding liquidity of ERC20 tokens without permission
    /// @dev When there are >= 3 chains, maxLiquidity is not enforced so everyone can add liquidity without any problem
    function addLiquidityPublic(uint256 poolId, uint256 amount) external nonReentrant {
        _checkPool(poolId);
        require(
            _poolInfo[poolId].maxLiquidity == type(uint256).max,
            "Pool: addLiquidityPublic only work when maxLiquidity is not limited"
        );
        _checkConvertRate(poolId, amount);
        IERC20(_poolInfo[poolId].token).safeTransferFrom(msg.sender, address(this), amount);
        _poolInfo[poolId].balance += amount;
        emit AddLiquidity(poolId, amount);
    }

    /// @notice The main function for adding liquidity of native token without permission
    /// @dev When there are >= 3 chains, maxLiquidity is not enforced so everyone can add liquidity without any problem
    function addLiquidityETHPublic() external payable nonReentrant {
        uint256 poolId = NATIVE_TOKEN_POOL_ID;
        _checkPool(poolId);
        require(
            _poolInfo[poolId].maxLiquidity == type(uint256).max,
            "Pool: addLiquidityPublic only work when maxLiquidity is not limited"
        );
        _checkConvertRate(poolId, msg.value);
        _poolInfo[poolId].balance += msg.value;
        emit AddLiquidity(poolId, msg.value);
    }

    /// @notice The main function for removing liquidity
    function removeLiquidity(uint256 poolId, uint256 amount) external onlyPoolManager nonReentrant {
        _checkPool(poolId);
        _checkConvertRate(poolId, amount);
        require(amount <= _poolInfo[poolId].balance);
        if (poolId == NATIVE_TOKEN_POOL_ID) {
            Address.sendValue(payable(msg.sender), amount);
        } else {
            IERC20(_poolInfo[poolId].token).safeTransfer(msg.sender, amount);
        }
        _poolInfo[poolId].balance -= amount;
        emit RemoveLiquidity(poolId, amount);
    }

    /// @notice Enable or disable a dstChain for a pool
    function setDstChain(uint256 poolId, uint16 dstChainId, bool enabled) external onlyPoolManager nonReentrant {
        _checkPool(poolId);
        require(_dstChains[poolId][dstChainId].enabled != enabled, "Pool: dst chain already enabled/disabled");
        _dstChains[poolId][dstChainId].enabled = enabled;
        emit DstChainStatusChanged(poolId, dstChainId, enabled);
    }

    /// @notice Set maxLiquidity. See the comments of PoolInfo.maxLiquidity
    function setMaxLiquidity(uint256 poolId, uint256 maxLiquidity) public onlyPoolManager nonReentrant {
        _checkPool(poolId);
        _poolInfo[poolId].maxLiquidity = maxLiquidity;
        emit NewMaxLiquidity(poolId, maxLiquidity);
    }

    /// @notice Adding liquidity and setting maxLiquidity in a single tx
    /// If you add liquidity first and then set maxLiquidity, the maxLiquidity may be reached between the two transactions, making the bridge unusable.
    /// If you raise maxLiquidity first and then add liquidity, a large number of users may use it between the two transactions, resulting in insufficient liquidity.
    /// Therefore, this function is provided to ensure atomicity.
    function addLiquidityAndSetMaxLiquidity(uint256 poolId, uint256 amount, uint256 maxLiquidity) external {
        addLiquidity(poolId, amount);
        setMaxLiquidity(poolId, maxLiquidity);
    }

    function addLiquidityETHAndSetMaxLiquidity(uint256 maxLiquidity) external payable {
        addLiquidityETH();
        setMaxLiquidity(NATIVE_TOKEN_POOL_ID, maxLiquidity);
    }

    function setMaxTransferLimit(uint256 poolId, uint16 dstChainId, uint256 maxTransferLimit)
        external
        onlyPoolManager
        nonReentrant
    {
        _checkDstChain(poolId, dstChainId);
        _dstChains[poolId][dstChainId].maxTransferLimit = maxTransferLimit;
        emit NewMaxTransferLimit(poolId, dstChainId, maxTransferLimit);
    }

    function setStaticFee(uint256 poolId, uint16 dstChainId, uint256 staticFee) external onlyPoolManager nonReentrant {
        _checkDstChain(poolId, dstChainId);
        _dstChains[poolId][dstChainId].staticFee = uint128(staticFee);
        emit NewStaticFee(poolId, dstChainId, staticFee);
    }

    function _deposit(uint256 poolId, uint16 dstChainId, uint256 amount) internal returns (uint256) {
        _checkDstChain(poolId, dstChainId);
        _checkConvertRate(poolId, amount);
        require(
            _poolInfo[poolId].balance + amount <= _poolInfo[poolId].maxLiquidity,
            "Pool: Insufficient liquidity on the target chain"
        );
        require(
            amount <= _dstChains[poolId][dstChainId].maxTransferLimit,
            "Pool: Exceeding the maximum limit of a single transfer"
        );
        _poolInfo[poolId].balance += amount;
        return amount / convertRate(poolId);
    }

    function _withdraw(uint256 poolId, uint16 srcChainId, uint256 amountSD) internal returns (uint256) {
        _checkDstChain(poolId, srcChainId);
        uint256 amount = amountSD * convertRate(poolId);
        require(amount <= _poolInfo[poolId].balance, "Pool: Liquidity shortage");
        _poolInfo[poolId].balance -= amount;
        return amount;
    }

    function accumulatedFees() public view returns (uint256) {
        return address(this).balance - _poolInfo[NATIVE_TOKEN_POOL_ID].balance;
    }

    function claimFees() external onlyPoolManager nonReentrant {
        uint256 fee = accumulatedFees();
        Address.sendValue(payable(msg.sender), fee);
        emit ClaimedFees(msg.sender, fee);
    }

    /// @notice Create a new pool
    /// @param poolId is the new pool ID. It should be NATIVE_TOKEN_POOL_ID for native token and other values for ERC20 tokens
    /// poolId needs to be the same across different chains for the same token
    /// @param token ERC20 token address. Should be address(0) for native token pool
    /// @param convertRateDecimals Should be (local decimals - shared decimals). See the comments of PoolInfo.convertRateDecimals
    function createPool(uint256 poolId, address token, uint8 convertRateDecimals)
        external
        onlyBridgeManager
        nonReentrant
    {
        require(!_poolInfo[poolId].enabled, "Pool: pool already created");
        if (poolId == NATIVE_TOKEN_POOL_ID) {
            require(token == address(0), "Pool: native token pool should not have token address");
        } else {
            require(token != address(0), "Pool: token address should not be zero");
        }
        _poolInfo[poolId].enabled = true;
        _poolInfo[poolId].convertRateDecimals = convertRateDecimals;
        _poolInfo[poolId].token = token;
        _poolInfo[poolId].maxLiquidity = type(uint256).max;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}
