// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* 
 *          ______        _____         __      _         _____         ____   
 *         (_   _ \      (_   _)       /  \    / )       / ___ \       / __ \  
 *           ) (_) )       | |        / /\ \  / /       / /   \_)     / /  \ \ 
 *           \   _/        | |        ) ) ) ) ) )      ( (  ____     ( ()  () )
 *           /  _ \        | |       ( ( ( ( ( (       ( ( (__  )    ( ()  () )
 *          _) (_) )      _| |__     / /  \ \/ /        \ \__/ /      \ \__/ / 
 *         (______/      /_____(    (_/    \__/          \____/        \____/  
 */

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./Base64.sol";
import "./ERC721Royalty.sol";
import "./EIP712.sol";
import "./ERC721Votes.sol";
import "./SVGParser.sol";
import "./BoardFactory.sol";

contract RegularBingo is ERC721, ERC721URIStorage, ERC721Royalty,  Pausable, AccessControl, EIP712, ERC721Votes, ERC721Burnable, BoardFactory {
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private _tokenIdCounter;
    mapping(uint => uint) private boards;
    SVGParser public svgParser;
    string private _animationURL = "ipfs://Qme2DPV7NvjbPsybrb71J7yW6nXJLn9CGrAENPoKjkaEYp/index.html?numbers=";

    constructor() ERC721("Regular Bingo", "BINGO") EIP712("Regular Bingo", "1") {
        _setDefaultRoyalty(msg.sender, 750);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        svgParser = new SVGParser();
    }

// MINT

    function mint() public whenNotPaused onlyRole(MINTER_ROLE) {
        mintTo(msg.sender);
    }

    function mintTo(address to) public whenNotPaused onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        boards[tokenId] = generateBoard(tokenId);
        _safeMint(to, tokenId);
    }

    function mintBatch(address to, uint256 quantity) public whenNotPaused onlyRole(MINTER_ROLE) {
        require(quantity > 0 && quantity <= 20, "Invalid quantity"); 

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            boards[tokenId] = generateBoard(tokenId);
            _safeMint(to, tokenId);
        }
    }

// VIEW

    function boardArray(uint tokenId) public view returns (uint8[5][5] memory) {
        require(_exists(tokenId), "Token ID has not been minted");
        return unpackNumbers(boards[tokenId]);
    }

    function boardString(uint tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token ID has not been minted");
        return unpackToString(boards[tokenId]);
    }

    function animationURL(uint tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token ID has not been minted");
        return string(abi.encodePacked(_animationURL, boardString(tokenId)));
    }

    function previewJSON(uint256 tokenId) public view returns (string memory) {
        string memory output = svgParser.generateSVG(boardArray(tokenId));
        string memory json = string(abi.encodePacked('{"name": "Regular Bingo Board #', toString(tokenId), '", "description": "Just Regular Bingo.","animation_url" : "', animationURL(tokenId),'", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'));
        return json;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        string memory output = svgParser.generateSVG(boardArray(tokenId));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Board #', toString(tokenId), '", "description": "Just Regular Bingo.","animation_url" : "', animationURL(tokenId),'", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }

// INTERNAL

    function packedNumber(uint tokenId) internal view returns (uint256) {
        require(_exists(tokenId), "Token ID has not been minted");
        return boards[tokenId];
    }


// ADMIN

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setSVGParser(address _addr) public onlyRole(DEFAULT_ADMIN_ROLE) {
        svgParser = SVGParser(_addr);
    }

    function setAnimationURL(string memory _url) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _animationURL = _url;
    }


// OVERRIDES + MISC

    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal whenNotPaused override {
    //     super._beforeTokenTransfer(from, to, tokenId, batchSize);
    // }

    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override(ERC721Votes, ERC721) {
        super._afterTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage, ERC721Royalty) {
        super._burn(tokenId);
    }

    function toString(uint256 value) internal pure returns (string memory) {
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

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
 
}