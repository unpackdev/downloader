// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.13;

import "./ILazyMint.sol";

//@title ITransferProxy is used for communicating with ERC721, ERC1155, tokens(WETH, WBNB, WMATIC,...).
//@notice the interface used for transferring NFTs from sender wallet address to receiver wallet address.
//@notice andalso transfers the assetFee, royaltyFee, platform fee from users.

interface ITransferProxy {

    //@notice the function transfers ERC721 NFTs to users.
    //@param token, ERC721 address @dev see {IERC721}.
    //@param from, seller address, NFTs to be transferrred from this address.
    //@param to, buyer address, NFTs to be received to this address.
    //@param tokenId, unique NFT id to be transfer.

    function erc721safeTransferFrom(
        IERC721 token,
        address from,
        address to,
        uint256 tokenId
    ) external;

    //@notice the function transfers ERC721 NFTs to users.
    //@param token, ERC1155 @dev see {IERC1155}.
    //@param from, seller address, NFTs to be transferrred from this address.
    //@param to, buyer address, NFTs to be received to this address.
    //@param tokenId, unique NFT id to be transfer.

    function erc1155safeTransferFrom(
        IERC1155 token,
        address from,
        address to,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external;

    //@notice function used for ERC1155Lazymint, it does NFT minting and NFT transfer.
    //@param nftAddress, ERC1155 @dev see {IERC1155}.
    //@param from, NFT to be minted on this address.
    //@param to, NFT to be transffered 'from' address to this address.
    //@param _tokenURI, IPFS URI of NFT to be Minted.
    //@param _royaltyFee, fee permiles for secondary sale.
    //@param _receivers, fee receivers for secondary sale.
    //@param supply, copies to minted to creator 'from' address.
    //@param qty, copies to be transfer to receiver 'to' address.
    //@return _tokenId, NFT unique id.
    //@dev see {ERC1155}.
    
    function mintAndSafe1155Transfer(
        ILazyMint nftAddress,
        address from,
        address to,
        string memory _tokenURI,
        uint96[] calldata _royaltyFee,
        address[] calldata _receivers,
        uint256 supply,
        uint256 qty
    ) external ;

    //@notice function used for ERC721Lazymint, it does NFT minting and NFT transfer.
    //@param nftAddress, ERC721 address @dev see {IERC721}.
    //@param from, NFT to be minted on this address.
    //@param to, NFT to be transffered from address to this address.
    //@param _tokenURI, IPFS URI of NFT to be Minted.
    //@param _royaltyFee, fee permiles for secondary sale.
    //@param _receivers, fee receivers for secondary sale.
    //@return _tokenId, NFT unique id.
    //@dev see {ERC721}.

    function mintAndSafe721Transfer(
        ILazyMint nftAddress,
        address from,
        address to,
        string memory _tokenURI,
        uint96[] calldata _royaltyFee,
        address[] calldata _receivers    
    ) external;

    //@notice the, function used for transferring token from 'from' address to 'to' address.
    //@param token, ERC20 address(WETH, WBNB, WMATIC) @dev see {IERC20}.
    //@param from, NFT to be minted on this address.
    //@param to, NFT to be transffered 'from' address to this address.
    //@param value, amount of tokens to transfer(Royalty, assetFee, platformFee...).

    function erc20safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) external;
}