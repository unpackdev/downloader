// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

import "./Base64.sol";

/*     _    ____   ____ ___ ___  */
/*    / \  / ___| / ___|_ _|_ _| */
/*   / _ \ \___ \| |    | | | |  */
/*  / ___ \ ___) | |___ | | | |  */
/* /_/   \_\____/ \____|___|___| */
/*  __        __    _ _          */
/* \ \      / /_ _| | |          */
/*  \ \ /\ / / _` | | |          */
/*   \ V  V / (_| | | |          */
/*    \_/\_/ \__,_|_|_|          */
// https://twitter.com/praetorian/

/* ASCII Canvas Size 40x18 */
/*    0123456789012345678901234567890123456789 */
/*  0 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM */
/*  1 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM */
/*  2 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM */
/*  3 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM */
/*  4 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM */
/*  5 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM */
/*  6 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM */
/*  7 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM */
/*  8 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM */
/*  9 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM */
/* 10 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM */
/* 11 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM */
/* 12 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM */
/* 13 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM */
/* 14 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM */
/* 15 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM */
/* 16 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM */
/* 17 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM */

// This is a contract that allows minters to add a small bit of text
// to a shared canvas/wall. The imagery and data is completely stored
// on the blockchain. My assumption is, if the contract was called too
// many times, the image will be completely unreadable which is
// alright by me. A few inspirations:
// http://www.milliondollarhomepage.com/
// https://en.wikipedia.org/wiki/Place_(Reddit)
// https://en.wikipedia.org/wiki/Latrinalia
//
// Example Call
// wall.safeMint("0xB5be4AefB1E996831781ADf936b1457805c617B2", "#FF0000", "@praetorian", 17, 29, {value: "20000000000000000"});
//
// - to: the address we're going to give the token to
// - hexColor: a string that represents the color of the text that you're going to add to the wall
// - message: the text of the message that you're going to add
// - line: the line that you're going to put your text. Should be a number from 0 to 17
// - offset: if you want to push your text over to the right side, you can offset it a certain number of spaces
// - the cost right now is 0.02 ETH.
//
// I'm not planning to create a discord, social media, or roadmap for
// this project. Just try it out if you're interested. Find me on
// twitter if you want to talk.
//
// If each minter uses the full size of the line, each mint will add
// about 80 bytes to the size of the SVG. If we want to keep the size
// of the final SVG under 100KB we need to limit the number of mints
// to about 1280 (/ (* 1024 100) 80)
contract ASCIIWall is ERC721, ERC721Enumerable, Pausable, Ownable {

    // Internal state tracking for the token id counter
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // The max number of lines that the canvas supports
    uint256 public constant MAX_LINE_COUNT = 18;
    // The max number of characters that are supportred on each line
    uint256 public constant MAX_LINE_LENGTH = 40;
    // The amount of space between each line
    uint256 public constant TEXT_LINE_HEIGHT = 32;
    // The amount of space (ideally) between each character
    uint256 public constant TEXT_CHARACTER_WIDTH = 16;
    // The max number of tokens that can be minted
    uint256 public constant MAX_TOKEN_COUNT = 1280;
    // The cost of each minte
    uint256 public constant TOKEN_COST = 20000000000000000;
    // The address to deposit
    address public constant DEPOSIT_ADDRESS = 0xB5be4AefB1E996831781ADf936b1457805c617B2;
    // The description of the project
    string public projectDescription = "ASCIIWall is a blockchain-based shared canvas. Anyone can write on it. It's like latrinalia, but in the blockchain. Each mint captures the current state of the wall. Future mints can overwrite and augment the wall.";
    // The base style of the image
    string public baseStyle = "text { font-family: monospace; font-size: 2em; letter-spacing: 0.38px; }";

    // Each mint will create a WordPlacement which is then used to render the final image
    struct WordPlacement {
        string color;
        string message;
        uint256 line;
        uint256 offset;
    }

    // The collection of word placements that have been minted
    WordPlacement[] public  wordPlacements;

    // Basic constructor to start in paused state
    constructor() ERC721("ASCIIWall", "ASC") {
        pause();
    }

    // pause the minting process
    function pause() public onlyOwner {
        _pause();
    }

    // unpause the minting process
    function unpause() public onlyOwner {
        _unpause();
    }

    // modify the description in case we want to add more context or something down the road
    function setDescription(string memory desc) public onlyOwner {
        projectDescription = desc;
    }
    
    // leave an option for ourselves modify the style a bit
    function setBaseStyle(string memory style) public onlyOwner {
        baseStyle = style;
    }

    // basic minting function
    function safeMint(address to, string memory hexColor, string memory message, uint256 line, uint256 offset) public payable {
        require(offset >= 0, "The offset must be zero or positive");
        require(line >= 0, "The line number must be zero or positive");
        require(offset + bytes(message).length <= MAX_LINE_LENGTH, "Message with offset is too long");
        require(isValidColor(hexColor), "The color needs to be a valid HEX string like #012ABC");
        require(isValidMessage(message), "The message contains an invalid character (&'\"#<>)");
        require(line < MAX_LINE_COUNT, "The line number is too high");
        require(this.totalSupply() < MAX_TOKEN_COUNT, "The supply has been exhausted.");
        require(msg.value >= TOKEN_COST, "Value below price");
        require(address(msg.sender).balance > TOKEN_COST, "Not enough ETH!");

        address payable p = payable(DEPOSIT_ADDRESS);
        p.transfer(TOKEN_COST);

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        wordPlacements.push(WordPlacement({color: hexColor, message: message, line: line, offset: offset}));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // color validation. Needs to be in the format like #123ABC
    function isValidColor(string memory color) public pure returns(bool) {
        bytes memory b = bytes(color);
        if(b.length != 7) {
            return false;
        }

        if (b[0] != 0x23) {
            return false;
        }

        for(uint i = 1; i < 7; i++){
            bytes1 char = b[i];
            if(
               !(char >= 0x30 && char <= 0x39) && // 9-0
               !(char >= 0x41 && char <= 0x46) && // A-F
               !(char >= 0x61 && char <= 0x66) // a-f
               ){
                return false;
            }
        }

        return true;
    }

    // Message validation. Need to make sure that there are no characters that are going to break the SVG
    function isValidMessage(string memory message) public pure returns(bool) {
        bytes memory b = bytes(message);
        for(uint i = 0; i < b.length; i++){
            bytes1 char = b[i];
            if(
               !(char >= 0x20 && char <= 0x21) && // [ !]
               !(char >= 0x23 && char <= 0x25) && // [#$%]
               !(char >= 0x28 && char <= 0x3B) && // [(-;]
               !(char >= 0x3F && char <= 0x7E) && // [?-~]
               char != 0x3D // =
               ){
                return false;
            }
        }
        return true;
    }

    // draw the svg image for the token
    function renderForIndex(uint256 idx) public view returns (string memory) {
        require(idx < wordPlacements.length, "Can't render for a placement that doesn't exist yet");
        string memory foo = string(abi.encodePacked("<svg version=\"1.1\" width=\"640\" height=\"590\" xmlns=\"http://www.w3.org/2000/svg\"><rect width=\"100%\" height=\"100%\" fill=\"#222222\" /><style>", baseStyle, "</style>"));

        for(uint i = 0; i <= idx && i < wordPlacements.length; i = i + 1) {
            WordPlacement memory wp = wordPlacements[i];
            foo = string(abi.encodePacked(foo, abi.encodePacked("<text fill=\"", wp.color, "\" x=\"", Strings.toString(TEXT_CHARACTER_WIDTH * wp.offset) ,"\" y=\"", Strings.toString(TEXT_LINE_HEIGHT * uint(wp.line) + TEXT_LINE_HEIGHT), "\">", wp.message , "</text>")));
        }
        foo = string(abi.encodePacked(foo,  "</svg>"));
        return foo;
    }

    // return the encoded payload for the token
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        bytes memory svg = bytes(renderForIndex(tokenId));

        bytes memory json = abi.encodePacked( "{\"name\": \"ASCII Wall #", Strings.toString(tokenId), "\", \"description\": \"", projectDescription, "\", \"image\": \"data:image/svg+xml;base64,", Base64.encode(svg), "\"}");
                                                      
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }

}

