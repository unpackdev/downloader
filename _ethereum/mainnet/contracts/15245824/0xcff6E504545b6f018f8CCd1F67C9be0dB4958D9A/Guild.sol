// SPDX-License-Identifier: MIT

/// @title RaidParty Guild ERC721 Contract

/**
 *   ___      _    _ ___          _
 *  | _ \__ _(_)__| | _ \__ _ _ _| |_ _  _
 *  |   / _` | / _` |  _/ _` | '_|  _| || |
 *  |_|_\__,_|_\__,_|_| \__,_|_|  \__|\_, |
 *                                    |__/
 */

pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";
import "./IGuild.sol";
import "./IGuildURIHandler.sol";
import "./ERC721Enumerable.sol";
import "./ERC721.sol";

contract Guild is IGuild, ERC721, ERC721Enumerable, AccessControlEnumerable {
    event HandlerUpdated(address indexed caller, address indexed handler);

    // Contract state and constants
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private _tokenIdCounter = 1;

    IGuildURIHandler private _handler;

    constructor(address admin) ERC721("Guild", "GUILD") {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MINTER_ROLE, admin);
    }

    /** PUBLIC */

    function mint(address to) external onlyRole(MINTER_ROLE) {
        unchecked {
            uint256 tokenIdCounter = _tokenIdCounter;
            _tokenIdCounter += 1;
            _mint(to, tokenIdCounter);
        }
    }

    function setHandler(IGuildURIHandler handler)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _handler = handler;
        emit HandlerUpdated(msg.sender, address(handler));
    }

    function getHandler() external view returns (address) {
        return address(_handler);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC721, AccessControlEnumerable, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply()
        public
        view
        override(IGuild, ERC721Enumerable)
        returns (uint256)
    {
        unchecked {
            return _tokenIdCounter - 1;
        }
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        override
        returns (uint256)
    {
        require(
            index < totalSupply(),
            "Guild::tokenByIndex: global index out of bounds"
        );
        return index;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256)
    {
        unchecked {
            require(
                index < balanceOf(owner),
                "Guild::tokenOfOwnerByIndex: owner index out of bounds"
            );
            uint256 iterations;

            for (uint256 i = 1; i <= _tokenIdCounter; i++) {
                if (_getOwner(i) == owner) {
                    if (iterations == index) {
                        return i;
                    }

                    iterations += 1;
                }
            }

            revert(
                "Guild::tokenOfOwnerByIndex: unable to get token of owner by index"
            );
        }
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256 balance = balanceOf(owner);
            uint256[] memory tokens = new uint256[](balance);
            uint256 idx;

            for (uint256 i = 1; i <= _tokenIdCounter; i++) {
                if (_getOwner(i) == owner) {
                    tokens[idx] = i;
                    idx += 1;

                    if (idx == balance) {
                        return tokens;
                    }
                }
            }

            revert("Guild::tokenOfOwnerByIndex: unable to get tokens of owner");
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "Guild::tokenURI: URI query for nonexistent token"
        );

        return _handler.tokenURI(tokenId);
    }

    /** INTERNAL */

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
