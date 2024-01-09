// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./AccessControlEnumerable.sol";

contract UCG is ERC20, ERC20Burnable, Pausable, AccessControlEnumerable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address _to, uint256 _initSupply)
        ERC20("Universe Crystal Gene", "UCG")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _mint(_to, _initSupply * 10**decimals());
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "UCG: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "UCG: must have pauser role to unpause"
        );
        _unpause();
    }

    function mint(address to, uint256 amount) public {
        require(!paused(), "UCG: token mint while paused");
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "UCG: must have minter role to mint"
        );
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!paused(), "UCG: token transfer while paused");
        super._beforeTokenTransfer(from, to, amount);
    }
}
