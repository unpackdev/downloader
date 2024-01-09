/*
 (        )                             (        (         *             (    (
 )\ )  ( /(   (       *   )  *   )      )\ )     )\ )    (  `     (      )\ ) )\ )
(()/(  )\())  )\    ` )  /(` )  /( (   (()/( (  (()/(    )\))(    )\    (()/((()/(
 /(_))((_)\((((_)(   ( )(_))( )(_)))\   /(_)))\  /(_))  ((_)()\((((_)(   /(_))/(_))
(_))   _((_))\ _ )\ (_(_())(_(_())((_) (_)) ((_)(_))_   (_()((_))\ _ )\ (_)) (_))
/ __| | || |(_)_\(_)|_   _||_   _|| __|| _ \| __||   \  |  \/  |(_)_\(_)| _ \/ __|
\__ \ | __ | / _ \    | |    | |  | _| |   /| _| | |) | | |\/| | / _ \  |  _/\__ \
|___/ |_||_|/_/ \_\   |_|    |_|  |___||_|_\|___||___/  |_|  |_|/_/ \_\ |_|  |___/

a blitmap derivative.

@author fishboy
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

import "./BytesLib.sol";

import "./IBlitmap.sol";
import "./BlitmapHelper.sol";
import "./Base64.sol";

contract Shattered is ERC721, ReentrancyGuard, Ownable {

	using BytesLib for bytes;

    using Counters for Counters.Counter;

    uint8 private constant TOP_LEFT = 1;

    uint8 private constant TOP_RIGHT = 2;

    uint8 private constant BOTTOM_LEFT = 3;

    uint8 private constant BOTTOM_RIGHT = 4;

    uint256 private constant PRICE = 0.002 ether;

    uint256 private maxSupply;

    bool public live;

    Counters.Counter private supply;

    Counters.Counter private forgedSupply;

    IBlitmap private blitmapContract;

    uint256 private blitmapSupply;

    mapping(uint256 => AllPieces) tokenPieces;

    mapping(uint256 => BlitmapPieces) usedPieces;

    event PieceMinted(uint256 blitTokenId);

    string[32] private lookup = [
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10',
        '11', '12', '13', '14', '15', '16', '17', '18', '19',
        '20', '21', '22', '23', '24', '25', '26', '27', '28', '29',
        '30', '31'
    ];

    struct BlitmapPieces {
        uint256[] corners;
        bool exists;
    }

    struct Piece {
        uint256 tid;
        uint256 corner;
        bool exists;
    }

    struct AllPieces {
        Piece topLeft;
        Piece topRight;
        Piece bottomLeft;
        Piece bottomRight;
        Piece single;
    }

    constructor(address blitmapAddr) ERC721("Shattered Maps", "SMAPS") {
        blitmapContract = IBlitmap(blitmapAddr);
        blitmapSupply = blitmapContract.totalSupply();
        maxSupply = blitmapSupply * 4;
        live = true;
    }

    function setLive(bool status) public onlyOwner {
        live = status;
    }

    function totalMinted() public view returns (uint256) {
        return supply.current();
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function getNextPieceId() private returns (uint256) {
        supply.increment();
        return supply.current();
    }

    function getNextForgedId() private returns (uint256) {
        forgedSupply.increment();
        return forgedSupply.current() + maxSupply;
    }

    function getPiece(bytes memory tokenData, uint256 startAt, uint256 pad) private pure returns (bytes memory) {
        bytes memory square;
        bytes memory colors = tokenData.slice(0, 12);
        uint256 startingAt = startAt;
        for (uint256 i = 1; i <= 16; i++) {
            square = square.concat(tokenData.slice(startingAt + pad, 4));
            startingAt += 8;
        }

        return colors.concat(square);
    }

    function getRect(string memory x, string memory y, string memory color) private pure returns (string memory) {
        return string(
            abi.encodePacked('<rect fill="', color, '" x="', x, '" y="', y, '" width="1.5" height="1.5" shape-rendering="crispEdges" />')
        );
    }

    function getCornerStart(uint corner) private pure returns (uint) {
        if (TOP_LEFT == corner || TOP_RIGHT == corner) {
            return 12;
        }

        if (BOTTOM_LEFT == corner) {
            return 136;
        }

        if (BOTTOM_RIGHT == corner) {
            return 144;
        }

        return 0;
    }

    function getCornerOffset(uint corner) private pure returns (uint) {
        if (TOP_LEFT == corner || BOTTOM_RIGHT == corner) {
            return 0;
        }

        if (TOP_RIGHT == corner || BOTTOM_LEFT == corner) {
            return 4;
        }

        return 0;
    }

    function getCornerString(uint256 corner) private pure returns (string memory) {
        if (corner == TOP_LEFT) {
            return 'Top Left';
        }
        if (corner == TOP_RIGHT) {
            return 'Top Right';
        }
        if (corner == BOTTOM_LEFT) {
            return 'Bottom Left';
        }
        if (corner == BOTTOM_RIGHT) {
            return 'Bottom Right';
        }

        return '';
    }

    function removeCorner(uint256 cornerIndex, uint256[] memory corners) private pure returns (uint256[] memory) {
        uint256[] memory newCorners = new uint256[](corners.length - 1);
        uint skipped = 0;
        for (uint256 i = 0; i < corners.length; i++) {
            if (i == cornerIndex) {
                skipped++;
                continue;
            }

            newCorners[i - skipped] = corners[i];
        }

        return newCorners;
    }

    function line(bytes1 data, uint256 x, uint256 y, string[4] memory colors) private view returns (string memory) {
        return string(abi.encodePacked(
            getRect(
                lookup[x], lookup[y], colors[BlitmapHelper.getColorToUse(BlitmapHelper.getBit(data, 6), BlitmapHelper.getBit(data, 7))]
            ),
            getRect(
                lookup[x+1], lookup[y], colors[BlitmapHelper.getColorToUse(BlitmapHelper.getBit(data, 4), BlitmapHelper.getBit(data, 5))]
            ),
            getRect(
                lookup[x+2], lookup[y], colors[BlitmapHelper.getColorToUse(BlitmapHelper.getBit(data, 2), BlitmapHelper.getBit(data, 3))]
            ),
            getRect(
                lookup[x+3], lookup[y], colors[BlitmapHelper.getColorToUse(BlitmapHelper.getBit(data, 0), BlitmapHelper.getBit(data, 1))]
            )
        ));
    }

    // @dev credit to blitmap contract for this clever implementation
    function draw(uint256 startX, uint256 startY, uint256 limit, bytes memory tokenData, string[4] memory colors) private view returns (string memory) {
        uint256 x = startX;
        uint256 y = startY;
        string[8] memory row;
        string memory svgString;
        for (uint256 i = 12; i < tokenData.length; i+=8) {
            row[0] = line(tokenData[i], x, y, colors);
            x += 4;
            row[1] = line(tokenData[i+1], x, y, colors);
            x += 4;
            row[2] = line(tokenData[i+2], x, y, colors);
            x += 4;
            row[3] = line(tokenData[i+3], x, y, colors);
            x += 4;

            if (x >= limit) {
                x = startX;
                y += 1;
            }

            row[4] = line(tokenData[i+4], x, y, colors);
            x += 4;
            row[5] = line(tokenData[i+5], x, y, colors);
            x += 4;
            row[6] = line(tokenData[i+6], x, y, colors);
            x += 4;
            row[7] = line(tokenData[i+7], x, y, colors);
            x += 4;

            if (x >= limit) {
                x = startX;
                y += 1;
            }

            svgString = string(abi.encodePacked(svgString, row[0], row[1], row[2], row[3], row[4], row[5], row[6], row[7]));
        }

        return svgString;
    }

    function tokenDataOf(uint256 tokenId) public view returns (bytes memory) {
        bytes memory tokenData;
        if (tokenPieces[tokenId].single.exists) {
            tokenData = tokenData.concat(
                getPiece(
                    blitmapContract.tokenDataOf(
                        tokenPieces[tokenId].single.tid
                    ),
                    getCornerStart(tokenPieces[tokenId].single.corner),
                    getCornerOffset(tokenPieces[tokenId].single.corner)
                )
            );
        } else {
            tokenData = tokenData.concat(
                getPiece(
                    blitmapContract.tokenDataOf(tokenPieces[tokenId].topLeft.tid),
                    getCornerStart(TOP_LEFT), getCornerOffset(TOP_LEFT)
                )
            );
            tokenData = tokenData.concat(
                getPiece(
                    blitmapContract.tokenDataOf(tokenPieces[tokenId].topRight.tid),
                    getCornerStart(TOP_RIGHT), getCornerOffset(TOP_RIGHT)
                )
            );
            tokenData = tokenData.concat(
                getPiece(
                    blitmapContract.tokenDataOf(tokenPieces[tokenId].bottomLeft.tid),
                    getCornerStart(BOTTOM_LEFT), getCornerOffset(BOTTOM_LEFT)
                )
            );
            tokenData = tokenData.concat(
                getPiece(
                    blitmapContract.tokenDataOf(tokenPieces[tokenId].bottomRight.tid),
                    getCornerStart(BOTTOM_RIGHT), getCornerOffset(BOTTOM_RIGHT)
                )
            );
        }

        return tokenData;
    }

    function tokenAttributes(uint256 tokenId) public view returns (string memory) {
        AllPieces memory piece = tokenPieces[tokenId];
        if (piece.single.exists) {
            return string(
                abi.encodePacked(
                    '{"trait_type": "Blitmap Token ID", "value":"', uint2str(piece.single.tid), '"}, {"trait_type": "corner", "value":"', getCornerString(piece.single.corner), '"}'
                )
            );
        } else {
            return string(
            abi.encodePacked(
                '{"trait_type": "Forged", "value":"True"},'
                '{"trait_type": "Blitmap Token ID", "value":"', uint2str(piece.topLeft.tid), '"},'
                '{"trait_type": "Blitmap Token ID", "value":"', uint2str(piece.topRight.tid), '"},{"trait_type": "Blitmap Token ID", "value":"', uint2str(piece.bottomLeft.tid), '"},{"trait_type": "Blitmap Token ID", "value":"', uint2str(piece.bottomRight.tid), '"}'
                )
            );
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Shattered Map #',uint2str(tokenId),'", "description":"Shattered Maps are an on-chain Blitmap derivative that allows you to mashup your favorite Blitmaps into new designs.", "image":"',tokenSvgDataOf(tokenId),'", "attributes":[',tokenAttributes(tokenId),']}'
                            )
                        )
                    )
                )
            );
    }

    function tokenSvgDataOf(uint256 tokenId) public view returns (string memory) {
        bytes memory tokenData = tokenDataOf(tokenId);
        bool fullSquare = tokenData.length > 76;
        string memory dims = fullSquare ? '32' : '16';
        string memory svgString = string(abi.encodePacked(
            '<?xml version="1.0" encoding="UTF-8" standalone="no"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 ',
            dims,
            ' ',
            dims,
            '">'));
        string[4] memory colors;
        uint256 square = 0;
        for (uint256 i = 0; i < tokenData.length; i+=76) {
            bytes memory data = tokenData.slice(i, 76);
            colors = BlitmapHelper.getColorsAsHex(data);
            bool left = square % 2 == 0;
            bool top = i < 152;
            svgString = string(abi.encodePacked(svgString, draw(left ? 0 : 16, top ? 0 : 16, left ? 16 : 32, data, colors)));
            square++;
        }

        return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(abi.encodePacked(svgString, "</svg>"))));
    }

    function mintPiece(uint256 tokenId, uint256 blitTokenId) private {
        require(tokenId <= maxSupply, 'Total supply has been minted');

        uint256 cornerIndex;
        if (usedPieces[blitTokenId].exists) {
            if (usedPieces[blitTokenId].corners.length == 1) {
                cornerIndex = 0;
            } else {
                cornerIndex = uint(
                    keccak256(
                        abi.encodePacked(
                            block.difficulty, block.timestamp, msg.sender, tokenId
                        )
                    )
                )
                % usedPieces[blitTokenId].corners.length;
            }

            tokenPieces[tokenId].single = Piece(blitTokenId, usedPieces[blitTokenId].corners[cornerIndex], true);
            usedPieces[blitTokenId].corners = removeCorner(cornerIndex, usedPieces[blitTokenId].corners);
        } else {
            uint256[] memory corners = new uint256[](4);
            corners[0] = TOP_LEFT;
            corners[1] = TOP_RIGHT;
            corners[2] = BOTTOM_LEFT;
            corners[3] = BOTTOM_RIGHT;

            cornerIndex = uint(
                keccak256(
                    abi.encodePacked(
                        block.difficulty, block.timestamp, msg.sender, tokenId
                    )
                )
            ) % 4;

            BlitmapPieces memory blitmapPiece = BlitmapPieces(removeCorner(cornerIndex, corners), true);

            usedPieces[blitTokenId] = blitmapPiece;
            tokenPieces[tokenId] = AllPieces(
                Piece(0, 0, false),
                Piece(0, 0, false),
                Piece(0, 0, false),
                Piece(0, 0, false),
                Piece(blitTokenId, corners[cornerIndex], true)
            );
        }

        _safeMint(msg.sender, tokenId);
        emit PieceMinted(blitTokenId);
    }

    function mintMany(uint256[] memory ids) public payable nonReentrant {
        require(live == true, 'Minting must be live');
        require(ids.length * PRICE == msg.value, "Mint price is not correct");
        require(ids.length <= 8, "Can only mint 8 max at a time.");

        for (uint256 i = 0; i < ids.length; i++) {
            mintPiece(getNextPieceId(), ids[i]);
        }

    }

    function forge(uint256 firstId, uint256 secondId, uint256 thirdId, uint256 fourthId) public nonReentrant {
        require(msg.sender == ownerOf(firstId), 'Piece not owned');
        require(msg.sender == ownerOf(secondId), 'Piece not owned');
        require(msg.sender == ownerOf(thirdId), 'Piece not owned');
        require(msg.sender == ownerOf(fourthId), 'Piece not owned');
        require(tokenPieces[firstId].single.corner == TOP_LEFT, 'First selection must be top left corner');
        require(tokenPieces[secondId].single.corner == TOP_RIGHT, 'Second selection must be top right corner');
        require(tokenPieces[thirdId].single.corner == BOTTOM_LEFT, 'Third selection must be bottom left corner');
        require(tokenPieces[fourthId].single.corner == BOTTOM_RIGHT, 'Fourth selection must be bottom right corner');

        AllPieces memory allPieces = AllPieces(
            tokenPieces[firstId].single,
            tokenPieces[secondId].single,
            tokenPieces[thirdId].single,
            tokenPieces[fourthId].single,
            Piece(0, 0, false)
        );

        uint256 tokenId = getNextForgedId();
        tokenPieces[tokenId] = allPieces;

        _burn(firstId);
        _burn(secondId);
        _burn(thirdId);
        _burn(fourthId);

        _safeMint(msg.sender, tokenId);
    }

    // via https://stackoverflow.com/a/65707309/424107
    // @dev credit again to the blitmap contract
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

