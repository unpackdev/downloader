// SPDX-License-Identifier: WTFPL
pragma solidity ^0.6.0;

abstract contract ILootCitadel {
    /**
     * @dev Call alchemy for ERC20 token.
     * @param to Receiver of rewards
     * @param amount Amount of rewards
     */
    function alchemy(address to, uint256 amount) external virtual;

    /**
     * @dev Call alchemy for ERC1155 token.
     * @param to Receiver of rewards
     * @param id Item ID
     * @param amount Amount of rewards
     */
    function alchemy(
        address to,
        uint256 id,
        uint256 amount
    ) external virtual;

    /**
     * @dev Call alchemy for ERC721 token.
     * @param to Receiver of rewards
     * @param tokenId Token Identification Number
     */
    function alchemy721(address to, uint256 tokenId) external virtual;

    /**
     * @dev Get current expansion balance
     * @param expansion Receiver of rewards
     */
    function expansionBalance(address expansion)
        external
        virtual
        returns (uint256);
}
