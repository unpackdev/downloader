// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

//                ,|||||<              ~|||||'         `_+7ykKD%RDqmI*~`          
//                8@@@@@@8'           `Q@@@@@`     `^oB@@@@@@@@@@@@@@@@@R|`       
//               !@@@@@@@@Q;          L@@@@@J    '}Q@@@@@@QqonzJfk8@@@@@@@Q,      
//               Q@@@@@@@@@@j        `Q@@@@Q`  `m@@@@@@h^`         `?Q@@@@@*      
//              =@@@@@@@@@@@@D.      7@@@@@i  ~Q@@@@@w'              ^@@@@@*      
//              Q@@@@@m@@@@@@@Q!    `@@@@@Q  ;@@@@@@;                .txxxx:      
//             |@@@@@u *@@@@@@@@z   u@@@@@* `Q@@@@@^                              
//            `Q@@@@Q`  'W@@@@@@@R.'@@@@@B  7@@@@@%        :DDDDDDDDDDDDDD5       
//            c@@@@@7    `Z@@@@@@@QK@@@@@+  6@@@@@K        aQQQQQQQ@@@@@@@*       
//           `@@@@@Q`      ^Q@@@@@@@@@@@W   j@@@@@@;             ,6@@@@@@#        
//           t@@@@@L        ,8@@@@@@@@@@!   'Q@@@@@@u,        .=A@@@@@@@@^        
//          .@@@@@Q           }@@@@@@@@D     'd@@@@@@@@gUwwU%Q@@@@@@@@@@g         
//          j@@@@@<            +@@@@@@@;       ;wQ@@@@@@@@@@@@@@@Wf;8@@@;         
//          ~;;;;;              .;;;;;~           '!Lx5mEEmyt|!'    ;;;~          
//
// Powered By:    @niftygateway
// Author:        @niftynathang
// Collaborators: @conviction_1 
//                @stormihoebe
//                @smatthewenglish
//                @dccockfoster
//                @blainemalone

import "./IERC721Cloneable.sol";
import "./IERC721DefaultOwnerCloneable.sol";
import "./IERC721MetadataGenerator.sol";
import "./INiftyEntityCloneable.sol";
import "./Clones.sol";
import "./NiftyPermissions.sol";

contract NiftyCloneFactory is NiftyPermissions {

    event ClonedERC721(address newToken);    
    event ClonedERC721MetadataGenerator(address metadataGenerator);    
    
    constructor(address niftyRegistryContract_) {
        initializeNiftyEntity(niftyRegistryContract_);
    }
        
    function cloneERC721(address implementation, address niftyRegistryContract_, address defaultOwner_, string calldata name_, string calldata symbol_, string calldata baseURI_) external returns (address) {
        _requireOnlyValidSender();
        require(IERC165(implementation).supportsInterface(type(IERC721Cloneable).interfaceId), "Not a valid ERC721 Token");        
        address clone = Clones.clone(implementation);

        emit ClonedERC721(clone);

        IERC721Cloneable(clone).initializeERC721(name_, symbol_, baseURI_);        

        if(IERC165(implementation).supportsInterface(type(INiftyEntityCloneable).interfaceId)) {
            INiftyEntityCloneable(clone).initializeNiftyEntity(niftyRegistryContract_);
        }

        if(IERC165(implementation).supportsInterface(type(IERC721DefaultOwnerCloneable).interfaceId)) {
            IERC721DefaultOwnerCloneable(clone).initializeDefaultOwner(defaultOwner_);
        }        

        return clone;
    }
    
    function cloneMetadataGenerator(address implementation, address niftyRegistryContract_) external returns (address) {
        _requireOnlyValidSender();
        require(IERC165(implementation).supportsInterface(type(IERC721MetadataGenerator).interfaceId), "Not a valid Metadata Generator");
        address clone = Clones.clone(implementation);        

        emit ClonedERC721MetadataGenerator(clone);
        
        if(IERC165(implementation).supportsInterface(type(INiftyEntityCloneable).interfaceId)) {
            INiftyEntityCloneable(clone).initializeNiftyEntity(niftyRegistryContract_);
        }        

        return clone;
    }
}