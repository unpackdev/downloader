// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract Lottery  {
    uint256[] public numberList = [1, 2, 3, 3, 5, 6];
    uint256 public luckNumber = 6;

   

    // 随机数
    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        msg.sender
                    )
                )
            );
    }

    function setLuckNumber() public  returns (uint256) {
        uint256 index = random() % numberList.length;
        luckNumber = numberList[index];
        return luckNumber;
    }


    function play() public view returns (uint256, bool) {
        uint256 index = random() % numberList.length;
        uint256 number = numberList[index];
        bool flag = number == luckNumber;
        return (number, flag);
    }
}
