// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC2981PerToken.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */

contract RingoStarr is ERC721URIStorage, Ownable, ERC2981PerTokenRoyalties {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint private availableNFTs = 0;
 
    constructor() ERC721("Ringo Starr", "BTL") {}

    /**
       * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of _mint method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */


    function safeMint(address to, string memory uri, address royaltyRecipient, uint256 royaltyValue) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _exists(tokenId);
        _tokenIdCounter.increment();
        require(tokenId < 20);
        _safeMint(to, tokenId);

        if (royaltyValue > 0) {
            _setTokenRoyalty(tokenId, royaltyRecipient, royaltyValue);
        }

        _setTokenURI(tokenId, uri);
    }
    /**
    * @dev Mints batch of n number of NFTs to specified address
    */
    function mintToAddressBatch(address to, string[] memory uri, address royaltyRecipient, uint256 royaltyValue) external onlyOwner {
        for (uint i=0; i < uri.length; i++) {
            safeMint(to, uri[i],royaltyRecipient, royaltyValue);
        }
    }


    string _contractURI = "ipfs://bafyreieptfh72555fuoh2nxmbsq7bd77g4nbt3624rnxowhwppp6gs6na4/metadata.json";
    function contractURI() public view returns (string memory) {
    return _contractURI;
}
    /**
    * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721: transfer caller is not owner nor approved'
        );
        _transfer(from, to, tokenId);
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC2981Base)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}
