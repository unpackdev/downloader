// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.0;

import "./AccessControlEnumerableUpgradeable.sol";
import "./Initializable.sol";

/// Vouchers for booster openings.
contract Voucher is Initializable, AccessControlEnumerableUpgradeable {
    bytes32 public constant SPENDER_ROLE = keccak256("SPENDER_ROLE");
    bytes32 public constant CREDIT_ROLE = keccak256("CREDIT_ROLE");

    uint256 public constant DECIMALS = 18;

    mapping(address => uint256) public vouchers;

    event Credited(address indexed receiver, uint256 amount);
    event Spend(address indexed spender, uint256 amount);

    function initialize() public initializer {
        AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function creditVouchers(address receiver, uint256 amount) external {
        require(hasRole(CREDIT_ROLE, msg.sender), "Must have credit role");
        vouchers[receiver] += amount;
        emit Credited(receiver, amount);
    }

    function spendVouchers(address spender, uint256 amount) external {
        require(hasRole(SPENDER_ROLE, msg.sender), "Must have spender role");
        require(vouchers[spender] >= amount, "Not enough vouchers");
        vouchers[spender] -= amount;
        emit Spend(spender, amount);
    }
}
