// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import "./ERC20.sol";
import "./Ownable.sol";


// Toil is used to create multiple uniswap V3 positions and allow for fee collections based on market volume and volatility across them
//By creating 3 positions with each paired token the system allows for curvation of token value over time
//With the ability of creating new V3 postions with unpaired token this consistently allows for liquidity to always be present with in

//No webpage
//No defined image atm
//No community created from developer
//TOIL stands for "The One I Love"
//Through toil we are complete...

interface Router {
	function factory() external view returns (address);
	function positionManager() external view returns (address);
	function WETH9() external view returns (address);
}

interface Factory {
	function createPool(address tokenA, address tokenB, uint24 fee) external returns (address);
}

interface Pool {
	function initialize(uint160 _sqrtPriceX96) external;
}

interface Params {
	struct MintParams {
		address token0;
		address token1;
		uint24 fee;
		int24 tickLower;
		int24 tickUpper;
		uint256 amount0Desired;
		uint256 amount1Desired;
		uint256 amount0Min;
		uint256 amount1Min;
		address recipient;
		uint256 deadline;
	}
	struct CollectParams {
		uint256 tokenId;
		address recipient;
		uint128 amount0Max;
		uint128 amount1Max;
	}

}

interface PositionManager is Params {
	function mint(MintParams calldata) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
	function collect(CollectParams calldata) external payable returns (uint256 amount0, uint256 amount1);
	
	function positions(uint256) external view returns (uint96 nonce, address operator, address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, uint128 tokensOwed0, uint128 tokensOwed1);
}


