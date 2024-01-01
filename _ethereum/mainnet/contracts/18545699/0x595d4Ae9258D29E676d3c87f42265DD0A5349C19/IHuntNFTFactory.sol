// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IHuntBridge.sol";
import "./IHunterAssetManager.sol";
import "./IFeeManager.sol";
import "./IHunterValidator.sol";
import "./IHuntGameDeployer.sol";

/**huntnft
 * @title interface of HuntNFTFactory
 */
interface IHuntNFTFactory {
    //********************EVENT*******************************//
    event HuntGameCreated(
        address indexed owner,
        address game,
        uint64 indexed gameId,
        address indexed hunterValidator,
        IHuntGame.NFTStandard nftStandard,
        uint64 totalBullets,
        uint256 bulletPrice,
        address nftContract,
        uint64 originChain,
        address payment,
        uint256 tokenId,
        uint64 ddl,
        bytes validatorParams
    );

    //********************FUNCTION*******************************//

    /**
     * @dev create hunt game with native token payment(hunter need eth to buy bullet)
     * @param gameOwner owner of game
     * @param wantedGame if no empty address, contract will make sure the wanted and create game is the under same contract
     * @param hunterValidator the hunter validator hook when a hunter want to hunt in game.if no validator, just 0
     * @param nftStandard indivate the type of nft, erc721 or erc1155
     * @param totalBullets total bullet of hunt game
     * @param bulletPrice bullet price
     * @param nftContract nft
     * @param originChain origin chain id of nft
     * @param tokenId token id of nft
     * @param ddl the ddl of game,
     * @param registerParams params for validator that used when game is created,if validator not set, just empty
     * @notice required:
     * - totalBullets should less than 10_000 and large than 0
     * - ddl should larger than block.timestamp, if not, which is useless
     * - sender should approve nft first if nft is in local network.
     * - sender have enough baseFee paied to feeManager the fee is used for VRF and oracle service(such as help offline-users and so on).
     */
    function createETHHuntGame(
        address gameOwner,
        address wantedGame,
        IHunterValidator hunterValidator,
        IHuntGame.NFTStandard nftStandard,
        uint64 totalBullets,
        uint256 bulletPrice,
        address nftContract,
        uint64 originChain,
        uint256 tokenId,
        uint64 ddl,
        bytes memory registerParams
    ) external payable returns (address _game);

    /**
     * @dev create hunt game with erc20 payment
     * @param wantedGame if no empty address, contract will make sure the wanted and create game is the under same contract
     * @param hunterValidator the hunter validator hook when a hunter want to hunt in game.if no validator, just 0
     * @param nftStandard indivate the type of nft, erc721 or erc1155
     * @param totalBullets total bullet of hunt game
     * @param bulletPrice bullet price
     * @param  nftContract nft
     * @param originChain origin chain id of nft
     * @param payment the erc20 used to buy bullet, now only support usdt
     * @param tokenId token id of nft
     * @param ddl the ddl of game
     * @param registerParams params for validator that used when game is created,if validator not set, just empty
     * @notice creator should pay the fee to create a game, the fee is used for VRF and oracle service(such as help offline-users).
     * payment should be in whitelist, which prevent malicious attach hunters.
     */
    function createHuntGame(
        address gameOwner,
        address wantedGame,
        IHunterValidator hunterValidator,
        IHuntGame.NFTStandard nftStandard,
        uint64 totalBullets,
        uint256 bulletPrice,
        address nftContract,
        uint64 originChain,
        address payment,
        uint256 tokenId,
        uint64 ddl,
        bytes memory registerParams
    ) external payable returns (address _game);

    /// @dev pay the nft as well
    /// @notice approve factory first
    function createWithPayETHHuntGame(
        address gameOwner,
        address wantedGame,
        IHunterValidator hunterValidator,
        IHuntGame.NFTStandard nftStandard,
        uint64 totalBullets,
        uint256 bulletPrice,
        address nftContract,
        uint64 originChain,
        uint256 tokenId,
        uint64 ddl,
        bytes memory registerParams
    ) external payable;

    /**
     * @dev request random words from ChainLink VRF
     * @return requestId the requestId of VRF
     * @notice only hunt game can invoke, and the questId should never be used before
     */
    function requestRandomWords() external returns (uint256 requestId);

    /**
     * @dev hunt game transfer erc20 from a hunter to its game
     * @dev _hunter the hunter who want to participate in hunt game
     * @dev _erc20 erc20 token
     * @dev _amount erc20 amount
     * @notice only allowed by hunt game, which guarantee the logic is right
     */
    function huntGameClaimPayment(address _hunter, address _erc20, uint256 _amount) external;

    function isHuntGame(address _addr) external view returns (bool);

    function getGameById(uint64 _gameId) external view returns (address);

    function isPaymentEnabled(address _erc20) external view returns (bool);

    function getHuntBridge() external view returns (IHuntBridge);

    function getHunterAssetManager() external view returns (IHunterAssetManager);

    function getFeeManager() external view returns (IFeeManager);

    function totalGames() external view returns (uint64);

    function tempValidatorParams() external view returns (bytes memory);
}
