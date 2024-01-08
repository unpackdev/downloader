// SPDX-License-Identifier: GPL-3.0
/*

The most politically incorrect game takes birth on-chain. 

Cards against NFTs is an experiment, but a fun-filled one. Here, our community 
will create an on-chain game and as we come together, we will have created a deck 
of cards using this contract.

The game creation is on-chain. The play however, is best when played 
face to face, in groups!

The black and white cards minted using this contract will form the 
First edition of Cards Against NFTs, that'll be published on 1st December 2021.

We will setup a DAO to decide further course of action based on community interest.

Let's have some fun, shall we?

*/

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

import "./Base64.sol";


contract CardsAgainstNFTs is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _cardIds;
    
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    enum Color {WHITE, BLACK}
    
    struct CardInfo {
        uint256 cardId;
        string text;
        Color color;
        address creator;
    }
    
    
    mapping (uint256 => CardInfo) cardIdToCardInfo;

    constructor() ERC721("Cards Against NFTs", "CARD") {}

    function sliceStringBytes(uint start, uint end, bytes memory text, uint height) 
        private pure 
        returns (string memory) 
    {
        bytes memory slice = new bytes(end - start);
        for (uint i = start; i < end; i++) {
            slice[i - start] = text[i];
        }
        return string(
            abi.encodePacked(
                '<text x="10" y="',
                Strings.toString(height), 
                '" class="base">',
                string(slice),
                '</text>'
            )
        );
    }

    function turnIntoMultiLineText(string memory line) 
        private pure 
        returns (string memory)
    {

        string memory output;
        bytes memory input = bytes(line);
        uint maxWidth = 19;
        uint maxLines = 7;
        uint sol = 0;
        while (maxLines > 0) {
            for (uint i = sol + maxWidth; i >= sol; i--) {
                if (i >= input.length) {
                    continue;
                }
                if (input[i] == ' ' || i == input.length - 1) {
                    // sol to i is the latest line
                    string memory current = sliceStringBytes(sol, i + 1, input, 20 + (7 - maxLines) * 14);
                    output = string(abi.encodePacked(output, current));
                    sol = i + 1; 
                    break;
                }
            }
            if (sol >= input.length) {
                break;
            }
            maxLines -= 1;
        }
        return output;

    }
    
    
    function getTokenURI(CardInfo memory cardInfo) 
        private pure
        returns (string memory) 
    {
        
        string memory textColor = 'white';
        string memory bg = 'black';
        if (cardInfo.color == Color.WHITE) {
            textColor = 'black';
            bg = '#fbfbfb';
        }
        
        string[11] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 140 180"><style>.base { fill: ';
        
        parts[1] = string(abi.encodePacked(textColor));
        
        parts[2] = '; font-family: "Helvetica Neue"; font-size: 14px; font-weight="bold"; } .footer { fill: ';

        parts[3] = string(abi.encodePacked(textColor));

        parts[4] = '; font-family: "Helvetica Neue"; font-size: 6px; }</style><rect width="100%" height="100%" fill="';
        
        parts[5] = string(abi.encodePacked(bg));
        
        parts[6] = '" />';

        parts[7] = turnIntoMultiLineText(cardInfo.text);

        parts[8] = '<text x="10" y="170" class="footer">';

        parts[9] = string(abi.encodePacked("Cards Against NFTs"));
        
        parts[10] = '</text></svg>';

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7],
                parts[8],
                parts[9],
                parts[10]
            )
        );
        
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Card #',
                        Strings.toString(cardInfo.cardId),
                        '", "description": "', cardInfo.text, '", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked('data:application/json;base64,', json)
        );
        return output;
    }
    
    function mintCard() 
        private
        returns (uint256)
    {
        _cardIds.increment();
        uint256 newCardId = _cardIds.current();
        _mint(msg.sender, newCardId);
        return newCardId;
    }
    
    function setCardInfo(uint256 cardId, string memory text, Color color) 
        private
    {
        CardInfo memory cardInfo = CardInfo(cardId, text, color, msg.sender);
        cardIdToCardInfo[cardId] = cardInfo;
        _setTokenURI(cardId, getTokenURI(cardInfo));
    }
    
    
    function mintWhiteCard(string memory text)
        external
        returns (uint256)
    {
        
        uint256 cardId = mintCard();
        setCardInfo(cardId, text, Color.WHITE);
        return cardId;
    }
    
    
    function mintBlackCard(string memory text)
        external
        returns (uint256)
    {
        
        uint256 cardId = mintCard();
        setCardInfo(cardId, text, Color.BLACK);
        return cardId;
    }


    function getCardInfo(uint256 tokenId) 
        public view
        returns(CardInfo memory)
    {
        return cardIdToCardInfo[tokenId];

    }

}