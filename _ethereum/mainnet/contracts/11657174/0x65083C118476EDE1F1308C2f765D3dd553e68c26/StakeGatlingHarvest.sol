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



/**
 * Earn FARM 
 */
contract StakeGatlingHarvest is Ownable, IStakeGatling, MasterCaller {
    using SafeERC20 for IERC20;

    using SafeMath for uint256; 

    //Uniswap StakeToken
    IStakingRewards stakeToken;
    // UniLP ([usdt-eth].part)
    IUniswapV2Pair  stakeLpPair;
    //earnToken
    address public earnToken;
    // MatchPair.address
    address public matchPair;
    // Uniswsap V2Router
    address public v2Router;

    uint256 public totalAmount;
    uint256 public _presentRate = 1e18;
    uint256 public _profitRateDenominator = 1e18;

    uint256 public reprofitCountTotal;
    uint256 public createAt;
    
    //Update every half day by default
    uint256 public updatesPerDay = 2;
    uint256 public updatesMin;

    uint256 profitRateUpdateTime;

    struct ProfitRateHis {
        uint256 day;
        uint256 profitRateHis;
    }
    ProfitRateHis[] public profitRateHis;
    mapping(uint256 => uint256) public reprofitCount;

    constructor ( address _stakeToken, address _pair, address _earbToken) public {
        stakeToken =  IStakingRewards(_stakeToken);
        stakeLpPair = IUniswapV2Pair(_pair);
        earnToken = _earbToken;
        createAt = now;
    }

    function initApprove() public {
        TransferHelper.safeApprove(address(stakeLpPair), address(stakeToken), ~uint256(0));
    }
    
    function setMatchPair(address _matchPair) public onlyOwner() {
        matchPair = _matchPair;
    }

    function setUpdatesRule(uint256 _updatesPerDay, uint256  _updatesMin) public onlyOwner() {
        updatesPerDay = _updatesPerDay;
        updatesMin = _updatesMin;
    }

    function setRouterPaths(address _v2Router) public onlyOwner() {
        v2Router = _v2Router;

        //approve
        TransferHelper.safeApprove(earnToken, v2Router, ~uint256(0));
        TransferHelper.safeApprove(stakeLpPair.token0(), v2Router, ~uint256(0));
        TransferHelper.safeApprove(stakeLpPair.token1(), v2Router, ~uint256(0));
        
    }

    function stake(uint256 _amount) external override onlyMasterCaller() {
        updateRate();
        // todo stake mintLP
        // stake to earn
        stakeToken.stake(_amount);
        totalAmount = totalAmount.add(_amount);
    }

    function withdraw(uint256 _amount) public override onlyMasterCaller() {

        updateRate();
        if(_amount > 0 ) {
            stakeToken.withdraw(_amount);
            

            TransferHelper.safeTransfer(address(stakeLpPair), address(matchPair),_amount);
            totalAmount = totalAmount.sub(_amount);
        }
        
    }
    function updateRate() private {
        // 1. get earned
        earnUNI();
        uint256 _earnAmount = IERC20(earnToken).balanceOf(address(this));


        //update per Half Day
        //todo 
        if( _earnAmount > updatesMin && (now.sub(profitRateUpdateTime).mul(updatesPerDay) >= (1 days)) ) {
            // 2. sell earn to TokenA/ TokenB
            sellUNI2TokenTwice();
            // 3. mint LP
            uint256 liquidity = mintLP();


            // 4. update contract rate
            _presentRate = _presentRate.mul(totalAmount.add(liquidity)).div(totalAmount);

            totalAmount = totalAmount.add(liquidity);
            if(liquidity > 0) {
                stakeToken.stake(liquidity);
            }


            uint today = now.div(1 days).add(1);

            mapping(uint256 => uint256) storage  _reprofitCount = reprofitCount;

            if(_reprofitCount[today] == 0) { // daliy first calculate
                profitRateHis.push(ProfitRateHis(today, _presentRate ));
            }
            _reprofitCount[today] = _reprofitCount[today] + 1;
            reprofitCountTotal = reprofitCountTotal +1;
            
            profitRateUpdateTime = now;
        }
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

    function reprofitCountAverage() public view returns (uint256) {
        return reprofitCountTotal.div(now.sub(createAt).div(1 days));
    }

    function sellUNI2TokenTwice() private returns (address _tokenAddress) {

        (address _token0, address _token1) = (stakeLpPair.token0(), stakeLpPair.token1());

        uint256 _earnAmount = IERC20(earnToken).balanceOf(address(this));


        // address[] memory path = new address[](2);
        // path[0] = earnToken;
        // path[1] = _token0;
        // IUniswapV2Router01(v2Router).swapExactTokensForTokens( _earnAmount.div(2), 0, path, address(this), now.add(60000) );
    
        // address[] memory path1 = new address[](2);
        // path1[0] = earnToken;
        // path1[1] = _token1;
        // IUniswapV2Router01(v2Router).swapExactTokensForTokens( _earnAmount.div(2), 0, path1, address(this), now.add(60000) );

        execSell(_earnAmount.div(2), _token0);
        execSell(_earnAmount.div(2), _token1);

    }

    function execSell(uint256 _amount, address expectToken) private {
        if( expectToken != earnToken ) {
            address[] memory path1 = new address[](2);
            path1[0] = earnToken;
            path1[1] = expectToken;
            IUniswapV2Router01(v2Router).swapExactTokensForTokens( _amount, 0, path1, address(this), now.add(60000) );
        }
    }

    function earnUNI() private returns (int256) {
        stakeToken.getReward();
    }

    /**
     *  mintLP
     */
    function mintLP() private returns (uint256 liquidity) {

        (address _token0, address _token1) = (stakeLpPair.token0(), stakeLpPair.token1());
        address _addrThis = address(this);

        // (uint reserve0, uint reserve1, ) = stakeLpPair.getReserves();
        //

        uint balance0 = IERC20(_token0).balanceOf(_addrThis);
        uint balance1 = IERC20(_token1).balanceOf(_addrThis);


       
        if(balance0 > 0 && balance1 > 0) {
            //recalculate Amount0 Amoutn1 via TransactionHelper
            (uint amount0, uint amount1)  =  getPairAmount(balance0, balance1);

            //


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

    function getAmountOIn( uint256 _amountIn, uint256 _reserveIn, uint256 _reserveOut ) private returns (uint256)  {
            return  _amountIn.mul( _reserveIn.add(_reserveOut)).div( _reserveIn.mul(2).add(_reserveOut).sub(_amountIn) ) ;
    }

    function totalLp() public view returns (uint256 balance) {
        balance = stakeToken.balanceOf(address(this));
    }

    function totalToken() public view override returns (uint256 amount0, uint256 amount1) {
        //
        (uint112 _reserve0, uint112 _reserve1,) = stakeLpPair.getReserves();
        uint256 liquidity = stakeToken.balanceOf(address(this));
        uint256 _totalSupply = stakeLpPair.totalSupply();

        amount0 = liquidity.mul(_reserve0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(_reserve1) / _totalSupply;
    }

}