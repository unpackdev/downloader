// SPDX-License-Identifier: MIT
// Contract by Kokako Loon
// Artist:
//     _____                      ___           ___           ___                                 
//    /  /::\       ___          /  /\         /__/\         /  /\                                
//   /  /:/\:\     /  /\        /  /::\        \  \:\       /  /::\                               
//  /  /:/  \:\   /  /:/       /  /:/\:\        \  \:\     /  /:/\:\                              
// /__/:/ \__\:| /__/::\      /  /:/~/::\   _____\__\:\   /  /:/~/::\                             
// \  \:\ /  /:/ \__\/\:\__  /__/:/ /:/\:\ /__/::::::::\ /__/:/ /:/\:\                            
//  \  \:\  /:/     \  \:\/\ \  \:\/:/__\/ \  \:\~~\~~\/ \  \:\/:/__\/                            
//   \  \:\/:/       \__\::/  \  \::/       \  \:\  ~~~   \  \::/                                 
//    \  \::/        /__/:/    \  \:\        \  \:\        \  \:\                                 
//     \__\/         \__\/      \  \:\        \  \:\        \  \:\                                
//                               \__\/         \__\/         \__\/                                
//      ___         ___                         ___           ___           ___           ___     
//     /  /\       /  /\                       /  /\         /__/\         /__/\         /  /\    
//    /  /::\     /  /:/_                     /  /:/_        \  \:\        \  \:\       /  /::\   
//   /  /:/\:\   /  /:/ /\    ___     ___    /  /:/ /\        \  \:\        \  \:\     /  /:/\:\  
//  /  /:/~/:/  /  /:/ /:/_  /__/\   /  /\  /  /:/ /:/_   _____\__\:\   ___  \  \:\   /  /:/~/:/  
// /__/:/ /:/  /__/:/ /:/ /\ \  \:\ /  /:/ /__/:/ /:/ /\ /__/::::::::\ /__/\  \__\:\ /__/:/ /:/___
// \  \:\/:/   \  \:\/:/ /:/  \  \:\  /:/  \  \:\/:/ /:/ \  \:\~~\~~\/ \  \:\ /  /:/ \  \:\/:::::/
//  \  \::/     \  \::/ /:/    \  \:\/:/    \  \::/ /:/   \  \:\  ~~~   \  \:\  /:/   \  \::/~~~~ 
//   \  \:\      \  \:\/:/      \  \::/      \  \:\/:/     \  \:\        \  \:\/:/     \  \:\     
//    \  \:\      \  \::/        \__\/        \  \::/       \  \:\        \  \::/       \  \:\    
//     \__\/       \__\/                       \__\/         \__\/         \__\/         \__\/ 

pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC1155Supply.sol";

contract ArtByDiana is ERC1155, Ownable, Pausable, ERC1155Supply {
    string public uriPrefix = "ipfs://QmSwsiUHjuXGnYovP9SRjb8Zs35nURE2JJUnDY92jtFuvn/";
    string public name = "ArtByDiana";
    string public symbol = "ABD";

    constructor() ERC1155("") {}

    function setURI(string memory newuri) public onlyOwner {
        uriPrefix = newuri;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function uri(uint256 _tokenid) 
        override 
        public 
        view
        virtual
        returns (string memory) 
    {
        require(exists(_tokenid), "ERC1155Metadata: URI query for nonexistent token");
        string memory currentBaseURI = uriPrefix;
        return string(
            abi.encodePacked(
                currentBaseURI,
                Strings.toString(_tokenid),".json"
            )
        );
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

}
