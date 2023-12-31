// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author ambr0sia

/*
 * ⋆｡°✩ ⋆⁺｡˚⋆˙‧₊✩₊‧˙⋆˚｡⁺⋆ ✩°｡⋆
 *    wishing ・゜゜・・゜゜・．
 * ｡･ﾟﾟ･　　    tree    ･ﾟﾟ･｡
 * ⋆｡°✩ ⋆⁺｡˚⋆˙‧₊✩₊‧˙⋆˚｡⁺⋆ ✩°｡⋆
 *
 * wishes cascade like leaves in the wind, 
 * capturing the quiet yearnings of the human spirit. 
 *
 * with each invocation of the makeWish function, 
 * souls may inscribe their desires, 
 * max 256 characters
 *
 * i wish... i wish... i wish... 
 * 
 * cryptographically bound, 
 * these whispered dreams, transcend the tangible, 
 * becoming a network of collective imagination, 
 * universal desires 
 * and unspoken connections. 
 * 
 */

import "./Ownable.sol";
import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

contract wishingtree is Ownable, IERC165, ICreatorExtensionTokenURI {
    string private baseTokenURI;
    string[] private wishes;

    event WishMade(address indexed wisher, string wishText, string wishAcknowledgement);

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return (
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId
        );
    }

    function setBaseTokenURI(string memory _newBaseTokenURI) public onlyOwner {
        baseTokenURI = _newBaseTokenURI;
    }

    function mint(address br0sieBaseContract, string calldata newMintURI) public onlyOwner {
        require(wishes.length > 0, "no wishes have been made"); 
        IERC721CreatorCore(br0sieBaseContract).mintExtension(msg.sender);
        baseTokenURI = newMintURI;
    }

    function makeWish(string memory _wish) public {
        require(bytes(_wish).length > 0, "inscribe your deepest desires");
        require(bytes(_wish).length <= 256, "brevity is the soul of wish. max 256 characters pls");

        wishes.push(_wish);
        emit WishMade(msg.sender, _wish, "wish received. trust in the tree");
    }

    function tokenURI(address, uint256) external view override returns(string memory) {
        return baseTokenURI;
    }

    function seeWishes() public view returns (string[] memory) {
        return wishes;
    }
}
