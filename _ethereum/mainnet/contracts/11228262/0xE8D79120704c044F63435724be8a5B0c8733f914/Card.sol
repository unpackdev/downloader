pragma solidity =0.5.16;

import "./SafeMath.sol";

library Card {
    using SafeMath for uint256;

    function make(uint256 x, uint256 y, uint256 z, uint256 u, uint256 unit) internal pure returns (uint256) {
        return x.mul(unit**3).add(y.mul(unit**2)).add(z.mul(unit)).add(u);
    }

    function num(uint256 x, uint256 y, uint256 unit) internal pure returns (uint256) {
        return x.div(unit**(uint256(3).sub(y))) % unit;
    }

    function sub(uint256 x, uint256 y, uint256 z, uint256 unit) internal pure returns (uint256) {
        return x.sub(z.mul(unit**(uint256(3).sub(y))));
    }

    function merge(uint256 x, uint256 y, uint256 unit) internal pure returns (uint256) {
        uint256 a = num(x, 0, unit).add(num(y, 0, unit));
        uint256 b = num(x, 1, unit).add(num(y, 1, unit));
        uint256 c = num(x, 2, unit).add(num(y, 2, unit));
        uint256 d = num(x, 3, unit).add(num(y, 3, unit));
        return make(a, b, c, d, unit);
    }

    function min(uint256 x, uint256 unit) internal pure returns (uint256) {
        uint256 _min = num(x, 0, unit);
        for (uint256 i = 1; i < 4; i++) {
            uint256 _num = num(x, i, unit);
            if (_num < _min) _min = _num;
        }
        return _min;
    }
}
