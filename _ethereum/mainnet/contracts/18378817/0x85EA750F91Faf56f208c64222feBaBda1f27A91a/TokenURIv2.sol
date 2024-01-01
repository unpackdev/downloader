// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IColdHardCash {
  function owner() external view returns (address);
  function minter() external view returns (address);
  function isRedeemed(uint256) external view returns (bool);
}

interface ICashMinter {
  function auctionIdToHighestBid(uint256) external view returns (uint128 amount, uint128 timestamp, address bidder);
}

contract TokenURIv2 {
  using Strings for uint256;

  IColdHardCash public baseContract;
  string public baseURI = 'ipfs://bafybeiahxq26mj3r3w2j54hqsqg6vroksdyjtsnktrtocctz5irmiybpre/';
  string public externalUrl = 'https://steviep.xyz/cash';
  string public description = "Each Cold Hard Cash (CASH) token holder may request that the currency depicted in their token's thumbnail be mailed to them. All shipment costs above the cost of standard domestic postage shall be made at the expense of the token holder. The Artist shall not be held liable for any shipments lost in the mail. The Artist shall make a good faith effort to store all physical currency until such mailing takes place, but makes no guarantee on their ability to carry out said shipment. Please contact the Artist directly to arrange a shipment.";
  uint256 auctionOffset = 16;

  mapping(uint256 => string) public tokenIdToName;

  constructor() {
    baseContract = IColdHardCash(0x6DEa3f6f1bf5ce6606054BaabF5452726Fe4dEA1);

    tokenIdToName[0] = '$0.00';
    tokenIdToName[1] = '$0.01';
    tokenIdToName[2] = '$0.05';
    tokenIdToName[3] = '$0.10';
    tokenIdToName[4] = '$0.25';
    tokenIdToName[5] = '$0.50';
    tokenIdToName[6] = '$1.00';
    tokenIdToName[7] = '$2.00';
    tokenIdToName[8] = '$5.00';
    tokenIdToName[9] = '$6.67';
    tokenIdToName[10] = '$10.00';
    tokenIdToName[11] = '$20.00';
    tokenIdToName[12] = '$50.00';
    tokenIdToName[13] = '$50.32';
    tokenIdToName[14] = '$100.00';
    tokenIdToName[15] = '$???.??';
  }

  function tokenURI(uint256 tokenId) public view  returns (string memory) {
    (uint128 originalSaleAmount, ,) = ICashMinter(baseContract.minter()).auctionIdToHighestBid(tokenId + auctionOffset);

    string memory originalSalePrice = string.concat(
      '{"trait_type": "Original Sale Price", "value": "',
      (uint256(originalSaleAmount)).toString(),
      ' wei',
      '"}'
    );

    bytes memory json = abi.encodePacked(
      'data:application/json;utf8,',
      '{"name": "', tokenIdToName[tokenId],'",',
      '"description": "', description, '",',
      '"image": "', baseURI, tokenId.toString(), '.jpg",',
      '"attributes": [{"trait_type": "Physical Redeemed", "value": "', baseContract.isRedeemed(tokenId) ? 'True' : 'False', '"},', originalSalePrice,'],',
      '"external_url": "', externalUrl, '"',
      '}'
    );
    return string(json);
  }


  function updateURI(string memory newURI, string memory newExternalURL, uint256 newAuctionOffset) external {
    require(msg.sender == baseContract.owner(), 'Cannot update');
    baseURI = newURI;
    externalUrl = newExternalURL;
    auctionOffset = newAuctionOffset;
  }
}


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

    // Don't need these

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}