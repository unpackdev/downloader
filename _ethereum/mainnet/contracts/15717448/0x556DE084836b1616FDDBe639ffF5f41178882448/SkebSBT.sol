// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "./AccessControl.sol";
import "./ERC721Enumerable.sol";
import "./ISkebSBT.sol";

contract SkebSBT is ERC721Enumerable, AccessControl, ISkebSBT {
    string public baseURI;
    mapping(uint256 => address) internal tokenIdToOwner;
    uint256 public latestTokenId;
    using Strings for address;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function changeBaseURI(string memory newURI)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = newURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        string memory baseUri = _baseURI();
        return
            bytes(baseUri).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toHexString(
                            uint160(tokenIdToOwner[tokenId]),
                            20
                        )
                    )
                )
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function safeMint(address to)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        latestTokenId += 1;
        _safeMint(to, latestTokenId);
    }

    function batchSafeMint(address[] memory toAddresses)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 _latestTokenId = latestTokenId;
        require(
            toAddresses.length == toAddresses.length,
            "Error: Different Length of Array"
        );
        for (uint256 i = 0; i < toAddresses.length; i++) {
            _latestTokenId += 1;
            _safeMint(toAddresses[i], _latestTokenId);
        }
        latestTokenId = _latestTokenId;
    }

    function addAdmin(address newAdmin) external {
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
    }

    function deleteAdmin(address deletedAdmin) external {
        revokeRole(DEFAULT_ADMIN_ROLE, deletedAdmin);
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal override {
        tokenIdToOwner[tokenId] = to;
        super._safeMint(to, tokenId, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        require(false, "Error: This token is SBT");
    }
}
