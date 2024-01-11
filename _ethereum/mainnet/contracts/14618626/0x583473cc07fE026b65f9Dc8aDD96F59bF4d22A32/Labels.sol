// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Data.sol";

library Labels {
    using Data for Data.Reader;

    function get(uint256 i) internal pure returns (string memory) {
        bytes
            memory data = "DogOrangeRedGreenBluePurpleYellowWhiteBlackFluffySlimeGreySludgeStoneTreeCrystalCheesePointyRoundStacheBeardHumanoidBullCrabSpiderOctopusMushroomPigBunnyCatEtherealPinkBrownClosedSmilingStokedShockedAnxiousAnguishedHungryPantingNoneSharpGappedFangsLeft FangRight FangBuckStraightLevel 1Level 2Level 3Level 4Level 5Level 6Level 7Level 8";
        bytes
            memory index = "\x00\x00\x00\x03\x00\x09\x00\x0c\x00\x11\x00\x15\x00\x1b\x00\x21\x00\x26\x00\x2b\x00\x31\x00\x36\x00\x3a\x00\x40\x00\x45\x00\x49\x00\x50\x00\x56\x00\x5c\x00\x61\x00\x67\x00\x6c\x00\x74\x00\x78\x00\x7c\x00\x82\x00\x89\x00\x91\x00\x94\x00\x99\x00\x9c\x00\xa4\x00\xa8\x00\xad\x00\xb3\x00\xba\x00\xc0\x00\xc7\x00\xce\x00\xd7\x00\xdd\x00\xe4\x00\xe8\x00\xed\x00\xf3\x00\xf8\x01\x01\x01\x0b\x01\x0f\x01\x17\x01\x1e\x01\x25\x01\x2c\x01\x33\x01\x3a\x01\x41\x01\x48";
        Data.Reader memory reader = Data.Reader(i << 1);

        uint256 start = reader.nextUint16(index);
        uint256 end = ((i + 1) << 1) < index.length
            ? reader.nextUint16(index)
            : data.length;

        return reader.set(start).nextString32(data, end - start);
    }
}
