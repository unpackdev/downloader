pragma solidity 0.6.12;
import "./Ownable.sol";
import "./console.sol";

import "./IWETH9.sol";
import "./IFeeApprover.sol";
// import "./IUniswapV2Pair.sol";
import "./IERC20.sol";
import "./Math.sol";

import "./UniswapV2Library.sol";
import "./SafeMath.sol";
import "./ITensVault.sol";


contract TENSv1Router is Ownable {

    using SafeMath for uint256;
    mapping(address => uint256) public hardTENS;

    address public _tensToken;
    address public _tensWETHPair;
    IFeeApprover public _feeApprover;
    ITensVault public _tensVault;
    IWETH public _WETH;
    address public _uniV2Factory;

    constructor(address tensToken, address WETH, address uniV2Factory, address tensWethPair, address feeApprover, address tensVault) public {
        _tensToken = tensToken;
        _WETH = IWETH(WETH);
        _uniV2Factory = uniV2Factory;
        _feeApprover = IFeeApprover(feeApprover);
        _tensWETHPair = tensWethPair;
        _tensVault = ITensVault(tensVault);
        refreshApproval();
    }

    function refreshApproval() public {
        IUniswapV2Pair(_tensWETHPair).approve(address(_tensVault), uint(-1));
    }

    event FeeApproverChanged(address indexed newAddress, address indexed oldAddress);

    fallback() external payable {
        if(msg.sender != address(_WETH)){
             addLiquidityETHOnly(msg.sender, false);
        }
    }


    function addLiquidityETHOnly(address payable to, bool autoStake) public payable {
        require(to != address(0), "Invalid address");
        hardTENS[msg.sender] = hardTENS[msg.sender].add(msg.value);

        uint256 buyAmount = msg.value.div(2);
        require(buyAmount > 0, "Insufficient ETH amount");

        _WETH.deposit{value : msg.value}();

        (uint256 reserveWeth, uint256 reserveTens) = getPairReserves();
        uint256 outTens = UniswapV2Library.getAmountOut(buyAmount, reserveWeth, reserveTens);
        
        _WETH.transfer(_tensWETHPair, buyAmount);

        (address token0, address token1) = UniswapV2Library.sortTokens(address(_WETH), _tensToken);
        IUniswapV2Pair(_tensWETHPair).swap(_tensToken == token0 ? outTens : 0, _tensToken == token1 ? outTens : 0, address(this), "");

        _addLiquidity(outTens, buyAmount, to, autoStake);

        _feeApprover.sync();
    }

    function _addLiquidity(uint256 tensAmount, uint256 wethAmount, address payable to, bool autoStake) internal {
        (uint256 wethReserve, uint256 tensReserve) = getPairReserves();

        uint256 optimalTensAmount = UniswapV2Library.quote(wethAmount, wethReserve, tensReserve);

        uint256 optimalWETHAmount;
        if (optimalTensAmount > tensAmount) {
            optimalWETHAmount = UniswapV2Library.quote(tensAmount, tensReserve, wethReserve);
            optimalTensAmount = tensAmount;
        }
        else
            optimalWETHAmount = wethAmount;

        assert(_WETH.transfer(_tensWETHPair, optimalWETHAmount));
        assert(IERC20(_tensToken).transfer(_tensWETHPair, optimalTensAmount));

        if (autoStake) {
            IUniswapV2Pair(_tensWETHPair).mint(address(this));
            _tensVault.depositFor(to, 0, IUniswapV2Pair(_tensWETHPair).balanceOf(address(this)));
        }
        else
            IUniswapV2Pair(_tensWETHPair).mint(to);
        

        //refund dust
        if (tensAmount > optimalTensAmount)
            IERC20(_tensToken).transfer(to, tensAmount.sub(optimalTensAmount));

        if (wethAmount > optimalWETHAmount) {
            uint256 withdrawAmount = wethAmount.sub(optimalWETHAmount);
            _WETH.withdraw(withdrawAmount);
            to.transfer(withdrawAmount);
        }
    }

    function changeFeeApprover(address feeApprover) external onlyOwner {
        address oldAddress = address(_feeApprover);
        _feeApprover = IFeeApprover(feeApprover);

        emit FeeApproverChanged(feeApprover, oldAddress);    
    }


    function getLPTokenPerEthUnit(uint ethAmt) public view  returns (uint liquidity){
        (uint256 reserveWeth, uint256 reserveTens) = getPairReserves();
        uint256 outTens = UniswapV2Library.getAmountOut(ethAmt.div(2), reserveWeth, reserveTens);
        uint _totalSupply =  IUniswapV2Pair(_tensWETHPair).totalSupply();

        (address token0, ) = UniswapV2Library.sortTokens(address(_WETH), _tensToken);
        (uint256 amount0, uint256 amount1) = token0 == _tensToken ? (outTens, ethAmt.div(2)) : (ethAmt.div(2), outTens);
        (uint256 _reserve0, uint256 _reserve1) = token0 == _tensToken ? (reserveTens, reserveWeth) : (reserveWeth, reserveTens);
        liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);


    }

    function getPairReserves() internal view returns (uint256 wethReserves, uint256 tensReserves) {
        (address token0,) = UniswapV2Library.sortTokens(address(_WETH), _tensToken);
        (uint256 reserve0, uint reserve1,) = IUniswapV2Pair(_tensWETHPair).getReserves();
        (wethReserves, tensReserves) = token0 == _tensToken ? (reserve1, reserve0) : (reserve0, reserve1);
    }

}