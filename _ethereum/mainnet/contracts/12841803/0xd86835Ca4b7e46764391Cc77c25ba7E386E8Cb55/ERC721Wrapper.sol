// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author jpegmint.xyz

import "./IERC721Wrapper.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";

/**
 * @title ERC721 token wrapping base.
 */
 abstract contract ERC721Wrapper is ERC721, IERC721Wrapper, ReentrancyGuard {

    struct TokenIdRange {
        uint256 minTokenId;
        uint256 maxTokenId;
    }

    mapping(address => TokenIdRange) private _approvedTokenRanges;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Wrapper).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Transfers contract/tokenId into contract and issues wrapping token.
     */
    function wrap(address contract_, uint256 tokenId) external virtual override nonReentrant {
        require(IERC721(contract_).ownerOf(tokenId) == msg.sender, 'ERC721Wrapper: Caller must own NFT.');
        require(IERC721(contract_).getApproved(tokenId) == address(this), 'ERC721Wrapper: Contract must be given approval to wrap NFT.');
        require(isWrappable(contract_, tokenId), 'ERC721Wrapper: TokenId not within approved range.');

		IERC721(contract_).transferFrom(msg.sender, address(this), tokenId);
        _wrap(msg.sender, tokenId);
	}

    /**
     * @dev Burns wrapped token and transfer original back to sender.
     */
	function unwrap(address contract_, uint256 tokenId) external virtual override nonReentrant {
		require(msg.sender == ownerOf(tokenId), "ERC721Wrapper: Caller does not own wrapped token.");
		_burn(tokenId);
		IERC721(contract_).safeTransferFrom(address(this), msg.sender, tokenId);
        emit Unwrapped(msg.sender, tokenId);
	}

    /**
     * @dev Receives token and mints wrapped token back to sender.
     */
	function onERC721Received(address, address from, uint256 tokenId, bytes calldata) 
        external
        virtual
        override
        nonReentrant
        returns (bytes4)
    {
        require(isWrappable(msg.sender, tokenId), 'ERC721Wrapper: TokenId not within approved range.');

        _wrap(from, tokenId);
		return this.onERC721Received.selector;
	}

    /**
     * @dev Mints wrapped token.
     */
    function _wrap(address to, uint256 tokenId) internal virtual {
		_mint(to, tokenId);
        emit Wrapped(to, tokenId);
    }

    /**
     * @dev Returns whether the specified tokenId is approved to wrap.
     */
    function isWrappable(address contract_, uint256 tokenId) public view virtual override returns (bool) {
        return (
            _approvedTokenRanges[contract_].maxTokenId != 0 &&
            tokenId >= _approvedTokenRanges[contract_].minTokenId &&
            tokenId <= _approvedTokenRanges[contract_].maxTokenId
        );
    }

    /**
     * @dev See {IERC721Wrapper-updateApprovedTokenRanges}.
     */
    function updateApprovedTokenRanges(address contract_, uint256 minTokenId, uint256 maxTokenId) public virtual override;

    /**
     * @dev Updates approved contract/token ranges. Simple access control mechanism.
     */
    function _updateApprovedTokenRanges(address contract_, uint256 minTokenId, uint256 maxTokenId) internal virtual {
        require(minTokenId <= maxTokenId, 'ERC721Wrapper: Min tokenId must be less-than/equal to max.');

        if (_approvedTokenRanges[contract_].maxTokenId == 0) {
            _approvedTokenRanges[contract_] = TokenIdRange(minTokenId, maxTokenId);
        } else {
            _approvedTokenRanges[contract_].minTokenId = minTokenId;
            _approvedTokenRanges[contract_].maxTokenId = maxTokenId;
        }
    }
}
