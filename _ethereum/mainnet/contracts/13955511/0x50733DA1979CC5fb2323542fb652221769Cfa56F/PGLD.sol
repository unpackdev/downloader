// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC20.sol";
import "./AccessControl.sol";

/**
 * @title A bunch of gold for Penguins
 * @author Pengu Rescue Team
 */
contract PGLD is AccessControl, ERC20 {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    uint256 public rescueTeamBalance;
    address public rescueTeam;

    event Withdrawn(address recipient, uint256 amount);

    constructor(address dao, address rescueTeam_) ERC20("PGLD", "PGLD") {
        _setupRole(MINTER_ROLE, dao);
        _setupRole(ADMIN_ROLE, dao);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        rescueTeam = rescueTeam_;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "Nope");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Nope");
        _;
    }

    modifier onlyRescueTeam() {
        require(msg.sender == rescueTeam, "Nope");
        _;
    }

    function mint(address account, uint256 amount) external onlyMinter {
        rescueTeamBalance += ((amount * 5) / 100);
        _mint(account, amount);
    }

    function addMinter(address minter) external onlyAdmin {
        grantRole(MINTER_ROLE, minter);
    }

    function rescueTeamWithdraw(address recipient) external onlyRescueTeam {
        require(rescueTeamBalance > 0, "Nothing to withdraw");
        uint256 toMint = rescueTeamBalance;
        rescueTeamBalance = 0;
        _mint(recipient, toMint);
        emit Withdrawn(recipient, toMint);
    }

    function setRescueTeam(address rescueTeam_) external onlyRescueTeam {
        require(rescueTeam_ != address(0), "0 address not allowed");
        rescueTeam = rescueTeam_;
    }
}
