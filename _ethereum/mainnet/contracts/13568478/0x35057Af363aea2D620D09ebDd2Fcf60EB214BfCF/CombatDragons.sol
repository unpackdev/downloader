//SPDX-License-Identifier: MIT

pragma solidity 0.7.3;

import "./AccessControl.sol";
import "./Context.sol";
import "./Counters.sol";
import "./ERC721.sol";
import "./ERC721Burnable.sol";

contract CombatDragons is Context, AccessControl, ERC721Burnable {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_SUPPLY = 10000;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());

        _setBaseURI(baseURI);
    }

    function mint(address to) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "CombatDragons: must have minter role to mint"
        );

        require(
            totalSupply() <= MAX_SUPPLY,
            "CombatDragons: max supply reached"
        );

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _mint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "CombatDragons: must have admin role"
        );
        super._setTokenURI(tokenId, _tokenURI);
    }

    function setBaseURI(string memory baseURI_) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "CombatDragons: must have admin role"
        );
        super._setBaseURI(baseURI_);
    }
}
