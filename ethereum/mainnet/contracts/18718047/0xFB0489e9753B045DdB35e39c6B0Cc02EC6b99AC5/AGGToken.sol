// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20Pausable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./TimeLock.sol";

contract AGGToken is ERC20Pausable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    uint256 public constant MAX_SUPPLY = 10000000000000000000000000000;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require(amount + totalSupply() <= MAX_SUPPLY, "Insufficient supply");
        _mint(to, amount);
    }

    function burn(uint256 _amount) public {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        _burn(msg.sender, _amount);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override(ERC20Pausable) whenNotPaused {
        super._beforeTokenTransfer(_from, _to, _amount);
    }
}
