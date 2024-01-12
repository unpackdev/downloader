// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./AccessControl.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./ECDSA.sol";
import "./IStakeFor.sol";


contract RewardDistributor is AccessControl, Pausable {
    using SafeERC20 for IERC20;

    bytes32 public constant ROLE_OPERATOR = keccak256("ROLE_OPERATOR");
    bytes32 public constant ROLE_SIGNER = keccak256("ROLE_SIGNER");
    bytes32 public constant ROLE_WITHDRAW = keccak256("ROLE_WITHDRAW");
    bytes32 public constant ROLE_CLAIM_FOR = keccak256("ROLE_CLAIM_FOR");

    IERC20 public immutable TOKEN;
    uint256 public immutable CHAIN_ID;

    uint256 public totalRewardDistributed;
    IStakeFor public stakingPool;

    mapping(address => uint256) public userClaimedTotal;

    event Reward(address user, uint256 amount);
    event StakingPoolUpdate(address pool);

    constructor(
        IERC20 _token,
        IStakeFor _stakingPool,
        address _operator,
        address _signer,
        address _withdrawOperator,
        address _claimForOperator
    ) {
        uint256 chainId;
        assembly { chainId := chainid() }
        CHAIN_ID = chainId;

        TOKEN = _token;
        stakingPool = _stakingPool;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        if (_operator != address(0)) {
            _grantRole(ROLE_OPERATOR, _operator);
        }

        if (_signer != address(0)) {
            _grantRole(ROLE_SIGNER, _signer);
        }

        if (_withdrawOperator != address(0)) {
            _grantRole(ROLE_WITHDRAW, _withdrawOperator);
        }

        if (_claimForOperator != address(0)) {
            _grantRole(ROLE_CLAIM_FOR, _claimForOperator);
        }
    }

    function pause() external onlyRole(ROLE_OPERATOR) {
        _pause();
    }

    function unpause() external onlyRole(ROLE_OPERATOR) {
        _unpause();
    }

    function updateStakingPool(IStakeFor pool_) external onlyRole(ROLE_OPERATOR) {
        stakingPool = pool_;
        emit StakingPoolUpdate(address(pool_));
    }

    function withdraw(IERC20 token, address to, uint256 amount) external onlyRole(ROLE_WITHDRAW) {
        require(to != address(0), "withdraw: to is address(0)");
        token.safeTransfer(to, amount);
    }

    function claim(
        uint256 deadline,
        uint256 rewards,
        bool staking,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        whenNotPaused
    {
        _claim(msg.sender, deadline, rewards, staking, v, r, s);
    }

    function claimFor(
        address user,
        uint256 deadline,
        uint256 rewards,
        bool staking,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        whenNotPaused
        onlyRole(ROLE_CLAIM_FOR)
    {
        require(user != address(0), "claimFor: to is address(0)");
        _claim(user, deadline, rewards, staking, v, r, s);
    }

    function _claim(
        address user,
        uint256 deadline,
        uint256 rewards,
        bool staking,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        internal
    {
        require(rewards > 0, "_claim: reward is 0");
        require(deadline > block.timestamp, "_claim: deadline reached");

        address signer = ECDSA.recover(keccak256(abi.encode(CHAIN_ID, user, rewards, deadline)), v, r, s);
        require(hasRole(ROLE_SIGNER, signer), "_claim: invalid signature");

        uint256 amount = rewards - userClaimedTotal[user];
        require(amount > 0, "_claim: no reward to claim");

        userClaimedTotal[user] = rewards;
        totalRewardDistributed += amount;
        emit Reward(user, amount);

        if (staking && address(stakingPool) != address(0)) {
            TOKEN.approve(address(stakingPool), amount);
            stakingPool.depositFor(user, amount);
        } else {
            TOKEN.safeTransfer(user, amount);
        }
    }
}
