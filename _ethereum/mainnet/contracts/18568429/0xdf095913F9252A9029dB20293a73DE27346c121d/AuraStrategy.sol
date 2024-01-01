// SPDX-License-Identifier: AGPLv3

pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

import "IERC20Upgradeable.sol";
import "ReentrancyGuardUpgradeable.sol";
import "SafeMathUpgradeable.sol";
import "SafeERC20Upgradeable.sol";
import { BaseStrategy } from "BaseStrategy.sol";

import "IVault.sol";
import { IBalancerAsset } from "IBalancerAsset.sol";
import { ExitKind, IBalancerVault } from "IBalancerVault.sol";
import { IAuraLocker } from "IAuraLocker.sol";
import { IRewardDistributor } from "IRewardDistributor.sol";
import { IWeth } from "IWeth.sol";
import { IDelegateRegistry } from "IDelegateRegistry.sol";
import { IExtraRewardsMultiMerkle } from "IExtraRewardsMultiMerkle.sol";
import { IUniswapV2Router } from "IUniswapV2Router.sol";

// Welcome to GoldenBoys Club
// Own it, make Yourself a GoldenBoy!
// Its Time to Shine
contract AuraStrategy is BaseStrategy, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    bool public withdrawalSafetyCheck;
    // If nothing is unlocked, processExpiredLocks will revert
    bool public processLocksOnReinvest;

    uint256 public auraBalToBalEthBptMinOutBps;

    address public constant PALADIN_VOTER_ETH = 0x68378fCB3A27D5613aFCfddB590d35a6e751972C;

    IExtraRewardsMultiMerkle public constant PALADIN_REWARDS_MERKLE =
        IExtraRewardsMultiMerkle(0x997523eF97E0b0a5625Ed2C197e61250acF4e5F1);

    IBalancerVault public constant BALANCER_VAULT = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    IAuraLocker public constant LOCKER = IAuraLocker(0x3Fa73f1E5d8A792C80F426fc8F84FBF7Ce9bBCAC);

    IDelegateRegistry public constant SNAPSHOT = IDelegateRegistry(0x469788fE6E9E9681C6ebF3bF78e7Fd26Fc015446);

    IERC20Upgradeable public constant BAL = IERC20Upgradeable(0xba100000625a3754423978a60c9317c58a424e3D);
    IERC20Upgradeable public constant WETH = IERC20Upgradeable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20Upgradeable public constant AURA = IERC20Upgradeable(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF);
    IERC20Upgradeable public constant AURABAL = IERC20Upgradeable(0x616e8BfA43F920657B3497DBf40D6b1A02D4608d);
    IERC20Upgradeable public constant BALETH_BPT = IERC20Upgradeable(0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56);

    IUniswapV2Router internal constant UNI_V2 = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    bytes32 public constant AURABAL_BALETH_BPT_POOL_ID =
        0x3dd0843a028c86e0b760b1a76929d1c5ef93a2dd000200000000000000000249;
    bytes32 public constant BAL_ETH_POOL_ID = 0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014;
    bytes32 public constant AURA_ETH_POOL_ID = 0xcfca23ca9ca720b6e98e3eb9b6aa0ffc4a5c08b9000200000000000000000274;

    uint256 private constant BPT_WETH_INDEX = 1;

    // Bribe Token -> Redirection Fee
    mapping(address => uint256) public redirectionFees;

    event TreeDistribution(address indexed token, uint256 amount, uint256 indexed blockNumber, uint256 timestamp);
    event RewardsCollected(address token, uint256 amount);
    event RedirectionFee(
        address indexed destination,
        address indexed token,
        uint256 amount,
        uint256 indexed blockNumber,
        uint256 timestamp
    );
    event TokenRedirection(
        address indexed destination,
        address indexed token,
        uint256 amount,
        uint256 indexed blockNumber,
        uint256 timestamp
    );

    constructor() {
        // Disable proxy initialize
        _disableInitializers();
    }

    /// @dev Initialize the Strategy with security settings as well as tokens
    /// @notice Proxies will set any non constant variable you declare as default value
    /// @dev add any extra changeable variable at end of initializer as shown
    function initialize(address _vault) public initializer {
        require(IVault(_vault).token() == address(AURA));

        __BaseStrategy_init(_vault);
        __ReentrancyGuard_init();

        want = address(AURA);

        /// @dev do one off approvals here
        // Permissions for Locker
        AURA.safeApprove(address(LOCKER), type(uint256).max);

        AURABAL.safeApprove(address(BALANCER_VAULT), type(uint256).max);
        WETH.safeApprove(address(BALANCER_VAULT), type(uint256).max);

        // Set Safe Defaults
        withdrawalSafetyCheck = true;

        // For slippage check
        auraBalToBalEthBptMinOutBps = 9500;

        // Process locks on reinvest is best left false as gov can figure out if they need to save that gas
    }

    /// ===== Extra Functions =====

    /// @dev Change Delegation to another address
    function setAuraLockerDelegate(address delegate) external {
        _onlyGovernance();
        // Set delegate is enough as it will clear previous delegate automatically
        LOCKER.delegate(delegate);
    }

    /// @dev Set snapshot delegation for an arbitrary space ID (Can't be used to remove delegation)
    function setSnapshotDelegate(bytes32 id, address delegate) external {
        _onlyGovernance();
        // Set delegate is enough as it will clear previous delegate automatically
        SNAPSHOT.setDelegate(id, delegate);
    }

    /// @dev Clears snapshot delegation for an arbitrary space ID
    function clearSnapshotDelegate(bytes32 id) external {
        _onlyGovernance();
        SNAPSHOT.clearDelegate(id);
    }

    /// @dev Should we check if the amount requested is more than what we can return on withdrawal?
    function setWithdrawalSafetyCheck(bool newWithdrawalSafetyCheck) external {
        _onlyGovernance();
        withdrawalSafetyCheck = newWithdrawalSafetyCheck;
    }

    /// @dev Should we processExpiredLocks during reinvest?
    function setProcessLocksOnReinvest(bool newProcessLocksOnReinvest) external {
        _onlyGovernance();
        processLocksOnReinvest = newProcessLocksOnReinvest;
    }

    /// @dev Sets the redirection fee for a given token
    /// @param token Bribe token to redirect
    /// @param redirectionFee Fee to be processed for the redirection service, different per token
    function setRedirectionToken(address token, uint256 redirectionFee) external {
        _onlyGovernance();
        require(token != address(0), "Invalid token address");
        require(redirectionFee <= MAX_BPS, "Invalid redirection fee");
        // Sets redirection fees for a given token
        redirectionFees[token] = redirectionFee;
    }

    /// @dev Function to move rewards that are not protected
    /// @notice Only not protected, moves the whole amount using _handleRewardTransfer
    /// @notice because token paths are hardcoded, this function is safe to be called by anyone
    function sweepRewardToken(address token, address recepient) external nonReentrant {
        _onlyGovernance();
        _sweepRewardToken(token, recepient);
    }

    /// @dev Bulk function for sweepRewardToken
    function sweepRewards(address[] calldata tokens, address recepient) external nonReentrant {
        _onlyGovernance();

        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; ++i) {
            _sweepRewardToken(tokens[i], recepient);
        }
    }

    function setAuraBalToBalEthBptMinOutBps(uint256 _minOutBps) external {
        _onlyGovernance();
        require(_minOutBps <= MAX_BPS, "Invalid minOutBps");

        auraBalToBalEthBptMinOutBps = _minOutBps;
    }

    /// ===== View Functions =====

    /// @dev Return the name of the strategy
    function getName() external pure override returns (string memory) {
        return "GOLD vlAURA Voting Strategy";
    }

    /// @dev Specify the version of the Strategy, for upgrades
    function version() external pure returns (string memory) {
        return "1.0";
    }

    /// @dev Does this function require `tend` to be called?
    function _isTendable() internal pure override returns (bool) {
        return false; // Change to true if the strategy should be tended
    }

    /// @dev Return the balance (in want) that the strategy has invested somewhere
    function balanceOfPool() public view override returns (uint256) {
        // Return the balance in locker
        IAuraLocker.Balances memory balances = LOCKER.balances(address(this));
        return balances.locked;
    }

    /// @dev Return the balance of rewards that the strategy has accrued
    /// @notice Used for offChain APY and Harvest Health monitoring
    function balanceOfRewards() external view override returns (TokenAmount[] memory rewards) {
        IAuraLocker.EarnedData[] memory earnedData = LOCKER.claimableRewards(address(this));
        uint256 numRewards = earnedData.length;
        rewards = new TokenAmount[](numRewards);
        for (uint256 i; i < numRewards; ++i) {
            rewards[i] = TokenAmount(earnedData[i].token, earnedData[i].amount);
        }
    }

    /// @dev Return a list of protected tokens
    /// @notice It's very important all tokens that are meant to be in the strategy to be marked as protected
    /// @notice this provides security guarantees to the depositors they can't be sweeped away
    function getProtectedTokens() public view virtual override returns (address[] memory) {
        address[] memory protectedTokens = new address[](2);
        protectedTokens[0] = want; // AURA
        protectedTokens[1] = address(AURABAL);
        return protectedTokens;
    }

    /// @dev Get aura locker delegate address
    function getAuraLockerDelegate() public view returns (address) {
        return LOCKER.delegates(address(this));
    }

    /// @dev Get snapshot delegation, for a given space ID
    function getSnapshotDelegate(bytes32 id) external view returns (address) {
        return SNAPSHOT.delegation(address(this), id);
    }

    /// ===== Internal Core Implementations =====

    /// @dev Deposit `_amount` of want, investing it to earn yield
    function _deposit(uint256 _amount) internal override {
        // Lock tokens for 16 weeks, send credit to strat
        LOCKER.lock(address(this), _amount);
    }

    /// @dev utility function to withdraw all AURA that we can from the lock
    function prepareWithdrawAll() external {
        manualProcessExpiredLocks();
    }

    /// @dev Withdraw all funds, this is used for migrations, most of the time for emergency reasons
    function _withdrawAll() internal view override {
        //NOTE: This probably will always fail unless we have all tokens expired
        require(balanceOfPool() == 0 && LOCKER.balanceOf(address(this)) == 0, "Tokens still locked");

        // Make sure to call prepareWithdrawAll before _withdrawAll
    }

    /// @dev Withdraw `_amount` of want, so that it can be sent to the vault / depositor
    /// @notice just unlock the funds and return the amount you could unlock
    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        uint256 max = balanceOfWant();

        if (_amount > max) {
            // Try to unlock, as much as possible
            // @notice Reverts if no locks expired
            LOCKER.processExpiredLocks(false);
            max = balanceOfWant();
        }

        if (withdrawalSafetyCheck) {
            require(max >= _amount.mul(9980).div(MAX_BPS), "Withdrawal Safety Check"); // 20 BP of slippage
        }

        if (_amount > max) {
            return max;
        }

        return _amount;
    }

    /// @notice Autocompound auraBAL rewards into AURA.
    /// @dev Anyone can claim bribes for this contract from hidden hands with
    ///      the correct merkle proof. Therefore, only tokens that are gained
    ///      after claiming rewards or swapping are auto-compunded.
    function _harvest() internal override returns (TokenAmount[] memory harvested) {
        // Claim auraBAL from locker
        LOCKER.getReward(address(this));

        harvested = new TokenAmount[](1);
        harvested[0].token = address(AURA);

        uint256 auraBalEarned = AURABAL.balanceOf(address(this));
        // auraBAL -> BAL/ETH BPT -> WETH -> AURA
        if (auraBalEarned > 0) {
            // Common structs for swaps
            IBalancerVault.SingleSwap memory singleSwap;
            IBalancerVault.FundManagement memory fundManagement = IBalancerVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            });

            // Swap auraBal -> BAL/ETH BPT
            singleSwap = IBalancerVault.SingleSwap({
                poolId: AURABAL_BALETH_BPT_POOL_ID,
                kind: IBalancerVault.SwapKind.GIVEN_IN,
                assetIn: IBalancerAsset(address(AURABAL)),
                assetOut: IBalancerAsset(address(BALETH_BPT)),
                amount: auraBalEarned,
                userData: new bytes(0)
            });
            uint256 minOut = (auraBalEarned * auraBalToBalEthBptMinOutBps) / MAX_BPS;
            uint256 balEthBptEarned = BALANCER_VAULT.swap(singleSwap, fundManagement, minOut, type(uint256).max);

            // Withdraw BAL/ETH BPT -> WETH

            IBalancerAsset[] memory assets = new IBalancerAsset[](2);
            assets[0] = IBalancerAsset(address(BAL));
            assets[1] = IBalancerAsset(address(WETH));
            IBalancerVault.ExitPoolRequest memory exitPoolRequest = IBalancerVault.ExitPoolRequest({
                assets: assets,
                minAmountsOut: new uint256[](2),
                userData: abi.encode(ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, balEthBptEarned, BPT_WETH_INDEX),
                toInternalBalance: false
            });
            BALANCER_VAULT.exitPool(BAL_ETH_POOL_ID, address(this), payable(address(this)), exitPoolRequest);

            // Swap WETH -> AURA
            uint256 wethEarned = WETH.balanceOf(address(this));
            singleSwap = IBalancerVault.SingleSwap({
                poolId: AURA_ETH_POOL_ID,
                kind: IBalancerVault.SwapKind.GIVEN_IN,
                assetIn: IBalancerAsset(address(WETH)),
                assetOut: IBalancerAsset(address(AURA)),
                amount: wethEarned,
                userData: new bytes(0)
            });
            harvested[0].amount = BALANCER_VAULT.swap(singleSwap, fundManagement, 0, type(uint256).max);
        }

        _reportToVault(harvested[0].amount);
        if (harvested[0].amount > 0) {
            _deposit(harvested[0].amount);
        }
    }

    /// @notice Claims rewards from Paladin using merkle proofs, sell everything to AURA and report
    /// to vault
    function harvestPaladinDelegate(IExtraRewardsMultiMerkle.ClaimParams[] calldata claims)
        external
        returns (TokenAmount[] memory harvested)
    {
        _onlyAuthorizedActors();
        PALADIN_REWARDS_MERKLE.multiClaim(address(this), claims);
        harvested = new TokenAmount[](1);
        harvested[0].token = address(AURA);
        // Sell all  rewards to WETH
        for (uint256 i; i < claims.length; i++) {
            IERC20Upgradeable reward_token = IERC20Upgradeable(claims[i].token);
            // Skip if reward token is USDC or WETH
            if (address(reward_token) == address(WETH)) continue;

            uint256 reward_amount = reward_token.balanceOf(address(this));
            // Approve reward token to uniswap, if rewards are 0 skip
            if (reward_amount == 0) continue;
            else if (reward_amount > 0) reward_token.safeApprove(address(UNI_V2), reward_amount);

            address[] memory path = new address[](2);
            path[0] = address(reward_token);
            path[1] = address(WETH);
            try UNI_V2.swapExactTokensForTokens(reward_amount, uint256(0), path, address(this), block.timestamp)
            returns (uint256[] memory amounts) {
                emit RewardsCollected(address(reward_token), amounts[0]);
            } catch {
                // If univ2 pair wasn't found this means tokens can be swept later on
                // Also, approve allowance to 0 just in case
                reward_token.safeApprove(address(UNI_V2), 0);
                continue;
            }
        }
        // Finally, swap all WETH to AURA
        uint256 wethEarned = WETH.balanceOf(address(this));
        if (wethEarned > 0) {
            IBalancerVault.SingleSwap memory singleSwap;
            singleSwap = IBalancerVault.SingleSwap({
                poolId: AURA_ETH_POOL_ID,
                kind: IBalancerVault.SwapKind.GIVEN_IN,
                assetIn: IBalancerAsset(address(WETH)),
                assetOut: IBalancerAsset(address(AURA)),
                amount: wethEarned,
                userData: new bytes(0)
            });
            IBalancerVault.FundManagement memory fundManagement = IBalancerVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            });
            harvested[0].amount = BALANCER_VAULT.swap(singleSwap, fundManagement, 0, type(uint256).max);
        }
        // Report back to vault and deposit into locker
        _reportToVault(harvested[0].amount);
        if (harvested[0].amount > 0) {
            _deposit(harvested[0].amount);
        }
    }

    // Example tend is a no-op which returns the values, could also just revert
    function _tend() internal override returns (TokenAmount[] memory tended) {
        revert("no op");
    }

    /// MANUAL FUNCTIONS ///

    /// @dev process all locks, to redeem
    /// @notice No Access Control Checks, anyone can unlock an expired lock
    function manualProcessExpiredLocks() public {
        // Unlock vlAURA that is expired and redeem AURA back to this strat
        LOCKER.processExpiredLocks(false);
    }

    /// @dev Send all available Aura to the Vault
    /// @notice you can do this so you can earn again (re-lock), or just to add to the redemption pool
    function manualSendAuraToVault() external whenNotPaused {
        _onlyGovernance();
        uint256 auraAmount = balanceOfWant();
        _transferToVault(auraAmount);
    }

    /// *** Handling of rewards ***
    function _handleRewardTransfer(address token, address recepient, uint256 amount) internal {
        // NOTE: Tokens with an assigned recepient are sent there
        if (recepient != address(0)) {
            _sendTokenToBriber(token, recepient, amount);
        }
    }

    /// @dev Takes a fee on the token and sends remaining to the given briber recepient
    function _sendTokenToBriber(address token, address recepient, uint256 amount) internal {
        // Process redirection fee
        uint256 redirectionFee = amount.mul(redirectionFees[token]).div(MAX_BPS);
        if (redirectionFee > 0) {
            address cachedTreasury = IVault(vault).treasury();
            IERC20Upgradeable(token).safeTransfer(cachedTreasury, redirectionFee);
            emit RedirectionFee(cachedTreasury, token, redirectionFee, block.number, block.timestamp);
        }

        // Send remaining to bribe recepient
        // NOTE: Calculating instead of checking balance since there could have been an
        // existing balance on the contract beforehand (Could be 0 if fee == MAX_BPS)
        uint256 redirectionAmount = amount.sub(redirectionFee);
        if (redirectionAmount > 0) {
            IERC20Upgradeable(token).safeTransfer(recepient, redirectionAmount);
            emit TokenRedirection(recepient, token, redirectionAmount, block.number, block.timestamp);
        }
    }

    function _sweepRewardToken(address token, address recepient) internal {
        _onlyNotProtectedTokens(token);

        uint256 toSend = IERC20Upgradeable(token).balanceOf(address(this));
        _handleRewardTransfer(token, recepient, toSend);
    }
}
