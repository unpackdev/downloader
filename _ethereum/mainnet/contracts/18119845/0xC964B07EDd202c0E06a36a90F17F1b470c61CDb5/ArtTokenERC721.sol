// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ERC721URIStorageUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./IArtERC721.sol";

contract ArtTokenERC721 is
    IArtERC721,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 public totalSupply;

    // @notice ERC20 ArtToken address. Only this address can call onArtTokenTransfer.
    address private artToken;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol
    ) external initializer {
        __ERC721_init(name, symbol);
        __Ownable_init();
    }

    /** @notice Returns the item id from the owner address by converting it to uint256.
     * @param owner Owner address.
     * @return Item id.
     */
    function _tokenIdFromAddress(address owner) private pure returns (uint256) {
        return uint256(uint160(owner)) << 10;
    }

    /**
     * @dev does not allow tokens transfers of dynamic tokens. Allows minting and burning with no restrictions.
     */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override {
        if (from == address(0) || to == address(0)) {
            return;
        }
        require(firstTokenId < 10 << 2, "ArtTokenERC721: transfer of this tokenId is not allowed");
    }

    /**
     * @notice Generates dynamic NFT every time the ArtToken balance of the owner changes.
     * @param  owner Owner address.
     */
    function _onArtTokenTransfer(address owner, uint256 balance) private {
        uint256 tokenId = _tokenIdFromAddress(owner);
        if (balance == 0 && _exists(tokenId)) {
            totalSupply--;
            _burn(tokenId);
        } else if (balance > 0 && !_exists(tokenId)) {
            totalSupply++;
            _mint(owner, tokenId);
            _setTokenURI(tokenId, tokenURI(1));
        }
    }

    /// @notice Mints a new NFT item. Can be used to store extra images and documents.
    /// Can only be used by an owner and usually called by ArtTokenVault
    /// Cannot be used during the crowdsale or buyout.
    /// @param owner New owner the item.
    /// @param tokenURI New item metadata.
    /// @dev Emits ArtTokenERC721NewItem event with the new item id.
    /// @return New item id: this.balanceOf(owner) == new item id.
    function mintItem(
        address owner,
        string memory tokenURI
    ) public onlyOwner returns (uint256) {
        _tokenIds.increment();
        totalSupply++;

        uint256 newItemId = _tokenIds.current();
        _mint(owner, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    /**
     * @notice Burns an NFT item. Can only be used by an owner and usually called by ArtTokenVault
     * @param  tokenId Item id to burn.
     */
    function burnItem(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "ArtTokenERC721: tokenId does not exist");
        totalSupply--;
        _burn(tokenId);
    }

    /**
     * @notice Sets the ArtToken address. Usually called from ArtTokenVault.
     * @param  erc20 ArtToken address.
     */
    function setArtToken(address erc20) external onlyOwner {
        require(
            erc20 != address(0),
            "ArtTokenERC721: erc20 is the zero address"
        );
        artToken = erc20;
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * @dev    Can only be called by the current owner.
     */
    function transferOwnership(
        address newOwner
    ) public override(IArtERC721, OwnableUpgradeable) onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @notice Generates dynamic NFT every time the ArtToken balance of the owner changes.
     * @dev Can only be called by ArtToken contract.
     * @param  from Owner address.
     * @param  fromBalance ArtToken balance of the original owner after transfer.
     * @param  to New Owner address.
     * @param  toBalance ArtToken balance of the new owner after transfer.
     */
    function onArtTokenTransfer(address from, uint256 fromBalance, address to, uint256 toBalance) public {
        require(msg.sender == artToken, "ArtTokenERC721: not permitted");
        _onArtTokenTransfer(from, fromBalance);
        _onArtTokenTransfer(to, toBalance);
    }
}
