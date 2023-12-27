// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Created with Bossman's Bakery (bakery.mullet.capital)!

interface Callable {
	function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
}

interface Router {
	struct ExactInputSingleParams {
		address tokenIn;
		address tokenOut;
		uint24 fee;
		address recipient;
		uint256 amountIn;
		uint256 amountOutMinimum;
		uint160 sqrtPriceLimitX96;
	}
	function factory() external view returns (address);
	function positionManager() external view returns (address);
	function WETH9() external view returns (address);
	function exactInputSingle(ExactInputSingleParams calldata) external payable returns (uint256);
}

interface Factory {
	function createPool(address _tokenA, address _tokenB, uint24 _fee) external returns (address);
}

interface Pool {
	function initialize(uint160 _sqrtPriceX96) external;
}

interface PositionManager {
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
	function mint(MintParams calldata) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
	function collect(CollectParams calldata) external payable returns (uint256 amount0, uint256 amount1);
}

interface ERC20 {
	function balanceOf(address) external view returns (uint256);
	function transfer(address, uint256) external returns (bool);
}

interface WETH is ERC20 {
	function withdraw(uint256) external;
}


contract Team {

	Router constant private ROUTER = Router(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);

	struct Share {
		address payable user;
		uint256 shares;
	}
	Share[] public shares;
	uint256 public totalShares;
	ERC20 public token;


	function initialize(address _creator) external {
		require(totalShares == 0);
		token = ERC20(msg.sender);
		_addShare(_creator, 10);
		_addShare(0xe6c791FBd46dB3f4EdA5f7Bb76474F4FA530733E, 6);
		_addShare(0x12fe289b7588dE4ee1f1392Ce086be100f7165ed, 3);
		_addShare(0xc28C9da0F8a500DFfC16Ff09a3DD1Cc4c530D346, 1);
	}

	receive() external payable {}

	function withdrawETH() public {
		uint256 _balance = address(this).balance;
		if (_balance > 0) {
			for (uint256 i = 0; i < shares.length; i++) {
				Share memory _share = shares[i];
				!_share.user.send(_balance * _share.shares / totalShares);
			}
		}
	}

	function withdrawToken(ERC20 _token) public {
		WETH _weth = WETH(ROUTER.WETH9());
		if (address(_token) == address(_weth)) {
			_weth.withdraw(_weth.balanceOf(address(this)));
			withdrawETH();
		} else {
			uint256 _balance = _token.balanceOf(address(this));
			if (_balance > 0) {
				for (uint256 i = 0; i < shares.length; i++) {
					Share memory _share = shares[i];
					_token.transfer(_share.user, _balance * _share.shares / totalShares);
				}
			}
		}
	}

	function withdrawWETH() public {
		withdrawToken(ERC20(ROUTER.WETH9()));
	}

	function withdrawFees() external {
		withdrawWETH();
		withdrawToken(token);
	}


	function _addShare(address _user, uint256 _shares) internal {
		shares.push(Share(payable(_user), _shares));
		totalShares += _shares;
	}
}


