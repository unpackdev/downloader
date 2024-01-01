// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IERC165.sol";

/**
 * @title IHunterValidator is used for HuntGame to check whether a hunter is allowed to join hunt game.useful for whitelist
 */
interface IHunterValidator {
    /// @dev hunt game may register some info to validator when needed.
    /// @dev the params between register is stored in HuntNFTFactory.tempValidatorParams();
    function huntGameRegister() external;

    /**
     * @dev use validate to check the hunter, revert if check failed
     * @param _game hunt game hunter want to join in
     * @param _sender who call this contract
     * @param _hunter hunter who want to join in the hunt game
     * @param _bullet the bullet prepare to buy
     * @param _payload the extra payload for verify extension, such as offline cert
     * @notice check sender should be hunt game, just use HuntNFTFactory.isHuntGame(msg.sender);
     */
    function validateHunter(
        address _game,
        address _sender,
        address _hunter,
        uint64 _bullet,
        bytes calldata _payload
    ) external;

    /**
     * @dev hunt game check whether hunter can hunt on this game,the simply way is just use offline cert for hunter or
     * whitelist or check whether a hunter hold some kind of nft and so on
     * @param _game hunt game hunter want to join in
     * @param _sender who call this contract
     * @param _hunter hunter who want to join in the hunt game
     * @param _bullet the bullet prepare to buy
     * @param _payload the extra payload for verify extension, such as offline cert
     */
    function isHunterPermitted(
        address _game,
        address _sender,
        address _hunter,
        uint64 _bullet,
        bytes calldata _payload
    ) external view returns (bool);
}
