// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";


import "./IAavePool.sol";
import "./IAave.sol";
import "./IETHLeverage.sol";
import "./IFlashloanReceiver.sol";
import "./IExchange.sol";
import "./ISubStrategy.sol";
import "./IVault.sol";

contract ETHStrategy is Ownable,ReentrancyGuard, ISubStrategy, IETHLeverage {

    using SafeERC20 for IERC20;
    // Sub Strategy name
    string public constant poolName = "ETHStrategy V0.9";

    mapping(address=>bool) operator;

    // Controller address
    address public controller;

    // Vault address
    address public vault;

    // Constant magnifier
    uint256 public constant magnifier = 10000;

    // Exchange Address
    address public exchange;

    // Flashloan receiver
    address public receiver;

    // Fee collector
    address public feePool;

    // user input asset
    IERC20 public baseAsset;

    // deposit asset into aave pool
    IERC20 public depositAsset;

    // aave pool token
    IERC20 public aDepositAsset;

    // aave address
    address public IaavePool;

    uint256 public feeRate = 1000;

    // Max Deposit
    uint256 public override maxDeposit;

    // Last Earn Total
    uint256 internal lastTotal;
    bool internal harvested = false;

    // Max Loan Ratio
    uint256 public mlr;

    enum SrategyState {
        Normal,
        Deposit,
        Withdraw,
        RaiseMLR,
        ReduceMLR
    }

    event SetController(address controller);

    event SetVault(address vault);

    event SetExchange(address exchange);

    event SetFeePool(address feePool);

    event SetMaxDeposit(uint256 maxDeposit);

    event SetFlashloanReceiver(address receiver);

    event SetMLR(uint256 oldMlr, uint256 newMlr);

    event SetFeeRate(uint256 oldRate, uint256 newRate);

    event SetOperator(address operator, bool istrue);

    event LTVUpdate(
        uint256 oldDebt,
        uint256 oldCollateral,
        uint256 newDebt,
        uint256 newCollateral
    );

    constructor(
        IERC20 _baseAsset,
        IERC20 _depositAsset,
        IERC20 _aDepositAsset,
        uint256 _mlr,
        address _IaavePool,
        address _vault,
        address _feePool
    ) {
        mlr = _mlr;
        baseAsset = _baseAsset;
        depositAsset = _depositAsset;
        aDepositAsset = _aDepositAsset;
        IaavePool = _IaavePool;

        vault = _vault;
        feePool = _feePool;


        // Set Max Deposit as max uin256
        maxDeposit = type(uint256).max;
        address aave = IAavePool(_IaavePool).aave();
        baseAsset.safeApprove(aave, type(uint256).max);
        depositAsset.safeApprove(aave, type(uint256).max);
        IAave(aave).setUserEMode(1);
        
    }

    receive() external payable {}

    /**
        Only controller can call
     */
    modifier onlyController() {
        require(controller == _msgSender(), "NOT_CONTROLLER");
        _;
    }
    modifier onlyOperator() {
        require(operator[_msgSender()] == true, "NOT_OPERATOR");
        _;
    }
    /**
        Only Flashloan receiver can call
     */
    modifier onlyReceiver() {
        require(receiver == _msgSender(), "NOT_FLASHLOAN_RECEIVER");
        _;
    }
    modifier collectFee(){
        (,uint256 mintAmount) = _calculateFee();
        harvested = true;
        if(mintAmount>0){
            IVault(vault).mint(mintAmount, feePool);
        }
        _;
        harvested = false;
        lastTotal = _realTotalAssets();
    }
    //////////////////////////////////////////
    //           Flash loan Fallback        //
    //////////////////////////////////////////

    /**
        External Function for Callback when to flash loan
     */
    function loanFallback(
        uint256 loanAmt,
        uint256 feeAmt,
        bytes calldata userData
    ) external override onlyReceiver {
        (SrategyState curState,uint256 userValue) = abi.decode(userData,(SrategyState,uint256));
        require(curState != SrategyState.Normal, "NORMAL_STATE_CANT_CALL_THIS");
        address aave = IAavePool(IaavePool).aave();
        if (curState == SrategyState.Deposit) {
            // Swap baseAsset to depositAsset
            uint256 depoistAmt = IExchange(exchange).swap(address(baseAsset),address(depositAsset),userValue+loanAmt,0);
    
            IAave(aave).deposit(address(depositAsset), depoistAmt, address(this), 0);
            if (IAavePool(IaavePool).getCollateral(address(this)) == 0) {
                IAave(aave).setUserUseReserveAsCollateral(address(depositAsset), true);
            }
            // Repay flash loan
            uint256 repay = loanAmt + feeAmt;
            IAave(aave).borrow(address(baseAsset), repay, 2, 0, address(this));
        } else if (curState == SrategyState.Withdraw) {
            uint256 withdrawAmount = (loanAmt *
                aDepositAsset.balanceOf(address(this))) / IAavePool(IaavePool).getDebt(address(this));

            // Repay WETH to aave
            IAave(aave).repay(address(baseAsset), loanAmt, 2, address(this));
            IAave(aave).withdraw(address(depositAsset), withdrawAmount, address(this));

            // Swap depositAsset to baseAsset
            IExchange(exchange).swap(address(depositAsset),address(baseAsset),withdrawAmount,0);
        }else if (curState == SrategyState.RaiseMLR) {
            // Transfer baseAsset to Exchange
            uint256 slippage = userValue;
            uint256 minOut = IAavePool(IaavePool).convertAmount(address(baseAsset), address(depositAsset),loanAmt*(magnifier-slippage)/magnifier);
            // Swap baseAsset to depositAsset
            IExchange(exchange).swap(address(baseAsset),address(depositAsset),loanAmt,minOut);
    
            // Deposit depositAsset to AAVE
            uint256 depoistBalance = depositAsset.balanceOf(address(this));

            IAave(aave).deposit(address(depositAsset), depoistBalance, address(this), 0);
            if (IAavePool(IaavePool).getCollateral(address(this)) == 0) {
                IAave(aave).setUserUseReserveAsCollateral(address(depositAsset), true);
            }
            // Repay flash loan
            uint256 repay = loanAmt + feeAmt;
            IAave(aave).borrow(address(baseAsset), repay, 2, 0, address(this));
        } else if (curState == SrategyState.ReduceMLR) {
            uint256 slippage = userValue;
            uint256 repayflash = loanAmt + feeAmt;
            uint256 maxInput = IAavePool(IaavePool).convertAmount(address(baseAsset), address(depositAsset),repayflash*magnifier/(magnifier-slippage));
            IAave(aave).repay(address(baseAsset), loanAmt, 2, address(this));
            uint256 withdrawAmount =IExchange(exchange).getCurveInputValue(address(depositAsset),address(baseAsset),repayflash,maxInput);
            IAave(aave).withdraw(address(depositAsset), withdrawAmount, address(this));
            uint256 minOut = IAavePool(IaavePool).convertAmount(address(depositAsset), address(baseAsset),withdrawAmount*(magnifier-slippage)/magnifier);
            IExchange(exchange).swap(address(depositAsset),address(baseAsset),withdrawAmount,minOut);            // Repay Weth to receiver
            uint256 balance = baseAsset.balanceOf(address(this)) - loanAmt - feeAmt;
            uint256 debt = IAavePool(IaavePool).getDebt(address(this));
            if(balance>debt){
                balance = debt;
            }
            if(balance>0){
                IAave(aave).repay(address(baseAsset), balance, 2, address(this));
            }
        } else {
            revert("NOT_A_SS_STATE");
        }
    }

    //////////////////////////////////////////
    //          VIEW FUNCTIONS              //
    //////////////////////////////////////////

    /**
        External view function of total USDC deposited in Covex Booster
     */
    function totalAssets() external view override returns (uint256) {
        return _totalAssets();
    }

    /**
        Internal view function of total USDC deposited
    */
    function _totalAssets() internal view returns (uint256) {
        if (!harvested){
            (uint256 fee,) = _calculateFee();
            return _realTotalAssets() - fee;
        }else{
            return _realTotalAssets();
        }
    }
    function _realTotalAssets()internal view returns (uint256) {
        (uint256 st,uint256 e) = IAavePool(IaavePool).getCollateralAndDebt(address(this));
        return st-e;
    }
    /**
        Deposit function of USDC
     */
    function deposit(
        uint256 _amount
    ) external override onlyController collectFee returns (uint256) {
        uint256 deposited = _deposit(_amount);
        return deposited;
    }

    /**
        Deposit internal function
     */
    function _deposit(uint256 _amount) internal returns (uint256) {
        // Get Prev Deposit Amt
        uint256 prevAmt = _totalAssets();

        // Check Max Deposit
        require(prevAmt + _amount <= maxDeposit, "EXCEED_MAX_DEPOSIT");

        // Calculate Flashloan Fee - in terms of 1e4
        uint256 fee = IFlashloanReceiver(receiver).getFee();
        uint256 feeParam = fee + magnifier;
        uint256 loanAmt = (_amount * mlr) / (feeParam - mlr);
        // uint256 feeAmt = (loanAmt * fee) / magnifier;

        // Execute flash loan
        IFlashloanReceiver(receiver).flashLoan(address(baseAsset), loanAmt,abi.encode(SrategyState.Deposit,_amount));

        // Get new total assets amount
        uint256 newAmt = _totalAssets();

        // Deposited amt
        uint256 deposited = newAmt - prevAmt;
        return deposited;
    }

    /**
        Withdraw function of USDC
     */
    function withdraw(
        uint256 _amount
    ) external override onlyController collectFee returns (uint256) {

        // Get Prev Deposit Amt
        uint256 prevAmt = _totalAssets();
        require(_amount <= prevAmt, "INSUFFICIENT_ASSET");

        uint256 debt = IAavePool(IaavePool).getDebt(address(this));

        if(debt>0){
            uint256 preBalance = baseAsset.balanceOf(address(this));
            uint256 loanAmt = (debt * _amount) / prevAmt;
            IFlashloanReceiver(receiver).flashLoan(address(baseAsset), loanAmt,abi.encode(SrategyState.Withdraw,uint256(0)));

            uint256 toSend = baseAsset.balanceOf(address(this))-preBalance;
            return toSend;
        }else{
            address aave = IAavePool(IaavePool).aave();
            uint256 withdrawAmount = (_amount * aDepositAsset.balanceOf(address(this))) / prevAmt;
            //debt = 0
            IAave(aave).withdraw(address(depositAsset), withdrawAmount, address(this));
            // Swap depositAsset to baseAsset
            return IExchange(exchange).swap(address(depositAsset),address(baseAsset),withdrawAmount,0);
        }

    }

    /**
        Harvest reward token from convex booster
     */
    function harvest() external onlyOperator collectFee {
    }
    function _calculateFee()internal view returns (uint256,uint256) {
        uint256 currentAssets = _realTotalAssets();
        if(lastTotal>=currentAssets){
            return (0,0);
        }else{
            uint256 totalEF = IERC20(vault).totalSupply();
            if (totalEF == 0){
                return (0,0);
            }
            //uint256 feePoolBal = IERC20(vault).balanceOf(feePool);
            
            uint256 stFee = (currentAssets-lastTotal) *feeRate /magnifier;
            //stFee = stFee - ((stFee * feePoolBal) / (totalEF));
            uint256 mintAmt = (stFee * totalEF) / (currentAssets - stFee);
            if (mintAmt == 0){
                return (0,0);
            }
            return (stFee,mintAmt);
        }
    }


    function changeMLR(uint256 _mlr,uint256 swapSlippage) internal {
        if (_mlr > mlr){
            raiseMLR(_mlr, swapSlippage);
        }else if(_mlr < mlr){
            reduceMLR(_mlr, swapSlippage);
        }

    }
    function raiseMLR(uint256 _mlr,uint256 swapSlippage)internal{
        //flashloan = (mlr*a-b)/(1-mlr*s)
        (uint256 coll,uint256 debt) = IAavePool(IaavePool).getCollateralAndDebt(address(this));
        uint256 debtNew = _mlr*coll;
        debt = debt*magnifier;
        if (debtNew>debt){
            uint256 amount =(debtNew-debt)*magnifier/(magnifier*magnifier-_mlr*(magnifier-swapSlippage));
            IFlashloanReceiver(receiver).flashLoan(address(baseAsset), amount,abi.encode(SrategyState.RaiseMLR,swapSlippage));
        }
        (uint256 coll1,uint256 debt1) = IAavePool(IaavePool).getCollateralAndDebt(address(this));
        emit LTVUpdate(debt/magnifier, coll, debt1, coll1);
    }
    function reduceMLR(uint256 _mlr,uint256 swapSlippage)internal{
        //flashloan = (b-mlr*a)/(s-mlr)
        (uint256 coll,uint256 debt) = IAavePool(IaavePool).getCollateralAndDebt(address(this));
        uint256 debtNew = _mlr*coll;
        debt = debt*magnifier;
        if (debtNew<debt){
            uint256 amount =(debt-debtNew)/(magnifier-swapSlippage-_mlr);
            IFlashloanReceiver(receiver).flashLoan(address(baseAsset), amount,abi.encode(SrategyState.ReduceMLR,swapSlippage));
        }
        (uint256 coll1,uint256 debt1) = IAavePool(IaavePool).getCollateralAndDebt(address(this));
        emit LTVUpdate(debt/magnifier, coll, debt1, coll1);
    }
    /**
        Raise LTV
     */
     /*
    function raiseLTV(uint256 lt,uint256 swapSlippage) external onlyOwner {
        //flashloan = mlr/(1-mlr)*collateral-1/(1-mlr)*debt
        (uint256 st,uint256 e) = IAavePool(IaavePool).getCollateralAndDebt(address(this));

        require(e * magnifier < st * mlr, "NO_NEED_TO_RAISE");

        address aave = IAavePool(IaavePool).aave();
        uint256 x = (st * mlr - (e * magnifier)) / (magnifier - mlr);
        uint256 y = (st * lt) / magnifier - e - 1;

        if (x > y) {
            x = y;
        }

        IAave(aave).borrow(address(baseAsset), x, 2, 0, address(this));
        uint256 baseAmt = baseAsset.balanceOf(address(this));

        // Transfer base asset to Exchange
        baseAsset.safeTransfer(exchange, baseAmt);
        // Swap baseAsset to depositAsset
        uint256 minOut = IAavePool(IaavePool).convertAmount(address(baseAsset), address(depositAsset),baseAmt*(magnifier-swapSlippage)/magnifier);
        IExchange(exchange).swap(address(baseAsset),address(depositAsset),baseAmt,minOut);

        // Deposit STETH to AAVE
        uint256 depositAmt = depositAsset.balanceOf(address(this));

        IAave(aave).deposit(address(depositAsset), depositAmt, address(this), 0);
        (uint256 st1,uint256 e1) = IAavePool(IaavePool).getCollateralAndDebt(address(this));
        emit LTVUpdate(e, st, e1, st1);
    }
*/
    /**
        Reduce LTV
     */
     /*
    function reduceLTV(uint256 swapSlippage) external onlyOwner {
        (uint256 st,uint256 e) = IAavePool(IaavePool).getCollateralAndDebt(address(this));

        require(e * magnifier > st * mlr, "NO_NEED_TO_REDUCE");

        address aave = IAavePool(IaavePool).aave();

        uint256 x = (e * magnifier - st * mlr) / (magnifier - mlr);

        uint256 loanAmt = (x * e) / st;

        IFlashloanReceiver(receiver).flashLoan(address(baseAsset), loanAmt,abi.encode(SrategyState.Withdraw,uint256(0)));


        uint256 baseBal = baseAsset.balanceOf(address(this));
        // Approve WETH to AAVE
        // Repay WETH to aave
        IAave(aave).repay(address(baseAsset), baseBal, 2, address(this));
    }

*/

    /**
        Check withdrawable status of required amount
     */
    function withdrawable(
        uint256 _amount
    ) external view override returns (uint256) {
        // Get Current Deposit Amt
        uint256 total = _totalAssets();

        // If requested amt is bigger than total asset, return false
        if (_amount > total) return total;
        // Todo Have to check withdrawable amount
        else return _amount;
    }


    //////////////////////////////////////////////////
    //               SET CONFIGURATION              //
    //////////////////////////////////////////////////

    /**
        Set Controller
     */
    function setController(address _controller) external onlyOwner {
        require(controller == address(0), "CONTROLLER_ALREADY");
        require(_controller != address(0), "INVALID_ADDRESS");
        controller = _controller;
        baseAsset.safeApprove(_controller,type(uint256).max);
        emit SetController(controller);
    }
    /**
        Set Operator
     */
    function setOperator(address _Operator, bool _isTrue) external onlyOwner {
        require(_Operator != address(0), "INVALID_ADDRESS");
        operator[_Operator]=_isTrue;
        emit SetOperator(_Operator, _isTrue);
    }
    /**
        Set Vault
     */
    function setVault(address _vault) external onlyOwner {
        require(_vault != address(0), "INVALID_ADDRESS");
        vault = _vault;

        emit SetVault(vault);
    }

    /**
        Set Fee Pool
     */
    function setFeePool(address _feePool) external onlyOwner {
        require(_feePool != address(0), "INVALID_ADDRESS");
        feePool = _feePool;

        emit SetFeePool(feePool);
    }

    /**
        Set Max Deposit
     */
    function setMaxDeposit(uint256 _maxDeposit) external onlyOwner {
        require(_maxDeposit > 0, "INVALID_MAX_DEPOSIT");
        maxDeposit = _maxDeposit;

        emit SetMaxDeposit(maxDeposit);
    }

    /**
        Set Flashloan Receiver
     */
    function setFlashLoanReceiver(address _receiver) external onlyOwner {
        require(_receiver != address(0), "INVALID_RECEIVER_ADDRESS");
        if (receiver != address(0)){
            baseAsset.safeApprove(receiver,0);
        }
        receiver = _receiver;
        baseAsset.safeApprove(_receiver,type(uint256).max);
        emit SetFlashloanReceiver(receiver);
    }

    /**
        Set Exchange
     */
    function setExchange(address _exchange) external onlyOwner {
        require(_exchange != address(0), "INVALID_ADDRESS");
        if (exchange != address(0)){
            baseAsset.safeApprove(exchange,0);
            depositAsset.safeApprove(exchange,0);
        }
        exchange = _exchange;
        baseAsset.safeApprove(_exchange,type(uint256).max);
        depositAsset.safeApprove(_exchange,type(uint256).max);
        emit SetExchange(exchange);
    }

    /**
        Set Fee Rate
     */
    function setFeeRate(uint256 _rate) external collectFee onlyOwner {
        require(_rate > 0, "INVALID_RATE");

        uint256 oldRate = feeRate;
        feeRate = _rate;

        emit SetFeeRate(oldRate, feeRate);
    }

    /**
        Set MLR
     */
    function setMLR(uint256 _mlr,uint256 swapSlippage) external nonReentrant onlyOperator {
        require(_mlr > 0 && _mlr < magnifier, "INVALID_RATE");
        changeMLR(_mlr,swapSlippage);
        uint256 oldMlr = mlr;
        mlr = _mlr;

        emit SetMLR(oldMlr, _mlr);
    }
}
