// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

import "./Pool.sol";
import "./IPoolFactory.sol";

contract PoolFactory is Initializable, OwnableUpgradeable, IPoolFactory {
    using SafeERC20 for IERC20;

    // Base tokesn for whitelisting
    IERC20 public baseToken;
    uint256 public baseAmount;

    event PoolRegistered(uint256 poolId, address manager);
    event PoolApproved(uint256 poolId);

    struct PoolInfo {
        IERC20 token;
        uint256 tokenTarget;
        uint256 ratio;
        address weiToken;
        uint256 minWei;
        uint256 maxWei;
        Pool.PoolType poolType;
        uint256 startTime;
        uint256 endTime;
        uint256 claimTime;
        string meta;
        address manager;
    }

    uint256 public poolsCount;

    PoolInfo[] public poolInfos;

    mapping(address => bool) public isAdmin;

    mapping(uint256 => address) public pools;
    mapping(address => bool) public isPool;
    mapping(uint256 => bool) public isApproved;
    mapping(uint256 => bool) public isCreated;

    // fee
    address public feeRecipient;
    uint256 public feePercent; // 20: 2%

    function initialize(
        IERC20 _baseToken,
        uint256 _baseAmount,
        address _feeRecipient,
        uint256 _feePercent
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();
        baseToken = _baseToken;
        baseAmount = _baseAmount;
        feePercent = _feePercent;
        feeRecipient = _feeRecipient;

        isAdmin[msg.sender] = true;
    }

    function updateFeeInfo(address _feeRecipient, uint256 _feePercent)
        external
        onlyOwner
    {
        feePercent = _feePercent;
        feeRecipient = _feeRecipient;
    }

    function updateBaseInfo(IERC20 _baseToken, uint256 _baseAmount)
        external
        onlyOwner
    {
        require(_baseAmount > 0, "BaseAmount should be greater than 0!");
        baseToken = _baseToken;
        baseAmount = _baseAmount;
    }

    function getFeeInfo() external view override returns (address, uint256) {
        return (feeRecipient, feePercent);
    }

    function getBaseInfo() external view override returns (IERC20, uint256) {
        return (baseToken, baseAmount);
    }

    function addAdmins(address[] calldata addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i = i + 1) {
            isAdmin[addrs[i]] = true;
        }
    }

    function removeAdmins(address[] calldata addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i = i + 1) {
            isAdmin[addrs[i]] = false;
        }
    }

    function registerPool(
        IERC20 _token,
        uint256 _tokenTarget,
        uint256 _ratio,
        address _weiToken,
        uint256 _minWei,
        uint256 _maxWei,
        Pool.PoolType _poolType,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _claimTime,
        string memory _meta,
        address manager
    ) external onlyOwner {
        require(_tokenTarget > 0, "Token target can't be zero!");
        require(_ratio > 0, "ratio can't be zero!");
        require(_minWei > 0, "minWei can't be zero!");
        require(_maxWei > 0, "maxWei can't be zero!");
        require(_minWei < _maxWei, "minWei should be less than maxWei");
        require(_startTime > block.timestamp, "You can't set past time!");
        require(
            _startTime < _endTime,
            "EndTime can't be earlier than startTime"
        );
        require(
            _endTime < _claimTime,
            "ClaimTime can't be earlier than endTime"
        );
        require(
            address(_token) != address(0),
            "zero address provided for token"
        );
        require(
            manager != address(0),
            "zero address provided for manager address"
        );

        uint256 createdPoolId = poolInfos.length;

        poolInfos.push(
            PoolInfo(
                _token,
                _tokenTarget,
                _ratio,
                _weiToken,
                _minWei,
                _maxWei,
                _poolType,
                _startTime,
                _endTime,
                _claimTime,
                _meta,
                manager
            )
        );

        emit PoolRegistered(createdPoolId, manager);
    }

    function approvePool(uint256 poolId) external onlyAdmin {
        require(poolId < poolInfos.length, "Invalid PoolId");
        require(!isApproved[poolId], "Pool is already verified");

        isApproved[poolId] = true;

        emit PoolApproved(poolId);
    }

    function createPool(uint256 poolId) external returns (address) {
        require(poolId < poolInfos.length, "Invalid PoolId");
        require(isApproved[poolId], "Pool is not approved yet");
        require(!isCreated[poolId], "Already created for this registration");

        PoolInfo storage poolInfo = poolInfos[poolId];

        require(msg.sender == poolInfo.manager, "You're not the pool manager");

        Pool pool = new Pool(
            address(this),
            poolInfo.token,
            poolInfo.tokenTarget,
            poolInfo.weiToken,
            poolInfo.ratio,
            poolInfo.minWei,
            poolInfo.maxWei,
            poolId
        );

        pool.setBaseData(
            poolInfo.poolType,
            poolInfo.startTime,
            poolInfo.endTime,
            poolInfo.claimTime,
            poolInfo.meta
        );

        poolInfo.token.safeTransferFrom(
            msg.sender,
            address(pool),
            poolInfo.tokenTarget
        );

        pools[poolId] = address(pool);
        isPool[address(pool)] = true;
        isCreated[poolId] = true;

        pool.transferOwnership(msg.sender);

        poolsCount = poolsCount + 1;

        emit PoolCreated(poolId, address(pool), msg.sender);

        return address(pool);
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "You're not an admin!");

        _;
    }
}
