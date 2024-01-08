//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Upgradeable.sol";
import "./MathUpgradeable.sol";

import "./Collar.sol";

abstract contract CIPSwap is ERC20Upgradeable, Collar {
    uint256 public sx;
    uint256 public sy;

    function initialize() public virtual override initializer {
        super.initialize();
        __Context_init_unchained();
        __ERC20_init_unchained("Collar Liquidity Proof Token", "CLPT");
    }

    function swap_coll_to_min_want(uint256 dx, uint256 mindy) public {
        uint256 fee = swap_fee();
        uint256 dy = calc_dy(sx, sy, dx);
        dy = (dy * fee) / 1e18;
        require(dy >= mindy, "insufficient fund");
        sx += dx;
        sy -= dy;
        recv_coll(dx);
        send_want(dy);
    }

    function swap_want_to_min_coll(uint256 mindx, uint256 dy) public {
        uint256 fee = swap_fee();
        uint256 dx = calc_dx(sx, sy, dy);
        dx = (dx * fee) / 1e18;
        require(dx >= mindx, "insufficient fund");
        sx -= dx;
        sy += dy;
        send_coll(dx);
        recv_want(dy);
    }

    function mint(
        uint256 dx,
        uint256 dy,
        uint256 mindk
    ) public {
        uint256 k = calc_k(sx, sy);
        uint256 nk = calc_k(sx + dx, sy + dy);
        uint256 dk = nk - k;
        require(dk >= mindk, "insufficient fund");
        sx += dx;
        sy += dy;
        _mint(msg.sender, dk);
        recv_coll(dx);
        recv_want(dy);
    }

    function burn(uint256 dk) public {
        uint256 k = calc_k(sx, sy);
        uint256 dx = (sx * dk) / k;
        uint256 dy = (sy * dk) / k;
        dx = (dx * swap_fee()) / 1e18;
        dy = (dy * swap_fee()) / 1e18;
        sx -= dx;
        sy -= dy;
        _burn(msg.sender, dk);
        send_coll(dx);
        send_want(dy);
    }

    function get_coll_norm() internal view virtual override returns (uint256) {
        return super.get_coll_norm() + norm_want_max(sx);
    }

    function get_want_norm() internal view virtual override returns (uint256) {
        return super.get_want_norm() - norm_want_max(sy);
    }

    function sk() public view returns (uint256) {
        return calc_k(sx, sy);
    }

    function calc_dx(
        uint256 x,
        uint256 y,
        uint256 dy
    ) public pure returns (uint256) {
        uint256 k = calc_k(x, y) + 1;
        uint256 nx = calc_x(k, y + dy) + 1;
        if (x <= nx) {
            return 0;
        }
        unchecked {return x - nx;}
    }

    function calc_dy(
        uint256 x,
        uint256 y,
        uint256 dx
    ) public pure returns (uint256) {
        uint256 k = calc_k(x, y) + 1;
        uint256 ny = calc_y(k, x + dx) + 1;
        if (y <= ny) {
            return 0;
        }
        unchecked {return y - ny;}
    }

    function calc_x(uint256 k, uint256 y) public pure returns (uint256) {
        uint256 a = swap_sqp();
        uint256 ye9 = y * 1e9;
        uint256 ak = a * k;
        return (k * k * 1e9) / (ye9 + ak) - k;
    }

    function calc_y(uint256 k, uint256 x) public pure returns (uint256) {
        uint256 a = swap_sqp();
        uint256 ak = a * k;
        uint256 X = x + k;
        return (k * k * 1e9 - ak * X) / (X * 1e9);
    }

    function calc_k(uint256 x, uint256 y) public pure returns (uint256) {
        uint256 a = swap_sqp();
        uint256 ye9 = y * 1e9;
        uint256 ax = a * x;
        uint256 a_ = 1e9 - a;
        uint256 D = (ax + ye9)**2 + 4 * x * ye9 * a_;
        return (sqrt(D) + ye9 + ax) / (2 * a_);
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }

    function swap_sqp() public pure virtual returns (uint256) {
        return 950000000;
    }

    function swap_fee() public pure virtual returns (uint256) {
        return 9999e14;
    }
}
