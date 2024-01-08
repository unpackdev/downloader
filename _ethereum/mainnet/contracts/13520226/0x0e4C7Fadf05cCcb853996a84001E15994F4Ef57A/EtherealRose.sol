// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./IERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC165.sol";

                                                                                                                        
///////////////////////////////////////////////////////////////////////                                                                                                                                                                       
//                                                                   //             
//                           .''..,::,..                             //             
//                         .''....;llllc;'..  ..',.                  //             
//                        .'.....';:cloooool:;colol.                 //             
//                       .;'.....',;;;;:clllloc,,coc.                //             
//                       .,..'.';;,''',:ccc:;,,'.'cd;                //             
//                        .',;,,,,,'''.';,',,....;co;.               //             
//                         .,:;'.,,..'..',';,...'ll;'....,.          //             
//                         .,c;...,'....,;,,.. .'oc... .,c;.         //             
//                       .,;;;:;...''''',''... .,,... .;cc:.         //             
//                     .,;,'...:c;'',''''......;'. ..':c:,.          //             
//                   .;;'.',,..':;,,,''...',;;;,...','..             //             
//               ...;::,..:ol;'.',,;::lllcc;'........                //             
//              ..';:c:;'.,odc,..,coxxoc,...'........                //             
//                  .;cc:;,;loc:;,,;:;,',,,,'........                //             
//                    ...',;::::;,,,,,;;;;,,,,''....                 //             
//                         ...'''''.............                     //             
//                        ..,;;'......   ..',.                       //             
//                       .',:ccc,...........,.   ...''....           //             
//                      ..,;:::;,....',,....'.......'''''''...       //             
//                     ..,;;;;,'...  ............................    //             
//                   ...',,;,,''...    ............     .....        //             
//                   ..'',;;;,...     ...  .....                     //             
//                 .',...'','..        .........                     //             
//                 ...      ............'......                      //             
//                          .''.......'';;,'...                      //             
//                           .,,,,,,',;;:cc;.                        //             
//                            .,:::;;;;::::,.                        //             
//                             .,::;;;;,'....                        //             
//                               .;;'..     .                        //             
//                                ...       .                        //             
//                                           .                       //             
//                                           .                       //             
//                                           .                       //             
//                                           .                       //             
///////////////////////////////////////////////////////////////////////
contract EtherealRose is AdminControl, ICreatorExtensionTokenURI {

    using Strings for uint256;

    mapping(uint256 => string[]) _roses;
    uint rotationIndex;
    uint rotationLength;
    uint rotationStartTime;

    address _creator;
    uint _tokenId;

    constructor(address creator) {
        _creator = creator;
    }

    function mint() public adminRequired {
        require(_tokenId == 0, 'Token already minted');
        _tokenId = IERC721CreatorCore(_creator).mintExtension(msg.sender);
    }

    /**
        Used to switch which set of images is shown.
     */
    function setRotationIndex(uint _newIndex) public {
        require(IERC721(_creator).ownerOf(_tokenId) == msg.sender || isAdmin(msg.sender), "Only owner or admin can change.");
        require(_roses[_newIndex].length > 0, "Cannot switch to empty rotation.");
        rotationIndex = _newIndex;
    }

    /**
        Used to set how long the rotation is.
     */
    function setRotationLength(uint _newLength) public {
        require(IERC721(_creator).ownerOf(_tokenId) == msg.sender || isAdmin(msg.sender), "Only owner or admin can change.");
        rotationLength = _newLength;
    }

    /**
        Used to set when the rotation actually starts
     */
    function setRotationStartTime(uint _newStartTime) public {
        require(IERC721(_creator).ownerOf(_tokenId) == msg.sender || isAdmin(msg.sender), "Only owner or admin can change.");
        rotationStartTime = _newStartTime;
    }

    /**
        Adding a new seet of roses
     */
    function addRotation(string[] memory newRoses, uint roseIdx) public adminRequired {
        require(newRoses.length > 0, "Cannot add empty rotation.");
        _roses[roseIdx] = newRoses;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId);
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(tokenId == _tokenId && creator == _creator, 'Invalid token.');
        uint timeSinceStart = block.timestamp - rotationStartTime;

        uint moddedRotation = (timeSinceStart / rotationLength) % _roses[rotationIndex].length;

        return _roses[rotationIndex][moddedRotation];
    }
}
