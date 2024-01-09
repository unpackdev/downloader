// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ENSReverseRegistration.sol";
import "./BitMaps.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./MulticallUpgradeable.sol";
import "./ERC721DeckUpgradeable.sol";
import "./ERC721IPFSUpgradeable.sol";
import "./Whitelisted.sol";

contract Toucans is
    OwnableUpgradeable,
    ERC721PausableUpgradeable,
    ERC721DeckUpgradeable,
    ERC721IPFSUpgradeable,
    MulticallUpgradeable,
    Whitelisted
{
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private __claimedBitMap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer
    {}

    function initialize(
        string memory __name,
        string memory __symbol,
        string memory __ipfsHash,
        bytes32       __merkleRoot,
        uint256       __merkleLength
    )
    public
        initializer()
    {
        __Ownable_init();
        __ERC721_init(__name, __symbol);
        __ERC721Pausable_init();
        __ERC721Deck_init(__merkleLength);
        __ERC721IPFS_init(__ipfsHash);

        _setWhitelist(__merkleRoot);
    }

    /**
    * Lazy-minting
    */
    function isClaimed(uint256 index)
    external view returns (bool)
    {
        return __claimedBitMap.get(index);
    }

    function claim(uint256 index, address account, bytes32[] calldata proof)
    external virtual
        onlyWhitelisted(keccak256(abi.encodePacked(index, account)), proof)
    {
        require(!__claimedBitMap.get(index), "token already claimed");
        __claimedBitMap.set(index);

        _mint(account);
    }

    /**
    * Admin operations: ens reverse registration and pausing
    */
    function setName(address ensRegistry, string calldata ensName)
    external
        onlyOwner()
    {
        ENSReverseRegistration.setName(ensRegistry, ensName);
    }

    function pause()
    external
        onlyOwner()
    {
        _pause();
    }

    function unpause()
    external
        onlyOwner()
    {
        _unpause();
    }

    /**
     * Overrides
     */
    function _baseURI() internal view virtual override(ERC721Upgradeable, ERC721IPFSUpgradeable) returns (string memory)
    {
        return super._baseURI();
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721DeckUpgradeable) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
