// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./OwnerOperatorControlWithSignature.sol";
import "./ERC1155Configurable.sol";
import "./ERC1155WithRoyalties.sol";
import "./ERC1155WithMetadata.sol";
import "./GroupedURI.sol";

contract BeyondNFT1155V2 is
    OwnerOperatorControlWithSignature,
    ERC1155Configurable,
    ERC1155WithRoyalties,
    ERC1155WithMetadata,
    GroupedURI
{
    // function initialize(string memory uri, address _minter) public initializer {
    //     require(_minter != address(0));

    //     __OwnerOperatorControl_init(); // already inits context and ERC165
    //     __ERC1155WithRoyalties_init();
    //     __ERC1155WithMetadata_init(uri);

    //     _setupRole(OPERATOR_ROLE, _minter);
    // }

    receive() external payable {
        revert('No value accepted');
    }

    function mint(
        uint256 id,
        uint256 supply,
        string memory uri_,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 royalties,
        address royaltiesRecipient
    ) external {
        require(!minted(id), 'ERC1155: Already minted');

        address sender = _msgSender();
        requireOperatorSignature(
            prepareMessage(sender, id, supply, uri_),
            v,
            r,
            s
        );

        _mint(sender, id, supply, bytes(''));
        _setMetadata(id, uri_, sender);

        if (royalties > 0) {
            _setRoyalties(id, royaltiesRecipient, royalties);
        }
    }

    function burn(
        address owner,
        uint256 id,
        uint256 amount
    ) external {
        require(
            owner == _msgSender() || isApprovedForAll(owner, _msgSender()),
            'ERC1155: caller is not owner nor approved'
        );

        _burn(owner, id, amount);
    }

    function burnBatch(
        address owner,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external {
        require(
            owner == _msgSender() || isApprovedForAll(owner, _msgSender()),
            'ERC1155: caller is not owner nor approved'
        );

        _burnBatch(owner, ids, amounts);
    }

    /**
     * @dev allows to transfer one id to several recipient with corresponding amounts
     */
    function safeBatchTransferIdFrom(
        address from,
        address[] memory tos,
        uint256 id,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(tos.length == amounts.length, 'ERC1155: length mismatch');

        for (uint256 i = 0; i < tos.length; i++) {
            safeTransferFrom(from, tos[i], id, amounts[i], data);
        }
    }

    /**
     * Function to let Owner set configurationURI
     */
    function setInteractiveConfURI(
        uint256 tokenId,
        address owner,
        string calldata interactiveConfURI
    ) public {
        require(
            owner == _msgSender() || isApprovedForAll(owner, _msgSender()),
            'ERC1155: caller is not owner nor approved'
        );
        _setInteractiveConfURI(tokenId, owner, interactiveConfURI);
    }

    function prepareMessage(
        address sender,
        uint256 id,
        uint256 supply,
        string memory uri_
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(sender, id, supply, uri_));
    }

    function setBatchTokenMetadata(
        uint256[] memory ids,
        string[] memory uris,
        address[] memory creators
    ) external onlyOwner {
        for (uint256 i; i < ids.length; i++) {
            _setMetadata(ids[i], uris[i], creators[i]);
        }
    }

    function registerERC2981Interface() external onlyOwner {
        _registerInterface(0xc155531d);
    }

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // get base uri from id's Group
        string memory groupUri = _getIdGroupURI(id);
        // if set it will be something like ipfs://ipfs/IPFS_HASH/{id}
        return bytes(groupUri).length > 0 ? groupUri : super.uri(id);
    }

    // added to be able to batch update already created NFTs
    // to have them interactive on Wallet and dApps!
    /**
     * @dev Function to increment the group
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function setNextGroup(
        string memory currentGroupNewURI,
        string memory nextGroupBaseURI
    ) external onlyOwner {
        _setNnextGroup(currentGroupNewURI, nextGroupBaseURI);
    }

    /**
     * @dev Function to change group id for specific ids
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function setIdGroupIdBatch(uint256[] memory ids, uint256[] memory groupIds)
        external
        onlyOwner
    {
        _setIdGroupIdBatch(ids, groupIds);
    }

    /**
     * @dev Function to change groups uris
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function setGroupURIBatch(uint256[] memory groupIds, string[] memory uris)
        external
        onlyOwner
    {
        _setGroupURIBatch(groupIds, uris);
    }
}
