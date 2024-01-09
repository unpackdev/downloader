// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Parsable.sol";

/**
 * @title ERC721 Redeemable Token
 * @dev ERC721 Token that can be redeemable.
 */
abstract contract ERC721Redeemable is ERC721 {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Parsable for string;

    event Create(uint256 indexed prefix, uint256 redemptionsAllowed);
    event Redeem(
        address indexed from,
        uint256 indexed tokenId,
        uint256 redemptions
    );

    struct Redeemable {
        uint256 allowedRedemptions;
        uint256 expiresAt;
        string uri;
        Counters.Counter tokenIdCounter;
    }

    uint256 private constant ID_LENGTH = 5;
    mapping(uint256 => Redeemable) private _redeemables;
    mapping(uint256 => uint256) private _redemptions;

    function redeem(uint256 tokenId, uint256 amount) public virtual {
        _redeem(_msgSender(), tokenId, amount);
    }

    function redeemFrom(
        address from,
        uint256 tokenId,
        uint256 amount
    ) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "redeem caller is not owner nor approved"
        );
        _redeem(from, tokenId, amount);
    }

    function remaining(uint256 tokenId) public view virtual returns (uint256) {
        uint256 redeemableId = redeemableIdForTokenId(tokenId);
        uint256 redeemed = _redemptions[tokenId];
        return _redeemables[redeemableId].allowedRedemptions - redeemed;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "token doesn't exist");

        uint256 redeemableId = redeemableIdForTokenId(tokenId);
        return _redeemables[redeemableId].uri;
    }

    function _create(
        uint256 id,
        uint256 allowedRedemptions,
        uint256 expiresAt,
        string memory uri
    ) internal virtual {
        require(_redeemables[id].allowedRedemptions == 0, "Redeemable exists");

        Redeemable memory r;
        r.allowedRedemptions = allowedRedemptions;
        r.expiresAt = expiresAt;
        r.uri = uri;
        _redeemables[id] = r;

        emit Create(id, allowedRedemptions);
    }

    function _setBaseURI(uint256 redeemable, string memory uri)
        internal
        virtual
    {
        Redeemable storage r = _redeemables[redeemable];
        r.uri = uri;
    }

    function _mint(uint256 redeemable, address to) internal virtual {
        Redeemable storage r = _redeemables[redeemable];
        r.tokenIdCounter.increment();
        uint256 currentId = r.tokenIdCounter.current();

        string memory tokenId = string(
            abi.encodePacked(redeemable.toString(), currentId.toString())
        );

        _safeMint(to, tokenId.safeParseInt());
    }

    function _redeem(
        address from,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: redeem of token that is not own"
        );

        uint256 redeemableId = redeemableIdForTokenId(tokenId);

        require(
            _redeemables[redeemableId].expiresAt > block.timestamp,
            "redepmtions expired"
        );

        require(
            _redemptions[tokenId] + amount <=
                _redeemables[redeemableId].allowedRedemptions,
            "amount is more than remaining"
        );

        _redemptions[tokenId] += amount;

        emit Redeem(from, tokenId, amount);
    }

    function redeemableIdForTokenId(uint256 tokenId)
        internal
        view
        virtual
        returns (uint256)
    {
        return tokenId.toString().substring(0, ID_LENGTH).safeParseInt();
    }
}
