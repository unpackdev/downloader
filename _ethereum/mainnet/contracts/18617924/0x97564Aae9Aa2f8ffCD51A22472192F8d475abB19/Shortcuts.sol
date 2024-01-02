/*
     ┓           
    ┏┣┓┏┓┏┓╋┏┓┏╋┏
    ┛┛┗┗┛┛ ┗┗┗┻┗┛
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";


import "./Base64.sol";
import "./SSTORE2.sol";

/**
 * @title SHORTCUTS
 * @author diid.eth on behalf of cada.eth
 * @notice A path less followed
 */
contract Shortcuts is ERC1155, Ownable {
    uint public price = .03 ether;
    bool public saleActive = true;

    uint private _nextTokenId = 1;

    struct Token {
        string metadata;
        string mimeType;
        address[] chunks;
        string arweaveURI;
        uint[] dimensions;
        bool locked;
        bool migrated;
    }

    /**
     * @notice The mapping that contains the token data for a given edition
     */
    mapping(uint256 => Token) public tokenData;

    constructor() ERC1155("shortcuts") {}

    /*
    --------------------------
        METADATA FUNCTIONS
    --------------------------
    */

    /**
     * @notice updates the token `tokenId`
     * 
     * @param tokenId the token id to update
     * @param image The image data, split into bytes of max len 24576 (EVM contract limit)
     * @param mimeType The mime type for `image`
     */
    function moveTokenOnChain(
            uint256 tokenId,
            bytes[] calldata image,
            string calldata mimeType,
            uint[] calldata dimensions
    ) public onlyOwner {
        require(!tokenData[tokenId].locked, "Token is already locked.");

        tokenData[tokenId].mimeType = mimeType;

        delete tokenData[tokenId].chunks;

        for (uint8 i = 0; i < image.length;) {
            tokenData[tokenId].chunks.push(SSTORE2.write(image[i]));

            unchecked { i++; }
        }

        tokenData[tokenId].dimensions = dimensions;

        tokenData[tokenId].migrated = true;
    }
    
    function updateMetadata(uint256 tokenId, string calldata metadata) public onlyOwner {
        require(!tokenData[tokenId].locked, "Token is already locked.");

        tokenData[tokenId].metadata = metadata;
    }

    function updateArweaveUri(uint256 tokenId, string calldata arweaveUri) public onlyOwner {
        require(!tokenData[tokenId].locked, "Token is already locked.");

        tokenData[tokenId].arweaveURI = arweaveUri;
    }

    /**
     *  @notice Creates a token with `metadata` of type `mimeType` and image `image`.
     * 
     *  @param arweaveUri The arweave uri for the token
     *  @param metadata The string metadata for the token, expressed as a JSON with no opening or closing bracket, e.g. `"name": "hello!","description": "world!"`
     */
    function createToken(
        string calldata arweaveUri,
        string calldata metadata
    ) external onlyOwner {
        tokenData[_nextTokenId].arweaveURI = arweaveUri;
        tokenData[_nextTokenId].metadata = metadata;

        // save token id for the next card
        unchecked {
            _nextTokenId++;
        }
    }

    /**
     *  @notice Appends chunks of binary data to the chunks for a given token. If your image won't fit in a single "mint" transaction, you can use this to add data to it.
     *  @param tokenId The token to add data to
     *  @param chunks The chunks of data to add, max length for each individual chunk is 24576 bytes (EVM contract limit)
     */
    function appendChunks(
        uint256 tokenId,
        bytes[] calldata chunks
    ) external onlyOwner {
        require(!tokenData[tokenId].locked, "Token is already locked.");

        for (uint i = 0; i < chunks.length;) {
            tokenData[tokenId].chunks.push(SSTORE2.write(chunks[i]));

            unchecked { i++; }
        }
    }

    /**
     * @notice locks all token metadata permanently.
     */
    function lockAll() external onlyOwner {
        for (uint i = 0; i < _nextTokenId;) {
            tokenData[i].locked = true;

            unchecked { i++; }
        }
    }

    /**
     * @notice what are you doing here? this is an internal function!
     * @dev decomposes the binary image data and packs that in a valid JSON alongside the given metadata and mime type
     * 
     * @param tokenId the token id to pack
     */
    function _pack(uint256 tokenId) internal view returns (string memory) {
        if (!tokenData[tokenId].migrated) {
            return tokenData[tokenId].arweaveURI;
        }

        // prefix the image type with the URI prefix and mime type
        string memory image = string(
            abi.encodePacked(
                "data:",
                tokenData[tokenId].mimeType,
                ";base64,"
            )
        );

        // start by assembling all of the chunks in memory
        bytes memory data;
        for (uint8 i = 0; i < tokenData[tokenId].chunks.length; i++) {
            data = abi.encodePacked(
                data,
                SSTORE2.read(tokenData[tokenId].chunks[i])
            );
        }

        // base64 encode and append the image data!
        image = string(
            abi.encodePacked(
                image,
                Base64.encode(data)
            )
        );

        return image;
    }

    /**
     * @notice Returns the data URI for a given token
     * 
     * @param tokenId the token id to fetch metadata for
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(
            abi.encodePacked(
                'data:application/json;utf8,{',
                tokenData[tokenId].metadata,
                ',"image":"',
                _pack(tokenId),
                '"}'
            )
        );
    }

    /*
    --------------------------
      END METADATA FUNCTIONS
    --------------------------
    */

    /*
    --------------------------
          MINT FUNCTIONS
    --------------------------
    */

    /**
     * @notice mints editions based on the value provided, should send number of packs to mint * mint price
     * 
     * Overall, this is far from the most gas-efficient way to do things here, but it is relatively foolproof which is more important to me. The usage of a single function for everything is * chefs kiss *
     */
    function mint() external payable {
        // check a few REALLY basic things
        require(saleActive == true, "Sale is not active!");
        require(msg.value % price == 0, "Invalid price.");

        // the number of packs requested to be minted is based
        // on the amount of ETH sent to this function. Give that
        // a real basic check first.
        uint packs = msg.value / price;

        uint tokens = _nextTokenId - 1;
        uint[] memory tokensToMint = new uint[](tokens);
        uint[] memory mintCount = new uint[](tokens);
        for (uint i = 0; i < tokens;) {
            tokensToMint[i] = i + 1;
            mintCount[i] = packs;

            unchecked { i++; }
        }

        // mint the tokens as a batch
        _mintBatch(msg.sender, tokensToMint, mintCount, "");
    }

    /*
    --------------------------
        END MINT FUNCTIONS
    --------------------------
    */

    /*
    --------------------------
           START ADMIN
    --------------------------
    */
    /**
     * @notice disables the sale permanently.
     */
    function stopSale() external onlyOwner {
        saleActive = false;
    }

    /**
     * @notice sets a new per-pack price
     * 
     * @param _price the new price to set
     */
    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    /**
     * @notice withdraw to the owner
     */
    function withdraw() external onlyOwner {
        (bool s,) = owner().call{value: (address(this).balance)}("");
        require(s, "Withdraw failed.");
    }

    /*
    --------------------------
            END ADMIN
    --------------------------
    */
}

// diid wuz here