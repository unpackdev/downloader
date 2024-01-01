// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IHuntGameValidator.sol";

/**huntnft
 * @title the interface manage the asset that user deposited, which can be used when hunt game fulfilled user's condition
 * by IHuntGameValidator
 */
interface IHunterAssetManager {
    //********************EVENT*******************************//
    /// @notice if payment is zero, means native token
    event HunterAssetUsed(address indexed _hunter, address _huntGame, address _payment, uint256 _value);
    event HunterAssetDeposited(address indexed _hunter, address _payment, uint256 _value);
    event HunterAssetWithdrawal(address indexed _hunter, address _payment, uint256 _value);
    event HuntGameValidatorChanged(address indexed _hunter, address _huntGameValidator);
    event OfficialHuntGameValidatorChanged(uint8 _type, address _huntGameValidator);

    //********************FUNCTION*******************************//
    /**
     * @dev help a hunter to participate in a hunt game with bullet
     * @param _hunter choose a hunter to try to participate in a hunt game
     * @param _huntGame the hunt game that want to participate in
     * @param _bullet the bullet num try to buy
     * @notice the hunt game should record in huntnft factory;the asset manager will check the hunt using IHuntGameValidator.isHuntGamePermitted,and then
     * need to invoke IHuntGameValidator.afterValidated to change state if needed.
     */
    function hunt(address _hunter, IHuntGame _huntGame, uint64 _bullet) external;

    /**
     * @dev hunter try to deposit payment token to asset manager
     * @param _payment the payment erc20 token address,zero means native token
     * @param _value the value want to deposit
     */
    function deposit(address _payment, uint256 _value) external;

    /// @dev same, but support help others to deposit
    function deposit(address _hunter, address _payment, uint256 _value) external;

    /**
     * @dev deposit native token to asset manager
     */
    function deposit() external payable;

    ///@dev same, but help others to deposit
    function deposit(address _hunter) external payable;

    /**
     * dev withdraw token from asset manager, address(0) means native token
     * @param _payment the payment erc20 token address,zero means native token
     * @param _value the value want to withdraw
     */
    function withdraw(address _payment, uint256 _value) external;

    /**
     * @dev user set its own hunt game validator to check the hunt game when try to
     * participate in a hunt game.If not set, just use official blue chip validator
     * @param _huntGameValidator the contract that realize the IHuntGameValidator interface
     * @notice all zero address means using official blue chip verifier
     */
    function setHuntGameValidator(IHuntGameValidator _huntGameValidator) external;

    /**
     * @dev set official hunt game validator
     * @param _huntGameValidator used for validate hunt game
     * @notice allowed by owner:
     * - 0: blue chip
     */
    function setOfficialValidator(uint8 _type, IHuntGameValidator _huntGameValidator) external;

    /// @return hunt game validator of hunter
    function getHuntGameValidator(address _hunter) external view returns (IHuntGameValidator);

    function officialValidator(uint8 _type) external view returns (IHuntGameValidator);

    function getBalance(address _hunter, address _payment) external view returns (uint256);
}
