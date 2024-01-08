// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Realm is ERC721, ERC721Enumerable, IERC721Receiver, ReentrancyGuard, Ownable {
	uint256 public SUPPLY_INDEX = 1;
    uint256 public SUPPLY_LIMIT = 1;
	uint256 public PRICE = 0;
	
	uint256 public constant MAX_SUPPLY = 8088;
	uint256 public constant MAX_CLAIM = 8;
	uint256 public constant MAX_EDGES = 6;
	uint256 public constant MAX_CONTENTS = 16;
	
	// IPFS hash
	string[MAX_SUPPLY] public cellDescriptionIds;
	CellContent[MAX_CONTENTS][MAX_SUPPLY] public cellContents;
	uint256[MAX_EDGES][MAX_SUPPLY] public edges;
	uint256[MAX_EDGES][MAX_SUPPLY] public edgesOffered;
	mapping (uint256 => EdgeOfferFrom[]) public edgeOffersReceived;

	struct CellContent {
		address contractAddress;
		uint256 tokenId;
		address sealOwner;
		uint256 sealValue;
	}

	struct EdgeOfferFrom {
		uint256 fromCellIndex;
		uint256 fromEdgeIndex;
	}

	string[] public terrainTypes = [
		"Mountain",
		"Grassland",
		"River",
		"Jungle",
		"Lake",
		"Sea",
		"Cave",
		"Desert",
		"Forest",
		"Tundra",
		"Swamp"
	];

	constructor() ERC721("REALM", "R") {
		// Remove token 0 from supply so edges to 0 work as null
		_safeMint(address(this), 0);
		_burn(0);
	}
	
	function increaseSupplyAndClaim(address to, uint256 count) external onlyOwner {
        require(SUPPLY_INDEX == SUPPLY_LIMIT, "Limit not reached");
	    require(SUPPLY_LIMIT + count <= MAX_SUPPLY, "Max supply");
        SUPPLY_LIMIT += count;
		_claim(to, count);
    }

    function increaseSupply(uint256 count, uint256 price) external onlyOwner {
        require(SUPPLY_INDEX == SUPPLY_LIMIT, "Limit not reached");
	    require(SUPPLY_LIMIT + count <= MAX_SUPPLY, "Max supply");
		PRICE = price;
        SUPPLY_LIMIT += count;
    }
    
	function claim(address to, uint256 count) external payable nonReentrant {
	    require(SUPPLY_INDEX + count <= SUPPLY_LIMIT, "Count too high");
		require(count <= MAX_CLAIM, "Count too high");
		require(msg.value >= PRICE * count, "Value too low");
		_claim(to, count);
    }

	function _claim(address to, uint256 count) internal {
		for (uint i=0; i<count; i++) {
			_safeMint(to, SUPPLY_INDEX+i);
		}
		SUPPLY_INDEX += count;
		emit CreateCells(SUPPLY_INDEX, count);
    }

	// Assign an IPFS pointer to a description.
	function setCellDescriptionId(uint256 cellIndex, string memory descId) external {
		require(cellIndex < SUPPLY_INDEX, "Cell index");
		require(msg.sender == ownerOf(cellIndex), "Owner");
		cellDescriptionIds[cellIndex] = descId;
		emit SetCellDescriptionId(cellIndex, descId);
	}

	function _contentExists(uint256 cellIndex, uint256 contentIndex) internal view returns (bool) {
		return cellContents[cellIndex][contentIndex].sealOwner != address(0);
	}

    // Stores an nft in this cell. Must approve this contract to spend the nft before calling.
	function putContent(uint256 cellIndex, uint256 contentIndex, address contractAddress, uint256 tokenId, uint256 sealValue) external {
		require(msg.sender == ownerOf(cellIndex), "Owner");
		require(cellIndex < SUPPLY_INDEX, "Cell index");
		require(contentIndex < MAX_CONTENTS, "Content index");
		require(!_contentExists(cellIndex, contentIndex), "Content already");
		IERC721 nft = IERC721(contractAddress);
		nft.safeTransferFrom(msg.sender, address(this), tokenId);
		cellContents[cellIndex][contentIndex] = CellContent(contractAddress, tokenId, msg.sender, sealValue);
		emit PutContent(cellIndex, contractAddress, tokenId, sealValue, msg.sender);
	}

	function takeContent(uint256 cellIndex, uint256 contentIndex) external payable {
		require(msg.sender == ownerOf(cellIndex), "Owner");
		require(cellIndex < SUPPLY_INDEX, "Cell index");
		require(contentIndex < MAX_CONTENTS , "Content index");
		require(_contentExists(cellIndex, contentIndex), "Nothing there");
		CellContent memory content = cellContents[cellIndex][contentIndex];
		require(msg.value >= content.sealValue, "Value too low");
		IERC721 nft = IERC721(content.contractAddress);
		nft.safeTransferFrom(address(this), msg.sender, content.tokenId);
		cellContents[cellIndex][contentIndex] = CellContent(address(0), 0, address(0), 0);
		emit TakeContent(cellIndex, content.contractAddress, content.tokenId, content.sealValue, content.sealOwner, msg.sender);
	}

    // Connect two cells you own.
    function createEdge(uint256 fromCellIndex, uint256 fromEdgeIndex, uint256 toCellIndex, uint256 toEdgeIndex) external {
	    require(fromCellIndex > 0, "Cell index");
		require(fromCellIndex < SUPPLY_INDEX, "Cell index");
	    require(toCellIndex > 0, "Cell index");
		require(toCellIndex < SUPPLY_INDEX, "Cell index");
		require(fromEdgeIndex < MAX_EDGES, "Edge index");
		require(toEdgeIndex < MAX_EDGES, "Edge index");
		require(msg.sender == ownerOf(fromCellIndex), "Owner");
		require(msg.sender == ownerOf(toCellIndex), "Owner");
		require(edges[fromCellIndex][fromEdgeIndex] == 0, "Edge taken");
		require(edges[toCellIndex][toEdgeIndex] == 0, "Edge taken");
		_removeEdgeOffer(fromCellIndex, fromEdgeIndex);
		edges[fromCellIndex][fromEdgeIndex] = toCellIndex;
		edges[toCellIndex][toEdgeIndex] = fromCellIndex;
		emit CreateEdge(fromCellIndex, fromEdgeIndex, toCellIndex, toEdgeIndex);
    }

	// Offer to connect one cell to another.
	function offerEdge(uint256 fromCellIndex, uint256 fromEdgeIndex, uint256 toCellIndex) external {
		require(fromCellIndex > 0, "Cell index");
		require(fromCellIndex < SUPPLY_INDEX, "Cell index");
	    require(toCellIndex > 0, "Cell index");
		require(toCellIndex < SUPPLY_INDEX, "Cell index");
		require(fromEdgeIndex < MAX_EDGES, "Edge index");
		require(msg.sender == ownerOf(fromCellIndex), "Owner");
		require(edges[fromCellIndex][fromEdgeIndex] == 0, "Edge taken");
		_removeEdgeOffer(fromCellIndex, fromEdgeIndex);
		edgesOffered[fromCellIndex][fromEdgeIndex] = toCellIndex;
		uint noffers = edgeOffersReceived[toCellIndex].length;
		for (uint256 i = 0; i < noffers; i++) {
			if (edgeOffersReceived[toCellIndex][i].fromCellIndex == fromCellIndex && edgeOffersReceived[toCellIndex][i].fromEdgeIndex == fromEdgeIndex) return;
		}
		edgeOffersReceived[toCellIndex].push(EdgeOfferFrom(fromCellIndex, fromEdgeIndex));
		emit OfferEdge(fromCellIndex, fromEdgeIndex, toCellIndex);
	}

	function withdrawEdgeOffer(uint256 fromCellIndex, uint256 fromEdgeIndex) external {
		require(fromCellIndex > 0, "Cell index");
		require(fromCellIndex < SUPPLY_INDEX, "Cell index");
		require(fromEdgeIndex < MAX_EDGES, "Edge index");
		require(msg.sender == ownerOf(fromCellIndex), "Owner");
		require(edgesOffered[fromCellIndex][fromEdgeIndex] != 0, "No offer");
		_removeEdgeOffer(fromCellIndex, fromEdgeIndex);
		emit WithdrawEdgeOffer(fromCellIndex, fromEdgeIndex);
	}

	function _removeEdgeOffer(uint256 fromCellIndex, uint256 fromEdgeIndex) internal {
		if (edgesOffered[fromCellIndex][fromEdgeIndex] < SUPPLY_INDEX && edgesOffered[fromCellIndex][fromEdgeIndex] > 0) {
			uint256 toCellIndex = edgesOffered[fromCellIndex][fromEdgeIndex];
			edgesOffered[fromCellIndex][fromEdgeIndex] = 0;
			uint noffers = edgeOffersReceived[toCellIndex].length;
			EdgeOfferFrom[] memory offers = edgeOffersReceived[toCellIndex];
			for (uint256 i = 0; i < noffers; i++) {
				if (offers[i].fromCellIndex == fromCellIndex && offers[i].fromEdgeIndex == fromEdgeIndex) {
					edgeOffersReceived[toCellIndex][i] = edgeOffersReceived[toCellIndex][noffers-1];
					edgeOffersReceived[toCellIndex].pop();
					return;
				}
			}
		}
	}

	function acceptEdgeOffer(uint256 fromCellIndex, uint256 fromEdgeIndex, uint256 toCellIndex, uint256 toEdgeIndex) external {
	    require(fromCellIndex > 0, "Cell index");
		require(fromCellIndex < SUPPLY_INDEX, "Cell index");
	    require(toCellIndex > 0, "Cell index");
		require(toCellIndex < SUPPLY_INDEX, "Cell index");
		require(fromEdgeIndex < MAX_EDGES, "Edge index");
		require(toEdgeIndex < MAX_EDGES, "Edge index");
		require(msg.sender == ownerOf(toCellIndex), "Owner");
		require(edgesOffered[fromCellIndex][fromEdgeIndex] == toCellIndex, "No offer");
		require(edges[toCellIndex][toEdgeIndex] == 0, "Edge taken");
		_removeEdgeOffer(fromCellIndex, fromEdgeIndex);
		edges[fromCellIndex][fromEdgeIndex] = toCellIndex;
		edges[toCellIndex][toEdgeIndex] = fromCellIndex;
		emit AcceptEdgeOffer(fromCellIndex, fromEdgeIndex, toCellIndex, toEdgeIndex);
	}

	function destroyEdge(uint256 cellIndex, uint256 edgeIndex) external {
	    require(cellIndex > 0, "Cell index");
		require(cellIndex < SUPPLY_INDEX, "Cell index");
		require(edgeIndex < MAX_EDGES, "Edge index");
		require(msg.sender == ownerOf(cellIndex), "Owner");
		require(edges[cellIndex][edgeIndex] == 0, "Edge empty");
		uint256 toCellIndex = edges[cellIndex][edgeIndex];
		uint256 toEdgeIndex;
		for (uint i = 0; i < MAX_EDGES; i++) {
			if (edges[toCellIndex][i] == cellIndex) toEdgeIndex = i;
		}
		edges[toCellIndex][toEdgeIndex] = 0;
		edges[cellIndex][edgeIndex] = 0;
		emit DestroyEdge(toCellIndex, toEdgeIndex, cellIndex, edgeIndex);
	}

	function withdrawAll() external payable onlyOwner {
		uint256 balance = address(this).balance;
		require(balance > 0);
		_widthdraw(msg.sender, address(this).balance);
	}

	function _widthdraw(address _address, uint256 _amount) internal {
		(bool success, ) = _address.call{value: _amount}("");
		require(success, "Transfer failed.");
  	}

  	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
	
	function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external pure override(IERC721Receiver) returns (bytes4) {
        return Realm.onERC721Received.selector;
    }

	function tokenURI(uint256 tokenId) override public view returns (string memory) {
		uint256 rterr = uint256(keccak256(abi.encodePacked("REALMTERRAIN", Util.toString(tokenId))));
		return Util._tokenURI(tokenId, terrainTypes[rterr % terrainTypes.length]);
    }
	
	event CreateCells(uint256 indexed id, uint256 count);
	event SetCellDescriptionId(uint256 cellIndex, string descId);
	event OfferEdge(uint256 indexed fromCellIndex, uint256 fromEdgeIndex, uint256 indexed toCellIndex);
	event WithdrawEdgeOffer(uint256 indexed fromCellIndex, uint256 fromEdgeIndex);
	event AcceptEdgeOffer(uint256 indexed fromCellIndex, uint256 fromEdgeIndex, uint256 indexed toCellIndex, uint256 toEdgeIndex);
	event CreateEdge(uint256 indexed fromCellIndex, uint256 fromEdgeIndex, uint256 indexed toCellIndex, uint256 toEdgeIndex);
	event DestroyEdge(uint256 indexed fromCellIndex, uint256 fromEdgeIndex, uint256 indexed toCellIndex, uint256 toEdgeIndex);
	event PutContent(uint256 cellIndex, address indexed contractAddress, uint256 tokenId, uint256 sealValue, address indexed sealOwner);
	event TakeContent(uint256 cellIndex, address indexed contractAddress, uint256 tokenId, uint256 sealValue, address indexed sealOwner, address indexed takenBy);
}

library Util {
	function _tokenURI(uint256 tokenId, string memory _tt) public pure returns (string memory) {
        string[3] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        parts[1] = _tt;
		parts[2] = '</text></svg>';
		string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Cell #', toString(tokenId), '", "description": "This is the REALM. It exists to build upon.", "image_data": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
		return output;
    }
	
	function toString(uint256 value) public pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) public pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

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