contract Token {

	uint256 constant private UINT_MAX = type(uint256).max;
	uint128 constant private UINT128_MAX = type(uint128).max;
	uint256 constant private MAX_NAME_LENGTH = 32;
	uint256 constant private MIN_SUPPLY = 1e16; // 0.01 tokens
	uint256 constant private MAX_SUPPLY = 1e33; // 1 quadrillion tokens
	uint256 constant private PERCENT_PRECISION = 1000; // 1 = 0.1%
	uint256 constant private MAX_TIME_LIMIT = 24 hours;
	Router constant private ROUTER = Router(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);

	int24 constant internal MIN_TICK = -887272;
	int24 constant internal MAX_TICK = -MIN_TICK;
	uint160 constant internal MIN_SQRT_RATIO = 4295128739;
	uint160 constant internal MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

	string public name;
	string public symbol;
	uint8 constant public decimals = 18;

	string constant public source = "Created with Bossman's Bakery (bakery.mullet.capital)!";


	struct User {
		uint256 balance;
		mapping(address => uint256) allowance;
	}

	struct Info {
		bool locked;
		Team team;
		address pool;
		address creator;
		uint256 totalSupply;
		uint256 initialMarketCap;
		uint256 upperMarketCap;
		uint256 concentratedPercent;
		uint256 creatorFee;
		uint256 transferLimit;
		uint256 transferLimitEnd;
		mapping(address => User) users;
		uint256 positionId;
		string website;
		string twitter;
		string telegram;
		string discord;
		string additionalInfo;
	}
	Info private info;


	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);


	modifier _onlyCreator() {
		require(msg.sender == creator());
		_;
	}

	
	function lock() external {
		require(!info.locked);
		require(totalSupply() == 0);
		info.locked = true;
	}
	
	function initialize(address _creator, string memory _name, string memory _symbol, uint256 _totalSupply, uint256 _initialMarketCap, uint256 _upperMarketCap, uint256 _creatorFee, uint256 _transferLimit, uint256 _transferLimitTime) external payable {
		require(!info.locked);
		require(totalSupply() == 0);
		require(bytes(_name).length > 0 && bytes(_name).length <= MAX_NAME_LENGTH);
		require(bytes(_symbol).length > 0 && bytes(_symbol).length <= MAX_NAME_LENGTH);
		require(_totalSupply >= MIN_SUPPLY && _totalSupply <= MAX_SUPPLY);
		require(_initialMarketCap > 0 && _upperMarketCap > _initialMarketCap);
		require(_creatorFee <= PERCENT_PRECISION / 10);
		require(_transferLimitTime <= MAX_TIME_LIMIT);
		info.team = new Team();
		info.team.initialize(_creator);
		info.creator = _creator;
		name = _name;
		symbol = _symbol;
		info.totalSupply = _totalSupply;
		info.users[address(this)].balance = _totalSupply;
		emit Transfer(address(0x0), address(this), _totalSupply);
		info.initialMarketCap = _initialMarketCap;
		info.upperMarketCap = _upperMarketCap;
		info.creatorFee = _creatorFee;
		_createLP(_initialMarketCap, _upperMarketCap, _creatorFee);
		info.transferLimit = _transferLimit;
		info.transferLimitEnd = block.timestamp + _transferLimitTime;
	}

	function updateAll(string memory _website, string memory _twitter, string memory _telegram, string memory _discord, string memory _info) external _onlyCreator {
		info.website = _website;
		info.twitter = _twitter;
		info.telegram = _telegram;
		info.discord = _discord;
		info.additionalInfo = _info;
	}

	function updateWebsite(string memory _website) external _onlyCreator {
		info.website = _website;
	}

	function updateTwitter(string memory _twitter) external _onlyCreator {
		info.twitter = _twitter;
	}

	function updateTelegram(string memory _telegram) external _onlyCreator {
		info.telegram = _telegram;
	}

	function updateDiscord(string memory _discord) external _onlyCreator {
		info.discord = _discord;
	}

	function updateInfo(string memory _info) external _onlyCreator {
		info.additionalInfo = _info;
	}

	function collectTradingFees() external {
		PositionManager _pm = PositionManager(ROUTER.positionManager());
		_pm.collect(PositionManager.CollectParams({
			tokenId: info.positionId,
			recipient: team(),
			amount0Max: UINT128_MAX,
			amount1Max: UINT128_MAX
		}));
		info.team.withdrawFees();
	}

	function transfer(address _to, uint256 _tokens) external returns (bool) {
		return _transfer(msg.sender, _to, _tokens);
	}

	function approve(address _spender, uint256 _tokens) external returns (bool) {
		return _approve(msg.sender, _spender, _tokens);
	}

	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
		unchecked {
			uint256 _allowance = allowance(_from, msg.sender);
			require(_allowance >= _tokens);
			if (_allowance != UINT_MAX) {
				info.users[_from].allowance[msg.sender] -= _tokens;
			}
			return _transfer(_from, _to, _tokens);
		}
	}

	function transferAndCall(address _to, uint256 _tokens, bytes calldata _data) external returns (bool) {
		_transfer(msg.sender, _to, _tokens);
		uint32 _size;
		assembly {
			_size := extcodesize(_to)
		}
		if (_size > 0) {
			require(Callable(_to).tokenCallback(msg.sender, _tokens, _data));
		}
		return true;
	}
	

	function creator() public view returns (address) {
		return info.creator;
	}
	
	function team() public view returns (address) {
		return address(info.team);
	}

	function pool() public view returns (address) {
		return info.pool;
	}

	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance;
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function position() external view returns (uint256) {
		return info.positionId;
	}

	function initialMarketCap() external view returns (string memory) {
		return string(abi.encodePacked(_uint2str(info.initialMarketCap, 18, 5), " ETH"));
	}

	function upperMarketCap() external view returns (string memory) {
		return string(abi.encodePacked(_uint2str(info.upperMarketCap, 18, 5), " ETH"));
	}

	function creatorFee() external view returns (string memory) {
		return string(abi.encodePacked(_uint2str(info.creatorFee * 100, 3, 3), "%"));
	}

	function transferLimit() public view returns (uint256 limit, uint256 until, bool active) {
		limit = info.transferLimit;
		until = info.transferLimitEnd;
		active = limit > 0 && block.timestamp < until;
	}

	function website() external view returns (string memory) {
		return info.website;
	}

	function twitter() external view returns (string memory) {
		return info.twitter;
	}

	function telegram() external view returns (string memory) {
		return info.telegram;
	}

	function discord() external view returns (string memory) {
		return info.discord;
	}

	function additionalInfo() external view returns (string memory) {
		return info.additionalInfo;
	}


	function _createLP(uint256 _initialMarketCap, uint256 _upperMarketCap, uint256 _creatorFee) internal {
		unchecked {
			address _this = address(this);
			address _weth = ROUTER.WETH9();
			bool _weth0 = _weth < _this;
			(uint160 _initialSqrtPrice, ) = _getPriceAndTickFromValues(_weth0, totalSupply(), _initialMarketCap);
			info.pool = Factory(ROUTER.factory()).createPool(_this, _weth, 10000);
			Pool(pool()).initialize(_initialSqrtPrice);
			PositionManager _pm = PositionManager(ROUTER.positionManager());
			_approve(_this, address(_pm), totalSupply());
			( , int24 _minTick) = _getPriceAndTickFromValues(_weth0, totalSupply(), _initialMarketCap);
			( , int24 _maxTick) = _getPriceAndTickFromValues(_weth0, totalSupply(), _upperMarketCap);
			if (_creatorFee > 0) {
				_pm.mint(PositionManager.MintParams({
					token0: _weth0 ? _weth : _this,
					token1: !_weth0 ? _weth : _this,
					fee: 10000,
					tickLower: _weth0 ? _maxTick : _minTick,
					tickUpper: !_weth0 ? _maxTick : _minTick,
					amount0Desired: _weth0 ? 0 :  totalSupply() * _creatorFee / PERCENT_PRECISION,
					amount1Desired: !_weth0 ? 0 : totalSupply() * _creatorFee / PERCENT_PRECISION,
					amount0Min: 0,
					amount1Min: 0,
					recipient: creator(),
					deadline: block.timestamp
				}));
			}
			(info.positionId, , , ) = _pm.mint(PositionManager.MintParams({
				token0: _weth0 ? _weth : _this,
				token1: !_weth0 ? _weth : _this,
				fee: 10000,
				tickLower: _weth0 ? _maxTick : _minTick,
				tickUpper: !_weth0 ? _maxTick : _minTick,
				amount0Desired: _weth0 ? 0 :  totalSupply() * (PERCENT_PRECISION - _creatorFee) / PERCENT_PRECISION,
				amount1Desired: !_weth0 ? 0 : totalSupply() * (PERCENT_PRECISION - _creatorFee) / PERCENT_PRECISION,
				amount0Min: 0,
				amount1Min: 0,
				recipient: _this,
				deadline: block.timestamp
			}));
			if (_this.balance > 0) {
				ROUTER.exactInputSingle{value:_this.balance}(Router.ExactInputSingleParams({
					tokenIn: _weth,
					tokenOut: _this,
					fee: 10000,
					recipient: creator(),
					amountIn: _this.balance,
					amountOutMinimum: 0,
					sqrtPriceLimitX96: 0
				}));
			}
		}
	}
	
	function _approve(address _owner, address _spender, uint256 _tokens) internal returns (bool) {
		info.users[_owner].allowance[_spender] = _tokens;
		emit Approval(_owner, _spender, _tokens);
		return true;
	}
	
	function _transfer(address _from, address _to, uint256 _tokens) internal returns (bool) {
		unchecked {
			require(_tokens > 0);
			(uint256 _limit, , bool _active) = transferLimit();
			if (_active) {
				require(_tokens <= _limit);
			}
			require(balanceOf(_from) >= _tokens);
			info.users[_from].balance -= _tokens;
			info.users[_to].balance += _tokens;
			emit Transfer(_from, _to, _tokens);
			return true;
		}
	}


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

	function _uint2str(uint256 _value, uint256 _scale, uint256 _maxDecimals) internal pure returns (string memory str) {
		uint256 _d = _scale > _maxDecimals ? _maxDecimals : _scale;
		uint256 _n = _value / 10**(_scale > _d ? _scale - _d : 0);
		if (_n == 0) {
			return "0";
		}
		uint256 _digits = 1;
		uint256 _tmp = _n;
		while (_tmp > 9) {
			_tmp /= 10;
			_digits++;
		}
		_tmp = _digits > _d ? _digits : _d + 1;
		uint256 _offset = (_tmp > _d + 1 ? _tmp - _d - 1 > _d ? _d : _tmp - _d - 1 : 0);
		for (uint256 i = 0; i < _tmp - _offset; i++) {
			uint256 _dec = i < _tmp - _digits ? 0 : (_n / (10**(_tmp - i - 1))) % 10;
			bytes memory _char = new bytes(1);
			_char[0] = bytes1(uint8(_dec) + 48);
			str = string(abi.encodePacked(str, string(_char)));
			if (i < _tmp - _d - 1) {
				if ((i + 1) % 3 == (_tmp - _d) % 3) {
					str = string(abi.encodePacked(str, ","));
				}
			} else {
				if ((_n / 10**_offset) % 10**(_tmp - _offset - i - 1) == 0) {
					break;
				} else if (i == _tmp - _d - 1) {
					str = string(abi.encodePacked(str, "."));
				}
			}
		}
	}
}