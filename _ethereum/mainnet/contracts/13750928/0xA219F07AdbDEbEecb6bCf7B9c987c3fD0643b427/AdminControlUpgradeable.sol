// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./IERC165Upgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./IAdminControlUpgradeable.sol";

abstract contract AdminControlUpgradeable is
    Initializable,
    OwnableUpgradeable,
    IAdminControlUpgradeable,
    ERC165Upgradeable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // Track registered admins
    EnumerableSetUpgradeable.AddressSet private _admins;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __AdminControl_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC165_init_unchained();
        __AdminControl_init_unchained();
    }

    function __AdminControl_init_unchained() internal initializer {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return interfaceId == type(IAdminControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Only allows approved admins to call the specified function
     */
    modifier adminRequired() {
        require(isAdmin(_msgSender()), "AdminControl: Must be owner or admin");
        _;
    }

    /**
     * @dev See {IAdminControl-getAdmins}.
     */
    function getAdmins() external view override returns (address[] memory admins) {
        admins = new address[](_admins.length());
        for (uint256 i = 0; i < _admins.length(); i++) {
            admins[i] = _admins.at(i);
        }
        return admins;
    }

    /**
     * @dev See {IAdminControl-approveAdmin}.
     */
    function approveAdmin(address admin) external override onlyOwner {
        if (_admins.add(admin)) {
            emit AdminApproved(admin, msg.sender);
        }
    }

    /**
     * @dev See {IAdminControl-revokeAdmin}.
     */
    function revokeAdmin(address admin) external override onlyOwner {
        if (_admins.remove(admin)) {
            emit AdminRevoked(admin, msg.sender);
        }
    }

    /**
     * @dev See {IAdminControl-isAdmin}.
     */
    function isAdmin(address admin) public view override returns (bool) {
        return (owner() == admin || _admins.contains(admin));
    }

    uint256[49] private __gap;
}
