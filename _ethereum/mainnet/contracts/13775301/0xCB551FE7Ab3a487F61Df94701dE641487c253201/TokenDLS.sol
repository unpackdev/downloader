// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";

contract TokenDLS is ERC20, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    address private owner;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);

        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(BURNER_ROLE, ADMIN_ROLE);

        _mint(msg.sender, 0);

        owner = msg.sender;
    }

    function mint(address account, uint256 amount)
        external
        onlyRole(MINTER_ROLE)
    {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount)
        external
        onlyRole(BURNER_ROLE)
    {
        _burn(account, amount);
    }

    function withdrawToken(address token, uint256 amount)
        external
        onlyRole(ADMIN_ROLE)
    {
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function setOwner(address _newOnwer) external {
        require(msg.sender == owner, "you are not owner");
        owner = _newOnwer;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}