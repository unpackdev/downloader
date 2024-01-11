pragma solidity 0.8.11;

interface IERC721Wrapper {

    /**
     * @dev Emitted when the claim admin is updated
     * @param oldAdmin The address of the old admin
     * @param newAdmin The address of the new admin
     **/
    event ClaimAdminUpdated(address oldAdmin, address newAdmin);

    function setClaimAdmin(address claimAdmin) external;

    event ClaimERC20Airdrop(address indexed token, address indexed to, uint256 amount);

    event ClaimERC721Airdrop(address indexed token, address indexed to, uint256[] ids);

    event ClaimERC1155Airdrop(address indexed token, address indexed to, uint256[] ids, uint256[] amounts, bytes data);
    function claimERC20Airdrop(
        address token,
        address to,
        uint256 amount
    ) external;

    function claimERC721Airdrop(
        address token,
        address to,
        uint256[] calldata ids
    ) external;

    function claimERC1155Airdrop(
        address token,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    /**
    * @dev Returns the contract-level metadata.
    */
    function contractURI() external view returns (string memory);
}