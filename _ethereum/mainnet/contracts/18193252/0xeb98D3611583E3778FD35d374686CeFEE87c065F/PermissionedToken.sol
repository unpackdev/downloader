// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// imported contracts and libraries
import "./ERC20.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

// interfaces
import "./IAllowlist.sol";

import "./constants.sol";
import "./errors.sol";

abstract contract PermissionedToken is ERC20, OwnableUpgradeable, UUPSUpgradeable {
    /// @notice allowlist manager to check permissions
    IAllowlist public immutable allowlist;

    /*///////////////////////////////////////////////////////////////
                         State Variables V1
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;

    /*///////////////////////////////////////////////////////////////
                Constructor for implementation Contract
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _allowlist)
        ERC20(_name, _symbol, _decimals)
        initializer
    {
        if (_allowlist == address(0)) revert BadAddress();

        allowlist = IAllowlist(_allowlist);
    }

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

    function __PermissionedToken_init(string memory _name, string memory _symbol, address _owner) internal onlyInitializing {
        if (_owner == address(0)) revert BadAddress();
        _transferOwnership(_owner);

        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                        Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     *
     */
    function _authorizeUpgrade(address /*newImplementation*/ ) internal virtual override {
        _checkOwner();
    }

    /*///////////////////////////////////////////////////////////////
                            ERC20 Functions
    //////////////////////////////////////////////////////////////*/

    function transfer(address _to, uint256 _amount) public virtual override returns (bool) {
        _checkPermissions(msg.sender);
        _checkPermissions(_to);

        return super.transfer(_to, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public virtual override returns (bool) {
        _checkPermissions(_from);
        _checkPermissions(_to);

        return super.transferFrom(_from, _to, _amount);
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    function _checkPermissions(address _address) internal view {
        if (!allowlist.hasTokenPrivileges(_address)) revert NotPermissioned();
    }
}
