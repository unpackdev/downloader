// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

error OnlySHB();

abstract contract SchoolOfHardBlocksPuzzle {
    address SHB;

    constructor(address _shbAddress) {
        SHB = _shbAddress;
    }

    modifier onlySHB() {
        if (msg.sender != SHB) {
            revert OnlySHB();
        }
        _;
    }

    function attemptPuzzle(
        address _student,
        bytes32 _personalisedAnswer1,
        bytes32 _personalisedAnswer2,
        bytes32 _personalisedAnswer3,
        bytes32 _personalisedAnswer4,
        bytes32 _personalisedAnswer5
    ) public virtual view returns (uint8 score);

    function personaliseNumber(
        uint _number,
        address _studentAddress
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_number, _studentAddress));
    }
    function personaliseString(
        string memory _string,
        address _studentAddress
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_string, _studentAddress));
    }
}
