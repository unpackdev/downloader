//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IEscrow
 * @author Protofire
 * @dev Ilamini Dagogo for Protofire.
 *
 */
interface IEscrow {
    function setMakerDeposit(uint256 _offerId) external;

    function setNFTDeposit(uint256 _offerId) external;

    function withdrawDeposit(uint256 offerId, uint256 orderId) external;

    function withdrawNftDeposit(uint256 _nftOfferId, uint256 _nftOrderId) external;

    function freezeEscrow(address _account) external returns (bool);

    function setdOTCAddress(address _token) external returns (bool);

    function freezeOneDeposit(uint256 offerId, address _account) external returns (bool);

    function unFreezeOneDeposit(uint256 offerId, address _account) external returns (bool);

    function unFreezeEscrow(address _account) external returns (bool status);

    function cancelDeposit(
        uint256 offerId,
        address token,
        address maker,
        uint256 _amountToSend
    ) external returns (bool status);

    function cancelNftDeposit(uint256 nftOfferId) external;

    function removeOffer(uint256 offerId, address _account) external returns (bool status);

    function setNFTDOTCAddress(address _token) external returns (bool status);
}
