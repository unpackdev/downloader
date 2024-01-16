//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IAlluoPool.sol";

import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./EnumerableSetUpgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./IExchange.sol";
import "./ICvxBooster.sol";
import "./ICvxBaseRewardPool.sol";
import "./ICurvePool.sol";

import "./console.sol"; 


contract CVXETHAlluoPool is Initializable, PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {

    ICvxBooster public constant cvxBooster =
        ICvxBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    IExchange public constant exchange =
        IExchange(0x29c66CF57a03d41Cfe6d9ecB6883aa0E2AbA21Ec);


    bytes32 public constant  UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant  VAULT = keccak256("VAULT");

    bool public upgradeStatus;

    IERC20MetadataUpgradeable rewardToken;
    IERC20MetadataUpgradeable entryToken;
    EnumerableSetUpgradeable.AddressSet yieldTokens;
    address public curvePool;
    uint256 public poolId;
    address public vault;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

  function initialize(
        IERC20MetadataUpgradeable _rewardToken,
        address _multiSigWallet,
        address[] memory _yieldTokens,
        address _curvePool,
        uint256 _poolId,
        address _vault,
        IERC20MetadataUpgradeable _entryToken
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        rewardToken = _rewardToken;
        curvePool = _curvePool;
        poolId = _poolId;
        entryToken = _entryToken;
        for (uint256 i; i < _yieldTokens.length; i++) {
            yieldTokens.add(_yieldTokens[i]);
        }
        require(_multiSigWallet.isContract(), "BaseAlluoPool: Not contract");
        _grantRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);
        _grantRole(UPGRADER_ROLE, _multiSigWallet);


        // // TESTS ONLY:
        // _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // _grantRole(UPGRADER_ROLE, msg.sender);
        // _grantRole(VAULT, msg.sender);


        vault = _vault;
        _grantRole(VAULT, _vault);

    }

    function farm() onlyRole(VAULT) external {
        // Swap to CVX
        // Get CVX-ETH LP
        // Stake in Convex
        claimRewardsFromPool();
        for (uint256 i; i < yieldTokens.length(); i++) {
            address token = yieldTokens.at(i);
            uint256 balance = IERC20MetadataUpgradeable(token).balanceOf(address(this));
            if (token != address(entryToken)) {
                IERC20MetadataUpgradeable(token).safeIncreaseAllowance(address(exchange), balance);
                balance = exchange.exchange(token, address(entryToken), balance, 0);
            }
            entryToken.safeIncreaseAllowance(curvePool, balance);
            ICurvePool(curvePool).add_liquidity([0, balance], 0);
            rewardToken.safeIncreaseAllowance(address(cvxBooster), rewardToken.balanceOf(address(this)));
            cvxBooster.deposit(poolId, rewardToken.balanceOf(address(this)), true);
        }
    }

    function depositIntoBooster() external {
        rewardToken.safeIncreaseAllowance(address(cvxBooster), rewardToken.balanceOf(address(this)));
        cvxBooster.deposit(poolId, rewardToken.balanceOf(address(this)), true);
    }
    
    function withdraw(uint256 amount) external onlyRole(VAULT) {
        (, , , address pool, , ) = cvxBooster.poolInfo(poolId);
        ICvxBaseRewardPool(pool).withdrawAndUnwrap(amount, true);
        rewardToken.safeTransfer(vault, amount);
    }
    function fundsLocked() external view returns (uint256) {
        (,,, address rewardPool,,) =  cvxBooster.poolInfo(poolId);
        return ICvxBaseRewardPool(rewardPool).balanceOf(address(this));
    }

    function claimRewardsFromPool() public {
        (,,, address rewardPool,,) =  cvxBooster.poolInfo(poolId);
         ICvxBaseRewardPool(rewardPool).getReward();
    }

    function changeUpgradeStatus(bool _status)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        upgradeStatus = _status;
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }


    function grantRole(bytes32 role, address account)
        public
        override
        onlyRole(getRoleAdmin(role))
    {
        if (role == DEFAULT_ADMIN_ROLE) {
            require(account.isContract(), "IbAlluo: Not contract");
        }
        _grantRole(role, account);
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {
        require(upgradeStatus, "IbAlluo: Upgrade not allowed");
        upgradeStatus = false;
    }

    
}