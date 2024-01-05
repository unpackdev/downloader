// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./ERC677Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./SafeMath.sol";

/// @dev RampDefi Stablecoin.
contract RUSD is ERC677Upgradeable, AccessControlUpgradeable {
    using SafeMath for uint256;

    bytes32 public constant MINTBURN_ROLE = keccak256("MINTBURN_ROLE");

    function initialize() public initializer {
        __ERC677_init("rUSD", "rUSD");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTBURN_ROLE, msg.sender);
    }

    function mint(address _account, uint256 _amount) external hasMintBurnRole {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external hasMintBurnRole {
        _burn(_account, _amount);
    }

    /********************** INTERNAL ********************************/
    modifier hasMintBurnRole() {
        require(hasRole(MINTBURN_ROLE, msg.sender), "Caller does not have MINTBURN_ROLE");
        _;
    }
}
