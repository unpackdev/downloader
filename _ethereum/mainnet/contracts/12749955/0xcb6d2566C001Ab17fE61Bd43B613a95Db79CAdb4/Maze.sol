// contracts/Maze.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// BlockMazing

// The genesis maze https://blockmazing.com/m/0/maze.txt
// +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
// |   |   |   |   |               |                       |   |   |   |   |   |   |
// +   +   +   +   +---+---+---+   +---+---+---+---+---+   +   +   +   +   +   +   +
// |   |           |   |   |   |   |               |   |   |   |   |               |
// +   +---+---+   +   +   +   +   +---+---+---+   +   +   +   +   +---+---+---+   +
// |       |   |               |               |   |           |   |       |       |
// +---+   +   +---+---+---+   +---+---+---+   +   +---+---+   +   +---+   +---+   +
// |                                   |   |                   |       |           |
// +---+---+---+---+---+---+---+---+   +   +---+---+---+---+   +---+   +---+---+   +
// |   |       |   |   |       |   |   |           |       |   |       |   |       |
// +   +---+   +   +   +---+   +   +   +---+---+   +---+   +   +---+   +   +---+   +
// |                               |   |   |       |       |           |   |       |
// +---+---+---+---+---+---+---+   +   +   +---+   +---+   +---+---+   +   +---+   +
// |   |           |   |   |   |       |   |           |   |       |   |       |   |
// +   +---+---+   +   +   +   +---+   +   +---+---+   +   +---+   +   +---+   +   +
// |       |   |                   |   |   |       |   |           |   |   |       |
// +---+   +   +---+---+---+---+   +   +   +---+   +   +---+---+   +   +   +---+   +
// |   |               |   |   |       |       |   |   |   |   |       |   |       |
// +   +---+---+---+   +   +   +---+   +---+   +   +   +   +   +---+   +   +---+   +
// |   |   |   |   |           |   |   |                           |   |           |
// +   +   +   +   +---+---+   +   +   +---+---+---+---+---+---+   +   +---+---+   +
// |   |   |   |           |   |   |   |   |   |       |       |               |   |
// +   +   +   +---+---+   +   +   +   +   +   +---+   +---+   +---+---+---+   +   +
// |   |                   |           |   |   |       |           |   |       |   |
// +   +---+---+---+---+   +---+---+   +   +   +---+   +---+---+   +   +---+   +   +
// |       |   |   |                       |           |   |   |           |   |   |
// +---+   +   +   +---+---+---+---+---+   +---+---+   +   +   +---+---+   +   +   +
// |   |           |           |       |       |   |                   |   |       |
// +   +---+---+   +---+---+   +---+   +---+   +   +---+---+---+---+   +   +---+   +
// |   |   |                               |       |       |       |       |   |   |
// +   +   +---+---+---+---+---+---+---+   +---+   +---+   +---+   +---+   +   +   +
// |       |   |       |   |   |               |   |       |   |   |   |   |   |   |
// +---+   +   +---+   +   +   +---+---+---+   +   +---+   +   +   +   +   +   +   +
// |                   |           |           |                                   |
// +---+---+---+---+   +---+---+   +---+---+   +---+---+---+---+---+---+---+---+   +
// |                   |       |   |   |   |   |                   |           |   |
// +---+---+---+---+   +---+   +   +   +   +   +---+---+---+---+   +---+---+   +   +
// |   |   |           |   |               |   |           |       |   |           |
// +   +   +---+---+   +   +---+---+---+   +   +---+---+   +---+   +   +---+---+   +
// |                                                                               |
// +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

// This is a basic project inspired by 0xd4e4078ca3495de5b1d4db434bebc5a986197782 (Autoglyphs) as well as Jamis Buck's Mazes for programmers. The goal is to have a unique maze represented on the blockchain.

// https://pragprog.com/titles/jbmaze/mazes-for-programmers/
// https://github.com/praetoriansentry/maze/
// https://blockmazing.com

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";


