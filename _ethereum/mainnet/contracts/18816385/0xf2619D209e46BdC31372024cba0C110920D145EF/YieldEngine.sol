// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./SafeERC20.sol";
import "./UUPSUpgradeable.sol";

import "./INpYieldEngine.sol";
import "./ITreasury.sol";
import "./IUniswapV2Router02.sol";
import "./IReferralRegistry.sol";
import "./IUniswapV2Oracle.sol";
import "./IReferralReport.sol";

import "./Whitelist.sol";
import "./SafeMath.sol";

contract YieldEngine is UUPSUpgradeable, Whitelist, INpYieldEngine {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    ITreasury public collateralBufferPool;
    ITreasury public coreTreasury;
    IERC20 public collateralToken;
    IERC20 public coreToken;

    bool public forceLiquidity;

    IUniswapV2Router02 public collateralRouter;

    IReferralRegistry public referralData;

    IUniswapV2Oracle public oracle;

    event UpdateCollateralRouter(address indexed addr);
    event NewSponsorship(address indexed from, address indexed to, uint256 amount);

    event UpdateOracle(address indexed addr);
    event UpdateReferralData(address indexed addr);
    event UpdateForceLiquidity(bool value, bool new_value);

    /* ========== INITIALIZER ========== */

    constructor() {
        _disableInitializers();
    }

    function initialize(address _coreToken, address _collateralToken, address _router, address _treausry, address _buffer, address _referral) external initializer {
        coreToken = IERC20(_coreToken);
        collateralToken = IERC20(_collateralToken);

        //the collateral router can be upgraded in the future
        collateralRouter = IUniswapV2Router02(_router);

        collateralBufferPool = ITreasury(_buffer);
        coreTreasury = ITreasury(_treausry);

        referralData = IReferralRegistry(_referral);
        
        forceLiquidity = false;

        __Ownable_init(_msgSender());
    }

    //@dev Update the referral data for partner rewards
    function updateReferralData(address referralDataAddress) external onlyOwner {
        require(referralDataAddress != address(0), "Require valid non-zero addresses");

        referralData = IReferralRegistry(referralDataAddress);

        emit UpdateReferralData(referralDataAddress);
    }

    //@dev Forces the yield engine to topoff liquidity in the collateral buffer on every tx
    //a test harness
    function updateForceLiquidity(bool _force) external onlyOwner {
        emit UpdateForceLiquidity(forceLiquidity, _force);
        forceLiquidity = _force;
    }

    //@dev Update Core collateral liquidity can move from one contract location to another across major PCS releases
    function updateCollateralRouter(address _router) public onlyOwner {
        require(_router != address(0), "Router must be set");
        collateralRouter = IUniswapV2Router02(_router);

        emit UpdateCollateralRouter(_router);
    }

    //@dev Update the oracle used for price info
    function updateOracle(address oracleAddress) external onlyOwner {
        require(oracleAddress != address(0), "Require valid non-zero addresses");

        //the main oracle
        oracle = IUniswapV2Oracle(oracleAddress);

        address[] memory path = new address[](2);
        path[0] = address(collateralToken);
        path[1] = address(coreToken);

        //make sure our path for liquidation is registered
        oracle.updatePath(path);

        emit UpdateOracle(oracleAddress);
    }

    /********** Whitelisted Fuctions **************************************************/

    //@dev Claim and payout using the reserve
    //Sender must implement IReferralReport to succeed
    function yield(address _user, uint256 _amount) external onlyWhitelisted returns (uint yieldAmount) {
        oracle.updateAll();

        if (_amount == 0) {
            return 0;
        }

        //CollateralBuffer should be large enough to support daily yield
        uint256 cbShare = collateralToken.balanceOf(address(collateralBufferPool)) / 100;

        //if yield is greater than 1%
        if (_amount > cbShare || forceLiquidity) {
            uint _coreAmount = estimateCollateralToCore(_amount);
            liquidateCore(address(collateralBufferPool), (_coreAmount * 110) / 100); //Add an additional 10% to the BufferPool

            //account for TWAP inconsistency; the end user balance will only go down by the delivered amount
            //the buffer will never be overrun
            _amount = _amount.min(collateralToken.balanceOf(address(collateralBufferPool)));
        }

        //Calculate user referral rewards
        uint _referrals = _amount / 100;

        //Add referral bonus for referrer, 1%
        processReferralBonus(_user, _referrals, msg.sender);

        //Send collateral to user
        collateralBufferPool.withdrawTo(_user, _amount);

        return _amount;
    }

    /********** Internal Fuctions **************************************************/

    //@dev Add referral bonus if applicable
    function processReferralBonus(address _user, uint256 _amount, address referral_report) private {
        address _referrer = referralData.referrerOf(_user);

        //Need to have an upline
        if (_referrer == address(0)) {
            return;
        }

        //partners split 50/50
        // uint256 _share = _amount.div(2);

        //Report the reward distribution to the caller
        IReferralReport report = IReferralReport(referral_report);
        report.distributeReferrerReward(_referrer, _amount);

        emit NewSponsorship(_user, _referrer, _amount);
    }

    function estimateCollateralToCore(uint collateralAmount) public view returns (uint coreAmount) {
        //Convert from collateral to core using oracle
        address[] memory path = new address[](2);
        path[0] = address(collateralToken);
        path[1] = address(coreToken);

        uint[] memory amounts = oracle.consultAmountsOut(collateralAmount, path);

        //Use core router to get amount of coreTokens required to cover
        coreAmount = amounts[1];
    }

    //@dev liquidate core tokens from the treasury to the destination
    function liquidateCore(address destination, uint256 _amount) private returns (uint collateralAmount) {
        //Convert from collateral to backed
        address[] memory path = new address[](2);

        path[0] = address(coreToken);
        path[1] = address(collateralToken);

        //withdraw from treasury
        coreTreasury.withdraw(_amount);

        //approve & swap
        coreToken.approve(address(collateralRouter), _amount);

        uint initialBalance = collateralToken.balanceOf(destination);

        collateralRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(_amount, 0, path, destination, block.timestamp);

        collateralAmount = collateralToken.balanceOf(destination).safeSub(initialBalance);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
