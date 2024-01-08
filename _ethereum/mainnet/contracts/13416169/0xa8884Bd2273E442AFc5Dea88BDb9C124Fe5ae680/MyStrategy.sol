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
 * V1.1 Update to handle bribes which are sent to a multisig
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

    ICVXBribes public constant CVX_EXTRA_REWARDS = ICVXBribes(0x8Ed4bbf39E3080b35DA84a13A0D1A2FDcE1e0602);
    IVotiumBribes public constant VOTIUM_BRIBE_CLAIMER = IVotiumBribes(0x378Ba9B73309bE80BF4C2c027aAD799766a7ED5A);
    
    // We hardcode, an upgrade is required to change this as it's a meaningful change
    address public constant BRIBES_RECEIVER = 0x6F76C6A1059093E21D8B1C13C4e20D8335e2909F;
    

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
    /// @notice for security reasons, you can't claim a bribe for a protected token
    function claimBribeFromConvex (address token) external {
        _onlyGovernanceOrStrategist();

        // Revert if you try to claim a protected token, this is to avoid rugging
        _onlyNotProtectedTokens(token);
        // NOTE: If we end up getting bribes in form or protected tokens, we'll have to change

        // Claim reward for token
        CVX_EXTRA_REWARDS.getReward(address(this), token);

        // Send reward to Multisig
        uint256 toSend = IERC20Upgradeable(token).balanceOf(address(this));
        IERC20Upgradeable(token).safeTransfer(BRIBES_RECEIVER, toSend);
    }

    /// @dev given a list of token addresses, claim that as reward from CVX Extra Rewards
    /// @notice funds are transfered to the hardcoded address BRIBES_RECEIVER
    /// @notice for security reasons, you can't claim a bribe for a protected token
    function claimBribesFromConvex(address[] calldata tokens) external {
        _onlyGovernanceOrStrategist();

        // Revert if you try to claim a protected token, this is to avoid rugging
        uint256 length = tokens.length;
        for(uint i = 0; i < length; i++){
            _onlyNotProtectedTokens(tokens[i]);
        }
        // NOTE: If we end up getting bribes in form or protected tokens, we'll have to change

        // Claim reward for tokens
        CVX_EXTRA_REWARDS.getRewards(address(this), tokens);

        // Send reward to Multisig
        for(uint x = 0; x < length; x++){
            uint256 toSend = IERC20Upgradeable(tokens[x]).balanceOf(address(this));
            IERC20Upgradeable(tokens[x]).safeTransfer(BRIBES_RECEIVER, toSend);
        }
    }

    function claimBribeFromVotium(
        address token, 
        uint256 index, 
        address account, 
        uint256 amount, 
        bytes32[] calldata merkleProof
    ) external {
        _onlyGovernanceOrStrategist();

        // Revert if you try to claim a protected token, this is to avoid rugging
        _onlyNotProtectedTokens(token);
        // NOTE: If we end up getting bribes in form or protected tokens, we'll have to change

        VOTIUM_BRIBE_CLAIMER.claim(token, index, account, amount, merkleProof);

        uint256 toSend = IERC20Upgradeable(token).balanceOf(address(this));
        IERC20Upgradeable(token).safeTransfer(BRIBES_RECEIVER, toSend);
    }

    function claimBribesFromVotium(
        address account, 
        address[] calldata tokens, 
        uint256[] calldata indexes,
        uint256[] calldata amounts, 
        bytes32[][] calldata merkleProofs
    ) external {
        _onlyGovernanceOrStrategist();

        // Revert if you try to claim a protected token, this is to avoid rugging
        uint256 length = tokens.length;
        require(length == indexes.length && length == amounts.length && length == merkleProofs.length, "Length Mismatch");

        for(uint i = 0; i < length; i++){
            _onlyNotProtectedTokens(tokens[i]);
        }
        // NOTE: If we end up getting bribes in form or protected tokens, we'll have to change

        IVotiumBribes.claimParam[] memory request = new IVotiumBribes.claimParam[](length);
        for(uint x = 0; x < length; x++){
            request[x] = IVotiumBribes.claimParam({
                token: tokens[x],
                index: indexes[x],
                amount: amounts[x],
                merkleProof: merkleProofs[x]
            });
        }

        VOTIUM_BRIBE_CLAIMER.claimMulti(account, request);

        for(uint i = 0; i < length; i++){
            uint256 toSend = IERC20Upgradeable(tokens[i]).balanceOf(address(this));
            IERC20Upgradeable(tokens[i]).safeTransfer(BRIBES_RECEIVER, toSend);
        }
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
        return "1.1";
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
        uint256 max = IERC20Upgradeable(want).balanceOf(address(this));

        if (withdrawalSafetyCheck) {
            require(
                max >= _amount.mul(9_980).div(MAX_BPS),
                "Withdrawal Safety Check"
            ); // 20 BP of slippage
        }

        if (max < _amount) {
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
    function manualProcessExpiredLocks() public whenNotPaused {
        _onlyGovernance();
        LOCKER.processExpiredLocks(false);
        // Unlock veCVX that is expired and redeem CVX back to this strat
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
