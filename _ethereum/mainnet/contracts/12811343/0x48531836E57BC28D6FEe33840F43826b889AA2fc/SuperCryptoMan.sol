// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.6;

import "./RaribleUserERC1155.sol";

interface iSuperCyrptoMan {

    function mint(
        uint256 id,
        uint256 amount,
        string memory metadataCidStartsWithSlashIPFSSlash, // such as "/ipfs/[IPFS cid]"
        address payable[] memory _royaltyAddresses,
        uint256[] memory _royaltiesWithTwoDecimals
    ) external;

    function mintBatch(
        uint256[] memory ids,
        uint256[] memory amounts,
        string[] calldata metadataCidListStartsWithSlashIPFSSlash,
        address payable[] memory _royaltyAddresses,
        uint256[] memory _royaltiesWithTwoDecimals
    ) external;

    function mintForV1Holder(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function setMetadataForReservedTokens(
        string[45] memory metadataList
    ) external;
}

contract SuperCryptoMan is iSuperCyrptoMan, RaribleUserERC1155 {

    bytes32 public CONVERTER_ROLE = keccak256("CONVERTER_ROLE");
    uint256 private constant reservedTokenIdRange = 44;
    bool private setReservedTokenMeatadata;

    constructor(
        address creator,
        address signer,
        string memory _name,
        string memory _symbol,
        string memory contractURI
    )
    RaribleUserERC1155(
        creator,
        signer,
        _name,
        _symbol,
        contractURI,
        new address payable[](0),
        new uint256[](0)
    )
    {}

    function mint(
        uint256 id,
        uint8 v,
        bytes32 r,
        bytes32 s,
        Fee[] memory fees,
        uint256 amount,
        string memory metadataCidStartsWithSlashIPFSSlash
    ) public override {
        require(_isNotReserved(id), "reserved token");

        super.mint(id, v, r, s, fees, amount, metadataCidStartsWithSlashIPFSSlash);
    }

    function mint(
        uint256 id,
        uint256 amount,
        string memory metadataCidStartsWithSlashIPFSSlash, // such as "/ipfs/[IPFS cid]"
        address payable[] memory _royaltyAddresses,
        uint256[] memory _royaltiesWithTwoDecimals
    ) public override onlyOwner {
        require(_isNotReserved(id), "reserved token");
        require(!exists(id), "already minted");
        _setMetadataCid(id, metadataCidStartsWithSlashIPFSSlash);
        _setRoyaltiesOf(id, _royaltyAddresses, _royaltiesWithTwoDecimals);

        _mint(msg.sender, id, amount, "");
    }

    function mintBatch(
        uint256[] memory ids,
        uint256[] memory amounts,
        string[] calldata metadataCidListStartsWithSlashIPFSSlash,
        address payable[] memory _royaltyAddresses,
        uint256[] memory _royaltiesWithTwoDecimals
    ) public override onlyOwner {
        require(ids.length == metadataCidListStartsWithSlashIPFSSlash.length, "invalid length");

        for (uint256 i = 0; i < metadataCidListStartsWithSlashIPFSSlash.length; i++) {
            require(_isNotReserved(ids[i]), "reserved token");
            require(!exists(ids[i]), "already minted");
            _setMetadataCid(ids[i], metadataCidListStartsWithSlashIPFSSlash[i]);
            _setRoyaltiesOf(ids[i], _royaltyAddresses, _royaltiesWithTwoDecimals);
        }

        _mintBatch(msg.sender, ids, amounts, "");
    }

    function mintForV1Holder(
        address to,
        uint256 id,
        uint256 amount
    ) external override onlyRole(CONVERTER_ROLE) {
        require(!_isNotReserved(id), "non-reserved token");

        _mint(to, id, amount, "");
    }

    function setMetadataForReservedTokens(
        string[45] memory metadataList
    ) external override onlyOwner {
        require(!setReservedTokenMeatadata, "already set");
        setReservedTokenMeatadata = true;
        
        for (uint256 i = 0; i < metadataList.length; i++) {
            _setMetadataCid(i, metadataList[i]);
        }
    }

    function _isNotReserved(uint256 id) internal pure returns (bool) {
        return reservedTokenIdRange < id;
    }
}
