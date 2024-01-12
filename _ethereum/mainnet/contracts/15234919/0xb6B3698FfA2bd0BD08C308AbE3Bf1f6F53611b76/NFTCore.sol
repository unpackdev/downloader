// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Counters.sol";

/**
 *  Derived from Openzeppelin's ERC721PresetMinterPauserAutoId contract.
 *  The primary differeence is that the mint function returns the token ID
 *  that was minted to the calling contract and no Pauser support.
 *
 *  The account that deploys the contract gets the default admin role, which
 *  which enables to grant minter roles to other accounts.
 */
contract NFTCore is
    Context,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable,
    Ownable
{
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;

    /**
     * Grants `DEFAULT_ADMIN_ROLE` to the account that deploys the contract and
     * and initializes the counter to have tokenID start from 1.
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _baseTokenURI = baseTokenURI;
        //start at 1
        _tokenIdTracker.increment();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * Creates a new token for the 'to' address. Auto incremennts the token counter
     * and returns the token ID of the minted NFT
     */
    function mint(address to) public virtual returns (uint256 tokenId) {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Must have minter role to mint"
        );
        tokenId = _tokenIdTracker.current();
        _mint(to, tokenId);
        _tokenIdTracker.increment();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
