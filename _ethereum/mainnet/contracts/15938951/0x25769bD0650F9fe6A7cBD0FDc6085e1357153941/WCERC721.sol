// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;



import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

/**
* @dev   Generated using openzepplin wizard... https://docs.openzeppelin.com/contracts/4.x/wizard
*        at the time of writing it is envisaged that this file
*        will be replaced as additional functionality is required
*  NOTE: 
*    ERC721  - required to implement standard ERC721 tokens
*    ERC721Enumerable
*            - useful for keeping track of token supply and who
*              owns which tokens
*    Ownable - required for OpenSea to determine who the contract/collection owner is.. 
*              not required for this project but also to potentially transfer ownership etc.
**/
abstract contract WorldCupSweepstakeERC721 is ERC721, ERC721Enumerable, Ownable {
    

    constructor(string memory name_, string memory symbol_) ERC721(name_,symbol_) {}
    
    
    /**
     * @dev overrides required by Solidity due to multiple inheritance
     **/
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        //Will be using ERC721Enumerable implementation
        //as that is the right most Parent in inheritance
        //https://solidity-by-example.org/inheritance/#:~:text=Solidity%20supports%20multiple%20inheritance.,must%20use%20the%20keyword%20override%20.
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev allows other contracts and utilities like opensea
     *      write code to determine how it can interact with
     *      our contract based on whiche interfaces we are implementing
     **/
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
