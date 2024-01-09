// SPDX-License-Identifier: MIT

/*
* SuperBowl.sol
*
* Author: Don Huey / twitter: donbtc
* Created: January 30th, 2022
* Creators: Francis Almeda, Don Huey, Nate Gagnon, Max Mearsheimer
*
* Mint Price:  0.02 ETH
* Rinkby: 0xb61eb9e2593d84975e9aa429e7bf7f41bc2a77c5
*
* 
*
* Description: Generative Football Avatars whose jersey numbers represent your number in a digital game of SuperBowl Squares!!
*
*
*
 ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄   ▄▄▄▄▄▄▄▄▄▄▄  ▄            ▄                 ▄         ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄   ▄▄▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░▌ ▐░░░░░░░░░░░▌▐░▌          ▐░▌               ▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░▌ ▐░░░░░░░░░░░▌
▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌ ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░▌          ▐░▌               ▐░▌       ▐░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀ 
▐░▌          ▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌     ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌          ▐░▌               ▐░▌       ▐░▌▐░▌          ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌          
▐░█▄▄▄▄▄▄▄▄▄ ▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌     ▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░▌          ▐░▌               ▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌     ▐░░░░░░░░░░▌ ▐░░░░░░░░░░░▌▐░▌          ▐░▌               ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌
▐░█▀▀▀▀▀▀▀▀▀ ▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌     ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░▌          ▐░▌               ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░▌       ▐░▌ ▀▀▀▀▀▀▀▀▀█░▌
▐░▌          ▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌     ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌          ▐░▌               ▐░▌       ▐░▌▐░▌          ▐░▌       ▐░▌▐░▌       ▐░▌          ▐░▌
▐░▌          ▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌     ▐░▌     ▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄▄▄      ▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄█░▌ ▄▄▄▄▄▄▄▄▄█░▌
▐░▌          ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░▌     ▐░░░░░░░░░░▌ ▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░▌ ▐░░░░░░░░░░░▌
 ▀            ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀       ▀       ▀▀▀▀▀▀▀▀▀▀   ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀       ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀  ▀▀▀▀▀▀▀▀▀▀   ▀▀▀▀▀▀▀▀▀▀▀ 
                                                                                                                                                                              
*
*/

pragma solidity > 0.5.0 < 0.9.0;

import "./ERC721.sol"; 
import "./SafeMath.sol"; 
import "./HueyAccessControlnoGold.sol";
import "./Counters.sol"; 
import "./ERC2981ContractWideRoyalties.sol"; // Royalties for contract, EIP-2981


contract SUPERBOWL is ERC721, HueyAccessControlnoGold, ERC2981ContractWideRoyalties {

    //@dev Using SafeMath
        using SafeMath for uint256;
    //@dev Using Counters for increment/decrement
        using Counters for Counters.Counter;
    //@dev uint256 to strings
        using Strings for uint256;


    //@dev Important numbers and state variables
        string public baseExtension = ".json";
        uint256 public constant MAX_TOKENS = 100; // Max supply of tokens
        uint256 public constant SQUARE_PRICE = 20000000000000000; // 0.02
        Counters.Counter private tokenCounter;
        bool public revealed = false;
        string public constant ProvenanceHash = "f6188ace86aaf35ce157ba5290f6e35a3ce65ca18b3f913d24e2524c38d101fd"; // This is the compiled metadata of all the football heads which can be used to prove that no metadata was changed.



      //@dev constructor for ERC721 + custom constructor
        constructor()
            ERC721("Football Heads", "FBHD")
        {
            tokenCounter.increment();
            _gang[msg.sender] = true;
            _setRoyalties(0xC1f57690c16Bc1b11Fc3556c53c43B8ec7e8BE38, 500);
        }



     //@dev Tool 'mint' creates token & maps previously assigned tokenIdToURI mapping
        function SquareMint(uint256 numTokens) 
            public
            payable
        {
        require(
            tokenCounter.current() + 1 < MAX_TOKENS,
            "Huey: Exceeds maximum token supply."
        );
        
    //@dev Must mint atleast 1 and max mint is 10 at a time.
        require(
            numTokens > 0 && numTokens <= 50, "Huey: Minting must be a min of 1 and a max of 5."
        );

    //@dev The sent ETH has to be over the required amount.
        require(
            SQUARE_PRICE * numTokens <= msg.value, "Huey: Ethereum sent is not sufficient."
        );

    //@dev Iterate numTokens, mint & resolve URI to mapped URI
        for (uint256 i = 0; i < numTokens; i++){

            //Creates tokenId
            _safeMint(msg.sender, tokenCounter.current());

    //Increments token, since token created, mint
        tokenCounter.increment();

        }
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
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }


    //@dev internal baseURI function
            function _baseURI() 
                internal 
                view
                virtual 
                override 
                returns (string memory)
                {
                    return "ipfs://QmRAU3nZUi1vYAHV6n1MqH9Mq8UgN71J6skU6ySqaEzhkr/";
                }

    //@dev Allows us to withdraw funds collected.
            function withdraw(address payable wallet, uint256 amount)
                payable
                isGang 
                public
            {
                require(amount <= address(this).balance,
                    "Huey: Insufficient funds to withdraw");
                wallet.transfer(amount);
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