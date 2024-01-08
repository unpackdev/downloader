// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract FluffyPolarBears99SpecialEdition is ERC721, ERC721URIStorage, Pausable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter; 
    
    string[] legendaryIdToName = ["Vanilla Bear", "Golden Bear", "Puzzled Bear", "3D Bear", "Polar Lisa", "The Scream", "Vincent Polar Gogh", "Great Wave", "Bearida Kahlo", "Pablo Polarsco", "Bearet Mondriaan", "Salvador Fluffy", "Gm Bear", "Shakesbear", "Amabearus Mozart", "Crossword Fluffy", "Frankicetein", "Crazy Wizard", "Count Bearacula", "Fluffy Witch", "Zombear", "Evil Fluffy Robot", "Mummy Bear", "Cave Bear", "Fluffy Unicorn", "Fluffy Cowboy", "Astronaut Bear", "Desert Bear", "Bipolar", "Super Fluffy", "Fluffy Punk", "Purple Punk", "Ninja Bear", "Fluffy Pilot", "Pirate Captain", "Exhausted Bear", "Fluffy Painter", "Left Looking Bear", "Pink Bear", "Fluffy Bandit", "Ducky", "Chick", "Office Bear", "Fluffy Warrior", "Mcbear's", "Ethbeary", "Hodl Bear", "Frozen Fluffy", "Beauty Bear", "Intern Viking", "Shiny", "Tattooed Bear", "Silhouette Bear", "Ski Bear", "Fluffy Neo", "Robear Hood", "Bearlie Chaplin", "Obear Wan", "Bearlock Holmes", "Sad Sailor", "Fluffy Captain", "Miss Fluffy Sunshine", "Chief Redbird", "Diver Bear", "Rainbow Bear", "Albear Icetein", "Galileo Fluffio", "Iceac Newton", "Niclaw Tesla", "Fluffy Marie Curie", "Fluffy Santa", "Fluffy Holiday", "Stormy", "Narcissist Bear", "Seally Bear", "Fluffy Knight", "Princess Aurora", "Karate Bear", "Fluffy Lighthouse", "Party Bear", "Rainy", "Igloo Bear", "Fluffy Panda", "Fluffy Fall", "Pizza Chef", "Stoned Bear", "Sharky", "The Goat", "Fluffy Pharaoh", "Art Bear", "Manga Bear", "Fluffy Hipster", "Lucky", "Bearly Bear", "The Ice King", "Yeti", "Coder Bear", "Fluffy Arctic Wolf", "Baby Bear"];

    constructor() ERC721("Fluffy Polar Bears 99 Special Edition", "FPB99") {}
    
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
    function toString(uint256 value) 
    internal 
    pure 
    returns (string memory) {
        
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmbBTdjjk791nk1bCAfZZ1XmwN3JwFzBVnxkKNa9rMwMtp/";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    function generateMetadata(uint256 _tokenId)
    public
    view 
    returns (string memory) {
        
        string memory metadataString;
        
        metadataString = string(abi.encodePacked(metadataString, '{"trait_type":"Legendary","value":"', legendaryIdToName[_tokenId],'"}'));
        return string(abi.encodePacked("[", metadataString, "]"));
    }
    
    function tokenURI(uint256 _tokenId) 
    public
    view 
    override(ERC721, ERC721URIStorage)
    returns (string memory) {
        
        return
        string(
            abi.encodePacked(
                "data:application/json;base64,",
                encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "Fluffy Polar Bears 99 Special Edition#',
                                toString(_tokenId + 1),
                                '", "description": "After a very harsh ice age, polar bears were the only species that survived. Now, they need to explore the world, create inventions and a world of polar bears - cold, funky and definitely interesting! Fluffy Polar Bears are a collection of 9,999 randomly and fully On-Chain generated NFTs that exist on the Ethereum Blockchain.", "image": "',
                                _baseURI(),
                                toString(_tokenId + 1),
                                '.png"',
                                ', "attributes":',
                                generateMetadata(_tokenId),
                                "}"
                            )
                        )
                    )
                )
            )
        );
    }
}
