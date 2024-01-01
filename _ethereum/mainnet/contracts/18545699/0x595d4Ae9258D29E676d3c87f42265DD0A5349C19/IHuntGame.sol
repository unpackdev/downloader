// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IHuntNFTFactory.sol";
import "./IHunterValidator.sol";

struct HunterInfo {
    address hunter;
    uint64 bulletsAmountBefore;
    uint64 bulletNum;
    uint64 totalBullets;
    bool isFromAssetManager;
}

/**huntnft
 * @title interface of HuntGame contract
 */
interface IHuntGame {
    /**
     * @dev NFTStandard, now support standard ERC721, ERC1155
     */
    enum NFTStandard {
        GlobalERC721,
        GlobalERC1155
    }

    enum Status {
        Depositing,
        Hunting,
        Waiting,
        Timeout,
        Unclaimed,
        Claimed
    }

    //********************EVENT*******************************//
    /// emit when hunt game started, allowing hunter to hunt
    event Hunting();

    /// emit when hunter hunt in game
    event Hunted(uint64 hunterIndex, HunterInfo hunterInfo);

    /// emit when all bullet sold out, and wait for VRF
    event Waiting();

    /// emit when timeout, game is over
    event Timeout();

    /// emit when timeout and hunter withdraw asset back
    event HunterWithdrawal(uint64[] hunterIndexes);

    /// emit when NFT claimed to recipient either winner or owner of nft
    event NFTClaimed(address recipient);

    /// emit when VRF arrived, so winner is chosen, but nft and reward of owner is unclaimed
    event Unclaimed();

    /// all claimed, game is over
    event Claimed();

    /// emit when game creator claimed the reward
    event OwnerPaid();

    //********************FUNCTION*******************************//

    /**
     * @dev start hunt game when NFT is indeed owned by hunt game contract
     * @notice anyone can invoke this contract, be sure transfer exactly right contract
     */
    function startHunt() external;

    /**
     * @dev hunter hunt game by buy bullet to this game
     * @param bullet bullet num hunter try to buy
     * @notice only in hunting period and hunter should be permitted
     * if hunt game has hunter validator
     */
    function hunt(uint64 bullet) external payable;

    /// @dev same, can fulfill the payload
    function hunt(address hunter, uint64 bullet, bool _isFromAssetManager, bytes calldata payload) external payable;

    /**
     * @dev buy bullet in native token(ETH), hunter need bullet to hunt nft, just like tickets in raffle
     * @param hunter hunter
     * @param bullet bullet num
     * @param minNum how much bullet at least, tolerate async of action
     * @param isFromAssetManager whether to refund to asset manager
     * @param payload useful for hunter verify extension
     * @notice require :
     * - hunt game do accept native token
     * - hunt game is in hunting period
     */
    function huntInNative(
        address hunter,
        uint64 bullet,
        uint64 minNum,
        bool isFromAssetManager,
        bytes calldata payload
    ) external payable returns (uint64);

    /// @dev same, but accept erc20
    function hunt(
        address hunter,
        uint64 bullet,
        uint64 minNum,
        bool isFromAssetManager,
        bytes calldata payload
    ) external returns (uint64);

    /// @dev claim timeout when in hunting period and waiting period
    /// @notice only block.timestamp beyond the ddl and in hunting and waiting period
    function claimTimeout() external;

    /**
     * @dev withdraw bullet when timeout.the asset form HunterAssetManager will return back to HunterAssetManager.Others
     * just return back to users wallet
     * @param _hunterIndexes a set of hunter index prepared to withdraw
     * @notice if hunter already withdraw in provided index, just revert
     */
    function timeoutWithdrawBullets(uint64[] memory _hunterIndexes) external;

    /// @dev withdraw nft to creator when game timeout.The nft deposited from other chain will be returned back.
    /// @notice only in timeout period and the nft should not paid in twice.
    function timeoutWithdrawNFT() external payable;

    /// @dev same but can chose to keep in this network other than withdraw back to origin chain
    function timeoutClaimNFT(bool withdraw) external payable;

    /**
     * @dev claim nft with winner index.The NFT will be transferred to winner by native chain  or bridge.
     * @param _winnerIndex winner index which can get by getWinnerIndex method.
     * @notice only allowed when random num is filled and game is in unclaimed status,and do not try to claim twice
     */
    function claimNft(uint64 _winnerIndex) external payable;

    /// @dev same, but do not withdraw in other chain, just transfer to winner
    function claimNft(uint64 _winnerIndex, bool _withdraw) external payable;

    /**
     * @dev claim hunt game reward to the creator
     * @notice only allowed when in unclaimed status, and do not try to claim twice
     */
    function claimReward() external;

    /// @return get winner index
    /// @notice revert if random num is not filled yet
    function getWinnerIndex() external view returns (uint64);

    /// @return check hunter has the right to hunt in this game
    function canHunt(address hunter, uint64 bullet) external view returns (bool);

    /// @dev same
    function canHunt(address sender, address hunter, uint64 bullet, bytes memory payload) external view returns (bool);

    function factory() external view returns (IHuntNFTFactory);

    function gameId() external view returns (uint64);

    function owner() external view returns (address);

    function validator() external view returns (IHunterValidator);

    function ddl() external view returns (uint64);

    function bulletPrice() external view returns (uint256);

    function totalBullets() external view returns (uint64);

    function getPayment() external view returns (address);

    function nftStandard() external view returns (NFTStandard);

    function nftContract() external view returns (address);

    function tokenId() external view returns (uint256);

    function status() external view returns (Status);

    function tempHunters(
        uint256 index
    )
        external
        view
        returns (
            address hunter,
            uint64 bulletsAmountBefore,
            uint64 bulletNum,
            uint64 totalBullets,
            bool isFromAssetManager
        );

    function randomNum() external view returns (uint256);

    function requestId() external view returns (uint256);

    function winner() external view returns (address);

    function nftPaid() external view returns (bool);

    function ownerPaid() external view returns (bool);

    function leftBullet() external view returns (uint64);

    function estimateFees() external view returns (uint256);

    function userNonce() external view returns (uint256);

    function originChain() external view returns (uint64);
}
