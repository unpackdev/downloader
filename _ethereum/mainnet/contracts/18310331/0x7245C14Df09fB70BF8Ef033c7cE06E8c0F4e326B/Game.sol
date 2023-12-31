// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract Game {
    string[] public prizeList = [
        "apple",
        "ice cream",
        "juice",
        "hanbunger",
        "candy"
    ];
    mapping(address => string) records;

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

    function play() public returns (string memory) {
        bytes32 str1Hash = keccak256(abi.encode(records[msg.sender]));
        bytes32 str2Hash = keccak256(abi.encode(""));
        require(str1Hash == str2Hash, "you had particted already");
        uint256 index = random() % prizeList.length;
        string memory prize = prizeList[index];
        records[msg.sender] = prize;
        return records[msg.sender];
    }
}
