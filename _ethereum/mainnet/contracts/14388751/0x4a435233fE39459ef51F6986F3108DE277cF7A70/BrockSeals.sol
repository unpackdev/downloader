// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: eucliiid.xyz

/////////////////////////////////////////////////////////////////////////////////////////
//        ▐▄,                                                                     ,    //      
//         ██▄ ▐▄⌐╓▓L                                                            ]C    //            
//          █████████                                          ▄▄         ▄▄▄██▄▄▌     //                
//      ▄████████████                     ▄█               ▄▄████        ████▀████▄    //            
//    ▐██████████████M    ,▄▄▄▄▄ç         ███⌐        ▄▄█████████       ████▌,██████   //           
//    ▐██████▄▄ '▀███⌐  4▀▀▀▀▀▀▀└        ┌████         -▀▀▀█████▌       ██████▀  ▀▀▀   //           
//     █████████▄   -                    ██████            █████   ,█    ▀█████▄       //          
//      '▀████████.   ▄▄█████████▄      ████████          █████▀  ███     ███████      //         
//         └███████  '▀'▀▀▀▀▀▀▀▀└      ███"█████▌     ]█▄█████═  ¬███    ▄█▀ └███      //        
//  ▐█▄      ▀█████▌                  ▄██-  ██████     ▀█████▄▄▄▄▄████  ▄█"   ███      //         
//  ▀██▄     ▄█████'  ,▄▄█████████▄  ,██▄▄▄▄▄██████▄,  ████████████▀███▄█-   ▄██▌      //         
//    ▀███████████" ,███████████████████████████▀▀██████▀▀          ╙██████████▀       //         
//       ¬▀▀▀▀▀"             ▄▄███▀▀▀▀▀¬            "▀-              ▐█▀▀███▀└         //       
//                        .═▀└                                      ╒█`                //     
//                                                                  Å                  //  
/////////////////////////////////////////////////////////////////////////////////////////

import "./ERC721Upgradeable.sol";
import "./AdminControlUpgradeable.sol";

import "./ERC721CreatorExtensionBurnable.sol";
import "./CreatorExtensionBasic.sol";

contract BrockSeals is ERC721CreatorExtensionBurnable, CreatorExtensionBasic {
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721CreatorExtensionBurnable, CreatorExtensionBasic) returns (bool) {
        return interfaceId == LEGACY_ERC721_EXTENSION_BURNABLE_INTERFACE
            || interfaceId == type(IERC721CreatorExtensionBurnable).interfaceId
            || interfaceId == type(ICreatorExtensionBasic).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function mint(address creator, address to, string memory uri) external adminRequired returns (uint256) {
        return _mint(creator, to, uri);
    }
    
    /**
     * @dev See {ICreatorExtensionBasic-setBaseTokenURI}.
     */
    function setBaseTokenURI(address creator, string calldata uri) external virtual override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(ICreatorCore).interfaceId), "Requires creator to implement ICreatorCore");
        ICreatorCore(creator).setBaseTokenURIExtension(uri);
    }       

    /**
     * @dev See {ICreatorExtensionBasic-setTokenURI}.
     */
    function setTokenURI(address creator, uint256 tokenId, string calldata uri) external virtual override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(ICreatorCore).interfaceId), "Requires creator to implement CreatorCore");
        ICreatorCore(creator).setTokenURIExtension(tokenId, uri);
    }

    /**
     * @dev See {ICreatorExtensionBasic-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(address creator, string calldata prefix) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(ICreatorCore).interfaceId), "Requires creator to implement CreatorCore");
        ICreatorCore(creator).setTokenURIPrefixExtension(prefix);
    }
}