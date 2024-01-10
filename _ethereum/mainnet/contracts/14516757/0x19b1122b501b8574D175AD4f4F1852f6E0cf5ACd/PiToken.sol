// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./ERC20Snapshot.sol";
import "./AccessControl.sol";
import "./Pausable.sol";

contract PiToken is ERC20, ERC20Snapshot, AccessControl, Pausable {
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
        require(
            piprivate != address(0) &&
                pidevelopment != address(0) &&
                piecosystem != address(0) &&
                pireserve != address(0),
            "account cannot be the zero address"
        );

        require(
            privateAmount != 0 &&
                developmentAmount != 0 &&
                ecosystemAmount != 0 &&
                reserveAmount != 0,
            "amount cannot be zero"
        );

        _setupRole(DEFAULT_ADMIN_ROLE, pireserve);
        _setupRole(SNAPSHOT_ROLE, piprivate);
        _setupRole(PAUSER_ROLE, pidevelopment);
        _mint(piprivate, privateAmount * 10**decimals());
        _mint(pidevelopment, developmentAmount * 10**decimals());
        _mint(piecosystem, ecosystemAmount * 10**decimals());
        _mint(pireserve, reserveAmount * 10**decimals());
        _setupRole(BURNER_ROLE, piecosystem);
    }

    function snapshot() external onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function burn(uint256 amount) external {
        require(amount != 0, "amount cannot be zero");
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount)
        external
        onlyRole(BURNER_ROLE)
        whenNotPaused
    {
        require(account != address(0), "account cannot be the zero address");
        require(amount != 0, "amount cannot be zero");
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _revokeRole(bytes32 role, address account) internal override {
        if (hasRole(role, account)) {
            address caller = _msgSender();
            if (role == DEFAULT_ADMIN_ROLE && account == caller) {
                revert(
                    "An account with the DEFAULT_ADMIN_ROLE role cannot renounce himself"
                );
            }
        }
        super._revokeRole(role, account);
    }
}
