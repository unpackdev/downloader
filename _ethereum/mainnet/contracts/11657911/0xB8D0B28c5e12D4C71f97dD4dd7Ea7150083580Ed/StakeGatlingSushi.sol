pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

import "./IUniswapV2Pair.sol";
import "./UniswapV2Library.sol";
import "./TransferHelper.sol";

import "./MasterCaller.sol";
import "./IUniswapV2Router01.sol";
import "./IStakingRewards.sol";
import "./IStakeGatling.sol";



interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);
}

/**
 * Earn Sushi 
 * Deposit LP to  SushiMasterChef, and calucator via pendingSushi(address), Earn via desposit(0)
 */
contract StakeGatlingSushi is Ownable, IStakeGatling, MasterCaller {
    using SafeERC20 for IERC20;
    using SafeMath for uint256; 

    //Sushi MasterChef
    IMasterChef sushiChef;
    // SushiP ([usdt-eth].part)
    IUniswapV2Pair  stakeLpPair;
    //sushiToken
    address public sushiToken;
    // MatchPair.address
    address public matchPair;
    // Uniswsap V2Router
    address public v2Router;

    uint256 public totalAmount;
    uint256 public _presentRate = 1e18;
    uint256 public _profitRateDenominator = 1e18;

    //Update every half day by default
    uint256 public updatesPerDay = 2;
    uint256 public updatesMin;

    uint256 profitRateUpdateTime;

    uint256 pid;

    struct ProfitRateHis {
        uint256 day;
        uint256 profitRateHis;
    }
    ProfitRateHis[] public profitRateHis;
    mapping(uint256 => uint256) public reprofitCount;

    constructor ( address _pair) public {
        stakeLpPair = IUniswapV2Pair(_pair);
    }

    function initApprove() public {
        TransferHelper.safeApprove(address(stakeLpPair), address(sushiChef), ~uint256(0));
    }
    
    function setStakeToken(address _stakeToken, address _earnToken ) public onlyOwner() {
        require( address(sushiChef) == address(0), "Only set once");
        sushiChef =  IMasterChef(_stakeToken);
        sushiToken = _earnToken;

        TransferHelper.safeApprove(address(stakeLpPair), address(sushiChef), ~uint256(0));
    }

    function setMatchPair(address _matchPair , uint256 _pid) public onlyOwner() {
        matchPair = _matchPair;
        pid = _pid;
    }

    function setUpdatesRule(uint256 _updatesPerDay, uint256  _updatesMin) public onlyOwner() {
        updatesPerDay = _updatesPerDay;
        updatesMin = _updatesMin;
    }

    function setRouterPaths(address _v2Router) public onlyOwner() {
        v2Router = _v2Router;
        //approve
        TransferHelper.safeApprove(sushiToken, v2Router, ~uint256(0));
        TransferHelper.safeApprove(stakeLpPair.token0(), v2Router, ~uint256(0));
        TransferHelper.safeApprove(stakeLpPair.token1(), v2Router, ~uint256(0));
    }

    function stake(uint256 _amount) external override onlyMasterCaller() {
        
        if(address(sushiChef) != address(0)) {
            updateRate();
            sushiChef.deposit( pid, _amount);
        }
        totalAmount = totalAmount.add(_amount);
    }

    function withdraw(uint256 _amount) public override onlyMasterCaller() {
        if(address(sushiChef) != address(0)) {
            updateRate();
            sushiChef.withdraw(pid, _amount);
        }
        
        if(_amount > 0 ) {

            TransferHelper.safeTransfer(address(stakeLpPair), address(matchPair),_amount);
            totalAmount = totalAmount.sub(_amount);
        }
        
    }
    function updateRate() private {
        // 1. get earned
        uint256 earnAmount = sushiChef.pendingSushi( pid, address(this));


        if( earnAmount > updatesMin && (now.sub(profitRateUpdateTime).mul(updatesPerDay) >= (1 days)) ) {
            earnToken();
            sellEarn2TokenTwice();
            uint256 liquidity = mintLP();

            // 5. update contract rate
            _presentRate = _presentRate.mul(totalAmount.add(liquidity)).div(totalAmount);

            totalAmount = totalAmount.add(liquidity);
            if(liquidity > 0) {
                sushiChef.deposit(pid, liquidity);
            }


            uint today = now.div(1 days).add(1);
            mapping(uint256 => uint256) storage  _reprofitCount = reprofitCount;

            if(_reprofitCount[today] == 0) { // daliy first calculate
                profitRateHis.push(ProfitRateHis(today, _presentRate ));
            }
            _reprofitCount[today] = _reprofitCount[today] + 1;
            
            profitRateUpdateTime = now;
        }
    }

    function earnToken() private {
        sushiChef.deposit(pid, 0);
    }

    function currentProfitRate() public view returns (uint256, uint256) {

        ProfitRateHis[]  storage _profitRateHis = profitRateHis;
        uint256 length = _profitRateHis.length;
        if(length == 0) {
            return (0, 0);
        }else if(length == 1) {
            return (_profitRateHis[0].profitRateHis, 1);
        }else {
            uint interval = _profitRateHis[length-1].day - _profitRateHis[length-2].day;
            return (_profitRateHis[length-1].profitRateHis.mul(1e18).div(_profitRateHis[length-2].profitRateHis), interval);
        }
    }

    function presentRate() public view override returns (uint256) {
        return _presentRate;
    }

    function sellEarn2TokenTwice() private  {

        (address _token0, address _token1) = (stakeLpPair.token0(), stakeLpPair.token1());
        // (uint reserve0, uint reserve1, ) = stakeLpPair.getReserves();
        uint256 earnAmount = IERC20(sushiToken).balanceOf(address(this));

        // address[] memory path = new address[](2);
        // path[0] = sushiToken;
        // path[1] = _token0;
        // IUniswapV2Router01(v2Router).swapExactTokensForTokens( earnAmount.div(2), 0, path, address(this), now.add(60000) );
    
        // address[] memory path1 = new address[](2);
        // path1[0] = sushiToken;
        // path1[1] = _token1;
        // IUniswapV2Router01(v2Router).swapExactTokensForTokens( earnAmount.div(2), 0, path1, address(this), now.add(60000) );

        execSell(earnAmount.div(2), _token0);
        execSell(earnAmount.div(2), _token1);
    }

    function execSell(uint256 _amount, address expectToken) private {
        if( expectToken != sushiToken ) {
            address[] memory path1 = new address[](2);
            path1[0] = sushiToken;
            path1[1] = expectToken;
            IUniswapV2Router01(v2Router).swapExactTokensForTokens( _amount, 0, path1, address(this), now.add(60000) );
        }
    }

    /**
     *  mintLP
     */
    function mintLP() private returns (uint256 liquidity) {

        (address _token0, address _token1) = (stakeLpPair.token0(), stakeLpPair.token1());
        address _addrThis = address(this);

        (uint reserve0, uint reserve1, ) = stakeLpPair.getReserves();

        

        uint balance0 = IERC20(_token0).balanceOf(_addrThis);
        uint balance1 = IERC20(_token1).balanceOf(_addrThis);


       
        if(balance0 > 0 && balance1 > 0) {
            //recalculate Amount0 Amoutn1 via TransactionHelper
            (uint amount0, uint amount1)  =  getPairAmount(balance0, balance1);




            TransferHelper.safeTransfer(_token0, address(stakeLpPair), amount0);
            TransferHelper.safeTransfer(_token1, address(stakeLpPair), amount1);
            
            //mint
            liquidity = stakeLpPair.mint(_addrThis);
        }
    }

    function getPairAmount(
        uint amountADesired,
        uint amountBDesired  ) public view returns ( uint amountA, uint amountB) {
            
        (uint reserveA, uint reserveB,) = stakeLpPair.getReserves();

        uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
        if (amountBOptimal <= amountBDesired) {
            (amountA, amountB) = (amountADesired, amountBOptimal);
        } else {
            uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
            assert(amountAOptimal <= amountADesired);
            (amountA, amountB) = (amountAOptimal, amountBDesired);
        }
    }

    function profitRateDenominator() public override view returns(uint256) {
        return _profitRateDenominator;
    }

    function getAmountOIn( uint256 _amountIn, uint256 _reserveIn, uint256 _reserveOut ) private pure returns (uint256)  {
            return  _amountIn.mul( _reserveIn.add(_reserveOut)).div( _reserveIn.mul(2).add(_reserveOut).sub(_amountIn) ) ;
    }

    function totalLp() public view returns (uint256) {
        return totalAmount;
    }

    function totalToken() public view override returns (uint256 amount0, uint256 amount1) {
        //
        (uint112 _reserve0, uint112 _reserve1,) = stakeLpPair.getReserves();
        uint256 liquidity = totalAmount;
        uint256 _totalSupply = stakeLpPair.totalSupply();

        amount0 = liquidity.mul(_reserve0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(_reserve1) / _totalSupply;
    }

}