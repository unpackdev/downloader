//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./CollarERC20.sol";

abstract contract Collar is Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public rate;

    function initialize() public virtual initializer {
        rate = 1e18 + 1;
    }

    function mint_dual(uint256 n) public before_expiry {
        send_call(n);
        send_coll(n);
        recv_bond(n);
    }

    function mint_coll(uint256 n) public before_expiry {
        send_coll(n);
        recv_want(n);
    }

    function burn_dual(uint256 n) public before_expiry {
        recv_call(n);
        recv_coll(n);
        send_bond(n);
    }

    function burn_call(uint256 n) public before_expiry {
        recv_call(n);
        recv_want(n);
        send_bond(n);
    }

    function burn_coll(uint256 n) public {
        uint256 rw = rate;
        uint256 rb = 1e18 - rw;
        recv_coll(n);
        send_want((n * rw) / 1e18);
        send_bond((n * rb) / 1e18);
    }

    function expire() public {
        require(rate > 1e18);
        uint256 time = expiry_time();
        require(block.timestamp > time);
        uint256 nw = get_want_norm();
        uint256 nw0 = get_coll_norm();
        if (nw >= nw0) {
            rate = 1e18;
        } else {
            rate = (nw * 1e18) / nw0;
        }
    }

    function send_call(uint256 n) internal virtual {
        address call = address_call();
        CollarERC20(call).mint(msg.sender, n);
    }

    function send_coll(uint256 n) internal virtual {
        address coll = address_coll();
        CollarERC20(coll).mint(msg.sender, n);
    }

    function recv_call(uint256 n) internal virtual {
        address call = address_call();
        CollarERC20(call).burn(msg.sender, n);
    }

    function recv_coll(uint256 n) internal virtual {
        address coll = address_coll();
        CollarERC20(coll).burn(msg.sender, n);
    }

    function send_want(uint256 n) internal virtual {
        address want = address_want();
        n = norm_want_min(n);
        IERC20Upgradeable(want).safeTransfer(msg.sender, n);
    }

    function send_bond(uint256 n) internal virtual {
        address bond = address_bond();
        n = norm_bond_min(n);
        IERC20Upgradeable(bond).safeTransfer(msg.sender, n);
    }

    function recv_want(uint256 n) internal virtual {
        address want = address_want();
        n = norm_want_max(n);
        IERC20Upgradeable(want).safeTransferFrom(msg.sender, address(this), n);
    }

    function recv_bond(uint256 n) internal virtual {
        address bond = address_bond();
        n = norm_bond_max(n);
        IERC20Upgradeable(bond).safeTransferFrom(msg.sender, address(this), n);
    }

    function norm_bond_max(uint256 n) public view virtual returns (uint256) {
        return n;
    }

    function norm_bond_min(uint256 n) public view virtual returns (uint256) {
        return n;
    }

    function norm_want_max(uint256 n) public view virtual returns (uint256) {
        return n;
    }

    function norm_want_min(uint256 n) public view virtual returns (uint256) {
        return n;
    }

    function get_coll_norm() internal view virtual returns (uint256) {
        address coll = address_coll();
        uint256 num = CollarERC20(coll).totalSupply();
        return norm_want_max(num);
    }

    function get_want_norm() internal view virtual returns (uint256) {
        address want = address_want();
        return IERC20Upgradeable(want).balanceOf(address(this));
    }

    function expiry_time() public pure virtual returns (uint256);

    function address_bond() public pure virtual returns (address);

    function address_want() public pure virtual returns (address);

    function address_call() public pure virtual returns (address);

    function address_coll() public pure virtual returns (address);

    function address_collar() public pure virtual returns (address);

    modifier before_expiry() {
        uint256 time = expiry_time();
        require(block.timestamp < time);
        _;
    }
}
