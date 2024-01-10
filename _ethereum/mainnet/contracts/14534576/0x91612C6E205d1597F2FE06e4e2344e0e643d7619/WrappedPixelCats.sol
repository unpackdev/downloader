pragma solidity >=0.8.13;

// SPDX-License-Identifier: CC0-1.0

import "./ERC1155Holder.sol";
import "./IERC1155.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract WrappedPixelCats is ERC1155Holder, ERC721, Ownable {

    constructor() ERC721("Wrapped PixelCats", "w24px") {}

    IERC1155 private constant openSeaStorefront = IERC1155(0x495f947276749Ce646f68AC8c248420045cb7b5e);

    // replace these parameters with your own if you are using this
    address  private constant OPENSEA_CREATOR = 0xEfE708e6Dd941e29965F34f4c5C6e78f0Ebe3F5b;
    uint     private constant MIN_ID = 1;
    uint     private constant MAX_ID = 9900;
    uint     private constant QUANTITY = 1;
    string   private constant BASE_URI = "ipfs://QmXFLtE5nvBRDCikZH6DeRvY7mmML9UQ4o87oCbpWeHTfV/";

    function _toOpenSeaId(uint id) internal pure returns (uint) {
        require(id >= MIN_ID, "id too low");
        require(id <= MAX_ID, "id too high");

        /* 
        ** We need to account for a few "ghost" tokens, which have been
        ** minted on the OS frontend and then subsequently deleted.
        ** These tokens technically no longer exist, but the ID counter
        ** for the author's creations has already been incremented,
        ** which breaks the sequentiality of the (undeleted) token IDs.
        ** In the case of 24px, the deleted tokens have the IDs 1, 10 and 1322.
        */

        uint offset = 1;

        if (id > 10)
            offset += 1;

        if (id > 1322)
            offset += 1;

        /* 
        ** While the token IDs for OpenSea Shared Storefront-based tokens
        ** appear to be gibberish in Base10, they are pretty predictable
        ** in Base16, and use the following format:
        **
        **   efe708e6dd941e29965f34f4c5c6e78f0ebe3f5b 000000000026af 0000000001
        **   token creator address                    token ID       total qty.
        **              (the example ID above is from PixelCat 9900)
        **
        */

        uint p1 = uint256(uint160(OPENSEA_CREATOR)) << 96;
        uint p2 = (id + offset) << 40;

        return p1 + p2 + QUANTITY;
    }

    function wrapSingle(uint _id) external {
        openSeaStorefront.safeTransferFrom(
            msg.sender,
            address(this),
            _toOpenSeaId(_id),
            QUANTITY,
            ""
        );

        _mint(msg.sender, _id);
    }

    function unwrapSingle(uint _id) external {
        require(ownerOf(_id) == msg.sender, "not the owner");
        _burn(_id);

        openSeaStorefront.safeTransferFrom(
            address(this),
            msg.sender,
            _toOpenSeaId(_id),
            QUANTITY,
            ""
        );
    }

    function wrapMultiple(uint[] calldata ids) external {
        uint[] memory openStoreIds = new uint[](ids.length);
        uint[] memory quantities = new uint[](ids.length);

        for (uint i = 0; i < ids.length; i++) {
            openStoreIds[i] = _toOpenSeaId(ids[i]);
            quantities[i] = 1;
            _mint(msg.sender, ids[i]);
        }

        openSeaStorefront.safeBatchTransferFrom(
            msg.sender,
            address(this),
            openStoreIds,
            quantities,
            ""
        );
    }

    function unwrapMultiple(uint[] calldata ids) external {
        uint[] memory openStoreIds = new uint[](ids.length);
        uint[] memory quantities = new uint[](ids.length);

        for (uint i = 0; i < ids.length; i++) {
            require(msg.sender == ownerOf(ids[i]), "not the owner");

            openStoreIds[i] = _toOpenSeaId(ids[i]);
            quantities[i] = 1;

            _burn(ids[i]);
        }

        openSeaStorefront.safeBatchTransferFrom(
            address(this),
            msg.sender,
            openStoreIds,
            quantities,
            ""
        );
    }

    function supportsInterface(bytes4 interfaceId) public pure override(ERC721, ERC1155Receiver) returns (bool) {
        return interfaceId == 0x01ffc9a7 || // ERC165
               interfaceId == 0x80ac58cd || // ERC721
               interfaceId == 0x5b5e139f || // ERC721Metadata
               interfaceId == 0x4e2312e0;   // ERC1155TokenReceiver
    }

    function tokenURI(uint id) public pure override returns (string memory) {
        return string(
            abi.encodePacked(
                BASE_URI, Strings.toString(id), ".json"
            )
        );
    }
    
}
