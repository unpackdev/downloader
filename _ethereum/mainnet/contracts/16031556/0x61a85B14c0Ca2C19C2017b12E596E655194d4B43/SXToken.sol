// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";

contract SXToken is ERC20, ERC20Burnable, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    address public ROUTER;
    address public DEV;

    constructor(
    ) ERC20("test2", "test2") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        DEV = msg.sender;
        uint256 total = 10000000 * 10**decimals();
        // pool
        _mint(msg.sender, total);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function changeDev(address _dev) public onlyRole(DEFAULT_ADMIN_ROLE) {
        DEV = _dev;
    }

    function changeRouter(address _router) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ROUTER = _router;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        uint256 fee = 0;
        //sell
        if (to == ROUTER) {
            // 7% fee
            fee = (amount * 7) / 100;
            transfer(DEV, fee);
        }
        super._beforeTokenTransfer(from, to, amount - fee);
    }
}
