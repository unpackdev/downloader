// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @author jpegmint.xyz

import "./GremlinsERC721Proxy.sol";
import "./StorageSlot.sol";
import "./IAccessControl.sol";

/*
 ██████╗ ██████╗ ███████╗███╗   ███╗██╗     ██╗███╗   ██╗███████╗
██╔════╝ ██╔══██╗██╔════╝████╗ ████║██║     ██║████╗  ██║██╔════╝
██║  ███╗██████╔╝█████╗  ██╔████╔██║██║     ██║██╔██╗ ██║███████╗
██║   ██║██╔══██╗██╔══╝  ██║╚██╔╝██║██║     ██║██║╚██╗██║╚════██║
╚██████╔╝██║  ██║███████╗██║ ╚═╝ ██║███████╗██║██║ ╚████║███████║
 ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝
                                                                 
███████╗██████╗ ██╗████████╗██╗ ██████╗ ███╗   ██╗               
██╔════╝██╔══██╗██║╚══██╔══╝██║██╔═══██╗████╗  ██║               
█████╗  ██║  ██║██║   ██║   ██║██║   ██║██╔██╗ ██║               
██╔══╝  ██║  ██║██║   ██║   ██║██║   ██║██║╚██╗██║               
███████╗██████╔╝██║   ██║   ██║╚██████╔╝██║ ╚████║               
╚══════╝╚═════╝ ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝               
*/
contract GremlinsEdition is GremlinsERC721Proxy {

    // Base Roles
    bytes32 private constant _AIRDROP_ADMIN_ROLE = keccak256("AIRDROP_ADMIN_ROLE");

    // Max planned supply
    uint16 public constant TOKEN_MAX_SUPPLY = 80;

    // App storage structure
    struct AppStorage {
        uint16 totalSupply;
    }

    // Constructor
    constructor(address baseContract, string memory name_, string memory symbol_)
    GremlinsERC721Proxy(baseContract, name_, symbol_) {}

    /**
     * @dev Gets app storage struct from defined storage slot.
     */
    function _appStorage() internal pure returns(AppStorage storage app) {
        bytes32 storagePosition = bytes32(uint256(keccak256("app.storage")) - 1);
        assembly {
            app.slot := storagePosition
        }
    }

    /**
     * @dev Mints tokens to the specified wallets.
     */
    function airdrop(address[] calldata wallets) public {
        require(IAccessControl(_implementation()).hasRole(_AIRDROP_ADMIN_ROLE, msg.sender), "!R");
        require(availableSupply() > wallets.length, "#");

        for (uint8 i = 0; i < wallets.length; i++) {
            _airdrop(wallets[i], totalSupply() + 1);
        }
    }

    /**
     * @dev Internal airdrop helper.
     */
    function _airdrop(address to, uint256 tokenId) internal {
        _appStorage().totalSupply += 1;
        bytes memory data = abi.encodeWithSignature("mint(address,uint256,string)", to, tokenId, "");
        Address.functionDelegateCall(_implementation(), data);
    }
    
    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _appStorage().totalSupply;
    }

    /**
     * @dev Helper function to pair with total supply.
     */
    function availableSupply() public view returns (uint256) {
        return TOKEN_MAX_SUPPLY - totalSupply();
    }
}
