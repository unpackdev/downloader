// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IERC721Metadata.sol";
import "./ERC165.sol";
import "./Context.sol";
import "./ILoot.sol";

contract UnitedLoot is ILoot, Context, ERC165 {
    ILoot public constant ogLoot = ILoot(0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7);
    ILoot public constant xLoot = ILoot(0x8bf2f876E2dCD2CAe9C3d272f325776c82DA366d);

    function _iLoot(uint256 tokenId) internal pure returns (ILoot) {
        if (tokenId < 8001) {
            return ogLoot;
        } else {
            return xLoot;
        }
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return ogLoot.balanceOf(owner) + xLoot.balanceOf(owner);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        ILoot loot = _iLoot(tokenId);
        address owner = loot.ownerOf(tokenId);
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return "United Loot";
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return "uLOOT";
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        uint256 ogBalance = ogLoot.balanceOf(owner);
        uint256 xBalance = xLoot.balanceOf(owner);
        require(index < ogBalance + xBalance, "ERC721Enumerable: owner index out of bounds");
        if (index < ogBalance) return ogLoot.tokenOfOwnerByIndex(owner, index);
        return xLoot.tokenOfOwnerByIndex(owner, index - ogBalance);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return ogLoot.totalSupply() + xLoot.totalSupply();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        uint256 ogSupply = ogLoot.totalSupply();
        uint256 xSupply = xLoot.totalSupply();
        require(index < ogSupply + xSupply, "ERC721Enumerable: global index out of bounds");
        if (index < ogSupply) return ogLoot.tokenByIndex(index);
        return xLoot.tokenByIndex(index - ogSupply);
    }

    /// @dev Requires approval
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        _iLoot(tokenId).safeTransferFrom(from, to, tokenId);
    }

    /// @dev Requires approval
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        _iLoot(tokenId).transferFrom(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) external override {
        _iLoot(tokenId).approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) external view override returns (address operator) {
        return _iLoot(tokenId).getApproved(tokenId);
    }

    function setApprovalForAll(address operator, bool _approved) external override {
        ogLoot.setApprovalForAll(operator, _approved);
        xLoot.setApprovalForAll(operator, _approved);
    }

    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return ogLoot.isApprovedForAll(owner, operator) && xLoot.isApprovedForAll(owner, operator);
    }

    /// @dev Requires approval
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override {
        _iLoot(tokenId).safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function getWeapon(uint256 tokenId) public view override returns (string memory) {
        return _iLoot(tokenId).getWeapon(tokenId);
    }

    function getChest(uint256 tokenId) public view override returns (string memory) {
        return _iLoot(tokenId).getChest(tokenId);
    }

    function getHead(uint256 tokenId) public view override returns (string memory) {
        return _iLoot(tokenId).getHead(tokenId);
    }

    function getWaist(uint256 tokenId) public view override returns (string memory) {
        return _iLoot(tokenId).getWaist(tokenId);
    }

    function getFoot(uint256 tokenId) public view override returns (string memory) {
        return _iLoot(tokenId).getFoot(tokenId);
    }

    function getHand(uint256 tokenId) public view override returns (string memory) {
        return _iLoot(tokenId).getHand(tokenId);
    }

    function getNeck(uint256 tokenId) public view override returns (string memory) {
        return _iLoot(tokenId).getNeck(tokenId);
    }

    function getRing(uint256 tokenId) public view override returns (string memory) {
        return _iLoot(tokenId).getRing(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string[17] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="#48494B" /><text x="10" y="20" class="base">';

        parts[1] = getWeapon(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getChest(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getHead(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getWaist(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getFoot(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getHand(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getNeck(tokenId);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getRing(tokenId);

        parts[16] = "</text></svg>";

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8])
        );
        output = string(
            abi.encodePacked(
                output,
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14],
                parts[15],
                parts[16]
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Bag #',
                        toString(tokenId),
                        '", "description": "UnitedLoot is the union of Loot and xLoot", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }

    function toString(uint256 value) internal pure returns (string memory) {
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
    function encode(bytes memory data) internal pure returns (string memory) {
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
