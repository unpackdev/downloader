// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IExofiswapCallee.sol";
import "./IExofiswapFactory.sol";
import "./IExofiswapPair.sol";
import "./IMigrator.sol";
import "./ExofiswapERC20.sol";
import "./MathUInt32.sol";
import "./MathUInt256.sol";
import "./UQ144x112.sol";

contract ExofiswapPair is IExofiswapPair, ExofiswapERC20
{
	// using UQ144x112 for uint256;
	// using SafeERC20 for IERC20Metadata; // For some unknown reason using this needs a little more gas than using the library without it.
	struct SwapAmount // needed to reduce stack deep;
	{
		uint256 balance0;
		uint256 balance1;
		uint112 reserve0;
		uint112 reserve1;
	}

	uint256 private constant _MINIMUM_LIQUIDITY = 10**3;
	uint256 private _price0CumulativeLast;
	uint256 private _price1CumulativeLast;
	uint256 private _kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event
	uint256 private _unlocked = 1;
	uint112 private _reserve0;           // uses single storage slot, accessible via getReserves
	uint112 private _reserve1;           // uses single storage slot, accessible via getReserves
	uint32  private _blockTimestampLast; // uses single storage slot, accessible via getReserves
	IExofiswapFactory private immutable _factory;
	IERC20Metadata private _token0;
	IERC20Metadata private _token1;

	modifier lock()
	{
		require(_unlocked == 1, "EP: LOCKED");
		_unlocked = 0;
		_;
		_unlocked = 1;
	}

	constructor() ExofiswapERC20("Plasma")
	{
		_factory = IExofiswapFactory(_msgSender());
	}

	// called once by the factory at time of deployment
	function initialize(IERC20Metadata token0Init, IERC20Metadata token1Init) override external
	{
		require(_msgSender() == address(_factory), "EP: FORBIDDEN");
		_token0 = token0Init;
		_token1 = token1Init;
	}

	// this low-level function should be called from a contract which performs important safety checks
	function burn(address to) override public lock returns (uint, uint)
	{
		SwapAmount memory sa;
		(sa.reserve0, sa.reserve1,) = getReserves(); // gas savings
		sa.balance0 = _token0.balanceOf(address(this));
		sa.balance1 = _token1.balanceOf(address(this));
		uint256 liquidity = balanceOf(address(this));

		// Can not overflow
		bool feeOn = _mintFee(MathUInt256.unsafeMul(sa.reserve0, sa.reserve1));
		uint256 totalSupplyValue = _totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
		uint256 amount0 = MathUInt256.unsafeDiv(liquidity * sa.balance0, totalSupplyValue); // using balances ensures pro-rata distribution
		uint256 amount1 = MathUInt256.unsafeDiv(liquidity * sa.balance1, totalSupplyValue); // using balances ensures pro-rata distribution
		require(amount0 > 0 && amount1 > 0, "EP: INSUFFICIENT_LIQUIDITY");
		_burn(address(this), liquidity);
		SafeERC20.safeTransfer(_token0, to, amount0);
		SafeERC20.safeTransfer(_token1, to, amount1);
		sa.balance0 = _token0.balanceOf(address(this));
		sa.balance1 = _token1.balanceOf(address(this));

		_update(sa);

		if (feeOn)
		{
			unchecked // Can not overflow
			{
				// _reserve0 and _reserve1 are up-to-date
				// What _update(sa) does is set _reserve0 to sa.balance0 and _reserve1 to sa.balance1
				// So there is no neet to access and converte the _reserves directly,
				// instead use the known balances that are already in the correct type.
				_kLast = sa.balance0 * sa.balance1; 
			}
		}
		emit Burn(msg.sender, amount0, amount1, to);
		return (amount0, amount1);
	}

	// this low-level function should be called from a contract which performs important safety checks
	function mint(address to) override public lock returns (uint256)
	{
		SwapAmount memory sa;
		(sa.reserve0, sa.reserve1,) = getReserves(); // gas savings
		sa.balance0 = _token0.balanceOf(address(this));
		sa.balance1 = _token1.balanceOf(address(this));
		uint256 amount0 = sa.balance0 - sa.reserve0;
		uint256 amount1 = sa.balance1 - sa.reserve1;

		bool feeOn = _mintFee(MathUInt256.unsafeMul(sa.reserve0, sa.reserve1));
		uint256 totalSupplyValue = _totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
		uint256 liquidity;

		if (totalSupplyValue == 0)
		{
			IMigrator migrator = _factory.migrator();
			if (_msgSender() == address(migrator))
			{
				liquidity = migrator.desiredLiquidity();
				require(liquidity > 0 && liquidity != type(uint256).max, "EP: Liquidity Error");
			}
			else
			{
				require(address(migrator) == address(0), "EP: Migrator set");
				liquidity = MathUInt256.sqrt(amount0 * amount1) - _MINIMUM_LIQUIDITY;
				_mintMinimumLiquidity();
			}
		}
		else
		{
			//Div by uint can not overflow
			liquidity = 
				MathUInt256.min(
					MathUInt256.unsafeDiv(amount0 * totalSupplyValue, sa.reserve0),
					MathUInt256.unsafeDiv(amount1 * totalSupplyValue, sa.reserve1)
				);
		}
		require(liquidity > 0, "EP: INSUFFICIENT_LIQUIDITY");
		_mint(to, liquidity);

		_update(sa);
		if (feeOn)
		{
			// _reserve0 and _reserve1 are up-to-date
			// What _update(sa) does is set _reserve0 to sa.balance0 and _reserve1 to sa.balance1
			// So there is no neet to access and converte the _reserves directly,
			// instead use the known balances that are already in the correct type.
			_kLast = sa.balance0 * sa.balance1; 
		}
		emit Mint(_msgSender(), amount0, amount1);
		return liquidity;
	}

	// force balances to match reserves
	function skim(address to) override public lock
	{
		SafeERC20.safeTransfer(_token0, to, _token0.balanceOf(address(this)) - _reserve0);
		SafeERC20.safeTransfer(_token1, to, _token1.balanceOf(address(this)) - _reserve1);
	}

	// this low-level function should be called from a contract which performs important safety checks
	function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) override public lock
	{
		require(amount0Out > 0 || amount1Out > 0, "EP: INSUFFICIENT_OUTPUT_AMOUNT");
		SwapAmount memory sa;
		(sa.reserve0, sa.reserve1, ) = getReserves(); // gas savings
		require(amount0Out < sa.reserve0, "EP: INSUFFICIENT_LIQUIDITY");
		require(amount1Out < sa.reserve1, "EP: INSUFFICIENT_LIQUIDITY");

		(sa.balance0, sa.balance1) = _transferTokens(to, amount0Out, amount1Out, data);

		(uint256 amount0In, uint256 amount1In) = _getInAmounts(amount0Out, amount1Out, sa);
		require(amount0In > 0 || amount1In > 0, "EP: INSUFFICIENT_INPUT_AMOUNT");
		{ 
			// This is a sanity check to make sure we don't lose from the swap.
			// scope for reserve{0,1} Adjusted, avoids stack too deep errors
			uint256 balance0Adjusted = (sa.balance0 * 1000) - (amount0In * 3); 
			uint256 balance1Adjusted = (sa.balance1 * 1000) - (amount1In * 3); 
			// 112 bit * 112 bit * 20 bit can not overflow a 256 bit value
			// Bigest possible number is 2,695994666715063979466701508702e+73
			// uint256 maxvalue is 1,1579208923731619542357098500869e+77
			// or 2**112 * 2**112 * 2**20 = 2**244 < 2**256
			require(balance0Adjusted * balance1Adjusted >= MathUInt256.unsafeMul(MathUInt256.unsafeMul(sa.reserve0, sa.reserve1), 1_000_000), "EP: K");
		}
		_update(sa);
		emit Swap(_msgSender(), amount0In, amount1In, amount0Out, amount1Out, to);
	}

	
	// force reserves to match balances
	function sync() override public lock
	{
		_update(SwapAmount(_token0.balanceOf(address(this)), _token1.balanceOf(address(this)), _reserve0, _reserve1));
	}
	
	function factory() override public view returns (IExofiswapFactory)
	{
		return _factory;
	}

	function getReserves() override public view returns (uint112, uint112, uint32)
	{
		return (_reserve0, _reserve1, _blockTimestampLast);
	}

	function kLast() override public view returns (uint256)
	{
		return _kLast;
	}
	
	function name() override(ERC20, IERC20Metadata) public view virtual returns (string memory)
	{
		return string(abi.encodePacked(_token0.symbol(), "/", _token1.symbol(), " ", super.name()));
	}

	function price0CumulativeLast() override public view returns (uint256)
	{
		return _price0CumulativeLast;
	}

	function price1CumulativeLast() override public view returns (uint256)
	{
		return _price1CumulativeLast;
	}


	function token0() override public view returns (IERC20Metadata)
	{
		return _token0;
	}
	
	function token1() override public view returns (IERC20Metadata)
	{
		return _token1;
	}

	function MINIMUM_LIQUIDITY() override public pure returns (uint256) //solhint-disable-line func-name-mixedcase
	{
		return _MINIMUM_LIQUIDITY;
	}

	function _mintMinimumLiquidity() private
	{
		require(_totalSupply == 0, "EP: Total supply not 0");

		_totalSupply += _MINIMUM_LIQUIDITY;
		_balances[address(0)] += _MINIMUM_LIQUIDITY;
		emit Transfer(address(0), address(0), _MINIMUM_LIQUIDITY);
	}

	function _transferTokens(address to, uint256 amount0Out, uint256 amount1Out, bytes calldata data) private returns (uint256, uint256)
	{
		require(address(to) != address(_token0) && to != address(_token1), "EP: INVALID_TO");
		if (amount0Out > 0) SafeERC20.safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
		if (amount1Out > 0) SafeERC20.safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
		if (data.length > 0) IExofiswapCallee(to).exofiswapCall(_msgSender(), amount0Out, amount1Out, data);
		return (_token0.balanceOf(address(this)), _token1.balanceOf(address(this)));
	}

	// if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
	function _mintFee(uint256 k) private returns (bool)
	{
		address feeTo = _factory.feeTo();
		uint256 kLastHelp = _kLast; // gas savings
		if (feeTo != address(0))
		{
			if (kLastHelp != 0)
			{
				uint256 rootK = MathUInt256.sqrt(k);
				uint256 rootKLast = MathUInt256.sqrt(kLastHelp);
				if (rootK > rootKLast)
				{
					uint256 numerator = _totalSupply * MathUInt256.unsafeSub(rootK, rootKLast);
					// Since rootK is the sqrt of k. Multiplication by 5 can never overflow
					uint256 denominator = MathUInt256.unsafeMul(rootK, 5) + rootKLast;
					uint256 liquidity = MathUInt256.unsafeDiv(numerator, denominator);
					if (liquidity > 0)
					{
						_mint(feeTo, liquidity);
					}
				}
			}
			return true;
		}
		if(kLastHelp != 0)
		{
			_kLast = 0;
		}
		return false;
	}

	// update reserves and, on the first call per block, price accumulators
	function _update(SwapAmount memory sa) private
	{
		require(sa.balance0 <= type(uint112).max, "EP: OVERFLOW");
		require(sa.balance1 <= type(uint112).max, "EP: OVERFLOW");
		// solhint-disable-next-line not-rely-on-time
		uint32 blockTimestamp = uint32(block.timestamp);
		if (sa.reserve1 != 0)
		{
			if (sa.reserve0 != 0)
			{	
				uint32 timeElapsed = MathUInt32.unsafeSub32(blockTimestamp, _blockTimestampLast); // overflow is desired
				if (timeElapsed > 0)
				{	
					// * never overflows, and + overflow is desired
					unchecked
					{
						_price0CumulativeLast += (UQ144x112.uqdiv(UQ144x112.encode(sa.reserve1),sa.reserve0) * timeElapsed);
						_price1CumulativeLast += (UQ144x112.uqdiv(UQ144x112.encode(sa.reserve0), sa.reserve1) * timeElapsed);
					}
				}
			}
		}
		_reserve0 = uint112(sa.balance0);
		_reserve1 = uint112(sa.balance1);
		_blockTimestampLast = blockTimestamp;
		emit Sync(_reserve0, _reserve1);
	}

	function _getInAmounts(uint256 amount0Out, uint256 amount1Out, SwapAmount memory sa)
		private pure returns(uint256, uint256)
	{
		uint256 div0 = MathUInt256.unsafeSub(sa.reserve0, amount0Out);
		uint256 div1 = MathUInt256.unsafeSub(sa.reserve1, amount1Out);
		return (sa.balance0 > div0 ? MathUInt256.unsafeSub(sa.balance0, div0) : 0, sa.balance1 > div1 ? MathUInt256.unsafeSub(sa.balance1, div1) : 0);
	}
}
