// "SPDX-License-Identifier: UNLICENSED"

pragma solidity 0.8.7;

import "./ERC20.sol";
import "./Ownable.sol";
import "./AccessControl.sol";

// Example class - a mock class using delivering from ERC20
// Only use for testing
contract BasicToken is ERC20, Ownable, AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    modifier onlyMinter {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _;
    }

    modifier onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a minter");
        _;
    }

    function mint(address receiver, uint256 amount) external onlyMinter {
        _mint(receiver, amount);
    }

    function grantMinter(address minter) external onlyAdmin {
        grantRole(MINTER_ROLE, minter);
    }

    function revokeMinter(address minter) external onlyAdmin {
        revokeRole(MINTER_ROLE, minter);

    }

}
