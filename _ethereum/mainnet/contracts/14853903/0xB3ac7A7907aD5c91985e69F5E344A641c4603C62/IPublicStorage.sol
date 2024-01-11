//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPublicStorage {
    struct UserInfo {
        string urlAvatar;
        string numberPhone;
    }

    /** @notice add enable list name BlockChain by id BlockChain
     *  @param idBlockchain id Block Chain
     *  @param nameBlockchain_ name BlockChain
     */
    function addBlockchainOwner(
        uint256[] memory idBlockchain,
        string[] memory nameBlockchain_
    ) external;

    /** @notice add list user address Wallet in different by token ID
     *  @param number id Token number
     *  @param idBlockchain id Block Chain
     *  @param addressUser addresses user
     */
    function addWallet(
        uint256 number,
        uint256[] memory idBlockchain,
        string[] memory addressUser
    ) external;

    /** @notice add Avatar by token ID
     *  @param number token ID (PrefixNumberId)
     *  @param urlImage link of Avatar
     */
    function addAvatar(uint256 number, string memory urlImage) external;

    /** @notice add Avatar by token ID
     *  @param number token ID (PrefixNumberId)
     *  @param phoneNumber real user phone
     */
    function addNumberPhone(uint256 number, string memory phoneNumber) external;

    /** @notice add enable list name Social Network by id Social Network
     *  @param idSocial id Social Network
     *  @param nameSocial_ name Social Network
     */
    function addSocialOwner(
        uint256[] memory idSocial,
        string[] memory nameSocial_
    ) external;

    /** @notice add list user address Wallet in different by token ID
     *  @param number id Token number
     *  @param idSocial id Social Network
     *  @param userName username of Social Network
     */
    function addSocial(
        uint256 number,
        uint256[] memory idSocial,
        string[] memory userName
    ) external;
}
