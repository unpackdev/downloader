pragma solidity ^0.6.0;

import "./AccessControl.sol";
import "./Ownable.sol";

contract MinterRole is AccessControl, Ownable {

    bytes32 public constant MINTER_ADMIN_ROLE = keccak256("MINTER_ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bool private _finalized = false;
    event Finalized();

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    constructor () public {
        _setRoleAdmin(MINTER_ROLE, MINTER_ADMIN_ROLE);
    }

    /**
     * @dev Create and ading new role.
     * @param role role account.
     * @param account account for adding to the role.
     */
    function addAdmin(bytes32 role, address account) public virtual onlyOwner returns (bool) {
        require(!_finalized, "MinterRole: already finalized");

        _setupRole(role, account);
        return true;
    }

    /**
     * @dev block adding admins.
     */
    function finalize() public virtual onlyOwner {
        require(!_finalized, "MinterRole: already finalized");

        _finalized = true;
        emit Finalized();
    }
}