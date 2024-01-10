//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;

import "./ERC721Base.sol";
import "./IERC721Enumerable.sol";

import "./console.sol";

contract Photograph is ERC721Base {

    IERC721[] public referenceNFTs;
    mapping(IERC721 => mapping(uint256 => bool)) public redeemed;

    struct TokenSet {
        IERC721 nft;
        uint256[] tokenIds;
    }

    constructor(
        string memory baseTokenURI
    ) ERC721Base("Macro Slide", "MS", baseTokenURI, 666) {
    }

    /**
    Return unredeemed tokens of sender for reference NFTs.
    @dev if a reference NFT is not enumerable, tokens ids can be inspected/redeemed manually.
     */
    function allRedeemableSets() public view returns (TokenSet[] memory allRedeemable) {
        uint256 length = referenceNFTs.length;
        allRedeemable = new TokenSet[](length);
        for (uint256 i=0; i<length; i++) {
            try this.redeemableSet(
                msg.sender,
                referenceNFTs[i]
            ) returns (
                TokenSet memory redeemable
            ) {
                allRedeemable[i] = redeemable;
            }
            catch {
                allRedeemable[i].nft = referenceNFTs[i];
                // skip referenceNFTs that can't be read, not revert.
                // These would have to be redeemed with explicit token ids
            }
        }
    }

    /**
    Return unredeemed tokens of given owner for a reference NFT.
    @dev will fail
     */
    function redeemableSet(
        address nftOwner,
        IERC721 nft
    ) public view onlyReferenceNFT(nft) returns (
        TokenSet memory redeemable
    ) {
        uint256 tokensOwned = nft.balanceOf(nftOwner);
        redeemable.nft = nft;
        if (nft.supportsInterface(type(IERC721Enumerable).interfaceId)) {
            IERC721Enumerable enumerableNFT = IERC721Enumerable(address(nft));
            uint256 nextRedeemableIndex = 0;
            // cache redeemable token ids in full-length array
            uint256[] memory redeemableTokensFullLength = new uint256[](tokensOwned);
            for (uint256 i=0; i<tokensOwned; i++) {
                uint256 tokenId = enumerableNFT.tokenOfOwnerByIndex(nftOwner, i);
                if (!redeemed[nft][tokenId]) {
                    redeemableTokensFullLength[nextRedeemableIndex] = tokenId;
                    nextRedeemableIndex++;
                }
            }
            uint256 redeemableLength = nextRedeemableIndex;
            // copy only redeemable token ids to correct size array in result
            redeemable.tokenIds = new uint256[](redeemableLength);
            for (uint256 i=0; i<redeemableLength; i++) {
                redeemable.tokenIds[i] = redeemableTokensFullLength[i];
            }
        }
    }


    function redeemAll() public {
        TokenSet[] memory redeemableSets = allRedeemableSets();
        for (uint256 i=0; i<redeemableSets.length; i++) {
            redeemTokenSet(redeemableSets[i]);
        }
    }

    function redeemTokenSet(TokenSet memory tokenSet) public {
        redeemNFTIds(tokenSet.nft, tokenSet.tokenIds);
    }

    function redeemNFTIds(IERC721 nft, uint256[] memory tokenIds) public onlyReferenceNFT(nft) {
        uint256 tokenId;
        for (uint256 i=0; i<tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (msg.sender == nft.ownerOf(tokenId)
                && (!redeemed[nft][tokenId])
            ) {
                redeemed[nft][tokenId] = true;
                _mint(msg.sender);
            } 
        }
    }

    /**
    @dev Add an NFT contract that this contract will check for redeem rights.
    Owners of these added NFT contracts can redeem a Photograph per token.
     */
    function addReferenceNFT(IERC721 referenceNFT) public onlyOwner {
        require(address(referenceNFT) != address(this), "Photograph: must not reference self");
        referenceNFTs.push(referenceNFT);
    }

    modifier onlyReferenceNFT(IERC721 nft) {
        uint256 i;
        for (i=0; i<referenceNFTs.length; i++) {
            if (nft == referenceNFTs[i]) {
                break;
            }
        }
        _;
    }

}
