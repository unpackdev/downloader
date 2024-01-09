// contracts/GameflipItems.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721Upgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract CollectibleTokenUpgradeable is OwnableUpgradeable, AccessControlEnumerableUpgradeable, ERC721Upgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private _baseUri;
    string private _contractUri;

    function initialize(string memory baseUri, string memory contractUri) initializer public {
        __Ownable_init();
        __AccessControlEnumerable_init();
        __ERC721_init("Gameflip", "GFP");

        _baseUri = baseUri;
        _contractUri = contractUri;

        // Make the contract owner the role admin
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        // Mint token 0 for testing deployment
        _safeMint(_msgSender(), 0, '');
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        super.transferOwnership(newOwner);

        // Make the new contract owner the role admin
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, AccessControlEnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseUri) public onlyOwner {
        _baseUri = baseUri;
    }

    // See https://docs.opensea.io/docs/contract-level-metadata
    function setContractURI(string memory contractUri) public onlyOwner {
        _contractUri = contractUri;
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function mint(address to, uint256 id, bytes memory data) public onlyRole(MINTER_ROLE) {
        _safeMint(to, id, data);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    function toUuid(uint256 n) public pure returns (string memory) {
        bytes32 value = bytes32(n);
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(36);
        uint p = 0;
        for (uint i = 0; i < 16; i++) {
            bytes1 b = value[i + 16];
            str[p++] = alphabet[uint8(b >> 4)];
            str[p++] = alphabet[uint8(b & 0x0f)];

            if (i == 3 || i == 5 || i == 7 || i == 9) {
                str[p++] = '-';
            }
        }
        return string(str);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        string memory uuid = toUuid(tokenId);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, uuid)) : "";
    }
}
