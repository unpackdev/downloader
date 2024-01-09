// SPDX-License-Identifier: MIT

/*
* Blue.sol
*
* Author: Don Huey / twitter: donbtc
* Created: December 28th, 2021
* Creators: Blue the Great, Don Huey
*
* Mint Price:  0.0000 ETH
* Rinkby: 0x1d4591307a256c8336e9edca1e1e63f6d3098b7b
*
* Description: A story of yielding creative control to transform the world’s we navigate. 
*       Bryan Blue presents the “Alchemist”, a genesis work-of-art and 1 of 1 edition NFT.
*
  ________  ___       ___  ___  _______                                                                                              
|\   __  \|\  \     |\  \|\  \|\  ___ \   ___                                                                                       
\ \  \|\ /\ \  \    \ \  \\\  \ \   __/| |\__\                                                                                      
 \ \   __  \ \  \    \ \  \\\  \ \  \_|/_\|__|                                                                                      
  \ \  \|\  \ \  \____\ \  \\\  \ \  \_|\ \  ___                                                                                    
   \ \_______\ \_______\ \_______\ \_______\|\__\                                                                                   
    \|_______|\|_______|\|_______|\|_______|\|__|                                                                                   
                                                                                                                                    
                                                                                                                                    
                                                                                                                                    
 _________  ___  ___  _______           ________  ___       ________  ___  ___  _______   _____ ______   ___  ________  _________   
|\___   ___\\  \|\  \|\  ___ \         |\   __  \|\  \     |\   ____\|\  \|\  \|\  ___ \ |\   _ \  _   \|\  \|\   ____\|\___   ___\ 
\|___ \  \_\ \  \\\  \ \   __/|        \ \  \|\  \ \  \    \ \  \___|\ \  \\\  \ \   __/|\ \  \\\__\ \  \ \  \ \  \___|\|___ \  \_| 
     \ \  \ \ \   __  \ \  \_|/__       \ \   __  \ \  \    \ \  \    \ \   __  \ \  \_|/_\ \  \\|__| \  \ \  \ \_____  \   \ \  \  
      \ \  \ \ \  \ \  \ \  \_|\ \       \ \  \ \  \ \  \____\ \  \____\ \  \ \  \ \  \_|\ \ \  \    \ \  \ \  \|____|\  \   \ \  \ 
       \ \__\ \ \__\ \__\ \_______\       \ \__\ \__\ \_______\ \_______\ \__\ \__\ \_______\ \__\    \ \__\ \__\____\_\  \   \ \__\
        \|__|  \|__|\|__|\|_______|        \|__|\|__|\|_______|\|_______|\|__|\|__|\|_______|\|__|     \|__|\|__|\_________\   \|__|
                                                                                                                \|_________|        
                                                                                                                                                                                                                                                               
*                                                                                                                                  
*                                                                                                                               
* 
*
*/

pragma solidity > 0.5.0 < 0.9.0;

import "./ERC721.sol"; 
import "./SafeMath.sol"; 
import "./HueyAccessControllite.sol";
import "./Counters.sol"; 
import "./ERC2981ContractWideRoyalties.sol"; // Royalties for contract, EIP-2981


contract BLUE is ERC721, HueyAccessControllite, ERC2981ContractWideRoyalties {

    //@dev Using SafeMath
        using SafeMath for uint256;
    //@dev Using Counters for increment/decrement
        using Counters for Counters.Counter;
    //@dev uint256 to strings
        using Strings for uint256;



    //@dev Important numbers and state variables
        uint256 public constant MAX_TOKENS = 1; // Max supply of tokens
        Counters.Counter private tokenCounter;
        string public constant CurrentHash = "QmdTyZAFhLckUU92tPj4pyou4UCM1W12gxQfVS1eQ4Z7aa"; // Current hash value for URI



    //@dev constructor for ERC721 + custom constructor
            constructor()
                ERC721("Alchemist_Blue", "BLUE")
            {
                _safeMint(0x00bfB471c45819dF2428B2A5E858AD4bd196e2cB, tokenCounter.current());
                _setRoyalties(0x00bfB471c45819dF2428B2A5E858AD4bd196e2cB, 1000);
            }



    //@dev returns the tokenURI of tokenID
        function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "Huey: URI query for nonexistent token"
        );
        

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
           ? string(abi.encodePacked(currentBaseURI, CurrentHash))
            : "";
    }


    //@dev internal baseURI
        function _baseURI() 
            internal 
            view
            virtual 
            override 
            returns (string memory)
            {
                return "ipfs://";
            }

        
    //@dev overrides interface functions for EIP-2981, royalties.
        function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC721,ERC2981Base)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}