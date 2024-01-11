// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./AccessControl.sol";

contract BurnCntNft is ERC721URIStorage, AccessControl {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    struct BurnCntNftItem {
        string name;
        string email;
        uint256 amount;
        bytes32 transactionHash;
        string description;
    }
    mapping(uint256 => BurnCntNftItem) public tokenIdBurnCntNftItemMap;

    constructor(address administrator) ERC721("MVGX Carbon Neutralizer Gift", "CNG") {
        _setupRole(DEFAULT_ADMIN_ROLE, administrator);
        _setupRole(ISSUER_ROLE, administrator);
    }

    function create(
        address recipient,
        uint256 tokenId,
        string memory name,
        string memory email,
        uint256 amount,
        bytes32 transactionHash,
        string memory description,
        string memory tokenURI
    ) public onlyRole(ISSUER_ROLE) returns (uint256) {
        _mint(recipient, tokenId);
        _setTokenURI(tokenId, tokenURI);

        BurnCntNftItem memory nft = BurnCntNftItem(
            name,
            email,
            amount,
            transactionHash,
            description
        );
        tokenIdBurnCntNftItemMap[tokenId] = nft;

        return tokenId;
    }

    function grantIssuerRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(ISSUER_ROLE, account);
    }

    function revokeIssuerRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(ISSUER_ROLE, account);
    }

    /**
     * overrive support interfaces
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}