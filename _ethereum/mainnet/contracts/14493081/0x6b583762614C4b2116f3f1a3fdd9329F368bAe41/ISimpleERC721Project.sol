// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface ISimpleERC721Project {
    /**
     * @dev mint a token. Can only be called by a registered manager. set uri to "" to use default uri
     * Returns tokenId minted
     */
    function managerMint(address to, string calldata uri) external returns (uint256);

    /**
     * @dev batch mint a token. Can only be called by a registered manager.
     * Returns tokenIds minted
     */
    function managerMintBatch(address[] calldata recipients, string[] calldata uris)
        external
        returns (uint256[] memory);

    /**
     * @dev Configure so transfers of tokens created by the caller (must be manager) gets approval
     * from the manager before transferring
     */
    function managerSetApproveTransfer(bool enabled) external;

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    function managerBurnBatch(address caller, uint256[] calldata tokenIds) external;

    /**
     * @dev totalSupply
     */
    function totalSupply() external view returns (uint256);
}
