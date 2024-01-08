// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./LibReignStorage.sol";
import "./LibOwnership.sol";
import "./SafeMath.sol";

contract EpochClockFacet {
    using SafeMath for uint256;

    function getEpochDuration() public view returns (uint256) {
        LibReignStorage.Storage storage ds = LibReignStorage.reignStorage();

        return ds.epochDuration;
    }

    function getEpoch1Start() public view returns (uint256) {
        LibReignStorage.Storage storage ds = LibReignStorage.reignStorage();
        return ds.epoch1Start;
    }

    function setEpochDuration(uint256 _duration) public {
        LibOwnership.enforceIsContractOwner();
        LibReignStorage.Storage storage ds = LibReignStorage.reignStorage();
        ds.epochDuration = _duration;
    }

    function getCurrentEpoch() public view returns (uint128) {
        LibReignStorage.Storage storage ds = LibReignStorage.reignStorage();
        if (block.timestamp < ds.epoch1Start) {
            return 0;
        }
        return
            uint128((block.timestamp - ds.epoch1Start) / ds.epochDuration + 1);
    }
}
