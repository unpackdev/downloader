// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./StringsUpgradeable.sol";

import "./BasicErc2981V1.sol";
import "./MetadataUriV1.sol";
import "./OperatorFilterConsumerV1.sol";

abstract contract Erc1155V2 is
    ERC1155Upgradeable,
    OperatorFilterConsumerV1,
    MetadataUriV1,
    BasicErc2981V1,
    OwnableUpgradeable,
    AccessControlUpgradeable
{
    // =============================================================
    // Custom implementation
    // =============================================================

    // No need to reinitialize when upgrading from V1
    function __Erc1155V2_init(
        address _royaltiesReceiver,
        uint256 _royaltiesFraction,
        string memory _uriPrefix,
        string memory _uriSuffix
    ) internal onlyInitializing {
        __Ownable_init();
        __AccessControl_init();
        __BasicErc2981_init(_royaltiesReceiver, _royaltiesFraction);
        __MetadataUriV1_init(_uriPrefix, _uriSuffix);

        __Erc1155V1_init_unchained();
    }

    function __Erc1155V1_init_unchained() internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     */
    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return _buildTokenUri(_tokenId);
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC1155Upgradeable, BasicErc2981V1, AccessControlUpgradeable) returns (bool) {
        return ERC1155Upgradeable.supportsInterface(_interfaceId) || BasicErc2981V1.supportsInterface(_interfaceId) || AccessControlUpgradeable.supportsInterface(_interfaceId);
    }

    // =============================================================
    // Maintenance Actions
    // =============================================================

    function setUriPrefix(string memory _uriPrefix) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setUriPrefix(_uriPrefix);
    }

    function setUriSuffix(string memory _uriSuffix) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setUriSuffix(_uriSuffix);
    }

    function setRoyalties(address _receiver, uint256 _fraction) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRoyalties(_receiver, _fraction);
    }

    // =============================================================
    // Operator Filter
    // =============================================================

    function setApprovalForAll(address _operator, bool _approved) public virtual override onlyApprovableOperator(_operator) {
        super.setApprovalForAll(_operator, _approved);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public virtual override onlyAllowedOperator(_from) {
        super.safeTransferFrom(_from, _to, _id, _amount, _data);
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public virtual override onlyAllowedOperator(_from) {
        super.safeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
    }
}
