// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @author jpegmint.xyz

import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./StorageSlotUpgradeable.sol";

/*
 ██████╗ ██████╗ ███████╗███╗   ███╗██╗     ██╗███╗   ██╗███████╗
██╔════╝ ██╔══██╗██╔════╝████╗ ████║██║     ██║████╗  ██║██╔════╝
██║  ███╗██████╔╝█████╗  ██╔████╔██║██║     ██║██╔██╗ ██║███████╗
██║   ██║██╔══██╗██╔══╝  ██║╚██╔╝██║██║     ██║██║╚██╗██║╚════██║
╚██████╔╝██║  ██║███████╗██║ ╚═╝ ██║███████╗██║██║ ╚████║███████║
 ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝
                                                                 
 █████╗  ██████╗ ██████╗███████╗███████╗███████╗     ██████╗ ██████╗ ███╗   ██╗████████╗██████╗  ██████╗ ██╗     
██╔══██╗██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝    ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔══██╗██╔═══██╗██║     
███████║██║     ██║     █████╗  ███████╗███████╗    ██║     ██║   ██║██╔██╗ ██║   ██║   ██████╔╝██║   ██║██║     
██╔══██║██║     ██║     ██╔══╝  ╚════██║╚════██║    ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══██╗██║   ██║██║     
██║  ██║╚██████╗╚██████╗███████╗███████║███████║    ╚██████╗╚██████╔╝██║ ╚████║   ██║   ██║  ██║╚██████╔╝███████╗
╚═╝  ╚═╝ ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚══════╝
*/
contract GremlinsAccessControl is Initializable, AccessControlUpgradeable, OwnableUpgradeable {

    /// ERC1967 implementation storage slot
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    
    // Whitelist role allows minting.
    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");

    // General admin role to manage airdrop.
    bytes32 public constant AIRDROP_ADMIN_ROLE = keccak256("AIRDROP_ADMIN_ROLE");


    //  ██████╗ ██████╗ ███╗   ██╗███████╗████████╗██████╗ ██╗   ██╗ ██████╗████████╗ ██████╗ ██████╗ 
    // ██╔════╝██╔═══██╗████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║   ██║██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗
    // ██║     ██║   ██║██╔██╗ ██║███████╗   ██║   ██████╔╝██║   ██║██║        ██║   ██║   ██║██████╔╝
    // ██║     ██║   ██║██║╚██╗██║╚════██║   ██║   ██╔══██╗██║   ██║██║        ██║   ██║   ██║██╔══██╗
    // ╚██████╗╚██████╔╝██║ ╚████║███████║   ██║   ██║  ██║╚██████╔╝╚██████╗   ██║   ╚██████╔╝██║  ██║
    //  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝

    function __GremlinsAccessControl_base_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __Ownable_init_unchained();
        __GremlinsAccessControl_init_unchained();
    }
    
    function __GremlinsAccessControl_proxy_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __Ownable_init_unchained();
    }

    function __GremlinsAccessControl_init_unchained() internal initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(AIRDROP_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(WHITELISTED_ROLE, AIRDROP_ADMIN_ROLE);
        _setRoleAdmin(AIRDROP_ADMIN_ROLE, AIRDROP_ADMIN_ROLE);
    }


    // ██████╗ ██████╗  ██████╗ ██╗  ██╗██╗   ██╗
    // ██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝
    // ██████╔╝██████╔╝██║   ██║ ╚███╔╝  ╚████╔╝ 
    // ██╔═══╝ ██╔══██╗██║   ██║ ██╔██╗   ╚██╔╝  
    // ██║     ██║  ██║╚██████╔╝██╔╝ ██╗   ██║   
    // ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   
    
    /**
     * @dev Returns the stored implementation address. 0x0 when accessed directly.
     */
    function _implementation() internal view virtual returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
    
    /**
     * @dev Returns GremlinWhitelist found at implementation address.
     */
    function _getERC721Implementation() internal view returns(GremlinsAccessControl) {
        return GremlinsAccessControl(_implementation());
    }


    // ██╗    ██╗██╗  ██╗██╗████████╗███████╗██╗     ██╗███████╗████████╗
    // ██║    ██║██║  ██║██║╚══██╔══╝██╔════╝██║     ██║██╔════╝╚══██╔══╝
    // ██║ █╗ ██║███████║██║   ██║   █████╗  ██║     ██║███████╗   ██║   
    // ██║███╗██║██╔══██║██║   ██║   ██╔══╝  ██║     ██║╚════██║   ██║   
    // ╚███╔███╔╝██║  ██║██║   ██║   ███████╗███████╗██║███████║   ██║   
    //  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝   ╚═╝   ╚══════╝╚══════╝╚═╝╚══════╝   ╚═╝   

    modifier onlyWhitelisted(address wallet) {
        bool isWhitelisted = _getERC721Implementation().hasRole(WHITELISTED_ROLE, wallet);
        require(isWhitelisted, "!W");
        _;
    }

    modifier onlyAirdropAdmin() {
        bool isAirdropAdmin = _getERC721Implementation().hasRole(AIRDROP_ADMIN_ROLE, _msgSender());
        require(isAirdropAdmin, "!R");
        _;
    }

    /**
     * @dev Deployer and Airdrop admins can manage metadata.
     */
    modifier onlyMetadataAdmin() {
        bool isAirdropAdmin = _getERC721Implementation().hasRole(AIRDROP_ADMIN_ROLE, _msgSender());
        bool isOwner = owner() == _msgSender();

        require(isAirdropAdmin || isOwner, "!R");
        _;
    }

    /**
     * @dev Add wallets to whitelist via Role mechanism.
     */
    function addWhitelist(address[] calldata wallets) public onlyRole(AIRDROP_ADMIN_ROLE) {
        for (uint8 i = 0; i < wallets.length; i++) {
            _grantRole(WHITELISTED_ROLE, wallets[i]);
        }
    }
    
    /**
     * @dev Remove wallets from whitelist via Role mechanism.
     */
    function removeWhitelist(address[] calldata wallets) public onlyRole(AIRDROP_ADMIN_ROLE) {
        for (uint8 i = 0; i < wallets.length; i++) {
            _revokeRole(WHITELISTED_ROLE, wallets[i]);
        }
    }

    /**
     * @dev Checks whitelist at this implementation.
     */
    function checkWhitelist(address wallet) public view returns (bool) {
        return hasRole(WHITELISTED_ROLE, wallet);
    }
    
    /**
     * @dev Helper function to check if wallet is whitelisted at eip1967.proxy.implementation
     */
    function _hasRoleAtImplementation(bytes32 role, address wallet) internal view returns (bool) {
        return _getERC721Implementation().hasRole(role, wallet);
    }
}
