// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/**
 * @title ERC721Reviewable
 * @author YUMEMI inc. - akibe & iizumi
 */

import "./ERC721.sol";
import "./IERC721Reviewable.sol";

abstract contract ERC721Reviewable is ERC721, IERC721Reviewable {
    // The next token ID to be minted.
    uint256 private _reviewIndex;

    // array of review ids for each token
    mapping(uint256 => uint256[]) private _reviewsOfToken;

    // array of review ids for collection
    uint256[] private _reviewsOfCollection;

    // array of review ids by token id
    mapping(uint256 => string) private _reviewURIs;

    constructor() {
        _reviewIndex = _startReviewId();
    }

    // =============================================================
    //                   COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the total amount of reviews for token.
     */
    function totalReviewsOfToken(
        uint256 tokenId
    ) public view virtual override returns (uint256) {
        _requireMinted(tokenId);
        return _reviewsOfToken[tokenId].length;
    }

    /**
     * @dev Returns the total amount of reviews for contract.
     */
    function totalReviewsOfContract()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _reviewsOfCollection.length;
    }

    /**
     * @dev Returns the starting review ID.
     * To change the starting review ID, please override this function.
     */
    function _startReviewId() internal pure virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next review ID to be reviewed.
     */
    function _nextReviewId() internal view virtual returns (uint256) {
        return _reviewIndex;
    }

    // =============================================================
    //                   DATA OPERATIONS
    // =============================================================

    /**
     * @dev post review for token
     */
    function postReviewOfToken(
        uint256 tokenId,
        string memory uri
    ) public virtual override returns (uint256) {
        _requireMinted(tokenId);
        require(bytes(uri).length > 0, "ERC721Reviewable: require URL");

        uint256 index = _reviewIndex;
        _reviewsOfToken[tokenId].push(index);
        _setReviewURI(index, uri);
        _reviewIndex += 1;

        emit ReviewToken(_msgSender(), index, tokenId);

        return index;
    }

    /**
     * @dev get review for token
     */
    function reviewOfTokenByIndex(
        uint256 tokenId,
        uint256 index
    ) public view virtual override returns (uint256) {
        _requireMinted(tokenId);
        require(
            _reviewsOfToken[tokenId].length > index,
            "ERC721Reviewable: token review index out of bounds"
        );
        return _reviewsOfToken[tokenId][index];
    }

    /**
     * @dev post review for contract
     */
    function postReviewOfContract(
        string calldata uri
    ) public virtual override returns (uint256) {
        require(bytes(uri).length > 0, "ERC721Reviewable: require URL");

        uint256 index = _reviewIndex;
        _reviewsOfCollection.push(index);
        _setReviewURI(index, uri);
        _reviewIndex += 1;

        emit ReviewContract(_msgSender(), index);

        return index;
    }

    /**
     * @dev get review for contract
     */
    function reviewOfContractByIndex(
        uint256 index
    ) public view virtual override returns (uint256) {
        require(
            _reviewsOfCollection.length > index,
            "ERC721Reviewable: contract review index out of bounds"
        );
        return _reviewsOfCollection[index];
    }

    /**
     * @dev Get reviewURI from reviewId
     */
    function reviewURI(
        uint256 reviewId
    ) public view virtual override returns (string memory) {
        // Review URI
        string memory uri = _reviewURIs[reviewId];
        require(bytes(uri).length > 0, "Not Exist ReviewURI");

        // Base Review URI
        string memory base = _baseReviewURI();
        if (bytes(base).length == 0) {
            return uri;
        }

        // If both are set, concatenate the baseURI and tokenURI
        return string(abi.encodePacked(base, uri));
    }

    /**
     * @dev Get baseReviewURI. Empty by default, can be overridden in child contracts.
     */
    function _baseReviewURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev sets `_reviewURI` as the reviewURI of `reviewId`.
     */
    function _setReviewURI(
        uint256 reviewId,
        string memory uri
    ) internal virtual {
        _reviewURIs[reviewId] = uri;
    }

    // =============================================================
    //                   INTERFACE
    // =============================================================

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC721) returns (bool) {
        return
            interfaceId == type(IERC721Reviewable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
