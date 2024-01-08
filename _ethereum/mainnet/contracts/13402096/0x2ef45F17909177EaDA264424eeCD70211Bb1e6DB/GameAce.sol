//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./AccessControl.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./IBridgeable.sol";

contract GameAce is
    AccessControlUpgradeable,
    ERC721EnumerableUpgradeable,
    IBridgeable
{
    uint16 base;
    mapping(uint16 => uint256) units;
    mapping(uint16 => string) uri;
    address constant BRIDGE_ADDRESS = address(0xdead);
    bytes32 constant BRIDGE_ROLE = keccak256("BRIDGE");

    function initialize() public initializer {
        __AccessControl_init();
        __ERC721_init("Game Ace", "GA");
        __Ace_init_unchained();
    }

    function __Ace_init_unchained() internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        base = 10000;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return uri[uint16(tokenId % base)];
    }

    function mint(
        address account,
        uint16 game,
        uint16 many
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(game < base, "Max 10000 games");
        uint256 existing = units[game];
        for (uint256 x = 0; x < many; x++) {
            _mint(account, (existing + x + 1) * base + game);
        }
        units[game] = existing + many;
    }

    function burn(address account, uint256 many)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 existing = balanceOf(account);
        if (existing < many) many = existing;
        for (uint256 x = 0; x < many; x++) {
            _burn(tokenOfOwnerByIndex(account, 0));
        }
    }

    function setGameURL(uint16 game, string memory url)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uri[game] = url;
    }

    function tokenOfOwnerByIndexRange(
        address owner,
        uint256 start,
        uint256 length
    ) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory result;
        if (start >= balance) return result;
        if (start + length > balance) length = balance - start;

        result = new uint256[](length);

        for (
            uint256 current = 0;
            current < length && current + start < balance;
            current++
        ) {
            result[current] = (tokenOfOwnerByIndex(owner, start + current));
        }
        return result;
    }

    function grantBridgeRole(address account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(BRIDGE_ROLE, account);
    }

    function revokeBridgeRole(address account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(BRIDGE_ROLE, account);
    }

    function bridgeLeave(
        address owner,
        uint256 tokenId,
        uint32 chainId
    ) external override onlyRole(BRIDGE_ROLE) returns (bytes memory) {
        require(_isApprovedOrOwner(owner, tokenId));
        _transfer(owner, BRIDGE_ADDRESS, tokenId);
        return bytes("");
    }

    function bridgeEnter(
        address owner,
        uint256 tokenId,
        uint32 chainId,
        bytes memory _data
    ) external override onlyRole(BRIDGE_ROLE) {
        bool exists = _exists(tokenId);
        address currentOwner = exists ? ownerOf(tokenId) : address(0);
        require(
            currentOwner == BRIDGE_ADDRESS || currentOwner == address(0),
            "Clone detected!"
        );

        if (exists) {
            _transfer(BRIDGE_ADDRESS, owner, tokenId);
        } else {
            _mint(owner, tokenId);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IBridgeable).interfaceId ||
            AccessControlUpgradeable.supportsInterface(interfaceId) ||
            ERC721EnumerableUpgradeable.supportsInterface(interfaceId);
    }
}
