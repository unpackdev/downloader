// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IGetStatus {
    /**
     * @dev Returns if the user is blocked and if the token is blocked
     * @param user The user address
     * @param contractAddress The contract address
     * @param tokenId The token id
     * @return (userBlocked, tokenBlocked)
     */
    function userTokenIdBlockStatus(
        address user,
        address contractAddress,
        uint256 tokenId
    ) external view returns (bool, bool);

    /**
     * @dev Returns if the user is blocked and if the tokens are blocked
     * @param user The user address
     * @param contractAddress The contract address
     * @param tokenIds Array of token ids
     * @return (userBlocked, tokenIdsBlocked)
     */
    function userTokenIdsBlockStatus(
        address user,
        address contractAddress,
        uint256[] calldata tokenIds
    ) external view returns (bool, bool[] memory);

    /**
     * @dev Returns if the user is blocked and if the tokens are blocked
     * @param users Array of user addresses
     * @param contractAddress The contract address
     * @param tokenId The token id
     * @return (usersBlocked, tokenBlocked)
     */
    function usersTokenIdBlockStatus(
        address[] calldata users,
        address contractAddress,
        uint256 tokenId
    ) external view returns (bool[] memory, bool);

    /**
     * @dev Returns if the users are blocked and if the tokens ids of a token are blocked
     * @param users Array of user addresses
     * @param contractAddress The contract address
     * @param tokenIds Array of token ids
     * @return (usersBlocked, tokenIdsBlocked)
     */
    function usersTokenIdsBlockStatus(
        address[] calldata users,
        address contractAddress,
        uint256[] calldata tokenIds
    ) external view returns (bool[] memory, bool[] memory);

    /**
     * @dev Returns if the users are blocked and if the tokens are blocked
     * @param users Array of user addresses
     * @param contractAddresses Array of contract addresses
     * @param tokenIds Array of token ids
     * @return (usersBlocked, tokenIdsBlocked)
     */
    function usersTokensIdsBlockStatus(
        address[] calldata users,
        address[] calldata contractAddresses,
        uint256[][] calldata tokenIds
    ) external view returns (bool[] memory, bool[][] memory);
}
