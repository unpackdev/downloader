// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IConvexDeposits.sol";
import "./IConvexStaking.sol";
import "./IFxnDepositor.sol";
import "./ICurveExchange.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";


/*
 Treasury module for cvxfxn lp management
*/
contract TreasuryManager{
    using SafeERC20 for IERC20;

    address public constant crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address public constant cvx = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    address public constant fxn = address(0x365AccFCa291e7D3914637ABf1F7635dB165Bb09);
    address public constant cvxFxn = address(0x183395DbD0B5e93323a7286D1973150697FFFCB3);
    address public constant treasury = address(0x1389388d01708118b497f59521f6943Be2541bb7);
    address public constant exchange = address(0x1062FD8eD633c1f080754c19317cb3912810B5e5);
    address public constant fxnDeposit = address(0x56B3c8eF8A095f8637B6A84942aA898326B82b91);
    address public constant booster = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    address public constant lprewards = address(0x19A0117a5bE27e4D3059Be13FB069eB8f1646d86);
    uint256 public constant pid = 242;

    address public immutable owner;


    mapping(address => bool) public operators;
    uint256 public slippage;

    event OperatorSet(address indexed _op, bool _active);
    event Swap(uint256 _amountIn, uint256 _amountOut);
    event Convert(uint256 _amount);
    event AddedToLP(uint256 _lpamount);
    event RemovedFromLp(uint256 _lpamount);
    event ClaimedReward(address indexed _token, uint256 _amount);

    constructor() {
        owner = address(0xa3C5A1e09150B75ff251c1a7815A07182c3de2FB);
        operators[msg.sender] = true;

        slippage = 970 * 1e15;
        IERC20(cvxFxn).safeApprove(exchange, type(uint256).max);
        IERC20(fxn).safeApprove(exchange, type(uint256).max);
        IERC20(fxn).safeApprove(fxnDeposit, type(uint256).max);
        IERC20(exchange).safeApprove(booster, type(uint256).max);
    }


    modifier onlyOwner() {
        require(owner == msg.sender, "!owner");
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender] || owner == msg.sender, "!operator");
        _;
    }

    function treasuryBalanceOfCvxFxn() external view returns(uint256){
        return IERC20(cvxFxn).balanceOf(treasury);
    }

    function treasuryBalanceOfFxn() external view returns(uint256){
        return IERC20(fxn).balanceOf(treasury);
    }

    function setOperator(address _op, bool _active) external onlyOwner{
        operators[_op] = _active;
        emit OperatorSet(_op, _active);
    }

    function setSlippageAllowance(uint256 _slip) external onlyOwner{
        require(_slip > 0, "!valid slip");
        slippage = _slip;
    }

    function withdrawTo(IERC20 _asset, uint256 _amount, address _to) external onlyOwner{
        _asset.safeTransfer(_to, _amount);
    }

    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns (bool, bytes memory) {

        (bool success, bytes memory result) = _to.call{value:_value}(_data);

        return (success, result);
    }

    function calc_minOut_swap(uint256 _amount) external view returns(uint256){
        uint256[2] memory amounts = [_amount,0];
        uint256 tokenOut = ICurveExchange(exchange).calc_token_amount(amounts, false);
        tokenOut = tokenOut * slippage / 1e18;
        return tokenOut;
    }

    function calc_minOut_deposit(uint256 _fxnamount, uint256 _cvxFxnamount) external view returns(uint256){
        uint256[2] memory amounts = [_fxnamount,_cvxFxnamount];
        uint256 tokenOut = ICurveExchange(exchange).calc_token_amount(amounts, true);
        tokenOut = tokenOut * slippage / 1e18;
        return tokenOut;
    }

    function calc_withdraw_one_coin(uint256 _amount) external view returns(uint256){
        uint256 tokenOut = ICurveExchange(exchange).calc_withdraw_one_coin(_amount, 1);
        tokenOut = tokenOut * slippage / 1e18;
        return tokenOut;
    }

    function swap(uint256 _amount, uint256 _minAmountOut) external onlyOperator{
        require(_minAmountOut > 0, "!min_out");

        uint256 before = IERC20(cvxFxn).balanceOf(treasury);

        //pull
        IERC20(fxn).safeTransferFrom(treasury,address(this),_amount);
        
        //swap fxn for cvxFxn and return to treasury
        ICurveExchange(exchange).exchange(0,1,_amount,_minAmountOut, treasury);

        emit Swap(_amount, IERC20(cvxFxn).balanceOf(treasury) - before );
    }

    function convert(uint256 _amount, bool _lock) external onlyOperator{
        //pull
        IERC20(fxn).safeTransferFrom(treasury,address(this),_amount);
        
        //deposit
        IFxnDepositor(fxnDeposit).deposit(_amount,_lock);

        //return
        IERC20(cvxFxn).safeTransfer(treasury,_amount);

        emit Convert(_amount);
    }


    function addToPool(uint256 _fxnamount, uint256 _cvxFxnamount, uint256 _minAmountOut) external onlyOperator{
        require(_minAmountOut > 0, "!min_out");

        //pull
        IERC20(fxn).safeTransferFrom(treasury,address(this),_fxnamount);
        IERC20(cvxFxn).safeTransferFrom(treasury,address(this),_cvxFxnamount);

        //add lp
        uint256[2] memory amounts = [_fxnamount,_cvxFxnamount];
        ICurveExchange(exchange).add_liquidity(amounts, _minAmountOut, address(this));

        //add to convex
        uint256 lpBalance = IERC20(exchange).balanceOf(address(this));
        IConvexDeposits(booster).deposit(pid, lpBalance, true);

        emit AddedToLP(lpBalance);
    }

    function removeFromPool(uint256 _amount, uint256 _minAmountOut) external onlyOperator{
        require(_minAmountOut > 0, "!min_out");

        //remove from convex
        IConvexStaking(lprewards).withdrawAndUnwrap(_amount, true);

        //remove from LP with treasury as receiver
        ICurveExchange(exchange).remove_liquidity_one_coin(IERC20(exchange).balanceOf(address(this)), 1, _minAmountOut, treasury);

        uint256 bal = IERC20(crv).balanceOf(address(this));
        if(bal > 0){
            //transfer to treasury
            IERC20(crv).safeTransfer(treasury, bal);
        }

        bal = IERC20(cvx).balanceOf(address(this));
        if(bal > 0){
            //transfer to treasury
            IERC20(cvx).safeTransfer(treasury, bal);
        }

        bal = IERC20(fxn).balanceOf(address(this));
        if(bal > 0){
            //transfer to treasury
            IERC20(fxn).safeTransfer(treasury, bal);
        }

        bal = IERC20(cvxFxn).balanceOf(address(this));
        if(bal > 0){
            //transfer to treasury
            IERC20(cvxFxn).safeTransfer(treasury, bal);
        }

        emit RemovedFromLp(_amount);
    }

    function removeAsLP(uint256 _amount) external onlyOperator{
        //remove from convex
        IConvexStaking(lprewards).withdrawAndUnwrap(_amount, true);

        //remove from LP with treasury as receiver
        IERC20(exchange).safeTransfer(treasury,IERC20(exchange).balanceOf(address(this)));

        uint256 bal = IERC20(crv).balanceOf(address(this));
        if(bal > 0){
            //transfer to treasury
            IERC20(crv).safeTransfer(treasury, bal);
        }

        bal = IERC20(cvx).balanceOf(address(this));
        if(bal > 0){
            //transfer to treasury
            IERC20(cvx).safeTransfer(treasury, bal);
        }

        bal = IERC20(fxn).balanceOf(address(this));
        if(bal > 0){
            //transfer to treasury
            IERC20(fxn).safeTransfer(treasury, bal);
        }

        emit RemovedFromLp(_amount);
    }


     function claimLPRewards() external onlyOperator{
        //claim from convex
        IConvexStaking(lprewards).getReward();

        uint256 bal = IERC20(crv).balanceOf(address(this));
        if(bal > 0){
            //transfer to treasury
            IERC20(crv).safeTransfer(treasury, bal);
            emit ClaimedReward(crv,bal);
        }

        bal = IERC20(cvx).balanceOf(address(this));
        if(bal > 0){
            //transfer to treasury
            IERC20(cvx).safeTransfer(treasury, bal);
            emit ClaimedReward(cvx,bal);
        }

        bal = IERC20(fxn).balanceOf(address(this));
        if(bal > 0){
            //transfer to treasury
            IERC20(fxn).safeTransfer(treasury, bal);
            emit ClaimedReward(fxn,bal);
        }
    }

}