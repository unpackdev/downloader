// SPDX-License-Identifier: MIT

/*
* TheCreator.sol
*
* Author: Don Huey / twitter: donbtc
* Created: December 20th, 2021
* Creators: Brandon Breaux, Don Huey
*
* Rinkby: 0xdea66912a0a5235b36668ca2ebc9c8e2bff2e37c
*
* Description: The Genesis drop of Brandon Breaux.
* 
* - The Creator will be in a state of Rest upon initial mint.
* - The Creator will "awaken" upon it's creator's command.
* - The Creator should be put to rest when it's creator has been laid to rest...eternally.
*
 __   __             __   __           __   __   ___                
|__) |__)  /\  |\ | |  \ /  \ |\ |    |__) |__) |__   /\  |  | \_/ .
|__) |  \ /~~\ | \| |__/ \__/ | \|    |__) |  \ |___ /~~\ \__/ / \ .
                                                                    
___       ___     __   __   ___      ___  __   __                   
 |  |__| |__     /  ` |__) |__   /\   |  /  \ |__)                  
 |  |  | |___    \__, |  \ |___ /~~\  |  \__/ |  \                  
                                                                    
*/



pragma solidity > 0.5.0 < 0.9.0;


import "./ERC721.sol"; 
import "./SafeMath.sol"; 
import "./HueyAccessControlnoGold.sol";
import "./Counters.sol"; 
import "./ERC2981ContractWideRoyalties.sol"; // Royalties for contract, EIP-2981


contract Creator is ERC721, HueyAccessControlnoGold, ERC2981ContractWideRoyalties {

    //@dev Using SafeMath
        using SafeMath for uint256;
    //@dev Using Counters for increment/decrement
        using Counters for Counters.Counter;
    //@dev uint256 to strings
        using Strings for uint256;


    //@dev Important numbers and state variables
	uint256 public MAX_TOKENS = 1; // Max supply of tokens
    Counters.Counter private tokenCounter;
    string public constant RestHash = "QmXgMUZC5QV8X5TwncmhvCzL8nC3X4APN9p5NuwRbTbwAV";
    string public constant AwakenedHash = "QmNr99jVvBs9EZb7HnZtvBCAxTwv3n8Guf9UrM7fdYjKb1";
    string public CurrentHash; // Current hash value for URI

    //@dev constructor for ERC721 + custom constructor
        constructor()
            ERC721("Creator", "CRTR")
        {
            CurrentHash = "QmXgMUZC5QV8X5TwncmhvCzL8nC3X4APN9p5NuwRbTbwAV";
            _safeMint(0xC6115407937cF5c8E14eB8971A3f3984ED791Ea1, tokenCounter.current());
    //@dev Sets the royalties for EIP-2981 standard
            _setRoyalties(0xC6115407937cF5c8E14eB8971A3f3984ED791Ea1, 1000);
    //@dev Sets Admin, supersedes owner
            _gang[0xC6115407937cF5c8E14eB8971A3f3984ED791Ea1] = true;
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


    //@dev Awaken's the creator
        function Awaken()
        public
        isGang
        {
                string memory _AwakenedHash = AwakenedHash;
                CurrentHash = _AwakenedHash;
        }

        
    //@dev When the creator rests
        function Rest()
        public
        isGang
        {
           require(
                compareStrings(CurrentHash, AwakenedHash), "Huey: The creator will rest one day, but must be awakened."
        );
            string memory _RestHash = RestHash;
            CurrentHash = _RestHash;
        }

    //@dev internal baseURI function
        function _baseURI() 
            internal 
            view
            virtual 
            override 
            returns (string memory)
            {
                return "ipfs://";
            }

    //@dev compares the string values of the state varialbes.
        function compareStrings(string memory a, string memory b) 
        public 
        pure
        returns (bool) 
        {
            return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
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