contract TickMath {

	int24 internal constant MIN_TICK = -887272;
	int24 internal constant MAX_TICK = -MIN_TICK;
	uint160 internal constant MIN_SQRT_RATIO = 4295128739;
	uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;


	function _getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
		unchecked {
			uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
			require(absTick <= uint256(int256(MAX_TICK)), 'T');

			uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
			if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
			if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
			if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
			if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
			if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
			if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
			if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
			if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
			if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
			if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
			if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
			if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
			if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
			if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
			if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
			if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
			if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
			if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
			if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

			if (tick > 0) ratio = type(uint256).max / ratio;

			sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
		}
	}

	function _getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
		unchecked {
			require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
			uint256 ratio = uint256(sqrtPriceX96) << 32;

			uint256 r = ratio;
			uint256 msb = 0;

			assembly {
				let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
				msb := or(msb, f)
				r := shr(f, r)
			}
			assembly {
				let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
				msb := or(msb, f)
				r := shr(f, r)
			}
			assembly {
				let f := shl(5, gt(r, 0xFFFFFFFF))
				msb := or(msb, f)
				r := shr(f, r)
			}
			assembly {
				let f := shl(4, gt(r, 0xFFFF))
				msb := or(msb, f)
				r := shr(f, r)
			}
			assembly {
				let f := shl(3, gt(r, 0xFF))
				msb := or(msb, f)
				r := shr(f, r)
			}
			assembly {
				let f := shl(2, gt(r, 0xF))
				msb := or(msb, f)
				r := shr(f, r)
			}
			assembly {
				let f := shl(1, gt(r, 0x3))
				msb := or(msb, f)
				r := shr(f, r)
			}
			assembly {
				let f := gt(r, 0x1)
				msb := or(msb, f)
			}

			if (msb >= 128) r = ratio >> (msb - 127);
			else r = ratio << (127 - msb);

			int256 log_2 = (int256(msb) - 128) << 64;

			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(63, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(62, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(61, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(60, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(59, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(58, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(57, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(56, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(55, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(54, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(53, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(52, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(51, f))
				r := shr(f, r)
			}
			assembly {
				r := shr(127, mul(r, r))
				let f := shr(128, r)
				log_2 := or(log_2, shl(50, f))
			}

			int256 log_sqrt10001 = log_2 * 255738958999603826347141;

			int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
			int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

			tick = tickLow == tickHi ? tickLow : _getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
		}
	}

	function _sqrt(uint256 _n) internal pure returns (uint256 result) {
		unchecked {
			uint256 _tmp = (_n + 1) / 2;
			result = _n;
			while (_tmp < result) {
				result = _tmp;
				_tmp = (_n / _tmp + _tmp) / 2;
			}
		}
	}

	function _getPriceAndTickFromValues(bool _weth0, uint256 _tokens, uint256 _weth) internal pure returns (uint160 price, int24 tick) {
		uint160 _tmpPrice = uint160(_sqrt(2**192 / (!_weth0 ? _tokens : _weth) * (_weth0 ? _tokens : _weth)));
		tick = _getTickAtSqrtRatio(_tmpPrice);
		tick = tick - (tick % 200);
		price = _getSqrtRatioAtTick(tick);
	}
}

contract Token is ERC20, Ownable, TickMath, Params{
    

    Router public constant ROUTER =Router(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);

    uint256[] initialMCs;
    uint256[]  midMCs;
    uint256[] upperMCs;
    uint256 tokenSupply;
    address[] pairedTokens;

    uint256[] private liquidityPositions;

    address[] public pools;

    uint256 interval = 1 weeks;
    uint256 nextClaim;

    mapping(address => bool) public usedTokens;

    constructor(
        uint256[] memory _initialMCs,
        uint256[] memory _midMCs,
        uint256[] memory _upperMCs,
        uint256 _tokenSupply,
        address[] memory _pairedTokens

        ) ERC20('Toil','Toil'){

            require(_initialMCs.length == _midMCs.length && _midMCs.length == _upperMCs.length && _upperMCs.length == _pairedTokens.length, "Arrays not equal length");
            tokenSupply = _tokenSupply;
            address _this = address(this);



            for(uint x =0; x< _initialMCs.length; x++){
                address token = _pairedTokens[x];
		        (uint160 _initialSqrtPrice, ) = _getPriceAndTickFromValues(token < _this, _tokenSupply, _initialMCs[x]);//gets price
		
                pools.push( Factory(ROUTER.factory()).createPool(_this, token, 10000));//starts pool with 1% fee
		        Pool(pools[x]).initialize(_initialSqrtPrice); //Set the pool pricing, needs looked into

                //nonfungiblePositionManager = _nonfungiblePositionManager;
                nextClaim = block.timestamp + interval;

                require(_upperMCs[x] > _midMCs[x] && _midMCs[x] > _initialMCs[x], "Fix MC");
                initialMCs.push(_initialMCs[x]);
                midMCs.push(_midMCs[x]);
                upperMCs.push(_upperMCs[x]);

                pairedTokens.push(token);

            }

    }

      function initialize() external {
       
		require(totalSupply() == 0);

        
        _mint(address(this), tokenSupply);

		uint256 amount = tokenSupply/pairedTokens.length;
        for(uint i = 0; i < pairedTokens.length; i++){
			if(totalSupply() >= amount){
				_threePositions(initialMCs[i], midMCs[i], upperMCs[i], tokenSupply/pairedTokens.length, pairedTokens[i]);
			}
        }
		
	}

    function _threePositions(uint256 lower, uint256 mid, uint256 up, uint256 supply, address _token) internal{
		address _this = address(this);

		bool _token0 = _token < _this; //token0 is the lesser address()
        nextClaim = block.timestamp + interval;

		( , int24 _minTick) = _getPriceAndTickFromValues(_token0, tokenSupply, lower);
        (, int24 _midTick) = _getPriceAndTickFromValues(_token0, tokenSupply, mid);
		( , int24 _maxTick) = _getPriceAndTickFromValues(_token0, tokenSupply, up);

        uint256 _concentratedTokens = 20 * supply / 100;

        //First Step blue line
        liquidityPositions.push(_createNewPosition(_token, _this, 
          _token0,
          _token0 ? _minTick - 200 : _minTick,//LowerTick
         !_token0 ? _minTick + 200 : _minTick,//UpperTick
         _concentratedTokens
         ));
		//Second step orange curve
        liquidityPositions.push(_createNewPosition(_token, _this, 
          _token0,
          _token0 ? _midTick: _minTick + 200,//LowerTick
         !_token0 ? _midTick: _minTick - 200,//UpperTick
         (3*_concentratedTokens)
         ));
        //Third Step blowoff
        liquidityPositions.push(_createNewPosition(_token, _this, 
          _token0,
          _token0 ? _maxTick : _midTick,//LowerTick
         !_token0 ? _maxTick : _midTick,//UpperTick
         _concentratedTokens > balanceOf(_this)? balanceOf(_this) : _concentratedTokens
         ));

    }

    function _createNewPosition(address _token, address _this, bool _token0, int24 _tickLower, int24 _tickUpper, uint256 amount) internal returns(uint256 a){
        PositionManager _pm = PositionManager(ROUTER.positionManager());
        _approve(_this, address(_pm), amount);

        (a, , , ) = _pm.mint(MintParams({
			token0: _token0 ? _token : _this,
			token1: !_token0 ? _token : _this,
			fee: 10000,
			tickLower: _tickLower,
			tickUpper: _tickUpper,
			amount0Desired: _token0 ? 0 : amount,
			amount1Desired: !_token0 ? 0 : amount,
			amount0Min: 0,
			amount1Min: 0,
			recipient: _this,
			deadline: block.timestamp
		}));
    } 

    function createNewPosition(address token, uint256 lowerMC, uint256 midMC, uint256 upperMC)public onlyOwner{


        require(upperMC > midMC && midMC > lowerMC, "Fix MC");
        require(!usedTokens[token], "Token Already Used");
        
        address _this = address(this);

        (uint160 _initialSqrtPrice, ) = _getPriceAndTickFromValues(token < _this, tokenSupply , lowerMC);
        address npool = Factory(ROUTER.factory()).createPool(_this, token, 10000);//starts pool with 1% fee
		Pool(npool).initialize(_initialSqrtPrice); //Set the pool pricing, needs looked into
        pools.push(npool);

        _threePositions(lowerMC, midMC, upperMC, balanceOf(_this), token);

        pairedTokens.push(token);

    }

    function claimFees()public{
        require(nextClaim < block.timestamp, "Not enough time has passed");
        nextClaim = block.timestamp + interval;
        _claimFees();
        for(uint i =0; i < pairedTokens.length;){
            IERC20 t = IERC20(pairedTokens[i]);
            uint256 _amount = t.balanceOf(address(this));
            if(_amount > 0){
                t.transfer(msg.sender, _amount/50);
                t.transfer(owner(), t.balanceOf(address(this)));
            } 
            unchecked{i++;}
        }

        uint256 amount = address(this).balance;
        if(amount >50){
            address payable m = payable(msg.sender);
            bool f;
            f = m.send(amount/50);
            address payable o = payable(owner());
            f=o.send(address(this).balance);

        }

    }

    function _claimFees()internal{


        for(uint i = 0; i < liquidityPositions.length;){
			_claim(liquidityPositions[i]);
            unchecked{i++;}
        }
    }

	function _claim(uint256 pos)internal{

        PositionManager _pm = PositionManager(ROUTER.positionManager());
        uint128 Uint128Max = type(uint128).max;
        _pm.collect(CollectParams({
                tokenId: pos,
                recipient: address(this),
                amount0Max: Uint128Max,
                amount1Max: Uint128Max
        }));

	}

    function claim()external onlyOwner{
        _claimFees();
        nextClaim = block.timestamp + interval;
        for(uint i =0; i < pairedTokens.length;){
            IERC20 t = IERC20(pairedTokens[i]);
            if(t.balanceOf(address(this)) > 0) {
                t.transfer(msg.sender, t.balanceOf(address(this)));
            }
            unchecked{i++;}
        }



        uint256 amount = address(this).balance;
        if(amount >0){
            address payable o = payable(owner());
            bool f;
            f = o.send(amount);
        }
    }

    receive() external payable {}

	function liquidityPositons()external view returns(uint256[] memory){

		return liquidityPositions;
	}

	function claimSpecficPositions(uint256[] memory positions)external{

		for(uint i =0; i < positions.length;){
			_claim(positions[i]);
			unchecked{i++;}
		}

	} 

	function erc20Withdrawal(address[] memory tokens) external onlyOwner{

		address _this = address(this);
		for(uint i =0; i < tokens.length;){
			require(tokens[i] != _this, "Cannot withdraw contract token");
			IERC20 t = IERC20(tokens[i]);
			t.transfer(msg.sender, t.balanceOf(_this));
			unchecked{i++;}
		}
        uint256 amount = address(this).balance;
        if(amount >0){
            address payable o = payable(owner());
            bool f;
            f = o.send(amount);
        }
	}

	function pairedTokensView() public view returns(address[]memory ){
		return pairedTokens;
	}

}