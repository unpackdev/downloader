// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";
import "./AccessControl.sol";
import "./Context.sol";
import "./TransferHelper.sol";

contract NitroVault is Context, AccessControl {
    bytes32 public constant VAULT = keccak256("VAULT");
    address public owner;
    address public token;

    constructor(address _owner, address _token) {
        require(_owner != address(0), "Vault:: Owner can not be zero address");
        require(_token != address(0), "Vault:: Token can not be zero address");
        owner = _owner;
        token = _token;
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
    }

    function release(address _to, uint256 _amount) public {
        require(_to != address(0), "Vault:: _to can not be zero address");
        require(_amount > 0, "Vault:: _amount can not be zero");
        require(hasRole(VAULT, _msgSender()), "Vault:: Release :: Unauthorized Access");
        TransferHelper.safeTransfer(token, _to, _amount);
    }
}