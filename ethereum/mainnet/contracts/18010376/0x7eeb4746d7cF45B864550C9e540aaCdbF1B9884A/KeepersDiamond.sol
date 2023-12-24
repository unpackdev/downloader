// SPDX-License-Identifier: MIT

/*                                                                                                                                                                                                                                                                            
                                       ..';;::::::;;;::::;,'.                                       
                                   .,;;;;;,'....     ....';;;;;;'.                                  
                                ';;;,..                       .';;:,.                               
                             .,;,.                                .';;'                             
                           .,;.                  ...                 .,;.                           
                          .;.                                          .;;.                         
                         ',.                                             ';.                        
                        ''                                                .,.                       
                       .'                                                  .,                       
                      .'.                      .....                        ..                      
                      ..                    .;;,,,;,,;,.                     ..                     
                     ..                    ;c'       .;c'                    ..                     
                     ..                   ;c.          'c.                    .                     
                     .                .',;dl.         .;dl,,'.                ..                    
                     .              ,:;,..:xc:,.    .;:od,.',;;.               .                    
                    .             .:c.     ,c:cc.  ,l:::.     'c'              .                    
                    .             ,l.       .,:docldl;'        ,c.                                  
                                  ,c.        ';ddldxl,.        ,c.                                  
                                  .::.     '::lo' .;oc:;.     .c'                                   
                                   .,:,...;dc::.    '::do...';:.                                    
                                      ':clkd,.        .cxdlc;.                                      
                                    .,;,,,od:;.     .,;ldc,,;;'                                     
                                   ,c,.   .:c:c,   .:::c,    .:c.                                   
                                  'l.       ,;cxc;:do:;.       ;c.                                  
                                  ,c.        .;xkxOkl.         ,c.                                  
                                  .c,      .;:lx:';od::'      .c:                                   
                                   .:;.   .lc;c,   .:::l;   .,c;                                    
                                     .,;;:do;,.      .;cxl;;;,.                                     
                                     ';;;:do;'.      .,cxl;;;,.                                     
                                   .:;.   'oc::'   .;::o:.  .,c;.                                   
                                  .l'      .::ld;.,ld::,      .c;                                   
                                  ;c.        .:xkxOko'         ,c.                                  
                                  .l'      .,;cxc;cdo:;.      .c:                                   
                                   'c;.   .cc;c;   .c::l,    'c;.                                   
                                    .';;,;od:,.     .,;lxc,;;;.                                     
                                        .'l:           .o:..                                        
                                          'l'         .::.                                          
                                           .:;'......,:;.                                           
                                             .,;,,,,,'.                                             
                                                                                                    
                                                                                                    
                                 ..                              ...                                
                                  .''.                        .''..                                 
                                    ',,'.                  ..,,,.    ......                         
                                  ..,;:c;''...        .....'..          ...':c'                     
                               .;:;;'.    ................                 .:Kx.                    
                            .:lc,.                                   ..';:cokd'                     
                           ;xo.                                 ..,:ldkkOOxo,                       
                          ;0l                            ...',:oxO0KXK0xl;.                         
                          ;0x'   ................''',;:lodkOKXNWNX0ko:'.                            
                           ,oxdoccclodxxxkkkOO00KKXXXNWWWWWNK0xoc;..                                
                             .':lloodxkO00KKKKKK0OOOkxdoc:;'..                                      
                                    ................                                                                                                                                                                       
*/

pragma solidity 0.8.18;

import "./SolidStateDiamondRevokableUpgradability.sol";
import "./AccessControlInternal.sol";
import "./IERC721.sol";
import "./IERC165.sol";
import "./IERC2981.sol";
import "./IERC721Enumerable.sol";
import "./ERC2981Storage.sol";
import "./KeepersERC721Storage.sol";
import "./ERC721MetadataStorage.sol";
import "./TermsStorage.sol";
import "./ConstantsLib.sol";
import "./DiamondWritableInternal.sol";
import "./Constants.sol";
import "./DiamondOperatorFilter.sol";
import "./Counters.sol";

/**
 * @title KeepersDiamond "Diamond" proxy implementation based on SolidState Diamond Reference
 */
contract KeepersDiamond is SolidStateDiamondRevokableUpgradability, AccessControlInternal, DiamondOperatorFilter {
    using Counters for Counters.Counter;

    constructor(string memory name_, string memory symbol_, string memory baseURI_) {
        // ERC165 - note: other interfaces are set in SolidStateDiamondRevokableUpgradability
        _setSupportsInterface(type(IERC721).interfaceId, true);
        _setSupportsInterface(type(IERC721Enumerable).interfaceId, true);
        _setSupportsInterface(type(IERC2981).interfaceId, true);

        // AccessControl
        _grantRole(ConstantsLib.KEEPERS_TERMS_OPERATOR, msg.sender);
        _grantRole(ConstantsLib.KEEPERS_LICENSE_OPERATOR, msg.sender);

        // ERC2981
        ERC2981Storage.layout().defaultRoyaltyBPS = 700; // 7%
        ERC2981Storage.layout().defaultRoyaltyReceiver = msg.sender;

        // mint parameters
        KeepersERC721Storage.layout().maxPerAddress = 10;
        KeepersERC721Storage.layout().numAvailableTokens = uint16(ConstantsLib.MAX_TICKETS);

        // Metadata
        ERC721MetadataStorage.layout().name = name_;
        ERC721MetadataStorage.layout().symbol = symbol_;
        ERC721MetadataStorage.layout().baseURI = baseURI_;

        // Terms version
        TermsStorage.layout().termsVersion.increment(); // Set terms to V1 by default

        // Set up Operator Filter Registry
        __OperatorFilterer_init(CANONICAL_CORI_SUBSCRIPTION);
    }
}
