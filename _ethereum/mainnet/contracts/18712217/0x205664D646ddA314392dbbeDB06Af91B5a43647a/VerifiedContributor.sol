// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./AccessControl.sol";

import "./IERC721.sol";

contract VerifiedContributor is ERC721Enumerable, AccessControl {
    bytes32 public constant MINT_ROLE = keccak256("MINT");
    bytes32 public constant BURN_ROLE = keccak256("BURN");
    string public metadataUri;

    error NotTransferable();

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _metadataUri,
        address _admin
    ) ERC721(name_, symbol_) {
        metadataUri = _metadataUri;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        virtual
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return
            ERC721Enumerable.supportsInterface(_interfaceId) ||
            AccessControl.supportsInterface(_interfaceId);
    }

    /// @notice Mints a token to an address.
    /// @param to The address receiving the token.
    /// @param tokenId The id of the token to be minted.
    function mint(
        address to,
        uint256 tokenId
    ) external virtual onlyRole(MINT_ROLE) {
        _mint(to, tokenId);
    }

    /// @notice Burns a token.
    /// @param tokenId The id of the token to be burned.
    function burn(uint256 tokenId) external virtual onlyRole(BURN_ROLE) {
        _burn(tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) {
        if (from != address(0)) {
            // Not a mint, token is non-transferable
            revert NotTransferable();
        }

        super.transferFrom(from, to, tokenId);
    }

    function tokenURI(uint256) public view override returns (string memory) {
        // Single image
        return metadataUri;
    }

    function updateMetadata(
        string calldata _metadataUri
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        metadataUri = _metadataUri;
    }
}
