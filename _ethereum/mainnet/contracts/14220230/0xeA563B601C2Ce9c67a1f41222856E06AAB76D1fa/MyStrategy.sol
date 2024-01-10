// SPDX-License-Identifier: MIT

pragma solidity ^0.6.11;
pragma experimental ABIEncoderV2;

import "IERC20Upgradeable.sol";
import "SafeMathUpgradeable.sol";
import "AddressUpgradeable.sol";
import "SafeERC20Upgradeable.sol";

import "ISettV4.sol";
import "IController.sol";
import "ICvxLocker.sol";
import "ICVXBribes.sol";
import "IVotiumBribes.sol";
import "IDelegateRegistry.sol";
import "ICurvePool.sol";

import {BaseStrategy} from "BaseStrategy.sol";

/**
 * CHANGELOG
 * V1.0 Initial Release, can lock
 * V1.1 Update to handle rewards which are sent to a multisig
 * V1.2 Update to emit badger, all other rewards are sent to multisig
 * V1.3 Updated Address to claim CVX Rewards
 * V1.4 Updated Claiming mechanism to allow claiming any token (using difference in balances)
 * V1.5 Unlocks are permissioneless, added Chainlink Keepeers integration
 */
contract MyStrategy is BaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    uint256 public constant MAX_BPS = 10_000;

    // address public want // Inherited from BaseStrategy, the token the strategy wants, swaps into and tries to grow
    address public lpComponent; // Token we provide liquidity with
    address public reward; // Token we farm and swap to want / lpComponent

    address public constant BADGER_TREE = 0x660802Fc641b154aBA66a62137e71f331B6d787A;

    IDelegateRegistry public constant SNAPSHOT =
        IDelegateRegistry(0x469788fE6E9E9681C6ebF3bF78e7Fd26Fc015446);

    // The initial DELEGATE for the strategy // NOTE we can change it by using manualSetDelegate below
    address public constant DELEGATE =
        0x14F83fF95D4Ec5E8812DDf42DA1232b0ba1015e6;

    bytes32 public constant DELEGATED_SPACE =
        0x6376782e65746800000000000000000000000000000000000000000000000000;
    
    ISettV4 public constant CVXCRV_VAULT =
        ISettV4(0x2B5455aac8d64C14786c3a29858E43b5945819C0);

    // NOTE: At time of publishing, this contract is under audit
    ICvxLocker public constant LOCKER = ICvxLocker(0xD18140b4B819b895A3dba5442F959fA44994AF50);

    ICVXBribes public constant CVX_EXTRA_REWARDS = ICVXBribes(0xDecc7d761496d30F30b92Bdf764fb8803c79360D);
    IVotiumBribes public constant VOTIUM_BRIBE_CLAIMER = IVotiumBribes(0x378Ba9B73309bE80BF4C2c027aAD799766a7ED5A);
    
    // We hardcode, an upgrade is required to change this as it's a meaningful change
    address public constant BRIBES_RECEIVER = 0x6F76C6A1059093E21D8B1C13C4e20D8335e2909F;
    
    // We emit badger through the tree to the vault holders
    address public constant BADGER = 0x3472A5A71965499acd81997a54BBA8D852C6E53d;

    bool public withdrawalSafetyCheck = false;
    bool public harvestOnRebalance = false;
    // If nothing is unlocked, processExpiredLocks will revert
    bool public processLocksOnReinvest = false;
    bool public processLocksOnRebalance = false;

    // Used to signal to the Badger Tree that rewards where sent to it
    event TreeDistribution(
        address indexed token,
        uint256 amount,
        uint256 indexed blockNumber,
        uint256 timestamp
    );
    event RewardsCollected(
        address token,
        uint256 amount
    );
    event PerformanceFeeGovernance(
        address indexed destination,
        address indexed token,
        uint256 amount,
        uint256 indexed blockNumber,
        uint256 timestamp
    );
    event PerformanceFeeStrategist(
        address indexed destination,
        address indexed token,
        uint256 amount,
        uint256 indexed blockNumber,
        uint256 timestamp
    );

    function initialize(
        address _governance,
        address _strategist,
        address _controller,
        address _keeper,
        address _guardian,
        address[3] memory _wantConfig,
        uint256[3] memory _feeConfig
    ) public initializer {
        __BaseStrategy_init(
            _governance,
            _strategist,
            _controller,
            _keeper,
            _guardian
        );

        /// @dev Add config here
        want = _wantConfig[0];
        lpComponent = _wantConfig[1];
        reward = _wantConfig[2];

        performanceFeeGovernance = _feeConfig[0];
        performanceFeeStrategist = _feeConfig[1];
        withdrawalFee = _feeConfig[2];

        
        IERC20Upgradeable(reward).safeApprove(address(CVXCRV_VAULT), type(uint256).max);

        /// @dev do one off approvals here
        // Permissions for Locker
        IERC20Upgradeable(want).safeApprove(address(LOCKER), type(uint256).max);

        // Delegate voting to DELEGATE
        SNAPSHOT.setDelegate(DELEGATED_SPACE, DELEGATE);
    }

    /// ===== Extra Functions =====
    /// @dev Change Delegation to another address
    function manualSetDelegate(address delegate) external {
        _onlyGovernance();
        // Set delegate is enough as it will clear previous delegate automatically
        SNAPSHOT.setDelegate(DELEGATED_SPACE, delegate);
    }

    ///@dev Should we check if the amount requested is more than what we can return on withdrawal?
    function setWithdrawalSafetyCheck(bool newWithdrawalSafetyCheck) external {
        _onlyGovernance();
        withdrawalSafetyCheck = newWithdrawalSafetyCheck;
    }

    ///@dev Should we harvest before doing manual rebalancing
    ///@notice you most likely want to skip harvest if everything is unlocked, or there's something wrong and you just want out
    function setHarvestOnRebalance(bool newHarvestOnRebalance) external {
        _onlyGovernance();
        harvestOnRebalance = newHarvestOnRebalance;
    }

    ///@dev Should we processExpiredLocks during reinvest?
    function setProcessLocksOnReinvest(bool newProcessLocksOnReinvest) external {
        _onlyGovernance();
        processLocksOnReinvest = newProcessLocksOnReinvest;
    }

    ///@dev Should we processExpiredLocks during manualRebalance?
    function setProcessLocksOnRebalance(bool newProcessLocksOnRebalance)
        external
    {
        _onlyGovernance();
        processLocksOnRebalance = newProcessLocksOnRebalance;
    }

    /// *** Bribe Claiming ***
    /// @dev given a token address, claim that as reward from CVX Extra Rewards
    /// @notice funds are transfered to the hardcoded address BRIBES_RECEIVER
    function claimBribeFromConvex (address token) external {
        _onlyGovernanceOrStrategist();
        uint256 beforeVaultBalance = _getBalance();

        uint256 beforeBalance = IERC20Upgradeable(token).balanceOf(address(this));
        // Claim reward for token
        CVX_EXTRA_REWARDS.getReward(address(this), token);
        uint256 afterBalance = IERC20Upgradeable(token).balanceOf(address(this));

        _handleRewardTransfer(token, afterBalance.sub(beforeBalance));

        require(beforeVaultBalance == _getBalance(), "Balance can't change");
    }

    /// @dev given a list of token addresses, claim that as reward from CVX Extra Rewards
    /// @notice funds are transfered to the hardcoded address BRIBES_RECEIVER
    function claimBribesFromConvex(address[] calldata tokens) external {
        _onlyGovernanceOrStrategist();
        uint256 beforeVaultBalance = _getBalance();

        // Revert if you try to claim a protected token, this is to avoid rugging
        // Also checks balance diff
        uint256 length = tokens.length;
        uint256[] memory beforeBalance = new uint256[](length);
        for(uint i = 0; i < length; i++){
            beforeBalance[i] = IERC20Upgradeable(tokens[i]).balanceOf(address(this));
        }
        // NOTE: If we end up getting bribes in form or protected tokens, we'll have to change

        // Claim reward for tokens
        CVX_EXTRA_REWARDS.getRewards(address(this), tokens);

        // Send reward to Multisig
        for(uint x = 0; x < length; x++){
            _handleRewardTransfer(tokens[x], IERC20Upgradeable(tokens[x]).balanceOf(address(this)).sub(beforeBalance[x]));
        }

        require(beforeVaultBalance == _getBalance(), "Balance can't change");
    }

    /// @dev given the votium data (available at: https://github.com/oo-00/Votium/tree/main/merkle)
    /// @dev allows claiming of rewards, badger is sent to tree
    function claimBribeFromVotium(
        address token, 
        uint256 index, 
        address account, 
        uint256 amount, 
        bytes32[] calldata merkleProof
    ) external {
        _onlyGovernanceOrStrategist();
        uint256 beforeVaultBalance = _getBalance();

        // Revert if you try to claim a protected token, this is to avoid rugging
        // NOTE: If we end up getting bribes in form or protected tokens, we'll have to change

        uint256 beforeBalance = IERC20Upgradeable(token).balanceOf(address(this));
        VOTIUM_BRIBE_CLAIMER.claim(token, index, account, amount, merkleProof);
        uint256 afterBalance = IERC20Upgradeable(token).balanceOf(address(this));

        _handleRewardTransfer(token, afterBalance.sub(beforeBalance));

        require(beforeVaultBalance == _getBalance(), "Balance can't change");
    }
    /// @dev given the votium data (available at: https://github.com/oo-00/Votium/tree/main/merkle)
    /// @dev allows claiming of multiple rewards rewards, badger is sent to tree
    function claimBribesFromVotium(
        address account, 
        address[] calldata tokens, 
        uint256[] calldata indexes,
        uint256[] calldata amounts, 
        bytes32[][] calldata merkleProofs
    ) external {
        _onlyGovernanceOrStrategist();
        uint256 beforeVaultBalance = _getBalance();

        // Revert if you try to claim a protected token, this is to avoid rugging
        require(tokens.length == indexes.length && tokens.length == amounts.length && tokens.length == merkleProofs.length, "Length Mismatch");
        // tokens.length = length, can't declare var as stack too deep
        uint256[] memory beforeBalance = new uint256[](tokens.length);
        for(uint i = 0; i < tokens.length; i++){
            beforeBalance[i] = IERC20Upgradeable(tokens[i]).balanceOf(address(this));
        }
        // NOTE: If we end up getting bribes in form or protected tokens, we'll have to change

        IVotiumBribes.claimParam[] memory request = new IVotiumBribes.claimParam[](tokens.length);
        for(uint x = 0; x < tokens.length; x++){
            request[x] = IVotiumBribes.claimParam({
                token: tokens[x],
                index: indexes[x],
                amount: amounts[x],
                merkleProof: merkleProofs[x]
            });
        }

        VOTIUM_BRIBE_CLAIMER.claimMulti(account, request);

        for(uint i = 0; i < tokens.length; i++){
            _handleRewardTransfer(tokens[i], IERC20Upgradeable(tokens[i]).balanceOf(address(this)).sub(beforeBalance[i]));
        }

        require(beforeVaultBalance == _getBalance(), "Balance can't change");
    }
    
    /// @dev Function to move rewards that are not protected
    /// @notice Only not protected, moves the whole amount using _handleRewardTransfer
    /// @notice because token paths are harcoded, this function is safe to be called by anyone
    function sweepRewardToken(address token) public {
        _onlyGovernanceOrStrategist();
        _onlyNotProtectedTokens(token);

        uint256 toSend = IERC20Upgradeable(token).balanceOf(address(this));
        _handleRewardTransfer(token, toSend);
    }

    /// @dev Bulk function for sweepRewardToken
    function sweepRewards(address[] calldata tokens) external {
        uint256 length = tokens.length;
        for(uint i = 0; i < length; i++){
            sweepRewardToken(tokens[i]);
        }
    }

    /// *** Handling of rewards ***
    function _handleRewardTransfer(address token, uint256 amount) internal {
        // NOTE: BADGER is emitted through the tree
        if (token == BADGER){
            _sendBadgerToTree(amount);
        } else {
        // NOTE: All other tokens are sent to multisig
            _sentTokenToBribesReceiver(token, amount);
        }
    }

    /// @dev Send funds to the bribes receiver
    function _sentTokenToBribesReceiver(address token, uint256 amount) internal {
        IERC20Upgradeable(token).safeTransfer(BRIBES_RECEIVER, amount);
        emit RewardsCollected(token, amount);
    }

    /// @dev Send the BADGER token to the badgerTree
    function _sendBadgerToTree(uint256 amount) internal {
        IERC20Upgradeable(BADGER).safeTransfer(BADGER_TREE, amount);
        emit TreeDistribution(BADGER, amount, block.number, block.timestamp);
    }

    /// @dev Get the current Vault.balance
    /// @notice this is reflexive, a change in the strat will change the balance in the vault
    function _getBalance() internal returns (uint256) {
        ISettV4 vault = ISettV4(IController(controller).vaults(want));
        return vault.balance();
    }

    /// ===== View Functions =====

    function getBoostPayment() public view returns(uint256){
        uint256 maximumBoostPayment = LOCKER.maximumBoostPayment();
        require(maximumBoostPayment <= 1500, "over max payment"); //max 15%
        return maximumBoostPayment;
    }

    /// @dev Specify the name of the strategy
    function getName() external pure override returns (string memory) {
        return "veCVX Voting Strategy";
    }

    /// @dev Specify the version of the Strategy, for upgrades
    function version() external pure returns (string memory) {
        return "1.5";
    }

    /// @dev Balance of want currently held in strategy positions
    function balanceOfPool() public view override returns (uint256) {
        // Return the balance in locker
        return LOCKER.lockedBalanceOf(address(this));
    }

    /// @dev Returns true if this strategy requires tending
    function isTendable() public view override returns (bool) {
        return false;
    }

    // @dev These are the tokens that cannot be moved except by the vault
    function getProtectedTokens()
        public
        view
        override
        returns (address[] memory)
    {
        address[] memory protectedTokens = new address[](3);
        protectedTokens[0] = want;
        protectedTokens[1] = lpComponent;
        protectedTokens[2] = reward;
        return protectedTokens;
    }

    /// ===== Internal Core Implementations =====
    /// @dev security check to avoid moving tokens that would cause a rugpull, edit based on strat
    function _onlyNotProtectedTokens(address _asset) internal override {
        address[] memory protectedTokens = getProtectedTokens();

        for (uint256 x = 0; x < protectedTokens.length; x++) {
            require(
                address(protectedTokens[x]) != _asset,
                "Asset is protected"
            );
        }
    }

    /// @dev invest the amount of want
    /// @notice When this function is called, the controller has already sent want to this
    /// @notice Just get the current balance and then invest accordingly
    function _deposit(uint256 _amount) internal override {
        // Lock tokens for 16 weeks, send credit to strat, always use max boost cause why not?
        LOCKER.lock(address(this), _amount, getBoostPayment());
    }

    /// @dev utility function to withdraw all CVX that we can from the lock
    function prepareWithdrawAll() external {
        manualProcessExpiredLocks();
    }

    /// @dev utility function to withdraw everything for migration
    /// @dev NOTE: You cannot call this unless you have rebalanced to have only CVX left in the vault
    function _withdrawAll() internal override {
        //NOTE: This probably will always fail unless we have all tokens expired
        require(
            LOCKER.lockedBalanceOf(address(this)) == 0 &&
                LOCKER.balanceOf(address(this)) == 0,
            "You have to wait for unlock or have to manually rebalance out of it"
        );

        // Make sure to call prepareWithdrawAll before _withdrawAll
    }

    /// @dev withdraw the specified amount of want, liquidate from lpComponent to want, paying off any necessary debt for the conversion
    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        uint256 max = balanceOfWant();

        if(_amount > max){
            // Try to unlock, as much as possible
            // @notice Reverts if no locks expired
            LOCKER.processExpiredLocks(false);
            max = balanceOfWant();
        }


        if (withdrawalSafetyCheck) {
            require(
                max >= _amount.mul(9_980).div(MAX_BPS),
                "Withdrawal Safety Check"
            ); // 20 BP of slippage
        }

        if (_amount > max) {
            return max;
        }

        return _amount;
    }

    /// @dev Harvest from strategy mechanics, realizing increase in underlying position
    function harvest() public whenNotPaused returns (uint256) {
        _onlyAuthorizedActors();

        uint256 _beforeReward = IERC20Upgradeable(reward).balanceOf(address(this));

        // Get cvxCRV
        LOCKER.getReward(address(this), false);

        // Rewards Math
        uint256 earnedReward =
            IERC20Upgradeable(reward).balanceOf(address(this)).sub(_beforeReward);

        uint256 cvxCrvToGovernance = earnedReward.mul(performanceFeeGovernance).div(MAX_FEE);
        if(cvxCrvToGovernance > 0){
            CVXCRV_VAULT.depositFor(IController(controller).rewards(), cvxCrvToGovernance);
            emit PerformanceFeeGovernance(IController(controller).rewards(), address(CVXCRV_VAULT), cvxCrvToGovernance, block.number, block.timestamp);
        }
        uint256 cvxCrvToStrategist = earnedReward.mul(performanceFeeStrategist).div(MAX_FEE);
        if(cvxCrvToStrategist > 0){
            CVXCRV_VAULT.depositFor(strategist, cvxCrvToStrategist);
            emit PerformanceFeeStrategist(strategist, address(CVXCRV_VAULT), cvxCrvToStrategist, block.number, block.timestamp);   
        }

        // Send rest of earned to tree //We send all rest to avoid dust and avoid protecting the token
        uint256 cvxCrvToTree = IERC20Upgradeable(reward).balanceOf(address(this));
        CVXCRV_VAULT.depositFor(BADGER_TREE, cvxCrvToTree);
        emit TreeDistribution(address(CVXCRV_VAULT), cvxCrvToTree, block.number, block.timestamp);


        /// @dev Harvest event that every strategy MUST have, see BaseStrategy
        emit Harvest(earnedReward, block.number);

        /// @dev Harvest must return the amount of want increased
        return earnedReward;
    }

    /// @dev Rebalance, Compound or Pay off debt here
    function tend() external whenNotPaused {
        revert("no op"); // NOTE: For now tend is replaced by manualRebalance
    }

    /// MANUAL FUNCTIONS ///

    /// @dev manual function to reinvest all CVX that was locked
    function reinvest() external whenNotPaused returns (uint256) {
        _onlyGovernance();

        if (processLocksOnReinvest) {
            // Withdraw all we can
            LOCKER.processExpiredLocks(false);
        }

        // Redeposit all into veCVX
        uint256 toDeposit = IERC20Upgradeable(want).balanceOf(address(this));

        // Redeposit into veCVX
        _deposit(toDeposit);

        return toDeposit;
    }

    /// @dev process all locks, to redeem
    /// @notice No Access Control Checks, anyone can unlock an expired lock
    function manualProcessExpiredLocks() public whenNotPaused {
        // Unlock veCVX that is expired and redeem CVX back to this strat
        LOCKER.processExpiredLocks(false);
    }

    function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData) {
        // We need to unlock funds if the lockedBalance (locked + unlocked) is greater than the balance (actively locked for this epoch)
        upkeepNeeded = LOCKER.lockedBalanceOf(address(this)) > LOCKER.balanceOf(address(this));
    }

    /// @dev Function for ChainLink Keepers to automatically process expired locks
    function performUpkeep(bytes calldata performData) external {
        // Works like this because it reverts if lock is not expired
        LOCKER.processExpiredLocks(false);
    }

    /// @dev Send all available CVX to the Vault
    /// @notice you can do this so you can earn again (re-lock), or just to add to the redemption pool
    function manualSendCVXToVault() external whenNotPaused {
        _onlyGovernance();
        uint256 cvxAmount = IERC20Upgradeable(want).balanceOf(address(this));
        _transferToVault(cvxAmount);
    }

    /// @dev use the currently available CVX to lock
    /// @notice toLock = 0, lock nothing, deposit in CVX as much as you can
    /// @notice toLock = 10_000, lock everything (CVX) you have
    function manualRebalance(uint256 toLock) external whenNotPaused {
        _onlyGovernance();
        require(toLock <= MAX_BPS, "Max is 100%");

        if (processLocksOnRebalance) {
            // manualRebalance will revert if you have no expired locks
            LOCKER.processExpiredLocks(false);
        }

        if (harvestOnRebalance) {
            harvest();
        }

        // Token that is highly liquid
        uint256 balanceOfWant =
            IERC20Upgradeable(want).balanceOf(address(this));
        // Locked CVX in the locker
        uint256 balanceInLock = LOCKER.balanceOf(address(this));
        uint256 totalCVXBalance =
            balanceOfWant.add(balanceInLock);

        // Amount we want to have in lock
        uint256 newLockAmount = totalCVXBalance.mul(toLock).div(MAX_BPS);

        // We can't unlock enough, no-op
        if (newLockAmount <= balanceInLock) {
            return;
        }

        // If we're continuing, then we are going to lock something
        uint256 cvxToLock = newLockAmount.sub(balanceInLock);

        // We only lock up to the available CVX
        uint256 maxCVX = IERC20Upgradeable(want).balanceOf(address(this));
        if (cvxToLock > maxCVX) {
            // Just lock what we can
            LOCKER.lock(address(this), maxCVX, getBoostPayment());
        } else {
            // Lock proper
            LOCKER.lock(address(this), cvxToLock, getBoostPayment());
        }

        // If anything left, send to vault
        uint256 cvxLeft = IERC20Upgradeable(want).balanceOf(address(this));
        if(cvxLeft > 0){
            _transferToVault(cvxLeft);
        }
    }
}
