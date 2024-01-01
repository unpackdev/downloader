// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./SafeERC20.sol";
import "./Ownable2Step.sol";

// import our needed interfaces
import "./IChainlink.sol";
import "./IConvex.sol";
import "./ICurve.sol";
import "./IIronBank.sol";

/**
 * @title Iron Bank Fixed Forex Borrower
 * @notice Contract for borrowing fixed forex tokens uncollateralized from Iron Bank and supplying them as liquidity to
 *  Curve/Convex.
 * @dev Only profit may be swept out by owner, and Iron Bank multisig can claw back all funds and repay borrows at any
 *  time. Contract framework can easily be forked to supply liquidity to any markets (Curve, Uniswap, etc.) as needed.
 */
contract IBFFBorrowerCurveLPv2 is Ownable2Step {
    using SafeERC20 for IERC20;

    struct Forex {
        string name;
        uint256 pid;
        address underlying;
        address synth;
        address cyToken;
        address curveLpToken;
        address curvePool;
        address rewardsContract;
        uint256 borrowLimit;
        uint256 borrowAmountStored;
        uint256 chainlinkUint;
        bytes32 currencyKey;
    }

    /* ========== STATE VARIABLES ========== */

    /// @notice Used to track the deployed version of this contract.
    string public constant apiVersion = "0.2.0";

    // use this to allow repaying v1 borrower debt to transfer debt over to this contract
    address public constant V1_BORROWER =
        0x9A97664f3aBA3d6De05099b513a854D838c99Db6;

    /// @notice Iron Bank multisig, can call specific permissioned functions
    address public constant ironBankMultisig =
        0x9d960dAe0639C95a0C822C9d7769d19d30A430Aa;

    // tokens
    IERC20 internal constant crv =
        IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20 internal constant cvx =
        IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);

    // other infra contracts
    address internal constant depositContract =
        0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    IChainlink internal constant feedRegistry =
        IChainlink(0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf);
    IIronBank internal constant unitroller =
        IIronBank(0xAB1c342C7bf5Ec5F02ADEA1c2270670bCa144CbB);
    IConvex internal constant zapContract =
        IConvex(0xDd49A93FDcae579AE50B4b9923325e9e335ec82B); // with this we can claim all rewards at once

    /**
     * @notice Boolean if we should always claim rewards when withdrawing.
     * @dev Generally this should be false as we only need to claim rewards on harvest().
     */
    bool public claimRewards;

    /// @notice Array of our rewards contracts, used to claim all rewards at once.
    address[] public rewardsContracts;

    /**
     * @notice Array of structs with all of the data on our markets.
     * @dev Keys: 0: ibEUR, 1: ibKRW, 2: ibCHF, 3: ibGBP, 4: ibEUR-USDC, 5: ibJPY, 6: ibAUD
     */
    mapping(uint256 => Forex) public forexInfo;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        string[] memory _names,
        uint256[] memory _pids,
        address[] memory _underlyingTokens,
        address[] memory _synths,
        address[] memory _cyTokens,
        address[] memory _curveLpTokens,
        address[] memory _curvePools,
        address[] memory _rewardsContracts,
        uint256[] memory _chainlinkUint,
        bytes32[] memory _currencyKeys
    ) {
        // setup almost everything in our struct
        for (uint256 i = 0; i < _pids.length; i++) {
            // set up our struct
            forexInfo[i] = Forex(
                _names[i],
                _pids[i],
                _underlyingTokens[i],
                _synths[i],
                _cyTokens[i],
                _curveLpTokens[i],
                _curvePools[i],
                _rewardsContracts[i],
                0,
                0,
                _chainlinkUint[i],
                _currencyKeys[i]
            );
        }

        // do approvals
        for (uint256 i = 0; i < _pids.length; i++) {
            uint256 _pid = _pids[i];
            (address _want, , , address _rewardsContract, , ) = IConvex(
                depositContract
            ).poolInfo(_pid);
            require(_want == _curveLpTokens[i], "Underlying array incorrect");
            require(
                _rewardsContract == _rewardsContracts[i],
                "Rewards array incorrect"
            );

            IERC20(_want).approve(depositContract, type(uint256).max);

            // approve depositing our token into the pool, for repaying our borrows, and for swaps
            IERC20(_underlyingTokens[i]).approve(
                _curvePools[i],
                type(uint256).max
            );

            // don't want to do these approvals again for ibEUR-USDC
            if (_pid != 86) {
                IERC20(_synths[i]).approve(_curvePools[i], type(uint256).max);
                IERC20(_underlyingTokens[i]).approve(
                    _cyTokens[i],
                    type(uint256).max
                );
            } else {
                // approve ibEUR-USDC LP on pool
                IERC20(_curveLpTokens[i]).approve(
                    _curvePools[i],
                    type(uint256).max
                );
            }
        }

        // setup our rewardsContracts array
        rewardsContracts = _rewardsContracts;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyIronBank() {
        _onlyIronBank();
        _;
    }

    function _onlyIronBank() internal view {
        require(msg.sender == ironBankMultisig, "Must be Iron Bank");
    }

    /* ========== VIEWS ========== */

    function name() external pure returns (string memory) {
        return "IronBankBorrowerV2";
    }

    /**
     * @notice How much of an LP we have staked in Convex.
     * @param _forexKey Key in our forexInfo struct to use.
     */
    function stakedBalance(uint256 _forexKey) public view returns (uint256) {
        IConvex rewardsContract = IConvex(forexInfo[_forexKey].rewardsContract);
        return rewardsContract.balanceOf(address(this));
    }

    /**
     * @notice How much we can borrow of an asset in USD.
     * @param _forexKey Key in our forexInfo struct to use.
     */
    function creditLimit(uint256 _forexKey) public view returns (uint256) {
        return
            unitroller.creditLimits(
                address(this),
                forexInfo[_forexKey].cyToken
            );
    }

    /**
     * @notice How much CRV we can claim from the staking contract for a given pool.
     * @param _forexKey Key in our forexInfo struct to use.
     */
    function claimableBalance(uint256 _forexKey) public view returns (uint256) {
        IConvex rewardsContract = IConvex(forexInfo[_forexKey].rewardsContract);
        return rewardsContract.earned(address(this));
    }

    /**
     * @notice Whether our we can safely unwind our borrow with rewards
     * @dev Note that this uses the stored value, for current values call cyToken.borrowBalanceCurrent(address(this)).
     * @param _forexKey Key in our forexInfo struct to use.
     */
    function canRepayBorrowStored(uint256 _forexKey)
        public
        view
        returns (bool)
    {
        return
            claimableProfitInUsdc(_forexKey) +
                forceWithdrawValueInUsdc(_forexKey) >
            borrowedValueInUsdc(_forexKey);
    }

    /**
     * @notice Value of our borrowed assets in USDC.
     * @param _forexKey Key in our forexInfo struct to use.
     */
    function borrowedValueInUsdc(uint256 _forexKey)
        public
        view
        returns (uint256 borrowedValue)
    {
        // check how much we have borrowed
        IIronBank cyToken = IIronBank(forexInfo[_forexKey].cyToken);
        borrowedValue =
            (cyToken.borrowBalanceStored(address(this)) *
                usdcPerForex(_forexKey)) /
            1e20; // 1e18 * 1e8 = 1e26
    }

    /**
     * @notice Value of our holdings if we unwind completely to our ibXYZ token.
     * @param _forexKey Key in our forexInfo struct to use.
     */
    function forceWithdrawValueInUsdc(uint256 _forexKey)
        public
        view
        returns (uint256 assetsValue)
    {
        // check for any starting balance of underlying
        IERC20 underlying = IERC20(forexInfo[_forexKey].underlying);
        uint256 looseAssets = underlying.balanceOf(address(this));
        uint256 totalAssets;
        uint256 poolAssets;
        uint256 stakedAssets;

        // check our forex per usdc
        uint256 _usdcPerForex = usdcPerForex(_forexKey);

        // we use ibEUR for two pools
        if (_forexKey == 0 || _forexKey == 4) {
            // simulate how much we would get out
            stakedAssets = stakedBalance(0);
            if (stakedAssets > 0) {
                ICurveFi curvePool = ICurveFi(forexInfo[0].curvePool);
                poolAssets = curvePool.calc_withdraw_one_coin(
                    stakedBalance(0),
                    0
                );
            }
            totalAssets = poolAssets + looseAssets;
            poolAssets = 0;

            stakedAssets = stakedBalance(4);
            if (stakedAssets > 0) {
                ICurveFiPool curvePool = ICurveFiPool(forexInfo[4].curvePool);
                poolAssets = curvePool.calc_withdraw_one_coin(
                    stakedBalance(4),
                    0
                );
            }
            totalAssets = totalAssets + poolAssets;
        } else {
            // simulate how much we would get out
            stakedAssets = stakedBalance(_forexKey);
            if (stakedAssets > 0) {
                ICurveFi curvePool = ICurveFi(forexInfo[_forexKey].curvePool);
                poolAssets = curvePool.calc_withdraw_one_coin(
                    stakedBalance(_forexKey),
                    0
                );
            }
            totalAssets = poolAssets + looseAssets;
        }

        assetsValue = (totalAssets * _usdcPerForex) / 1e20; // 1e18 * 1e8 = 1e26
    }

    /**
     * @notice Value of our holdings if we remove our LPs balanced from Curve, assuming 1 ibXYZ = 1 sXYZ = spot oracle price.
     * @param _forexKey Key in our forexInfo struct to use.
     */
    function holdingsValueInUsdc(uint256 _forexKey)
        public
        view
        returns (uint256 assetsValue)
    {
        // check for any starting balance of underlying, no reason for us to ever have loose synth balances
        IERC20 underlying = IERC20(forexInfo[_forexKey].underlying);
        uint256 looseAssets = underlying.balanceOf(address(this));
        uint256 totalAssets;
        uint256 poolAssets;
        uint256 stakedAssets;

        // check our forex per usdc
        uint256 _usdcPerForex = usdcPerForex(_forexKey);

        // we use ibEUR for two pools
        if (_forexKey == 0 || _forexKey == 4) {
            // simulate how much we would get out
            stakedAssets = stakedBalance(0);
            if (stakedAssets > 0) {
                ICurveFi curvePool = ICurveFi(forexInfo[0].curvePool);
                poolAssets =
                    (curvePool.balances(0) * stakedAssets) /
                    curvePool.totalSupply();
                poolAssets +=
                    (curvePool.balances(1) * stakedAssets) /
                    curvePool.totalSupply();
            }
            totalAssets = poolAssets + looseAssets;
            poolAssets = 0;

            stakedAssets = stakedBalance(4);
            if (stakedAssets > 0) {
                ICurveFiPool curvePool = ICurveFiPool(forexInfo[4].curvePool);
                IERC20 curveLp = ICurveFiPool(forexInfo[4].curveLpToken);
                poolAssets =
                    (curvePool.balances(0) * stakedAssets) /
                    curveLp.totalSupply();
                assetsValue =
                    (curvePool.balances(1) * stakedAssets) /
                    curveLp.totalSupply();
            }
            totalAssets = totalAssets + poolAssets;
        } else {
            // simulate how much we would get out
            stakedAssets = stakedBalance(_forexKey);
            if (stakedAssets > 0) {
                ICurveFi curvePool = ICurveFi(forexInfo[_forexKey].curvePool);
                poolAssets =
                    (curvePool.balances(0) * stakedAssets) /
                    curvePool.totalSupply();
                poolAssets +=
                    (curvePool.balances(1) * stakedAssets) /
                    curvePool.totalSupply();
            }
            totalAssets = poolAssets + looseAssets;
        }

        assetsValue += (totalAssets * _usdcPerForex) / 1e20; // 1e18 * 1e8 = 1e26
    }

    /**
     * @notice The value in dollars that our claimable rewards are worth (in USDC, 6 decimals).
     * @param _forexKey Key in our forexInfo struct to use.
     */
    function claimableProfitInUsdc(uint256 _forexKey)
        public
        view
        returns (uint256)
    {
        // calculations pulled directly from CVX's contract for minting CVX per CRV claimed
        uint256 totalCliffs = 1_000;
        uint256 maxSupply = 100 * 1_000_000 * 1e18; // 100mil
        uint256 reductionPerCliff = 100_000 * 1e18; // 100,000
        uint256 supply = cvx.totalSupply();
        uint256 mintableCvx;

        uint256 cliff = supply / reductionPerCliff;
        uint256 _claimableBal = claimableBalance(_forexKey);
        //mint if below total cliffs
        if (cliff < totalCliffs) {
            //for reduction% take inverse of current cliff
            uint256 reduction = totalCliffs - cliff;
            //reduce
            mintableCvx = (_claimableBal * reduction) / totalCliffs;

            //supply cap check
            uint256 amtTillMax = maxSupply - supply;
            if (mintableCvx > amtTillMax) {
                mintableCvx = amtTillMax;
            }
        }

        // our chainlink oracle returns prices normalized to 8 decimals, we convert it to 6
        uint256 crvPrice = feedRegistry.latestAnswer(
            address(crv),
            address(840)
        ) / 1e2; // ETH, USD. 1e8 div 1e2 = 1e6

        uint256 cvxPrice = feedRegistry.latestAnswer(
            address(cvx),
            address(840)
        ) / 1e2; // ETH, USD. 1e8 div 1e2 = 1e6

        uint256 crvValue = (crvPrice * _claimableBal) / 1e18; // 1e6 mul 1e18 div 1e18 = 1e6
        uint256 cvxValue = (cvxPrice * mintableCvx) / 1e18; // 1e6 mul 1e18 div 1e18 = 1e6

        return crvValue + cvxValue;
    }

    /**
     * @notice Convert 1 token to base USDC using chainlink oracles.
     * @dev Returns with 8 decimals
     * @param _forexKey Key in our forexInfo struct to use.
     */
    function usdcPerForex(uint256 _forexKey) public view returns (uint256) {
        // feed registry output is 8 decimals. in solidity 0.8.0+, must cast to uint160 BEFORE address
        uint256 _usdcPerForex = feedRegistry.latestAnswer(
            address(uint160(forexInfo[_forexKey].chainlinkUint)),
            address(840)
        );

        return _usdcPerForex;
    }

    /* ========== V1 -> V2 MIGRATION FUNCTIONS ========== */

    /**
     * @notice Repay borrows on our v1 borrower. Used to transfer debt from v1 to v2.
     * @dev May only be called by owner. This should be called in a multisend with a repayBorrow call in v1.
     * @param _forexKey Key in our forexInfo struct to use (asset to repay).
     * @param _amount Amount to repay.
     */
    function transferToRepayBorrowV1(uint256 _forexKey, uint256 _amount)
        external
        onlyOwner
        returns (uint256 totalTransferred)
    {
        IIronBank cyToken = IIronBank(forexInfo[_forexKey].cyToken);
        IERC20 underlying = IERC20(forexInfo[_forexKey].underlying);

        // repay the amount we input, or everything if we do 0
        if (_amount > 0) {
            underlying.transfer(V1_BORROWER, _amount);
            totalTransferred = _amount;
        } else {
            // repay max
            totalTransferred = cyToken.borrowBalanceCurrent(V1_BORROWER);
            underlying.transfer(V1_BORROWER, totalTransferred);
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Borrow using our credit line.
     * @dev May only be called by owner.
     * @param _forexKey Key in our forexInfo struct to use (asset to borrow).
     * @param _amount Amount to borrow.
     */
    function borrow(uint256 _forexKey, uint256 _amount) external onlyOwner {
        IIronBank cyToken = IIronBank(forexInfo[_forexKey].cyToken);
        cyToken.borrow(_amount);

        // update our borrow limit and balance for this token
        forexInfo[_forexKey].borrowLimit = creditLimit(_forexKey);
        forexInfo[_forexKey].borrowAmountStored = cyToken.borrowBalanceStored(
            address(this)
        );
    }

    /**
     * @notice Repay borrow for an asset.
     * @dev May only be called by owner.
     * @param _forexKey Key in our forexInfo struct to use (asset to repay).
     * @param _amount Amount to repay.
     */
    function repayBorrow(uint256 _forexKey, uint256 _amount)
        external
        onlyOwner
    {
        _repayBorrow(_forexKey, _amount);
    }

    function _repayBorrow(uint256 _forexKey, uint256 _amount) internal {
        IIronBank cyToken = IIronBank(forexInfo[_forexKey].cyToken);

        // repay the amount we input, or everything if we do 0
        if (_amount > 0) {
            cyToken.repayBorrow(_amount);
        } else {
            // repay max
            cyToken.repayBorrow(type(uint256).max);
        }

        // update our borrow limit and balance for this token
        forexInfo[_forexKey].borrowLimit = creditLimit(_forexKey);
        forexInfo[_forexKey].borrowAmountStored = cyToken.borrowBalanceStored(
            address(this)
        );
    }

    /**
     * @notice Deposit held ibToken to a Curve pool and stake it in Convex.
     * @dev May only be called by owner. If needed, can use this to add more sXYZ to our LP holdings by externally
     *  minting more LP via the synth, then sending it directly here to be staked.
     * @param _forexKey Key in our forexInfo struct to use (asset to LP).
     * @param _forexAmount Amount to deposit to Curve LP.
     * @param _minAmountOut Min amount of LP expected from ibToken, set this to avoid 🥪.
     */
    function deposit(
        uint256 _forexKey,
        uint256 _forexAmount,
        uint256 _minAmountOut
    ) external onlyOwner {
        require(_minAmountOut > 0, "Set _minAmountOut");

        // check for balances of tokens to deposit
        uint256 ibTokenBalance = IERC20(forexInfo[_forexKey].underlying)
            .balanceOf(address(this));

        if (ibTokenBalance > 0) {
            ICurveFi curvePool = ICurveFi(forexInfo[_forexKey].curvePool);
            curvePool.add_liquidity([_forexAmount, 0], _minAmountOut);
        }

        // Send all of our Curve pool tokens to be deposited
        ICurveFi curveLpToken = ICurveFi(forexInfo[_forexKey].curveLpToken);
        uint256 _toInvest = curveLpToken.balanceOf(address(this));

        // deposit into convex and stake immediately (but only if we have something to invest)
        if (_toInvest > 0) {
            uint256 pid = forexInfo[_forexKey].pid;
            IConvex(depositContract).deposit(pid, _toInvest, true);
        }
    }

    /**
     * @notice Claim and sweep out CRV and CVX to owner address.
     * @dev May only be called by owner.
     */
    function harvestAndSweep() external onlyOwner {
        _harvest();
        _sweepRewards();
    }

    /**
     * @notice Claim rewards (likely only CVX and CRV). Rewards are not sold but may be swept out later.
     * @dev May only be called by owner.
     */
    function harvest() external onlyOwner {
        _harvest();
    }

    function _harvest() internal {
        // this claims our CRV, CVX, and any extra tokens for all pools we are staked in
        address[] memory empty;
        zapContract.claimRewards(
            rewardsContracts,
            empty,
            empty,
            empty,
            0,
            0,
            0,
            0,
            0
        );
    }

    /**
     * @notice Sweep out all CRV and CVX (profit).
     * @dev May only be called by owner.
     */
    function sweepRewards() external onlyOwner {
        _sweepRewards();
    }

    function _sweepRewards() internal {
        uint256 crvBalance = crv.balanceOf(address(this));
        if (crvBalance > 0) {
            crv.transfer(owner(), crvBalance);
        }

        uint256 cvxBalance = cvx.balanceOf(address(this));
        if (cvxBalance > 0) {
            cvx.transfer(owner(), cvxBalance);
        }
    }

    /**
     * @notice Manually withdraw some of our Convex LP to our forex token.
     * @dev May only be called by owner.
     * @param _amountToUnstake Amount of Convex LP to unstake and withdraw from.
     * @param _forexKey Key in our forexInfo struct to use (LP to exit from).
     * @param _minAmountOut Min amount of ibToken expected from LP, set this to avoid 🥪.
     */
    function withdrawToForex(
        uint256 _amountToUnstake,
        uint256 _forexKey,
        uint256 _minAmountOut
    ) external onlyOwner {
        _withdrawToForex(_amountToUnstake, _forexKey, _minAmountOut);
    }

    /**
     * @notice Manually withdraw all of our staked Convex LP to our forex token.
     * @dev May only be called by owner.
     * @param _forexKey Key in our forexInfo struct to use (LP to exit from).
     * @param _minAmountOut Min amount of ibToken expected from LP, set this to avoid 🥪.
     */
    function withdrawToForexMax(uint256 _forexKey, uint256 _minAmountOut)
        external
        onlyOwner
    {
        _withdrawToForex(type(uint256).max, _forexKey, _minAmountOut);
    }

    function _withdrawToForex(
        uint256 _amountToUnstake,
        uint256 _forexKey,
        uint256 _minAmountOut
    ) internal {
        require(_minAmountOut > 0, "Set _minAmountOut");
        uint256 _stakedBal = stakedBalance(_forexKey);
        if (_amountToUnstake >= _stakedBal) {
            _amountToUnstake = _stakedBal;
        }

        if (_stakedBal > 0 && _amountToUnstake > 0) {
            IConvex rewardsContract = IConvex(
                forexInfo[_forexKey].rewardsContract
            );
            rewardsContract.withdrawAndUnwrap(_amountToUnstake, claimRewards);
        }

        ICurveFi curveLpToken = ICurveFi(forexInfo[_forexKey].curveLpToken);
        ICurveFi curvePool = ICurveFi(forexInfo[_forexKey].curvePool);
        uint256 toWithdraw = curveLpToken.balanceOf(address(this));

        if (toWithdraw > 0) {
            // ibEUR-USDC pool has slightly different interface
            if (_forexKey == 4) {
                curvePool.remove_liquidity_one_coin(
                    toWithdraw,
                    0,
                    _minAmountOut,
                    true
                );
            } else {
                curvePool.remove_liquidity_one_coin(
                    toWithdraw,
                    0,
                    _minAmountOut
                );
            }
        }
    }

    /* ========== IRON BANK ONLY ========== */

    /**
     * @notice Manually force a harvest() call.
     * @dev May only be called by Iron Bank Multisig.
     */
    function forceHarvest() external onlyIronBank {
        _harvest();
    }

    /**
     * @notice Manually force a withdrawToForex() call.
     * @dev May only be called by Iron Bank Multisig.
     */
    function forceWithdrawToForex(uint256 _forexKey, uint256 _minAmountOut)
        external
        onlyIronBank
    {
        _withdrawToForex(type(uint256).max, _forexKey, _minAmountOut);
    }

    /**
     * @notice Manually force a repayBorrow() call.
     * @dev May only be called by Iron Bank Multisig.
     */
    function forceRepayBorrow(uint256 _forexKey, uint256 _amount)
        external
        onlyIronBank
    {
        _repayBorrow(_forexKey, _amount);
    }

    /**
     * @notice Manually withdraw all assets from Convex, sell any profits, repay borrows, and/or sweep out anything else
     *  we want.
     * @dev SEND WITH FLASHBOTS. May only be called by Iron Bank Multisig. This assumes we have enough assets to fully
     *  repay borrow for a given market. Check canRepayBorrowStored() after calling borrowBalanceCurrent() on the
     *  cyToken to confirm that a borrow can be fully repaid. If for some reason we can't repay (if pools are depegged)
     *  then best to just withdraw and sweep out the curve LPs.
     * @param _keys Array of keys to exit, sell profits, and/or repay borrows.
     * @param _withdrawFromConvex Boolean for if we only want to withdraw from convex so we can sweep out the curve LPs.
     * @param _tokensToRug Addresses of any tokens to sweep out (LP tokens, CVX, CRV, etc.).
     */
    function forceCloseMax(
        uint256[] memory _keys,
        bool _withdrawFromConvex,
        address[] memory _tokensToRug
    ) external onlyIronBank {
        // make sure we claim our rewards
        claimRewards = true;

        // unstake everything from Convex but leave as Curve LP tokens and don't repay
        if (_withdrawFromConvex) {
            for (uint256 i = 0; i < _keys.length; i++) {
                uint256 _forexKey = _keys[i];
                uint256 _stakedBal = stakedBalance(_forexKey);
                IConvex rewardsContract = IConvex(
                    forexInfo[_forexKey].rewardsContract
                );
                rewardsContract.withdrawAndUnwrap(_stakedBal, claimRewards);
            }
        } else {
            // withdraw everything from Convex and our LPs (single-sided), and repay outstanding borrows
            for (uint256 i = 0; i < _keys.length; i++) {
                uint256 _forexKey = _keys[i];

                // withdraw LP position to ibToken and repay
                _withdrawToForex(type(uint256).max, _forexKey, 1); // can't be zero
                _repayBorrow(_forexKey, 0);
            }
        }

        // sweep any tokens we want back to the Iron Bank multisig. if we want to sweep LPs, include them in our array.
        for (uint256 j = 0; j < _tokensToRug.length; j++) {
            IERC20 token = IERC20(_tokensToRug[j]);
            uint256 toTransfer = token.balanceOf(address(this));
            if (toTransfer > 0) {
                token.safeTransfer(ironBankMultisig, toTransfer);
            }
        }
    }

    // include so our contract plays nicely with ether
    receive() external payable {}

    /* ========== SETTERS ========== */

    /**
     * @notice Set whether we claim assets on withdrawal (usually no).
     * @dev May only be called by owner.
     * @param _claimRewards Whether or not we claim rewards on withdrawals.
     */
    function setClaimRewards(bool _claimRewards) external onlyOwner {
        claimRewards = _claimRewards;
    }
}
