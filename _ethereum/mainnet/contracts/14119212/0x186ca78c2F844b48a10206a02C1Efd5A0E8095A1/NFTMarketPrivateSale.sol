// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "./IERC721Upgradeable.sol";

import "./NFTMarketFees.sol";

/**
 * @notice Adds support for a private sale of an NFT directly between two parties.
 */
abstract contract NFTMarketPrivateSale is NFTMarketFees {
    /**
     * @dev This name is used in the EIP-712 domain.
   * If multiple classes use EIP-712 signatures in the future this can move to the shared constants file.
   */
    string private constant NAME = "CRNFTMarket";
    /**
     * @dev This is a hash of the method signature used in the EIP-712 signature for private sales.
   */
    bytes32 private constant BUY_FROM_PRIVATE_SALE_TYPEHASH =
    keccak256("BuyFromPrivateSale(address nftContract,uint256 tokenId,address buyer,uint256 price,uint256 deadline)");

    /**
     * @dev This is the domain used in EIP-712 signatures.
   * It is not a constant so that the chainId can be determined dynamically.
   * If multiple classes use EIP-712 signatures in the future this can move to a shared file.
   */
    bytes32 private DOMAIN_SEPARATOR;

    event PrivateSaleFinalized(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 f8nFee,
        uint256 creatorFee,
        uint256 ownerRev,
        uint256 deadline
    );

    /**
     * @dev This function must be called at least once before signatures will work as expected.
   * It's okay to call this function many times. Subsequent calls will have no impact.
   */
    function _reinitialize() internal {
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(NAME)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    /**
     * @notice Allow two parties to execute a private sale.
   * @dev The seller signs a message approving the sale, and then the buyer calls this function
   * with the msg.value equal to the agreed upon price.
   * The sale is executed in this single on-chain call including the transfer of funds and the NFT.
   */
    function buyFromPrivateSale(
        IERC721Upgradeable nftContract,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        // The signed message from the seller is only valid for a limited time.
        require(deadline >= block.timestamp, "NFTMarketPrivateSale: EXPIRED");
        // The seller must have the NFT in their wallet when this function is called.
        address payable seller = payable(nftContract.ownerOf(tokenId));

        // Scoping this block to avoid a stack too deep error
        {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(abi.encode(BUY_FROM_PRIVATE_SALE_TYPEHASH, nftContract, tokenId, msg.sender, msg.value, deadline))
                )
            );
            // Revert if the signature is invalid, the terms are not as expected, or if the seller transferred the NFT.
            require(ecrecover(digest, v, r, s) == seller, "NFTMarketPrivateSale: INVALID_SIGNATURE");
        }

        // This will revert if the seller has not given the market contract approval.
        nftContract.transferFrom(seller, msg.sender, tokenId);
        // Pay the seller, creator, and Foundation as appropriate.
        (uint256 f8nFee, uint256 creatorFee, uint256 ownerRev) = _distributeFunds(
            address(nftContract),
            tokenId,
            seller,
            msg.value
        );

        emit PrivateSaleFinalized(
            address(nftContract),
            tokenId,
            seller,
            msg.sender,
            f8nFee,
            creatorFee,
            ownerRev,
            deadline
        );
    }

    uint256[1000] private ______gap;
}