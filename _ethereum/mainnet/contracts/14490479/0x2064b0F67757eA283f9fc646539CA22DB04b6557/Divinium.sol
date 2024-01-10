// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20BurnableUpgradeable.sol";
import "./ERC20PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./UUPSUpgradeable.sol";

contract Divinium is
    ERC20PausableUpgradeable,
    ERC20BurnableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    string public constant VERSION = "1.0";
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER");

    /*
     * @dev Replaces the constructor for upgradeable contracts
     */
    function initialize() public initializer {
        __ERC20_init("Divinium", "DVN");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Pause contract
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause contract
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function mint(address to_, uint256 amount_)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        _mint(to_, amount_);
    }

    function burnFromController(address from_, uint256 amount_)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        _burn(from_, amount_);
    }

    function multiTransfer(address[] memory to_, uint256[] memory amounts_)
        public
        virtual
    {
        require(to_.length == amounts_.length, "Length Mismatch");
        for (uint256 i = 0; i < to_.length; i++) {
            transfer(to_[i], amounts_[i]);
        }
    }

    function multiTransferFrom(
        address[] memory from_,
        address[] memory to_,
        uint256[] memory amounts_
    ) public virtual {
        require(
            from_.length == to_.length && from_.length == amounts_.length,
            "Length Mismatch"
        );
        for (uint256 i = 0; i < from_.length; i++) {
            transferFrom(from_[i], to_[i], amounts_[i]);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20PausableUpgradeable, ERC20Upgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * UUPS upgradeable
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}
