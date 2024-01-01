// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IConvexDeposits.sol";
import "./IConvexStaking.sol";
import "./IPrismaDepositor.sol";
import "./ICurveExchange.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";


/*
 Treasury module for cvxprisma lp management
*/
contract TreasuryManager{
    using SafeERC20 for IERC20;

    address public constant crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address public constant cvx = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    address public constant prisma = address(0xdA47862a83dac0c112BA89c6abC2159b95afd71C);
    address public constant cvxPrisma = address(0x34635280737b5BFe6c7DC2FC3065D60d66e78185);
    address public constant treasury = address(0x1389388d01708118b497f59521f6943Be2541bb7);
    address public constant exchange = address(0x3b21C2868B6028CfB38Ff86127eF22E68d16d53B);
    address public constant deposit = address(0x61404F7c2d8b1F3373eb3c6e8C4b8d8332c2D5B8);
    address public constant booster = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    address public constant lprewards = address(0x4b10c7fAd37cB7A9DaCcEeEe40C0d97549918298);
    uint256 public constant pid = 258;

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
        IERC20(cvxPrisma).safeApprove(exchange, type(uint256).max);
        IERC20(prisma).safeApprove(exchange, type(uint256).max);
        IERC20(prisma).safeApprove(deposit, type(uint256).max);
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

    function treasuryBalanceOfCvxPrisma() external view returns(uint256){
        return IERC20(cvxPrisma).balanceOf(treasury);
    }

    function treasuryBalanceOfPrisma() external view returns(uint256){
        return IERC20(prisma).balanceOf(treasury);
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

    function calc_minOut_deposit(uint256 _prismaAmount, uint256 _cvxPrismaAmount) external view returns(uint256){
        uint256[2] memory amounts = [_prismaAmount,_cvxPrismaAmount];
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

        uint256 before = IERC20(cvxPrisma).balanceOf(treasury);

        //pull
        IERC20(prisma).safeTransferFrom(treasury,address(this),_amount);
        
        //swap prisma for cvxPrisma and return to treasury
        ICurveExchange(exchange).exchange(0,1,_amount,_minAmountOut, treasury);

        emit Swap(_amount, IERC20(cvxPrisma).balanceOf(treasury) - before );
    }

    function convert(uint256 _amount, bool _lock) external onlyOperator{
        //pull
        IERC20(prisma).safeTransferFrom(treasury,address(this),_amount);
        
        //deposit
        IPrismaDepositor(deposit).deposit(_amount,_lock);

        //return
        IERC20(cvxPrisma).safeTransfer(treasury,_amount);

        emit Convert(_amount);
    }


    function addToPool(uint256 _prismaAmount, uint256 _cvxPrismaAmount, uint256 _minAmountOut) external onlyOperator{
        require(_minAmountOut > 0, "!min_out");

        //pull
        IERC20(prisma).safeTransferFrom(treasury,address(this),_prismaAmount);
        IERC20(cvxPrisma).safeTransferFrom(treasury,address(this),_cvxPrismaAmount);

        //add lp
        uint256[2] memory amounts = [_prismaAmount,_cvxPrismaAmount];
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

        bal = IERC20(prisma).balanceOf(address(this));
        if(bal > 0){
            //transfer to treasury
            IERC20(prisma).safeTransfer(treasury, bal);
        }

        bal = IERC20(cvxPrisma).balanceOf(address(this));
        if(bal > 0){
            //transfer to treasury
            IERC20(cvxPrisma).safeTransfer(treasury, bal);
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

        bal = IERC20(prisma).balanceOf(address(this));
        if(bal > 0){
            //transfer to treasury
            IERC20(prisma).safeTransfer(treasury, bal);
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

        bal = IERC20(prisma).balanceOf(address(this));
        if(bal > 0){
            //transfer to treasury
            IERC20(prisma).safeTransfer(treasury, bal);
            emit ClaimedReward(prisma,bal);
        }
    }

}