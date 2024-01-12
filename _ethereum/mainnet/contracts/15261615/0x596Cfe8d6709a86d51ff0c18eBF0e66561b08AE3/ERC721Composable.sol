// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";

interface IERC721Part is IERC721 {
    function exists(uint256 tokenId) external view returns (bool);

    function slotIndex(uint256 tokenId) external view returns (uint256);

    function safeMint(
        address to,
        uint256 tokenId,
        uint256 slotIndex,
        bytes memory data
    ) external;
}

abstract contract ERC721Composable is Ownable, EIP712, ERC721 {
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant PARTS_CLAIM_CALL_HASH_TYPE =
        keccak256("PartsClaim(uint256 tokenId,address part,uint256[] partIds,uint256[] slotIds)");

    struct Slot {
        address part;
        uint256 tokenId;
    }

    mapping(uint256 => Slot[6]) public slots;

    mapping(uint256 => bool) public claimed;

    EnumerableSet.AddressSet private _parts;

    address public claimSigner;

    event PartRemoved(address indexed part);
    event PartAdded(address indexed part);
    event PartSplit(uint256 indexed tokenId, address indexed part, uint256 partId, uint256 slotIndex);
    event PartCombined(uint256 indexed tokenId, address indexed part, uint256 partId, uint256 slotIndex);

    function claimParts(
        uint256 tokenId,
        address part,
        uint256[] calldata partIds,
        uint256[] calldata slotIds,
        bytes memory sig
    ) external {
        require(!claimed[tokenId], "already claimed");
        require(ownerOf(tokenId) == msg.sender, "not owner");
        require(isPart(part), "invalid part");
        require(partIds.length == slotIds.length, "parts length not match slots");

        bytes32 digest = ECDSA.toTypedDataHash(
            _domainSeparatorV4(),
            keccak256(
                abi.encode(
                    PARTS_CLAIM_CALL_HASH_TYPE,
                    tokenId,
                    part,
                    keccak256(abi.encodePacked(partIds)),
                    keccak256(abi.encodePacked(slotIds))
                )
            )
        );
        require(digest.recover(sig) == claimSigner, "invalid signer");

        for (uint256 i = 0; i < slotIds.length; i++) {
            require(slotIds[i] < 6, "invalid slotId");
            Slot storage slot = slots[tokenId][slotIds[i]];
            require(slot.part == address(0), "part duplicated");
            slot.part = part;
            slot.tokenId = partIds[i];
        }

        claimed[tokenId] = true;
    }

    function split(uint256 tokenId, uint256 slotIndex) external {
        require(claimed[tokenId], "parts not claimed");
        require(ownerOf(tokenId) == msg.sender, "not owner");

        Slot storage slot = slots[tokenId][slotIndex];
        require(slot.part != address(0), "part not exist");

        IERC721Part part = IERC721Part(slot.part);
        if (part.exists(slot.tokenId)) {
            part.safeTransferFrom(address(this), msg.sender, slot.tokenId);
        } else {
            part.safeMint(msg.sender, slot.tokenId, slotIndex, "");
        }

        emit PartSplit(tokenId, slot.part, slot.tokenId, slotIndex);

        slot.part = address(0);
        slot.tokenId = 0;
    }

    function combine(
        uint256 tokenId,
        address part,
        uint256 partId
    ) public {
        require(claimed[tokenId], "parts not claimed");
        require(ownerOf(tokenId) == msg.sender, "not owner");

        IERC721Part partNFT = IERC721Part(part);
        uint256 slotIndex = partNFT.slotIndex(partId);
        require(slots[tokenId][slotIndex].part == address(0), "part already exist");

        partNFT.safeTransferFrom(msg.sender, address(this), partId);

        Slot storage slot = slots[tokenId][slotIndex];
        slot.part = part;
        slot.tokenId = partId;

        emit PartCombined(tokenId, part, partId, slotIndex);
    }

    function setClaimSigner(address newSigner) external onlyOwner {
        claimSigner = newSigner;
    }

    function addPart(address part) external onlyOwner {
        require(!_parts.contains(part), "ERC721Composable: part already exist");
        _parts.add(part);

        emit PartAdded(part);
    }

    function removePart(address part) external onlyOwner {
        require(_parts.contains(part), "ERC721Composable: part not exist");
        _parts.remove(part);

        emit PartRemoved(part);
    }

    function isPart(address part) public view returns (bool) {
        return _parts.contains(part);
    }

    function partOf(uint256 tokenId, uint256 slotIndex) public view returns (Slot memory) {
        return slots[tokenId][slotIndex];
    }
}
