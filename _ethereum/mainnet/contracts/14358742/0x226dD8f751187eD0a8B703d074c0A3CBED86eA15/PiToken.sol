// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./AccessControl.sol";
import "./Pausable.sol";

contract PiToken is
    ERC20,
    ERC20Burnable,
    ERC20Snapshot,
    AccessControl,
    Pausable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(
        address piprivate,
        address pidevelopment,
        address piecosystem,
        address pireserve,
        uint256 privateAmount,
        uint256 developmentAmount,
        uint256 ecosystemAmount,
        uint256 reserveAmount
    ) ERC20("Pi Financial Token", "PIFI") {
        _setupRole(DEFAULT_ADMIN_ROLE, pireserve);
        _setupRole(SNAPSHOT_ROLE, pireserve);
        _setupRole(PAUSER_ROLE, pireserve);
        _mint(piprivate, privateAmount * 10**decimals());
        _mint(pidevelopment, developmentAmount * 10**decimals());
        _mint(piecosystem, ecosystemAmount * 10**decimals());
        _mint(pireserve, reserveAmount * 10**decimals());
        _setupRole(BURNER_ROLE, pireserve);
    }

    function snapshot() public onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function burnFrom(address account, uint256 amount)
        public
        override(ERC20Burnable)
        onlyRole(BURNER_ROLE)
        whenNotPaused
    {
        _burn(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
