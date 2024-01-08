// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Strings.sol";

/**
 * A series of artworks containing lines that cost gas. They are somewhat expensive as lines go.
 * 
 * Draw svg line artwork together. 
 * Select an artwork from 0 to MAX_ARTWORKS to draw lines on it.
 * After MAX_LINES have been drawn on the artwork, whoever drew the most lines may grant() the NFT to themselves.
 *
 * Client: expensivelines.com
 */
contract ExpensiveLines is ERC721, Ownable {
  constructor() ERC721('Expensive Lines', 'ELN') {} 
  
  /**
   * When this number of lines have been drawn, an artwork is complete.
   */
  uint8 constant internal MAX_LINES = 50;

  /**
   * The number of artworks available.
   */
  uint16 constant internal MAX_ARTWORKS = 4000;

  struct Line {
    uint8 x1;
    uint8 y1;
    uint8 x2;
    uint8 y2;
    uint8 colorR;
    uint8 colorG;
    uint8 colorB;
  }

  /**
   * For each artwork, we track who added each line in it as well as each line.
   * These data structures and their contents do not get deleted and persist across all artworks.
   */
  mapping(uint16 => Artwork) internal artworks;
  struct Artwork {
    uint8 lineCount; // For tracking how close we are to MAX_LINES
    address leader;  // Who has drawn the most lines
    mapping(address => uint8) linesAddedBy; // For tracking who has drawn the most lines
    Line[MAX_LINES] lines; // The lines used to draw the artwork when tokenURI is called
  }  

  /**
   * Emitted whenever a new line is drawn.
   */
  event LineAdded(uint16 indexed artworkId, uint8 lineCount, uint16 linesByLeader);

  /**
   * Emitted whenever someone draws more lines than the existing leader.
   */
  event LeaderChanged(uint16 indexed artworkId, address leader, uint8 lines);

  /**
   * Add a line to an artwork.
   *
   * You may also optionally send ether to this function to increase the "material cost" clients may read.
   */
  function draw(uint16 artworkId, uint8 x1, uint8 y1, uint8 x2, uint8 y2, uint8 colorR, uint8 colorG, uint8 colorB) external payable {
    require(!(x1 == x2 && y1 == y2), 'No dots!');
    require(artworkId < MAX_ARTWORKS, 'id does not exist.');

    Artwork storage artwork = artworks[artworkId];
    require(artwork.lineCount < MAX_LINES, 'Max lines reached.');

    Line memory line = Line(x1, y1, x2, y2, colorR, colorG, colorB);
    artwork.lines[artwork.lineCount] = line;
    artwork.lineCount++;

    updateLeader(artworkId, artwork, msg.sender);
    
    emit LineAdded(artworkId, artwork.lineCount, artwork.linesAddedBy[artwork.leader]);
  }

  /**
   * Grant yourself the NFT for the artwork.
   * You may only grant if you drew the most lines in that artwork.
   * Watch for the ERC721 Transfer event to be emitted.
   * Note: _safeMint has reentrancy issues potentially, so calling after everything to avoid.
   */
  function grant(uint16 artworkId) external {
    require(artworkId < MAX_ARTWORKS, 'id does not exist.');

    Artwork storage artwork = artworks[artworkId];

    require(artwork.lineCount == MAX_LINES, 'Artwork in progress.');    
    require(artwork.leader == msg.sender, 'Only the leader may grant.');     

    _safeMint(msg.sender, artworkId);
  }

  /**
   * Get the metadata and svg of the artwork corresponding to tokenId/NFT.
   * Best to run this from a local node to minimize cost.
   */
  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    require(tokenId < MAX_ARTWORKS, 'id does not exist.');

    Artwork storage artwork = artworks[uint16(tokenId)];
    Line[MAX_LINES] storage lines = artwork.lines;
    string memory output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 255 255">';
    
    // Loop is tolerable since underlying array is fixed.
    for (uint i = 0; i < artwork.lineCount; i++) {
      Line storage line = lines[i];
      output = string(abi.encodePacked(output, 
        '<line x1="',
        Strings.toString(line.x1),
        '" y1="',
        Strings.toString(line.y1),
        '" x2="',
        Strings.toString(line.x2),
        '" y2="',
        Strings.toString(line.y2),
        '" stroke="rgb(',
        Strings.toString(line.colorR),
        ',',
        Strings.toString(line.colorG),
        ',',
        Strings.toString(line.colorB),
        ')" stroke-width="10"/>'
      ));  
    }

    output = string(abi.encodePacked(output, '</svg>'));

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Expensive Lines #',
            Strings.toString(tokenId),
            '", "description": "We drew these lines together. They cost a lot.", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(output)),
            '"}'
          )
        )
      )
    );
    output = string(abi.encodePacked('data:application/json;base64,', json));

    return output;
  }

  /**
   * Find out how many lines you've drawn.
   */
  function linesBy(uint16 artworkId, address artist) external view returns (uint8) {
    return artworks[artworkId].linesAddedBy[artist];
  }

  /**
   * To withdraw balance optionally sent to draw to increase material costs.
   */
  function withdraw() external onlyOwner {
    address payable recipient = payable(owner());
    recipient.transfer(address(this).balance);
  }

  /**
   * Increments how many lines sender has added.
   * If sender has added more than the leader, they're the new leader.
   */
  function updateLeader(uint16 artworkId, Artwork storage artwork, address sender) internal {

    // Senders not yet tracked by linesAddedBy default to 0
    uint8 linesAdded = artwork.linesAddedBy[sender] + 1;
    artwork.linesAddedBy[sender] = linesAdded;

    if (artwork.leader == address(0) || linesAdded > artwork.linesAddedBy[artwork.leader]) {
      artwork.leader = sender;
      emit LeaderChanged(artworkId, artwork.leader, linesAdded);
    }
  }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return '';

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}