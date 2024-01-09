// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <= 0.8.0;

import "./AccessControlUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./Initializable.sol";
import "./IMoeToken.sol";

contract MOETokenV2 is Initializable, ERC20Upgradeable, AccessControlUpgradeable, IMoeToken {

    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");
    bool private _upgradeV2;

    function initialize() public initializer {
    }

    function upgradeV2(address predicateProxy) public {
        require(!_upgradeV2, "Already upgraded to V2");
        _upgradeV2 = true;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PREDICATE_ROLE, predicateProxy);
    }

    function mint(address user, uint256 amount) external override {
        require(hasRole(PREDICATE_ROLE, _msgSender()), "Must have minter role");
        _mint(user, amount);
    }


}