contract Maze is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint public constant MAZE_SIZE = 20;
    uint public constant MAX_TOKEN_COUNT = 256;
    uint constant FIELD_SIZE = MAZE_SIZE * MAZE_SIZE;
    uint256 constant TOKEN_COST = 25000000000000000;

    // each maze will donate some money to EFF!
    address constant EFF_ADDRESS = 0x095f1fD53A56C01c76A2a56B7273995Ce915d8C4;

    uint constant PRINTED_MAZE_COLS = (MAZE_SIZE * 4 + 2);
    uint constant PRINTED_MAZE_ROWS = (2 * MAZE_SIZE + 1);

    uint constant NORTH_WALL = 1;
    uint constant SOUTH_WALL = 2;
    uint constant EAST_WALL = 4;
    uint constant WEST_WALL = 8;
    uint constant VISITED = 16;

    bytes1 constant CHAR_PLUS = 0x2B;
    bytes1 constant CHAR_DASH = 0x2D;
    bytes1 constant CHAR_NEWLINE = 0x0A;
    bytes1 constant CHAR_PIPE = 0x7C;
    bytes1 constant CHAR_SPACE = 0x20;

    constructor() ERC721("BlockMazing", "MZE") {}

    function safeMint(address to) public onlyOwner payable {
        require(this.totalSupply() < MAX_TOKEN_COUNT, "The supply of mazes has been exhausted.");
        require(address(msg.sender).balance > TOKEN_COST, "Not enough ETH!");
        require(msg.value >= TOKEN_COST, "Value below price");
        address payable p = payable(EFF_ADDRESS);

        p.transfer(TOKEN_COST);
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://blockmazing.com/m/";
    }

    function tokenURI(uint tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked("data:text/plain;charset=UTF-8,", draw(tokenId)));
    }

    function tokenMetaURI(uint tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory tokenIdString =  Strings.toString(tokenId);
        return string(abi.encodePacked(_baseURI(), tokenIdString, "/" , Strings.toString(tokenId), ".json"));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Take a token id and draw the maze that's unique to that token.
    function draw(uint id) public pure returns (string memory) {
        uint[FIELD_SIZE] memory bitfield = getMazeData(id);
        uint cell;
        uint cellIndex;
        uint row;
        uint col;

        bytes memory mazeOutput = new bytes(PRINTED_MAZE_COLS * PRINTED_MAZE_ROWS);
        // For each row
        for (uint i = 0; i < PRINTED_MAZE_ROWS; i++) {
            uint j = 0;
            while (j < PRINTED_MAZE_COLS) {
                uint idx = i * PRINTED_MAZE_COLS + j;
                // END OF THE ROW
                if (j + 1 == PRINTED_MAZE_COLS) {
                    mazeOutput[idx] = CHAR_NEWLINE;
                    j = j + 1;
                    continue;
                }

                // START OF THE ROW
                if (j == 0 && i % 2 == 1) {
                    mazeOutput[idx] = CHAR_PIPE;
                    j = j + 1;
                    continue;
                } else if (j == 0 && i % 2 == 0) {
                    mazeOutput[idx] = CHAR_PLUS;
                    j = j + 1;
                    continue;
                }


                if (i == 0) {
                    cell = 31;
                } else {
                    row = (i - 1) / 2;
                    col = j / 4;
                    cellIndex = rowColToBitIndex(row, col);
                    if (cellIndex < FIELD_SIZE && cellIndex >= 0) {
                        cell = bitfield[cellIndex];
                    } else {
                        cell = 31;
                    }
                }

                // What cell are we in?
                if (i % 2 == 1) {// EAST WEST
                    mazeOutput[idx++] = CHAR_SPACE;
                    mazeOutput[idx++] = CHAR_SPACE;
                    mazeOutput[idx++] = CHAR_SPACE;
                    if ((cell & EAST_WALL) == EAST_WALL) {
                        mazeOutput[idx++] = CHAR_PIPE;
                    } else {
                        mazeOutput[idx++] = CHAR_SPACE;
                    }
                    j = j + 4;
                } else {// NORTH SOUTH
                    if ((cell & SOUTH_WALL) == SOUTH_WALL) {
                        mazeOutput[idx++] = CHAR_DASH;
                        mazeOutput[idx++] = CHAR_DASH;
                        mazeOutput[idx++] = CHAR_DASH;
                    } else {
                        mazeOutput[idx++] = CHAR_SPACE;
                        mazeOutput[idx++] = CHAR_SPACE;
                        mazeOutput[idx++] = CHAR_SPACE;
                    }
                    mazeOutput[idx++] = CHAR_PLUS;
                    j = j + 4;
                }
            }
        }

        string memory finalMaze = string(mazeOutput);
        return finalMaze;
    }

    // Implementing the fastest and most trivial algorithm I could find.
    // https://weblog.jamisbuck.org/2011/2/1/maze-generation-binary-tree-algorithm
    function getMazeData(uint id) public pure returns (uint[FIELD_SIZE] memory) {
        uint[FIELD_SIZE] memory bitfield;
        uint cell;
        uint randInt = semiRandomData(id);
        bool goSouth;
        // Initialize a bit field
        for (uint i = 0; i < FIELD_SIZE; i = i + 1) {
            cell = 31;
            randInt = semiRandomData(randInt);
            // coin filt to decide if I should go south or east
            goSouth = (randInt % 1000) >= 500;
            uint[2] memory rowCol = bitIndexToRowCol(i);
            if (goSouth) {
                if (rowCol[0] < (MAZE_SIZE - 1)) {
                    cell = cell & ~SOUTH_WALL;
                } else if (rowCol[1] < (MAZE_SIZE -1)) {
                    cell = cell & ~EAST_WALL;
                }
            } else {
                if (rowCol[1] < (MAZE_SIZE - 1)) {
                    cell = cell & ~EAST_WALL;
                } else if (rowCol[0] < (MAZE_SIZE) - 1){
                    cell = cell & ~SOUTH_WALL;
                }
            }
            bitfield[i] = cell;
        }
        return bitfield;

    }

    // take an index that stored the flat array and return an array corresponding to the row and column in question
    function bitIndexToRowCol(uint idx) private pure returns (uint[2] memory) {
        uint row = idx / MAZE_SIZE;
        uint col = idx % MAZE_SIZE;
        return [row, col];
    }

    // Given a row and column, at the index in the flat array.
    function rowColToBitIndex(uint row, uint col) private pure returns(uint) {
        return row * MAZE_SIZE + col;
    }

    // copying the paramters from glibc for creating a sequence of pseudo-random numbers. The idea is that each tokenid will have it's own sequence and therefor have it's own maze.
    // https://en.wikipedia.org/wiki/Linear_congruential_generator#Parameters_in_common_use
    function semiRandomData(uint seed) public pure returns (uint) {
        return ((seed * 1103515245) + 12345) % 2147483648;
    }
}
