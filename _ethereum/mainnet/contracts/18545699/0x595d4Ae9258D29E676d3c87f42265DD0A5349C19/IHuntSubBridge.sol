// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IHunterValidator.sol";

/** huntnft
 * @title the interface of huntnft sub bridge, which is used for deposit and withdraw cross chain with huntnft game
 */
interface IHuntSubBridge {
    //********************EVENT*******************************//
    //deposit event
    event NftDepositInitialized(
        bool isErc1155,
        address addr,
        uint256 tokenId,
        address from,
        address recipient,
        bytes extraData,
        uint64 _nonce
    );
    event NftWithdrawFinalized(
        bool isErc1155,
        address addr,
        uint256 tokenId,
        address from,
        address recipient,
        bytes extraData,
        uint64 _nonce
    );

    // dao event
    event Paused(bool);

    //********************FUNCTION*******************************//
    /**
     * @dev deposit nft to main bridge, support erc721 and erc1155
     * @param isErc1155 erc721 false, erc1155 true, other type not support
     * @param addr nft address
     * @param tokenId tokenId
     * @param recipient recipient address on main bridge network
     */
    function deposit(bool isErc1155, address addr, uint256 tokenId, address recipient) external payable;

    /**
     * @dev deposit nft and create hunt game related with it in main bridge
     * @param isErc1155 erc721 false, erc1155 true, other type not support
     * @param addr nft address
     * @param tokenId tokenId
     * @param hunterValidator hunter validator of hunt game,default zero address
     * @param totalBullets total bullets of hunt game
     * @param ddl ddl of hunt game
     * @param registerParams register params of validator
     */
    function depositAndCreateGame(
        bool isErc1155,
        address addr,
        uint256 tokenId,
        IHunterValidator hunterValidator,
        uint64 totalBullets,
        uint256 bulletPrice,
        uint64 ddl,
        bytes memory registerParams
    ) external payable;

    /// @dev check the bridge is paused or not, if paused, can't deposit anymore
    function isPaused() external view returns (bool);

    /// @return estimate fee for deposit nft
    function estimateFees() external view returns (uint256);

    function baseFee() external view returns (uint256);
}
