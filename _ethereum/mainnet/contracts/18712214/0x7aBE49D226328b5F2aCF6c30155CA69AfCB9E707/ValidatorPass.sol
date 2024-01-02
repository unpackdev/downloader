// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./AccessControl.sol";

import "./IERC721Mintable.sol";

contract ValidatorPass is ERC721, AccessControl, IERC721Mintable {
    bytes32 public constant MINT_ROLE = keccak256("MINT");
    string public metadataUri;
    uint256 public mintCounter;

    error NotTransferable();

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _metadataUri,
        address _admin
    ) ERC721(_name, _symbol) {
        metadataUri = _metadataUri;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721, AccessControl, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Mintable).interfaceId ||
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    /// @inheritdoc IERC721Mintable
    function mint(address account) external onlyRole(MINT_ROLE) {
        _mint(account, mintCounter++);
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
