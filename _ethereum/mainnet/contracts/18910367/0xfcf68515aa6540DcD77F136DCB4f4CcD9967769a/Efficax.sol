// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";
import "./IERC1155CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./ERC165.sol";

import "./Base64.sol";
import "./SSTORE2.sol";
import "./InflateLib.sol";

contract Efficax is AdminControl, ICreatorExtensionTokenURI{
    struct Token {
        string metadata;
        string mimeType;
        address[] chunks;
        bool deflated;
        uint totalLength;
    }

    struct Options {
        string metadata;
        string mimeType;
        uint quantity;
        bool deflated;
        uint totalLength;
    }

    /**
     * @notice The mapping that contains the token data for a given creator contract & token id.
     */
    mapping(address => mapping(uint256 => Token)) public tokenData;

    /**
     * @notice A modifier for checking that the sender of the transaction has admin permissions on the Creator Contract they are trying to do something with
     * 
     * Shamelessly borrowed from the Manifold claim page extension.
     * 
     * @param creatorContractAddress The Manifold Creator Contract in question
     */
    modifier creatorAdminRequired(address creatorContractAddress) {
        AdminControl creatorCoreContract = AdminControl(creatorContractAddress);
        require(creatorCoreContract.isAdmin(msg.sender), 'Wallet is not an administrator for contract');
        _;
    }
    /**
        @notice Mints a token with `metadata` of type `mimeType` and image `image`
        @param creatorContractAddress The Manifold contract to mint to
        @param options minting details: quantity, metadata, mimeType
          - quantity The number of editions to mint
          - metadata The string metadata for the token, expressed as a JSON with no opening or closing bracket, e.g. `"name": "hello!","description": "world!"`
          - mimeType The mime type for `image`
          - deflate Whether or not the data is compressed
        @param image The image data, split into bytes of max len 24576 (EVM contract limit)
    */
    function mint1155(
        address creatorContractAddress,
        Options calldata options,
        bytes[] calldata image
    ) external creatorAdminRequired(creatorContractAddress) {
        address[] memory dest = new address[](1);
        uint256[] memory quantities = new uint256[](1);
        string[] memory uris = new string[](1);

        dest[0] = msg.sender;
        quantities[0] = options.quantity;

        uint256[] memory tokenIds = IERC1155CreatorCore(creatorContractAddress).mintExtensionNew(dest, quantities, uris);
        uint256 tokenId = tokenIds[0];

        tokenData[creatorContractAddress][tokenId].metadata = options.metadata;
        tokenData[creatorContractAddress][tokenId].mimeType = options.mimeType;
        tokenData[creatorContractAddress][tokenId].deflated = options.deflated;
        tokenData[creatorContractAddress][tokenId].totalLength = options.totalLength;

        // loop through the image array, appending a new byte array
        // to the chunks. This is because the contract storage limit
        // is 24576 but we actually get much further than that before
        // running out of gas in the block.
        for (uint8 i = 0; i < image.length; i++) {
            tokenData[creatorContractAddress][tokenId].chunks.push(SSTORE2.write(image[i]));
        }
    }
    
    /**
        @notice Mints a token with `metadata` of type `mimeType` and image `image`
        @param creatorContractAddress The Manifold contract to mint to
        @param image The image data, split into bytes of max len 24576 (EVM contract limit)
        @param options minting details: quantity, metadata, mimeType
          - quantity The number of editions to mint
          - metadata The string metadata for the token, expressed as a JSON with no opening or closing bracket, e.g. `"name": "hello!","description": "world!"`
          - mimeType The mime type for `image`
          - deflate Whether or not the data is compressed
    */
    function mint(
        address creatorContractAddress,
        Options calldata options,
        bytes[] calldata image
    ) external creatorAdminRequired(creatorContractAddress) {
        uint256 tokenId = IERC721CreatorCore(creatorContractAddress).mintExtension(msg.sender);

        tokenData[creatorContractAddress][tokenId].metadata = options.metadata;
        tokenData[creatorContractAddress][tokenId].mimeType = options.mimeType;
        tokenData[creatorContractAddress][tokenId].deflated = options.deflated;
        tokenData[creatorContractAddress][tokenId].totalLength = options.totalLength;

        // loop through the image array, appending a new byte array
        // to the chunks. This is because the contract storage limit
        // is 24576 but we actually get much further than that before
        // running out of gas in the block.
        for (uint8 i = 0; i < image.length; i++) {
            tokenData[creatorContractAddress][tokenId].chunks.push(SSTORE2.write(image[i]));
        }
    }

    /**
        @notice Updates a token with `metadata` of type `mimeType` and image `image`.
        @param creatorContractAddress The Manifold contract to mint to
        @param tokenId the token to update the data for
        @param image The image data, split into bytes of max len 24576 (EVM contract limit)
        @param options minting details: quantity, metadata, mimeType
          - quantity The number of editions to mint
          - metadata The string metadata for the token, expressed as a JSON with no opening or closing bracket, e.g. `"name": "hello!","description": "world!"`
          - mimeType The mime type for `image`
          - deflate Whether or not the data is compressed
    */
    function updateToken(
        address creatorContractAddress,
        uint256 tokenId,
        bytes[] calldata image,
        Options calldata options
    ) external creatorAdminRequired(creatorContractAddress) {
        if (bytes(options.metadata).length > 0) {
            tokenData[creatorContractAddress][tokenId].metadata = options.metadata;
        }

        if (bytes(options.mimeType).length > 0) {
            tokenData[creatorContractAddress][tokenId].mimeType = options.mimeType;
        }

        tokenData[creatorContractAddress][tokenId].deflated = options.deflated;

        if (image.length > 0) {
            delete tokenData[creatorContractAddress][tokenId].chunks;
            for (uint8 i = 0; i < image.length; i++) {
                tokenData[creatorContractAddress][tokenId].chunks.push(SSTORE2.write(image[i]));
            }
        }
    }

    /**
        @notice Appends chunks of binary data to the chunks for a given token. If your image won't fit in a single "mint" transaction, you can use this to add data to it.
        @param creatorContractAddress The Manifold contract to mint to
        @param tokenId The token to add data to
        @param chunks The chunks of data to add, max length for each individual chunk is 24576 bytes (EVM contract limit)
    */
    function appendChunks(
        address creatorContractAddress,
        uint256 tokenId,
        bytes[] calldata chunks
    ) external creatorAdminRequired(creatorContractAddress) {
        for (uint8 i = 0; i < chunks.length; i++) {
            tokenData[creatorContractAddress][tokenId].chunks.push(SSTORE2.write(chunks[i]));
        }
    }

    /**
     * @dev packs token data by converting it to base64 and attaching the mime type
     * 
     * @param creatorContractAddress the contract address containing the token
     * @param tokenId the token id to pack
     */
    function pack(address creatorContractAddress, uint256 tokenId) public view returns (string memory) {
        string memory image = string(
            abi.encodePacked(
                "data:",
                tokenData[creatorContractAddress][tokenId].mimeType,
                ";base64,"
            )
        );

        bytes memory data;

        for (uint8 i = 0; i < tokenData[creatorContractAddress][tokenId].chunks.length; i++) {
            data = abi.encodePacked(
                data,
                SSTORE2.read(tokenData[creatorContractAddress][tokenId].chunks[i])
            );
        }

        if (tokenData[creatorContractAddress][tokenId].deflated) {
            (, data) = InflateLib.puff(data, tokenData[creatorContractAddress][tokenId].totalLength);
        }

        image = string(
            abi.encodePacked(
                image,
                Base64.encode(data)
            )
        );

        return image;
    }

    function inflate(bytes memory data, uint length) external pure returns (string memory) {
        (, bytes memory ourData) = InflateLib.puff(data, length);
        return string(
            abi.encodePacked(
                ourData
            )
        );
    }

    function tokenURI(address creatorContractAddress, uint256 tokenId) external view override returns (string memory) {
        require(tokenData[creatorContractAddress][tokenId].chunks.length != 0, "Token metadata doesn't exist here");

        return string(
            abi.encodePacked(
                'data:application/json;utf8,{',
                tokenData[creatorContractAddress][tokenId].metadata,
                ', "image": "',
                pack(creatorContractAddress, tokenId),
                '"}'
            )
        );

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId
            || AdminControl.supportsInterface(interfaceId)
            || super.supportsInterface(interfaceId);
    }
}