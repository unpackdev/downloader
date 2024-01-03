pragma solidity ^0.6.10;

import "./RhoInterfaces.sol";

contract InterestRateModel is InterestRateModelInterface {

	uint public immutable yOffset;
	uint public immutable slopeFactor;
	uint public immutable rateFactorSensitivity;
	uint public immutable range;
	uint public immutable feeBase;
	uint public immutable feeSensitivity;

	constructor(
		uint yOffset_,
		uint slopeFactor_,
		uint rateFactorSensitivity_,
		uint feeBase_,
		uint feeSensitivity_,
		uint range_
	) public {
		require(slopeFactor_ > 0 && rateFactorSensitivity_ > 0 && range_ > 0 , "Zero params not allowed");

		yOffset = yOffset_;
		slopeFactor = slopeFactor_;
		rateFactorSensitivity = rateFactorSensitivity_;
		feeBase = feeBase_;
		feeSensitivity = feeSensitivity_;
		range = range_;
	}

	/* @dev Calculates the per-block interest rate to offer an incoming swap based on the rateFactor stored in Rho.sol.
	 * @param userPayingFixed : If the user is paying fixed in incoming swap
	 * @param orderNotional : Notional order size of the incoming swap
	 * @param lockedCollateralUnderlying : The amount of the protocol's liquidity that is locked at the time of the swap in underlying tokens
	 * @param supplierLiquidityUnderlying : Total amount of the protocol's liquidity in underlying tokens
	 */
	function getSwapRate(
		int rateFactorPrev,
		bool userPayingFixed,
		uint orderNotional,
		uint lockedCollateralUnderlying,
		uint supplierLiquidityUnderlying
	) external override view returns (uint rate, int rateFactorNew) {
		require(supplierLiquidityUnderlying != 0, "supplied liquidity 0");
		uint rfDelta = div(mul(rateFactorSensitivity, orderNotional), supplierLiquidityUnderlying);
		rateFactorNew = userPayingFixed ? add(rateFactorPrev, rfDelta) : sub(rateFactorPrev, rfDelta);

		int num = mul(rateFactorNew, range);
		uint denom = sqrt(add(square(rateFactorNew), slopeFactor));

		uint baseRate = toZero(add(div(num, denom), yOffset)); // can not be negative
		uint fee = getFee(lockedCollateralUnderlying, supplierLiquidityUnderlying);

		// base + yOffset +- fee
		if (userPayingFixed) {
			rate = add(baseRate, fee);
		} else {
			if (baseRate > fee) {
				rate = sub(baseRate, fee);
			} else {
				rate = 0;
				// if the rate is negative, don't push rate factor even lower
				rateFactorNew = rateFactorPrev;
			}
		}
	}

	// @dev Calculates the fee to add to the rate. fee = feeBase + feeSensitivity * locked / total
	function getFee(uint lockedCollateralUnderlying, uint supplierLiquidityUnderlying) public view returns (uint) {
		return add(feeBase, div(mul(feeSensitivity, lockedCollateralUnderlying), supplierLiquidityUnderlying));
	}

    // ** Interest Rate Model Math Library **//

    // Source: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/libraries/Math.sol
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

	// ** UINT SAFE MATH ** //
	// Adapted from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol

	function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "SafeMath: Multiplication overflow");
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0, "SafeMath: Divide by zero");
        uint c = a / b;
        return c;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) pure internal returns (uint) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }

   	// ** INT SAFE MATH ** //
   	// Adapted from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SignedSafeMath.sol
	int constant private _INT_MIN = -2**255;

    function div(int a, int b) internal pure returns (int) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT_MIN), "SignedSafeMath: division overflow");

        int c = a / b;

        return c;
    }

    function mul(int a, int b) internal pure returns (int) {
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT_MIN), "SignedSafeMath: multiplication overflow");

        int c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    function add(int a, int b) internal pure returns (int) {
        int c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

   	// ** INT => UINT MATH ** //

   	// Set negative ints to 0
    function toZero(int x) internal pure returns (uint) {
		return x > 0 ? uint(x) : 0;
	}

	function square(int a) internal pure returns (uint) {
		return uint(mul(a, a));
	}

	// ** UINT => INT MATH ** //

	int constant private _INT_MAX = 2**255 - 1;

    function add(int a, uint b) internal pure returns (int){
        require(b < uint(_INT_MAX), "SafeMath: Int addition overflow detected");
        return add(a, int(b));
    }

	function mul(int a, uint b) internal pure returns (int) {
        require(b < uint(_INT_MAX), "SafeMath: Int multiplication overflow detected");
        return mul(a, int(b));
	}

    function sub(int a, uint b) internal pure returns (int){
        require(b < uint(_INT_MAX), "SafeMath: Int subtraction overflow detected");
        return sub(a, int(b));
    }

	function div(int a, uint b) internal pure returns (int) {
        require(b < uint(_INT_MAX), "SafeMath: Int division overflow detected");
        return div(a, int(b));
	}

}
