// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * Early implementation of EIP-2981 as of comment
 * https://github.com/ethereum/EIPs/issues/2907#issuecomment-831352868
 *
 * Interface ID:
 *
 * bytes4(keccak256('royaltyInfo(uint256,uint256,bytes)')) == 0xc155531d
 *
 * =>  0xc155531d
 */
interface IERC2981Royalties is IERC165Upgradeable {
    /**
     * @dev Returns an NFTs royalty payment information
     *
     * @param tokenId  The identifier for an NFT
     * @param value Purchase price of NFT
     * @param data Additional data for royalty info. Not to be used as part of EIP-2981.
     *
     * @return receiver The royalty recipient address
     * @return royaltyAmount Amount to be paid to the royalty recipient
     * @return royaltyPaymentData Additional data for royalty info. Not to be used as part of EIP-2981.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    )
        external
        view
        returns (
            address receiver,
            uint256 royaltyAmount,
            bytes memory royaltyPaymentData
        );
}
