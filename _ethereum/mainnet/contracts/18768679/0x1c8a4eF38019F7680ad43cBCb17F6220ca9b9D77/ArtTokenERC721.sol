// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ERC721URIStorageUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./IERC20.sol";
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
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721Upgradeable, IERC721Upgradeable) {
        require(
            tokenId < 1 << 10,
            "ArtTokenERC721: transfer of this tokenId is not allowed"
        );
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721Upgradeable, IERC721Upgradeable) {
        require(
            tokenId < 1 << 10,
            "ArtTokenERC721: transfer of this tokenId is not allowed"
        );
        super._safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(
        uint256 tokenId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, IERC721Upgradeable)
        returns (address)
    {
        if (tokenId < 1 << 10) {
            return super.ownerOf(tokenId);
        }
        return address(uint160(tokenId >> 10));
    }

    function balanceOf(
        address owner
    )
        public
        view
        override(ERC721Upgradeable, IERC721Upgradeable)
        returns (uint256)
    {
        require(
            owner != address(0),
            "ArtTokenERC721: address zero is not a valid owner"
        );
        if (artToken != address(0) && IERC20(artToken).balanceOf(owner) > 0) {
            return 1;
        }
        return super.balanceOf(owner);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        //        return super.tokenURI(tokenId);
        if (tokenId < 1 << 10) {
            return super.tokenURI(tokenId);
        }
        return super.tokenURI(1);
    }

    /// @notice Mints a new NFT item. Can be used to store extra images and documents.
    /// Can only be used by an owner and usually called by ArtTokenVault
    /// Cannot be used during the crowdsale or buyout.
    /// @param owner New owner the item.
    /// @param newTokenURI New item metadata.
    /// @dev Emits ArtTokenERC721NewItem event with the new item id.
    /// @return New item id: this.balanceOf(owner) == new item id.
    function mintItem(
        address owner,
        string memory newTokenURI
    ) public onlyOwner returns (uint256) {
        _tokenIds.increment();
        totalSupply++;

        uint256 newItemId = _tokenIds.current();
        _mint(owner, newItemId);
        _setTokenURI(newItemId, newTokenURI);

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
     * @param  fromBalanceBefore ArtToken balance of the original owner before transfer.
     * @param  to New Owner address.
     * @param  toBalanceBefore ArtToken balance of the new owner before transfer.
     * @param  amount ArtToken amount transferred.
     */
    function onArtTokenTransfer(
        address from,
        uint256 fromBalanceBefore,
        address to,
        uint256 toBalanceBefore,
        uint256 amount
    ) public {
        require(msg.sender == artToken, "ArtTokenERC721: not permitted");

        if (toBalanceBefore == 0) {
            totalSupply++;
            emit Transfer(address(0), to, _tokenIdFromAddress(to));
        }
        if (fromBalanceBefore == amount) {
            totalSupply--;
            emit Transfer(from, address(0), _tokenIdFromAddress(from));
        }
    }
}
