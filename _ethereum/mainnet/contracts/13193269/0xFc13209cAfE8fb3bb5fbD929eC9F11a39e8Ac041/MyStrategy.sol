// SPDX-License-Identifier: MIT

pragma solidity ^0.6.11;
pragma experimental ABIEncoderV2;

import "./IERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./IUniswapRouterV2.sol";
import "./ISettV3.sol";
import "./ISettV4.sol";
import "./IController.sol";
import "./ICvxLocker.sol";
import "./IDelegateRegistry.sol";
import "./ICurvePool.sol";

import "./BaseStrategy.sol";

contract MyStrategy is BaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    uint256 MAX_BPS = 10_000;

    // address public want // Inherited from BaseStrategy, the token the strategy wants, swaps into and tries to grow
    address public lpComponent; // Token we provide liquidity with
    address public reward; // Token we farm and swap to want / lpComponent
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    address public constant BADGER_TREE = 0x660802Fc641b154aBA66a62137e71f331B6d787A;

    address public constant SUSHI_ROUTER =
        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    IDelegateRegistry public constant SNAPSHOT =
        IDelegateRegistry(0x469788fE6E9E9681C6ebF3bF78e7Fd26Fc015446);

    // The initial DELEGATE for the strategy // NOTE we can change it by using manualSetDelegate below
    address public constant DELEGATE =
        0x14F83fF95D4Ec5E8812DDf42DA1232b0ba1015e6;

    bytes32 public constant DELEGATED_SPACE =
        0x6376782e65746800000000000000000000000000000000000000000000000000;

    ISettV3 public constant CVX_VAULT =
        ISettV3(0x53C8E199eb2Cb7c01543C137078a038937a68E40);
    
    ISettV4 public constant CVXCRV_VAULT =
        ISettV4(0x2B5455aac8d64C14786c3a29858E43b5945819C0);

    // NOTE: At time of publishing, this contract is under audit
    ICvxLocker public constant LOCKER = ICvxLocker(0xD18140b4B819b895A3dba5442F959fA44994AF50);

    // Curve Pool to swap between cvxCRV and CRV
    ICurvePool public constant CURVE_POOL = ICurvePool(0x9D0464996170c6B9e75eED71c68B99dDEDf279e8);

    bool public withdrawalSafetyCheck = true;
    bool public harvestOnRebalance = true;
    // If nothing is unlocked, processExpiredLocks will revert
    bool public processLocksOnReinvest = true;
    bool public processLocksOnRebalance = true;

    event Debug(string name, uint256 value);

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
        // Sushi to swap CRV -> CVX // TODO: REMOVE
        IERC20Upgradeable(CRV).safeApprove(SUSHI_ROUTER, type(uint256).max);
        // Curve to swap cvxCRV -> CRV // TODO: REMOVE
        IERC20Upgradeable(reward).safeApprove(address(CURVE_POOL), type(uint256).max);
        // Permissions for Locker
        IERC20Upgradeable(CVX).safeApprove(address(LOCKER), type(uint256).max);
        IERC20Upgradeable(CVX).safeApprove(
            address(CVX_VAULT),
            type(uint256).max
        );



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

    /// ===== View Functions =====

    function getBoostPayment() public view returns(uint256){
        uint256 maximumBoostPayment = LOCKER.maximumBoostPayment();
        require(maximumBoostPayment < 1500, "over max payment"); //max 15%
        return maximumBoostPayment;
    }

    /// @dev Specify the name of the strategy
    function getName() external pure override returns (string memory) {
        return "veCVX Voting Strategy";
    }

    /// @dev Specify the version of the Strategy, for upgrades
    function version() external pure returns (string memory) {
        return "1.0";
    }

    /// @dev From CVX Token to Helper Vault Token
    function CVXToWant(uint256 cvx) public view returns (uint256) {
        uint256 bCVXToCVX = CVX_VAULT.getPricePerFullShare();
        return cvx.mul(10**18).div(bCVXToCVX);
    }

    /// @dev From Helper Vault Token to CVX Token
    function wantToCVX(uint256 want) public view returns (uint256) {
        uint256 bCVXToCVX = CVX_VAULT.getPricePerFullShare();
        return want.mul(bCVXToCVX).div(10**18);
    }

    /// @dev Balance of want currently held in strategy positions
    function balanceOfPool() public view override returns (uint256) {
        if (withdrawalSafetyCheck) {
            uint256 bCVXToCVX = CVX_VAULT.getPricePerFullShare(); // 18 decimals
            require(bCVXToCVX > 10**18, "Loss Of Peg"); // Avoid trying to redeem for less / loss of peg
        }

        // Return the balance in locker + unlocked but not withdrawn, better estimate to allow some withdrawals
        // then multiply it by the price per share as we need to convert CVX to bCVX
        uint256 valueInLocker =
            CVXToWant(LOCKER.lockedBalanceOf(address(this))).add(
                CVXToWant(IERC20Upgradeable(CVX).balanceOf(address(this)))
            );

        return (valueInLocker);
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
        address[] memory protectedTokens = new address[](4);
        protectedTokens[0] = want;
        protectedTokens[1] = lpComponent;
        protectedTokens[2] = reward;
        protectedTokens[3] = CVX;
        return protectedTokens;
    }

    /// ===== Permissioned Actions: Governance =====
    /// @notice Delete if you don't need!
    function setKeepReward(uint256 _setKeepReward) external {
        _onlyGovernance();
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
        // We receive bCVX -> Convert to CVX
        CVX_VAULT.withdraw(_amount);

        uint256 toDeposit = IERC20Upgradeable(CVX).balanceOf(address(this));

        // Lock tokens for 16 weeks, send credit to strat, always use max boost cause why not?
        LOCKER.lock(address(this), toDeposit, getBoostPayment());
    }

    /// @dev utility function to convert all we can to bCVX
    /// @notice You may want to harvest before calling this to maximize the amount of bCVX you'll have
    function prepareWithdrawAll() external {
        _onlyGovernance();

        LOCKER.processExpiredLocks(false);

        uint256 toDeposit = IERC20Upgradeable(CVX).balanceOf(address(this));
        if (toDeposit > 0) {
            CVX_VAULT.deposit(toDeposit);
        }
    }

    /// @dev utility function to withdraw everything for migration
    /// @dev NOTE: You cannot call this unless you have rebalanced to have only bCVX left in the vault
    function _withdrawAll() internal override {
        //NOTE: This probably will always fail unless we have all tokens expired
        require(
            LOCKER.lockedBalanceOf(address(this)) == 0 &&
                LOCKER.balanceOf(address(this)) == 0,
            "You have to wait for unlock and have to manually rebalance out of it"
        );

        // NO-OP because you can't deposit AND transfer with bCVX
        // See prepareWithdrawAll above
    }

    /// @dev withdraw the specified amount of want, liquidate from lpComponent to want, paying off any necessary debt for the conversion
    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        uint256 max = IERC20Upgradeable(want).balanceOf(address(this));

        if (withdrawalSafetyCheck) {
            uint256 bCVXToCVX = CVX_VAULT.getPricePerFullShare(); // 18 decimals
            require(bCVXToCVX > 10**18, "Loss Of Peg"); // Avoid trying to redeem for less / loss of peg
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
        uint256 toDeposit = IERC20Upgradeable(CVX).balanceOf(address(this));

        // Redeposit into veCVX
        LOCKER.lock(address(this), toDeposit, getBoostPayment());

        return toDeposit;
    }

    /// @dev process all locks, to redeem
    function manualProcessExpiredLocks() external whenNotPaused {
        _onlyGovernance();
        LOCKER.processExpiredLocks(false);
        // Unlock veCVX that is expired and redeem CVX back to this strat
        // Processed in the next harvest or during prepareMigrateAll
    }

    /// @dev Take all CVX and deposits in the CVX_VAULT
    function manualDepositCVXIntoVault() external whenNotPaused {
        _onlyGovernance();

        uint256 toDeposit = IERC20Upgradeable(CVX).balanceOf(address(this));
        if (toDeposit > 0) {
            CVX_VAULT.deposit(toDeposit);
        }
    }

    /// @dev Send all available bCVX to the Vault
    /// @notice you can do this so you can earn again (re-lock), or just to add to the redemption pool
    function manualSendbCVXToVault() external whenNotPaused {
        _onlyGovernance();
        uint256 bCvxAmount = IERC20Upgradeable(want).balanceOf(address(this));
        _transferToVault(bCvxAmount);
    }

    /// @dev use the currently available CVX to either lock or add to bCVX
    /// @notice toLock = 0, lock nothing, deposit in bCVX as much as you can
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
        // CVX uninvested we got from harvest and unlocks
        uint256 balanceOfCVX = IERC20Upgradeable(CVX).balanceOf(address(this));
        // Locked CVX in the locker
        uint256 balanceInLock = LOCKER.balanceOf(address(this));
        uint256 totalCVXBalance =
            balanceOfCVX.add(balanceInLock).add(wantToCVX(balanceOfWant));

        // Amount we want to have in lock
        uint256 newLockAmount = totalCVXBalance.mul(toLock).div(MAX_BPS);

        // We can't unlock enough, just deposit rest into bCVX
        if (newLockAmount <= balanceInLock) {
            // Deposit into vault
            uint256 toDeposit = IERC20Upgradeable(CVX).balanceOf(address(this));
            if (toDeposit > 0) {
                CVX_VAULT.deposit(toDeposit);
            }

            return;
        }

        // If we're continuing, then we are going to lock something (unless it's zero)
        uint256 cvxToLock = newLockAmount.sub(balanceInLock);

        // NOTE: We only lock the CVX we have and not the bCVX
        // bCVX should be sent back to vault and then go through earn
        // We do this because bCVX has "blockLock" and we can't both deposit and withdraw on the same block
        uint256 maxCVX = IERC20Upgradeable(CVX).balanceOf(address(this));
        if (cvxToLock > maxCVX) {
            // Just lock what we can
            LOCKER.lock(address(this), maxCVX, getBoostPayment());
        } else {
            // Lock proper
            LOCKER.lock(address(this), cvxToLock, getBoostPayment());
        }

        // If anything else is left, deposit into vault
        uint256 cvxLeft = IERC20Upgradeable(CVX).balanceOf(address(this));
        if (cvxLeft > 0) {
            CVX_VAULT.deposit(cvxLeft);
        }
        // At the end of the rebalance, there won't be any balanceOfCVX as that token is not considered by our strat
    }
}
