// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./pin.sol";

abstract contract IMapifest is WithPin{
    Pin[] public pins;

    function makePin(
        uint256 _lat,
        uint256 _lng,
        uint256 _decimal,
        string calldata _message,
        uint256 _valueAmount
    ) external virtual returns (uint256);

    function makeId(
        uint256 _lat,
        uint256 _lng,
        uint256 _decimal
    ) external virtual pure returns (uint256);

    function acquire(uint256 _fromPinId, uint256 _toPinId) external virtual;

    function getPinInfo(uint256 _pinId) external virtual view
        returns (
            uint32,
            uint32,
            uint8,
            uint256,
            address
        );

    function setMessage(uint256 _pinId, string calldata _message)
        external
        virtual;

    function setImage(uint256 _pinId, string calldata _image) external virtual;

    function setVideo(uint256 _pinId, string calldata _video) external virtual;

    function setValueAmount(uint256 _pinId, uint256 _valueAmount)
        external
        virtual;


	function ownerOf(uint256 tokenId) public view virtual returns (address);
}
