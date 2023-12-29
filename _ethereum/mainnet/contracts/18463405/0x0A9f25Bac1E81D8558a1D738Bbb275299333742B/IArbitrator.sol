// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IArbitratorErrors.sol";
import "./IArbitratorEvents.sol";
import "./IArbitratorData.sol";

interface IArbitrator is IArbitratorErrors, IArbitratorEvents, IArbitratorData {
    /*////////////////////////////////////////////////////////////// 
                                  Core                          
    //////////////////////////////////////////////////////////////*/

    function create(
        address _asset,
        uint128 _bet,
        uint8 _seats,
        BetMode _betMode,
        RNGMode _rngMode
    ) external payable;

    function join(uint256 _id) external payable;

    function leave(uint256 _id, uint8 _index) external;

    function fold(uint256 _id, uint8 _index) external;

    function play(
        uint256 _id,
        uint8 _index,
        uint128 _bet,
        Randomness calldata _rng,
        bytes calldata _sig
    ) external payable;

    function claim(
        uint256 _id,
        uint8 _index,
        Randomness calldata _rng,
        bytes calldata _sig
    ) external;

    function collectFees(address _asset) external;

    /*//////////////////////////////////////////////////////////////
                                  Views
    //////////////////////////////////////////////////////////////*/

    function rngSource() external view returns (address);

    function fee() external view returns (uint128);

    function currentId() external view returns (uint256);

    function getBalance(address _token) external view returns (uint256);

    function getParticipant(
        uint256 _id,
        uint256 _index
    ) external view returns (address);

    function getParticipants(
        uint256 _id
    ) external view returns (address[] memory);

    function getAssetAllowed(address _asset) external view returns (bool);

    function getBetModeAllowed(BetMode _mode) external view returns (bool);

    function getRNGModeAllowed(RNGMode _mode) external view returns (bool);

    function getRandomness(
        uint256 _id,
        uint64 _counter
    ) external view returns (uint256);

    function getTontine(uint256 _id) external view returns (Tontine memory);

    function getAmountAfterFee(uint256 _amount) external view returns (uint256);

    function isActive(
        address _participant,
        uint256 _id
    ) external view returns (bool);

    function getParticipantState(
        uint256 _id,
        Randomness calldata _rng
    ) external view returns (uint128, bool, uint256);

    function getParticipantIdentifier(
        address _participant,
        uint256 _id
    ) external pure returns (bytes32);
}
