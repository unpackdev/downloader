//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./CIPStaking.sol";

abstract contract CHSLite is CIPStaking {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function borrow_want(uint256 nb, uint256 minnw) public {
        mint_dual(nb);
        swap_coll_to_min_want(nb, minnw);
    }

    function repay_both(uint256 nw, uint256 no) public {
        burn_dual(no);
        burn_call(nw);
    }

    function withdraw_both(uint256 dk) public {
        burn(dk);
    }

    function get_dx(uint256 dy) public view returns (uint256) {
        return calc_dx(sx, sy, dy);
    }

    function get_dy(uint256 dx) public view returns (uint256) {
        return calc_dy(sx, sy, dx);
    }

    function get_dk(uint256 dx, uint256 dy) public view returns (uint256) {
        uint256 k = calc_k(sx, sy);
        uint256 nk = calc_k(sx + dx, sy + dy);
        return nk - k;
    }

    function get_dxdy(uint256 dk) public view returns (uint256, uint256) {
        uint256 k = calc_k(sx, sy);
        uint256 dx = (sx * dk) / k;
        uint256 dy = (sy * dk) / k;
        return (dx, dy);
    }
    
    function burn_and_claim(uint256 dk) public {
        burn(dk);
        claim_reward();
    }
}
