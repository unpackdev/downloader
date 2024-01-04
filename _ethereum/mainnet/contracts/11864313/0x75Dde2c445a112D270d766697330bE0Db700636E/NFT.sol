// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./ERC721.sol";
import "./ERC165.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Curve.sol";


contract NFT is ERC721("Love on a Curve", "BONDLOVE"), Ownable, Curve {
    using SafeMath for uint256;

    uint256 constant MAX_TOKENS_PER_PIECE = 9;

    // Each token owns one piece. Only a limited number of tokens can own a
    // single piece.  A new piece is created once the previous one is full.
    // To save gas, we use uint64's here
    struct PieceRecord {
        uint64[] tokenIds;
        uint64 startedAt;
        uint64 endedAt;
        uint64 scheduledEndAt;
    }

    // Public piece structure, with dynamic fields.
    struct Piece {
        uint256 pieceNumber;
        uint64[] tokenIds;
        uint256 startedAt;
        uint256 endedAt;
        uint256 scheduledEndAt;
        uint256 randomSeed;
        bool[] states;
    }

    mapping(uint256 => PieceRecord) pieces;
    mapping(uint256 => uint256) tokenIdToPieceId;
    uint256 public numPieces = 0;

    // Store the code to render on-chain.
    string public renderScriptCode;

    constructor() Curve(msg.sender) {
    }

    // End the old piece, add a new one
    function makeNewPiece() private returns (PieceRecord storage) {
        uint256 newSegmentLength;
        if (numPieces > 0) {
            PieceRecord storage currentPiece = pieces[numPieces];
            currentPiece.endedAt = uint64(block.timestamp);
            uint64 lastSegmentLength = currentPiece.endedAt - currentPiece.startedAt; // cannot underflow

            // If we filled up early, make the next segment longer. If we ended late, make the next segment longer.
            if (currentPiece.endedAt < currentPiece.scheduledEndAt) {
                newSegmentLength = lastSegmentLength * 75 / 100;   // Should not overflow, plenty of space in uint64
            } else {
                newSegmentLength = lastSegmentLength * 125 / 100;
            }
        }
        else {
            // Initial segment length
            newSegmentLength = 2 days;
        }

        // Increase the piece count
        numPieces = numPieces + 1;
        uint256 pieceId = numPieces;

        pieces[pieceId].startedAt = uint64(block.timestamp);
        pieces[pieceId].scheduledEndAt = uint64(block.timestamp + newSegmentLength);   // Should not overflow, plenty of space in uint64

        return pieces[pieceId];
    }
    
    function onMint(uint256 tokenId) internal override returns (uint256 pieceId) {
        _mint(msg.sender, tokenId);

        PieceRecord storage currentPiece = pieces[numPieces];

        // We generate a new piece if the old one is full, or if it's segment timed out.
        if ((currentPiece.tokenIds.length >= MAX_TOKENS_PER_PIECE) || block.timestamp >= currentPiece.scheduledEndAt) {
            currentPiece = makeNewPiece();
        }

        currentPiece.tokenIds.push(uint64(tokenId));
        tokenIdToPieceId[tokenId] = numPieces;

        return tokenIdToPieceId[tokenId];
    }

    function onBurn(uint256 tokenId) internal override  returns (uint256 pieceId) {
        _burn(tokenId);
        return tokenIdToPieceId[tokenId];
    }

    // Public API

    function getPiece(uint256 pieceId) public view returns (Piece memory) {
        require(pieces[pieceId].startedAt > 0, "invalid piece");
        PieceRecord storage p = pieces[pieceId];

        Piece memory piece;
        piece.tokenIds = p.tokenIds;
        piece.startedAt = p.startedAt;
        piece.scheduledEndAt = p.scheduledEndAt;
        piece.endedAt = p.endedAt;

        piece.pieceNumber = pieceId;

        // Random seed is the timestamp of the previous piece
        if (pieceId > 1) {
            piece.randomSeed = getPiece(pieceId-1).startedAt;
        } else {
            // hard code the first one.
            piece.randomSeed = 5;
        }

        bool[] memory state = new bool[](piece.tokenIds.length);
        for (uint8 i = 0; i < piece.tokenIds.length ; i++) {
            state[i] = _exists(piece.tokenIds[i]);
        }
        piece.states = state;

        return piece;
    }

    // NB: pieceId is 1-indexed.
    function getPieceForToken(uint256 tokenId) public view returns (Piece memory) {
        require(tokenIdToPieceId[tokenId] > 0, "invalid token");
        uint256 pieceId = tokenIdToPieceId[tokenId];
        return getPiece(pieceId);
    }

    function setCode(string calldata code) public onlyOwner {
        renderScriptCode = code;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setCreator(address payable a) public onlyOwner {
        creator = a;
    }
}
