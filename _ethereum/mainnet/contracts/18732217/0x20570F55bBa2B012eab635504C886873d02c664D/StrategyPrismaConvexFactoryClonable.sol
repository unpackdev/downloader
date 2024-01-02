// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./Math.sol";
import "./BaseStrategy.sol";
import "./PrismaInterfaces.sol";

contract StrategyPrismaConvexFactoryClonable is BaseStrategy {
    using SafeERC20 for IERC20;

    // Fees are in basis points
    uint256 internal constant FEE_DENOMINATOR = 10_000;

    /// @notice Yearn's Prisma locker contract.
    address internal constant YEARN_LOCKER =
        0x90be6DFEa8C80c184C442a36e17cB2439AAE25a7;
    
    /// @notice The address of the yPrisma token. This is minted to us as an alternative to creating a lock.
    IERC20 public constant yPrisma = IERC20(0xe3668873D944E4A949DA05fc8bDE419eFF543882);

    /* ========== STATE VARIABLES ========== */

    /// @notice The percentage of CRV from each harvest that we send to our voter (out of 10,000).
    uint256 public localKeepCRV;

    /// @notice The percentage of CVX from each harvest that we send to our voter (out of 10,000).
    uint256 public localKeepCVX;

    /// @notice The percentage of yPRISMA from each harvest that we send to our voter (out of 10,000).
    uint256 public localKeepYPrisma;

    /// @notice The address of our Curve voter. This is where we send any keepCRV.
    address public curveVoter;

    /// @notice The address of our Convex voter. This is where we send any keepCVX.
    address public convexVoter;

    /// @notice The address of our yPRISMA POL contract. This is where we send any keepYPrisma.
    address public yprismaVoter;

    /// @notice Where we claim emissions as yPRISMA
    IPrismaVault public prismaVault;

    /// @notice The contract we deposit our LPs to that is approved for PRISMA emissions.
    IPrismaReceiver public prismaReceiver;

    /// @notice The address of our base token (CRV for Curve, BAL for Balancer, etc.).
    IERC20 public constant crv = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);

    /// @notice The address of our Convex token (CVX for Curve, AURA for Balancer, etc.).
    IERC20 public constant convexToken = IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);

    /// @notice Minimum profit size in USDC that we want to harvest.
    /// @dev Only used in harvestTrigger.
    uint256 public harvestProfitMinInUsdc;

    /// @notice Maximum profit size in USDC that we want to harvest (ignore gas price once we get here).
    /// @dev Only used in harvestTrigger.
    uint256 public harvestProfitMaxInUsdc;

    // ySwaps stuff
    /// @notice The address of our ySwaps trade factory.
    address public tradeFactory;

    /// @notice We use this flag to signal a desire to claim even if Yearns locker cant provide max boost.
    bool public forceClaimOnce;

    /// @notice Will only be true on the original deployed contract and not on clones; we dont want to clone a clone.
    bool public isOriginal = true;

    /// @notice Used to track the deployed version of this contract.
    string public constant strategyVersion = "3.0.1";

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _vault,
        address _tradeFactory,
        uint256 _harvestProfitMinInUsdc,
        uint256 _harvestProfitMaxInUsdc,
        address _prismaVault,
        address _prismaReceiver
    ) BaseStrategy(_vault) {
        _initializeStrat(
            _tradeFactory,
            _harvestProfitMinInUsdc,
            _harvestProfitMaxInUsdc,
            _prismaVault,
            _prismaReceiver
        );
    }

    /* ========== CLONING ========== */

    event Cloned(address indexed clone);

    /// @notice Use this to clone an exact copy of this strategy on another vault.
    /// @dev In practice, this will only be called by the factory on the template contract.
    /// @param _vault Vault address we are targeting with this strategy.
    /// @param _strategist Address to grant the strategist role.
    /// @param _rewards If we have any strategist rewards, send them here.
    /// @param _keeper Address to grant the keeper role.
    /// @param _tradeFactory Our trade factory address.
    /// @param _harvestProfitMinInUsdc Minimum acceptable profit for a harvest.
    /// @param _harvestProfitMaxInUsdc Maximum acceptable profit for a harvest.
    /// @param _prismaVault Address of the Prisma vault.
    /// @param _prismaReceiver Address of the Prisma receiver to farm.
    function cloneStrategyPrismaConvex(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        address _tradeFactory,
        uint256 _harvestProfitMinInUsdc,
        uint256 _harvestProfitMaxInUsdc,
        address _prismaVault,
        address _prismaReceiver
    ) external returns (address newStrategy) {
        // dont clone a clone
        if (!isOriginal) {
            revert("Cant clone a clone");
        }

        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));
        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(
                clone_code,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(
                add(clone_code, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            newStrategy := create(0, clone_code, 0x37)
        }

        StrategyPrismaConvexFactoryClonable(newStrategy).initialize(
            _vault,
            _strategist,
            _rewards,
            _keeper,
            _tradeFactory,
            _harvestProfitMinInUsdc,
            _harvestProfitMaxInUsdc,
            _prismaVault,
            _prismaReceiver
        );

        emit Cloned(newStrategy);
    }

    /// @notice Initialize the strategy.
    /// @dev This should only be called by the clone function above.
    /// @param _vault Vault address we are targeting with this strategy.
    /// @param _strategist Address to grant the strategist role.
    /// @param _rewards If we have any strategist rewards, send them here.
    /// @param _keeper Address to grant the keeper role.
    /// @param _tradeFactory Our trade factory address.
    /// @param _harvestProfitMinInUsdc Minimum acceptable profit for a harvest.
    /// @param _harvestProfitMaxInUsdc Maximum acceptable profit for a harvest.
    /// @param _prismaVault Address of the Prisma vault to claim from.
    /// @param _prismaReceiver Address of the Prisma receiver to farm.
    function initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        address _tradeFactory,
        uint256 _harvestProfitMinInUsdc,
        uint256 _harvestProfitMaxInUsdc,
        address _prismaVault,
        address _prismaReceiver
    ) public {
        _initialize(_vault, _strategist, _rewards, _keeper);
        _initializeStrat(
            _tradeFactory,
            _harvestProfitMinInUsdc,
            _harvestProfitMaxInUsdc,
            _prismaVault,
            _prismaReceiver
        );
    }

    // this is called by our original strategy, as well as any clones via the above function
    function _initializeStrat(
        address _tradeFactory,
        uint256 _harvestProfitMinInUsdc,
        uint256 _harvestProfitMaxInUsdc,
        address _prismaVault,
        address _prismaReceiver
    ) internal {
        // make sure that we havent initialized this before
        require(_prismaVault != address(0), "Non-zero required");
        require(address(prismaVault) == address(0), "Already initialized");

        prismaReceiver = IPrismaReceiver(_prismaReceiver);
        prismaVault = IPrismaVault(_prismaVault);
        tradeFactory = _tradeFactory;
        harvestProfitMinInUsdc = _harvestProfitMinInUsdc;
        harvestProfitMaxInUsdc = _harvestProfitMaxInUsdc;

        // want = Curve LP
        want.approve(address(_prismaReceiver), type(uint256).max);

        // set up our baseStrategy vars
        maxReportDelay = 365 days;
        creditThreshold = 50_000e18;

        require(address(want) == prismaReceiver.lpToken(), "Wrong LP.");

        _setUpTradeFactory();
    }

    /* ========== VIEWS ========== */

    /// @notice Strategy name.
    function name() external view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "StrategyPrismaConvexFactory-",
                    IDetails(address(want)).symbol()
                )
            );
    }

    /// @notice Balance of want staked in Prisma.
    function stakedBalance() public view returns (uint256) {
        return prismaReceiver.balanceOf(address(this));
    }

    /// @notice Balance of want sitting in our strategy.
    function balanceOfWant() public view returns (uint256) {
        // balance of want sitting in our strategy
        return want.balanceOf(address(this));
    }

    /// @notice Total assets the strategy holds, sum of loose and staked want.
    function estimatedTotalAssets() public view override returns (uint256) {
        return balanceOfWant() + stakedBalance();
    }

    /* ========== CORE STRATEGY FUNCTIONS ========== */

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        // rewards will be converted later with mev protection by yswaps (tradeFactory)
        _claimRewards();

        // by default this is zero, but if we want any for our voter this will be used
        uint256 _localKeepCRV = localKeepCRV;
        address _curveVoter = curveVoter;
        uint256 _sendToVoter;
        if (_localKeepCRV > 0 && _curveVoter != address(0)) {
            uint256 crvBalance = crv.balanceOf(address(this));
            unchecked {
                _sendToVoter = (crvBalance * _localKeepCRV) / FEE_DENOMINATOR;
            }
            if (_sendToVoter > 0) {
                crv.safeTransfer(_curveVoter, _sendToVoter);
            }
        }

        // by default this is zero, but if we want any for our voter this will be used
        uint256 _localKeepCVX = localKeepCVX;
        address _convexVoter = convexVoter;
        if (_localKeepCVX > 0 && _convexVoter != address(0)) {
            uint256 cvxBalance = convexToken.balanceOf(address(this));
            unchecked {
                _sendToVoter = (cvxBalance * _localKeepCVX) / FEE_DENOMINATOR;
            }
            if (_sendToVoter > 0) {
                convexToken.safeTransfer(_convexVoter, _sendToVoter);
            }
        }

        // by default this is zero, but if we want any for our voter this will be used
        uint256 _localKeepYPrisma = localKeepYPrisma;
        address _yprismaVoter = yprismaVoter;
        if (_localKeepYPrisma > 0 && _yprismaVoter != address(0)) {
            uint256 yprismaBalance = yPrisma.balanceOf(address(this));
            unchecked {
                _sendToVoter =
                    (yprismaBalance * _localKeepYPrisma) /
                    FEE_DENOMINATOR;
            }
            if (_sendToVoter > 0) {
                yPrisma.safeTransfer(_yprismaVoter, _sendToVoter);
            }
        }

        // serious loss should never happen, but if it does (for instance, if Curve is hacked), lets record it accurately
        uint256 assets = estimatedTotalAssets();
        uint256 debt = vault.strategies(address(this)).totalDebt;

        // if assets are greater than debt, things are working great!
        if (assets >= debt) {
            unchecked {
                _profit = assets - debt;
            }
            _debtPayment = _debtOutstanding;

            uint256 toFree = _profit + _debtPayment;

            // freed is math.min(wantBalance, toFree)
            (uint256 freed, ) = liquidatePosition(toFree);

            if (toFree > freed) {
                if (_debtPayment > freed) {
                    _debtPayment = freed;
                    _profit = 0;
                } else {
                    unchecked {
                        _profit = freed - _debtPayment;
                    }
                }
            }
        }
        // if assets are less than debt, we are in trouble. dont worry about withdrawing here, just report losses
        else {
            unchecked {
                _loss = debt - assets;
            }
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        // if in emergency exit, we dont want to deploy any more funds
        if (emergencyExit) {
            return;
        }

        // Send all of our Curve pool tokens to be deposited
        uint256 _toInvest = balanceOfWant();

        // deposit into Prisma
        if (_toInvest > 0) {
            prismaReceiver.deposit(address(this), _toInvest);
        }
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        // check our loose want
        uint256 _wantBal = balanceOfWant();
        if (_amountNeeded > _wantBal) {
            uint256 _stakedBal = stakedBalance();
            if (_stakedBal > 0) {
                uint256 _neededFromStaked;
                unchecked {
                    _neededFromStaked = _amountNeeded - _wantBal;
                }
                // withdraw whatever extra funds we need
                uint256 toWithdraw = Math.min(_stakedBal, _neededFromStaked);
                if (toWithdraw > 0) {
                    prismaReceiver.withdraw(address(this), toWithdraw);
                }
            }
            uint256 _withdrawnBal = balanceOfWant();
            _liquidatedAmount = Math.min(_amountNeeded, _withdrawnBal);
            unchecked {
                _loss = _amountNeeded - _liquidatedAmount;
            }
        } else {
            // we have enough balance to cover the liquidation available
            return (_amountNeeded, 0);
        }
    }

    // fire sale, get rid of it all!
    function liquidateAllPositions() internal override returns (uint256) {
        uint256 _stakedBal = stakedBalance();
        if (_stakedBal > 0) {
            // dont bother withdrawing zero, save gas where we can
            prismaReceiver.withdraw(address(this), _stakedBal);
        }
        return balanceOfWant();
    }

    // migrate our want token to a new strategy if needed, claim rewards tokens as well unless its an emergency
    function prepareMigration(address _newStrategy) internal override {
        uint256 stakedBal = stakedBalance();

        if (stakedBal > 0) {
            prismaReceiver.withdraw(address(this), stakedBal);
        }

        uint256 crvBal = crv.balanceOf(address(this));
        uint256 cvxBal = convexToken.balanceOf(address(this));

        if (crvBal > 0) {
            crv.safeTransfer(_newStrategy, crvBal);
        }
        if (cvxBal > 0) {
            convexToken.safeTransfer(_newStrategy, cvxBal);
        }
    }

    // want is blocked by default, add any other tokens to protect from gov here.
    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {}

    function _claimRewards() internal {
        // By default, we only claim if max boosted. Force claim once if needed.
        bool _forceClaimOnce = forceClaimOnce;

        if (claimsAreMaxBoosted() || _forceClaimOnce) {
            address[] memory rewardContracts = new address[](1);
            rewardContracts[0] = address(prismaReceiver);
            prismaVault.batchClaimRewards(
                YEARN_LOCKER, // receiver
                YEARN_LOCKER, // delegate
                rewardContracts, // rewards contracts
                FEE_DENOMINATOR // maxFee
            );

            // reset if we forced this one
            if (_forceClaimOnce) {
                forceClaimOnce = false;
            }
        }
    }

    function claimsAreMaxBoosted() public view returns (bool) {
        (uint256 claimable, , ) = prismaReceiver.claimableReward(address(this));
        (uint256 maxBoostable, ) = prismaVault.getClaimableWithBoost(
            YEARN_LOCKER
        );
        return maxBoostable >= claimable;
    }

    /* ========== YSWAPS ========== */

    /// @notice Use to update our trade factory.
    /// @dev Can only be called by governance.
    /// @param _newTradeFactory Address of new trade factory.
    function updateTradeFactory(
        address _newTradeFactory
    ) external onlyGovernance {
        require(
            _newTradeFactory != address(0),
            "Cant remove with this function"
        );
        _removeTradeFactoryPermissions(true);
        tradeFactory = _newTradeFactory;
        _setUpTradeFactory();
    }

    function _setUpTradeFactory() internal {
        // approve and set up trade factory
        address _tradeFactory = tradeFactory;
        address _want = address(want);

        crv.approve(_tradeFactory, type(uint256).max);
        convexToken.approve(_tradeFactory, type(uint256).max);
        yPrisma.approve(_tradeFactory, type(uint256).max);

        ITradeFactory tf = ITradeFactory(_tradeFactory);
        tf.enable(address(convexToken), _want);
        tf.enable(address(crv), _want);
        tf.enable(address(yPrisma), _want);
    }

    /// @notice Use this to remove permissions from our current trade factory.
    /// @dev Once this is called, setUpTradeFactory must be called to get things working again.
    /// @param _disableTf Specify whether to disable the tradefactory when removing.
    ///  Option given in case we need to get around a reverting disable.
    function removeTradeFactoryPermissions(
        bool _disableTf
    ) external onlyVaultManagers {
        _removeTradeFactoryPermissions(_disableTf);
    }

    function _removeTradeFactoryPermissions(bool _disableTf) internal {
        address _tradeFactory = tradeFactory;
        if (_tradeFactory == address(0)) {
            return;
        }
        ITradeFactory tf = ITradeFactory(_tradeFactory);

        address _want = address(want);
        crv.approve(_tradeFactory, 0);
        if (_disableTf) {
            tf.disable(address(crv), _want);
        }

        convexToken.approve(_tradeFactory, 0);
        if (_disableTf) {
            tf.disable(address(convexToken), _want);
        }

        yPrisma.approve(_tradeFactory, 0);
        if (_disableTf) {
            tf.disable(address(yPrisma), _want);
        }

        tradeFactory = address(0);
    }

    function claimRewards() external onlyVaultManagers {
        _claimRewards();
    }

    /* ========== KEEP3RS ========== */

    /**
     * @notice
     *  Provide a signal to the keeper that harvest() should be called.
     *
     *  Dont harvest if a strategy is inactive.
     *  If our profit exceeds our upper limit, then harvest no matter what. For
     *  our lower profit limit, credit threshold, max delay, and manual force trigger,
     *  only harvest if our gas price is acceptable.
     *
     * @param callCostinEth The keepers estimated gas cost to call harvest() (in wei).
     * @return True if harvest() should be called, false otherwise.
     */
    function harvestTrigger(
        uint256 callCostinEth
    ) public view override returns (bool) {
        // Should not trigger if strategy is not active (no assets and no debtRatio). This means we dont need to adjust keeper job.
        if (!isActive()) {
            return false;
        }

        // harvest if we have a profit to claim at our upper limit without considering gas price
        uint256 claimableProfit = claimableProfitInUsdc();
        if (claimableProfit > harvestProfitMaxInUsdc) {
            return true;
        }

        // check if the base fee gas price is higher than we allow. if it is, block harvests.
        if (!isBaseFeeAcceptable()) {
            return false;
        }

        // trigger if we want to manually harvest, but only if our gas price is acceptable
        if (forceHarvestTriggerOnce) {
            return true;
        }

        // harvest if we have a sufficient profit to claim and are max boosted.
        if (
            claimableProfit > harvestProfitMinInUsdc &&
            (claimsAreMaxBoosted() || forceClaimOnce)
        ) {
            return true;
        }

        StrategyParams memory params = vault.strategies(address(this));
        // harvest regardless of profit once we reach our maxDelay and are max boosted.
        if (
            block.timestamp - params.lastReport > maxReportDelay &&
            (claimsAreMaxBoosted() || forceClaimOnce)
        ) {
            return true;
        }

        // harvest our credit if its above our threshold
        if (vault.creditAvailable() > creditThreshold) {
            return true;
        }

        // otherwise, we dont harvest
        return false;
    }

    /// @notice Calculates the profit if all claimable assets were sold for USDC (6 decimals).
    /// @dev Uses Chainlinks feed registry.
    /// @return Total return in USDC from selling claimable CRV and CVX.
    function claimableProfitInUsdc() public view returns (uint256) {
        (
            uint256 yPrismaAmount,
            uint256 crvAmount,
            uint256 cvxAmount
        ) = prismaReceiver.claimableReward(address(this)); // This assumes 2x boost for prisma amount

        (, uint256 crvPrice, , , ) = IOracle(
            0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf
        ).latestRoundData(
                address(crv),
                address(0x0000000000000000000000000000000000000348) // USD, returns 1e8
            );

        (, uint256 cvxPrice, , , ) = IOracle(
            0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf
        ).latestRoundData(
                address(convexToken),
                address(0x0000000000000000000000000000000000000348) // USD, returns 1e8
            );

        uint256 ethUsdPrice = ISimpleOracle(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        ).latestAnswer();
        uint256 prismaEthPrice = ICurveOracle(
            0x322135Dd9cBAE8Afa84727d9aE1434b5B3EBA44B
        ).price_oracle();
        uint256 yprismaPrismaPrice = ICurveOracle(
            0x69833361991ed76f9e8DBBcdf9ea1520fEbFb4a7
        ).price_oracle();
        uint256 yPrismaPrice = (((ethUsdPrice * prismaEthPrice) / 1e8) *
            yprismaPrismaPrice) / 1e18; // usd price in 1e18

        // CRV and CVX prices are 1e8, yPRISMA is 1e18. All amounts are 1e18. Want to return as 1e6.
        return ((crvPrice * crvAmount + cvxPrice * cvxAmount) /
            1e20 +
            ((yPrismaPrice * yPrismaAmount) / (1e30)));
    }

    /// @notice Convert our keepers eth cost into want
    /// @dev We dont use this since we dont factor call cost into our harvestTrigger.
    /// @param _ethAmount Amount of ether spent.
    /// @return Value of ether in want.
    function ethToWant(
        uint256 _ethAmount
    ) public view override returns (uint256) {}

    /* ========== SETTERS ========== */
    // These functions are useful for setting parameters of the strategy that may need to be adjusted.

    /// @notice Use this to set or update our keep amounts for this strategy.
    /// @dev Must be less than 10,000. Set in basis points. Only governance can set this.
    /// @param _keepCrv Percent of each CRV harvest to send to our voter.
    /// @param _keepCvx Percent of each CVX harvest to send to our voter.
    function setLocalKeepCrvs(
        uint256 _keepCrv,
        uint256 _keepCvx,
        uint256 _keepYPrisma
    ) external onlyGovernance {
        if (_keepCrv > 10_000 || _keepCvx > 10_000 || _keepYPrisma > 10_000) {
            revert();
        }

        if (_keepCrv > 0 && curveVoter == address(0)) {
            revert();
        }

        if (_keepCvx > 0 && convexVoter == address(0)) {
            revert();
        }

        if (_keepYPrisma > 0 && yprismaVoter == address(0)) {
            revert();
        }

        localKeepCRV = _keepCrv;
        localKeepCVX = _keepCvx;
        localKeepYPrisma = _keepYPrisma;
    }

    /// @notice Use this to set or update our voter contracts.
    /// @dev For Convex strategies, this is simply where we send our keepCRV and keepCVX.
    ///  Only governance can set this.
    /// @param _curveVoter Address of our curve voter.
    /// @param _convexVoter Address of our convex voter.
    /// @param _yprismaVoter Address of our yPRISMA voter.
    function setVoters(
        address _curveVoter,
        address _convexVoter,
        address _yprismaVoter
    ) external onlyGovernance {
        curveVoter = _curveVoter;
        convexVoter = _convexVoter;
        yprismaVoter = _yprismaVoter;
    }

    /**
     * @notice
     *  Here we set various parameters to optimize our harvestTrigger.
     * @param _harvestProfitMinInUsdc The amount of profit (in USDC, 6 decimals)
     *  that will trigger a harvest if gas price is acceptable.
     * @param _harvestProfitMaxInUsdc The amount of profit in USDC that
     *  will trigger a harvest regardless of gas price.
     */
    function setHarvestTriggerParams(
        uint256 _harvestProfitMinInUsdc,
        uint256 _harvestProfitMaxInUsdc
    ) external onlyVaultManagers {
        harvestProfitMinInUsdc = _harvestProfitMinInUsdc;
        harvestProfitMaxInUsdc = _harvestProfitMaxInUsdc;
    }

    /**
     * @notice
     *  Here we force a claim of yPRISMA on our next harvest, even if not fully boosted.
     @param _forceClaimOnce True if we want to allow claims that are not max boosted.
     */
    function setForceClaimOnce(
        bool _forceClaimOnce
    ) external onlyVaultManagers {
        forceClaimOnce = _forceClaimOnce;
    }
}
