// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./AccessControlEnumerable.sol";

import "./NFTMintable.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract NFT is
    Ownable,
    AccessControlEnumerable,
    ERC721URIStorage,
    NFTMintable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private internalBaseURI;

    address public proxyRegistryAddress;

    uint256 public nextTokenId = 0;

    uint256 public burned = 0;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address _proxyRegistryAddress
    ) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        internalBaseURI = baseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function totalSupply() external view returns (uint256) {
        return nextTokenId - burned;
    }

    function mintTo(address to, uint16 amount) external override {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC721: must have minter role to mint"
        );
        _mintMulti(to, amount);
    }

    function giveaway(address to, uint16 amount) external onlyOwner {
        _mintMulti(to, amount);
    }

    function burn(uint256 tokenId) external virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    // ContextMixin
    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory newBaseUri) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERC721: must have admin role to change baseUri"
        );
        internalBaseURI = newBaseUri;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address _owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(_owner, operator);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERC721: must have admin role to set Token URIs"
        );
        super._setTokenURI(tokenId, _tokenURI);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        burned += 1;
    }

    function _mintMulti(address to, uint16 amount) internal virtual {
        for (uint16 i = 0; i < amount; i++) {
            _safeMint(to, nextTokenId);
            nextTokenId += 1;
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return internalBaseURI;
    }
}
