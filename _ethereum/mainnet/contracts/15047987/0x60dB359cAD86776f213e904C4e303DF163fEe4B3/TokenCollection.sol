// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SafeMathUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./BaseCollection.sol";
import "./Redeemables.sol";

contract TokenCollection is
    Redeemables,
    BaseCollection,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721BurnableUpgradeable
{
    using SafeMathUpgradeable for uint256;

    function initialize(
        string memory name_,
        string memory symbol_,
        address treasury_,
        address royalty_,
        uint96 royaltyFee_
    ) public override initializer {
        __ERC721_init(name_, symbol_);
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ERC721Burnable_init();

        __BaseCollection_init(treasury_, royalty_, royaltyFee_);
    }

    function mint(
        address to,
        uint256 quantity,
        string memory uri
    ) external onlyOwner {
        _mint(to, quantity, uri);
    }

    function createRedeemable(
        string memory uri,
        uint256 price,
        uint256 maxQuantity,
        uint256 maxPerWallet,
        uint256 maxPerMint
    ) external onlyOwner {
        _createRedeemable(uri, price, maxQuantity, maxPerWallet, maxPerMint);
    }

    function setMerkleRoot(uint256 redeemableId, bytes32 newRoot)
        external
        onlyOwner
    {
        _setMerkleRoot(redeemableId, newRoot);
    }

    function invalidate(uint256 redeemableId) external onlyOwner {
        _invalidate(redeemableId);
    }

    function revoke(uint256 redeemableId) external onlyOwner {
        _revoke(redeemableId);
    }

    function redeem(
        uint256 redeemableId,
        uint256 quantity,
        bytes calldata signature
    ) external payable {
        Redeemable memory redeemable = redeemableAt(redeemableId);

        unchecked {
            _totalRevenue = _totalRevenue.add(msg.value);
        }
        _niftyKit.addFees(msg.value);
        _mint(_msgSender(), quantity, redeemable.tokenURI);
        _redeem(redeemableId, quantity, signature, owner());
    }

    function redeem(
        uint256 redeemableId,
        uint256 quantity,
        bytes calldata signature,
        bytes32[] calldata proof
    ) external payable {
        Redeemable memory redeemable = redeemableAt(redeemableId);

        unchecked {
            _totalRevenue = _totalRevenue.add(msg.value);
        }
        _niftyKit.addFees(msg.value);
        _mint(_msgSender(), quantity, redeemable.tokenURI);
        _redeem(redeemableId, quantity, signature, owner(), proof);
    }

    function _mint(
        address to,
        uint256 quantity,
        string memory uri
    ) internal {
        for (uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply().add(1);
            _safeMint(to, mintIndex);
            _setTokenURI(mintIndex, uri);
        }
    }

    // The following functions are overrides required by Solidity.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        ERC721URIStorageUpgradeable._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, BaseCollection)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
