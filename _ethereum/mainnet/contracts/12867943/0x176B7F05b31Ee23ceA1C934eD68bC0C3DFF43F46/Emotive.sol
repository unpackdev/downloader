// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.4;

import "./ERC20.sol";
import "./AccessControl.sol";

contract EMotiveToken is ERC20, AccessControl {
    uint256 public constant FINAL_SUPPLY = 1000 * 10**6 * 10**18;
    uint256 public constant INITIAL_SUPPLY = 500 * 10**6 * 10**18;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "Restricted to minters.");
        _;
    }

    constructor() ERC20("EMotiveToken", "EMOT") {
        _mint(msg.sender, INITIAL_SUPPLY);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) external onlyMinter {
        require(
            totalSupply() + amount * 10**decimals() <= FINAL_SUPPLY,
            "Cannot mint more than Final Supply."
        );
        _mint(to, amount * 10**decimals());
    }

    function isAdmin(address account) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function isMinter(address account) external view returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    function addAdminRole(address account) external {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    function addMinterRole(address account) external {
        grantRole(MINTER_ROLE, account);
    }

    function removeAdminRole(address account) external {
        revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    function removeMinterRole(address account) external {
        revokeRole(MINTER_ROLE, account);
    }
}
