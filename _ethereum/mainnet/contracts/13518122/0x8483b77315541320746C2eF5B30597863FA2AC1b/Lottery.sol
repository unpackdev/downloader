// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;
    address internal vrfCoordinator;
    address internal link;
    uint256 public randomResult;

    constructor(
        address _coordinator,
        address _linkAddress,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(_coordinator, _linkAddress) {
        keyHash = _keyHash;
        fee = _fee;
    }

    function getRandomNumber(uint256 adminProvidedSeed)
        public
        returns (bytes32 requestId)
    {
        require(randomResult == 0, "Random number is already initiated");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee, adminProvidedSeed);
    }

    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        randomResult = randomness;
    }

    function _kec(uint256 num) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(num))) % 5800;
    }

    function getWinnersIds()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        require(randomResult > 0, "Random number is not initiated");
        uint256 d = uint256(keccak256(abi.encodePacked(randomResult))) % 10000;
        if (d == 0) {
            d = 1;
        }

        return (
            _kec(randomResult),
            _kec(randomResult + d),
            _kec(randomResult + d * 2),
            _kec(randomResult + d * 3),
            _kec(randomResult + d * 4),
            _kec(randomResult + d * 5),
            _kec(randomResult + d * 6),
            _kec(randomResult + d * 7),
            _kec(randomResult + d * 8)
        );
    }

}
