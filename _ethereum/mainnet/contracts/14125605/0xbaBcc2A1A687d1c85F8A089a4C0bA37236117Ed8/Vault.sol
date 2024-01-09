//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVault.sol";
import "./IERC20.sol";
import "./AccessControl.sol";

contract Vault is IVault, AccessControl {
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 public constant STAKING_ROLE = keccak256("STAKING_ROLE");

    IERC20 public immutable TOKEN;

    modifier onlyStaking() {
        require(hasRole(STAKING_ROLE, _msgSender()), "Only staking");
        _;
    }

    modifier onlyFactory() {
        require(hasRole(FACTORY_ROLE, _msgSender()), "Only factory");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Only admin");
        _;
    }

    constructor(address _factory, address _token) {
        require(_factory != address(0) && _token != address(0));
        TOKEN = IERC20(_token);
        _setupRole(FACTORY_ROLE, _factory);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setFactory(address _newFactory) external onlyAdmin {
        _setupRole(FACTORY_ROLE, _newFactory);
    }

    function setStaking(address _newStaking) external override onlyFactory {
        _setupRole(STAKING_ROLE, _newStaking);
    }

    function sendReward(uint256 amount, address user)
        external
        override
        onlyStaking
    {
        require(TOKEN.transfer(user, amount), "Transfer from VAULT is failed");
    }

    function withdrawTokens(uint256 amount) external onlyAdmin {
        require(
            TOKEN.balanceOf(address(this)) >= amount && amount > 0,
            "Wrong params"
        );
        require(
            TOKEN.transfer(_msgSender(), amount),
            "Transfer from VAULT is failed"
        );
    }
}
