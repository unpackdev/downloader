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
import "./IProfitStrategy.sol";

import "./GatlingStorage.sol";



contract StakeGatlingDelegate is GatlingStorage, Ownable, IStakeGatling, MasterCaller {
    using SafeERC20 for IERC20;
    using SafeMath for uint256; 
    function setMatchPair(address _matchPair) public onlyOwner() {
        matchPair = _matchPair;
        transferMastership(_matchPair);
    }

    function setUpdatesRule(uint256 _updatesPerDay, uint256  _updatesMin) public onlyOwner() {
        updatesPerDay = _updatesPerDay;
        updatesMin = _updatesMin;
    }

    function setRouter(address _v2Router ) public onlyOwner() {
        if(v2Router != _v2Router) {
            v2Router = _v2Router;
        }
    }

    function setProfitStrategy(address _profitStrategy) public onlyOwner() {

        if(profitStrategy != address(0)) {
            IProfitStrategy(profitStrategy).earn();
            uint256 _minedAmount = IProfitStrategy(profitStrategy).earnTokenBalance(address(this));
            if (_minedAmount > 0) {
                _execReprofit();   
            }
            //retrieve LP and Token;
            IProfitStrategy(profitStrategy).exit();
        }
        profitStrategy = _profitStrategy;
        if(_profitStrategy != address(0)) {
            //Stake to new profitStrategy
            uint256 _amount =  IUniswapV2Pair(stakeLpPair).balanceOf(address(this));
            if(_amount > 0) {
                TransferHelper.safeTransfer(stakeLpPair, _profitStrategy, _amount);
                IProfitStrategy(profitStrategy).stake(_amount);
            }
        }
        
        emit ProfitStrategyEvent(_profitStrategy);
    }

    function setRouterPath(uint256 _tokenSide, address[] calldata path ) public onlyOwner() {

        if(_tokenSide == 0 && routerPath0.length > 0) {
            delete routerPath0;
        } 
        if(_tokenSide == 1 && routerPath1.length > 0) {
            delete routerPath1;
        }
        _approvePath(path, _tokenSide);
    }

    function _approvePath( address[] calldata path, uint256 _tokenSide) private {

        address[] storage routerPath = _tokenSide == 0? routerPath0: routerPath1;

        for (uint i=0; i< path.length; i++) {

            address _erc20Token = path[i];
            routerPath.push(_erc20Token);
            _approveWithCheck(_erc20Token, v2Router);
        }
    }
    function _approveWithCheck(address _erc20Token, address _spender) private  {
        if( IERC20(_erc20Token).allowance(address(this), _spender) == 0 ) {
            TransferHelper.safeApprove(_erc20Token, _spender, ~uint256(0));
        }
    }

    function stake(uint256 _amount) external override onlyMasterCaller() {

        if(profitStrategy != address(0)) {
            updateRate();
            IProfitStrategy(profitStrategy).stake(_amount);
        }
        totalAmount = totalAmount.add(_amount);
    }

    function withdraw(uint256 _amount) public override onlyMasterCaller() {

        if(profitStrategy != address(0)) {
            updateRate();
            if(_amount > 0) {
                IProfitStrategy(profitStrategy).withdraw(_amount);
            }
        }
        if(_amount > 0 ) {

            TransferHelper.safeTransfer(stakeLpPair, address(matchPair),_amount);
            totalAmount = totalAmount.sub(_amount);
        }
        
    }
    function burn(address _to, uint256 _amount) external override returns (uint256 amount0, uint256 amount1) {
        if(profitStrategy != address(0)) {
            updateRate();
            if(_amount > totalAmount) {
                _amount = totalAmount;
            }
            if(_amount > 0) {
                (amount0, amount1) = IProfitStrategy(profitStrategy).burn(_to, _amount);
                totalAmount = totalAmount.sub(_amount);
            }
        }else {
            totalAmount = totalAmount.sub(_amount);
            TransferHelper.safeTransfer(stakeLpPair, stakeLpPair, _amount);
            (amount0, amount1) =  IUniswapV2Pair(stakeLpPair).burn(_to);
        }
    }

    function updateRate() private {
        if(now.sub(profitRateUpdateTime).mul(updatesPerDay) >= (1 days)) {
            // get earned
            //todo 
            uint256 pendingEarn = IProfitStrategy(profitStrategy).earnPending(profitStrategy);

            if( pendingEarn > updatesMin) {
                IProfitStrategy(profitStrategy).earn();
                _execReprofit();
            }
        }
    }

    function _execReprofit() private {
        // 2. sell earnToken to TokenA/ TokenB
        sellEarn2TokenTwice();
        // 3. mint LP
        uint256 liquidity = mintLP();

        // 4. update contract rate
        if(liquidity > 0) {
            _presentRate = _presentRate.mul(totalAmount.add(liquidity)).div(totalAmount);
            totalAmount = totalAmount.add(liquidity);
            IProfitStrategy(profitStrategy).stake(liquidity);
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

    function sellEarn2TokenTwice() private{

        (address _token0, address _token1) = (IUniswapV2Pair(stakeLpPair).token0(), IUniswapV2Pair(stakeLpPair).token1());

        uint256 _minedAmount = IProfitStrategy(profitStrategy).earnTokenBalance(address(this));
        address earnToken = IProfitStrategy(profitStrategy).earnToken();
        if(_token0 != earnToken) {
            execSell(_minedAmount.div(2), 0);
        }
        if(_token1 != earnToken) {
            execSell(_minedAmount.div(2), 1);
        }
    }

    function execSell(uint256 _amount, uint256 _tokenSide) private {
        
        address[] memory path = _tokenSide == 0? routerPath0 : routerPath1;
        IUniswapV2Router01(v2Router).swapExactTokensForTokens( _amount, 0, path, address(this), now.add(60000) );
    }

    /**
     *  mintLP
     */
    function mintLP() private returns (uint256 liquidity) {

        (address _token0, address _token1) = (IUniswapV2Pair(stakeLpPair).token0(), IUniswapV2Pair(stakeLpPair).token1());
        address _addrThis = address(this);

        uint balance0 = IERC20(_token0).balanceOf(_addrThis);
        uint balance1 = IERC20(_token1).balanceOf(_addrThis);


        if(balance0 > 0 && balance1 > 0) {
            //recalculate Amount0 Amoutn1 via TransactionHelper
            (uint amount0, uint amount1)  =  getPairAmount(balance0, balance1);
            TransferHelper.safeTransfer(_token0, stakeLpPair, amount0);
            TransferHelper.safeTransfer(_token1, stakeLpPair, amount1);
            //mint
            liquidity = IUniswapV2Pair(stakeLpPair).mint(profitStrategy);
        }
    }

    /**  View Function */
    function presentRate() public view override returns (uint256) {
        return _presentRate;
    }

    function reprofitCountAverage() public view returns (uint256) {
        return reprofitCountTotal.div(now.sub(createAt).div(1 days));
    }

    function getPairAmount(
        uint amountADesired,
        uint amountBDesired  ) public view returns ( uint amountA, uint amountB) {
            
        (uint reserveA, uint reserveB,) = IUniswapV2Pair(stakeLpPair).getReserves();

        uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
        if (amountBOptimal <= amountBDesired) {
            (amountA, amountB) = (amountADesired, amountBOptimal);
        } else {
            uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
            assert(amountAOptimal <= amountADesired);
            (amountA, amountB) = (amountAOptimal, amountBDesired);
        }
    }

    function totalLp() public view returns (uint256 balance) {
        balance = IProfitStrategy(profitStrategy).balanceOfLP(profitStrategy);
    }

    function totalToken() public view override returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = IUniswapV2Pair(stakeLpPair).getReserves();

        uint256 liquidity = totalAmount;
        uint256 _totalSupply = IUniswapV2Pair(stakeLpPair).totalSupply();

        amount0 = liquidity.mul(_reserve0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(_reserve1) / _totalSupply;
    }

    function lpStakeDst() public view override returns (address) {
        address _profitStrategy = profitStrategy;
        return _profitStrategy == address(0)? address(this) : _profitStrategy;
    }

    function totalLPAmount() public view override returns (uint256) {
        return totalAmount;
    }
}