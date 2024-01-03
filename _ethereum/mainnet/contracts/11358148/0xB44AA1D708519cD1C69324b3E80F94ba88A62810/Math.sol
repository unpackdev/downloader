pragma experimental ABIEncoderV2;
pragma solidity ^0.6.10;

import "./Types.sol";

/* @dev A safe math lib for Rho data types. 
   Note: always returns type of left side param */
contract Math is Types {

	uint constant EXP_SCALE = 1e18;
    Exp ONE_EXP = Exp({mantissa: EXP_SCALE});

    function toExp_(uint num) pure internal returns (Exp memory) {
    	return Exp({mantissa: num});
    }

    function toUint_(int a) pure internal returns (uint) {
        return a > 0 ? uint(a) : 0;
    }

    function lt_(CTokenAmount memory a, CTokenAmount memory b) pure internal returns (bool) {
        return a.val < b.val;
    }

    function lte_(CTokenAmount memory a, CTokenAmount memory b) pure internal returns (bool) {
        return a.val <= b.val;
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(CTokenAmount memory a, CTokenAmount memory b) pure internal returns (CTokenAmount memory) {
        return CTokenAmount({val: add_(a.val, b.val)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function subToZero_(CTokenAmount memory a, CTokenAmount memory b) pure internal returns (CTokenAmount memory) {
        if (b.val >= a.val) {
            return CTokenAmount({val: 0});
        } else {
            return sub_(a,b);
        }
    }

    function subToZero_(uint a, uint b) pure internal returns (uint) {
        if (b >= a) {
            return 0;
        } else {
            return sub_(a,b);
        }
    }

    function subToZero_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        if (b.mantissa >= a.mantissa) {
            return Exp({mantissa: 0});
        } else {
            return sub_(a,b);
        }
    }

    function sub_(CTokenAmount memory a, CTokenAmount memory b) pure internal returns (CTokenAmount memory) {
        return CTokenAmount({val: sub_(a.val, b.val)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }

    function sub_(int a, uint b) pure internal returns (int) {
        int c = a - int(b);
        require(a >= c, "int - uint underflow");
        return c;
    }

    function add_(int a, uint b) pure internal returns (int) {
        int c = a + int(b);
        require(a <= c, "int + uint overflow");
        return c;
    }

    function mul_(uint a, CTokenAmount memory b) pure internal returns (uint) {
        return mul_(a, b.val);
    }

    function mul_(CTokenAmount memory a, uint b) pure internal returns (CTokenAmount memory) {
        return CTokenAmount({val: mul_(a.val, b)});
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / EXP_SCALE});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / EXP_SCALE;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }

    function div_(uint a, CTokenAmount memory b) pure internal returns (uint) {
        return div_(a, b.val);
    }

    function div_(CTokenAmount memory a, uint b) pure internal returns (CTokenAmount memory) {
        return CTokenAmount({val: div_(a.val, b)});
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, EXP_SCALE), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, EXP_SCALE), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        require(b > 0, "divide by zero");
        return a / b;
    }

}
