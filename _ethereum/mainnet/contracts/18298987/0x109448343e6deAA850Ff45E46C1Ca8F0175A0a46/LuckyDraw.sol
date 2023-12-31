// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract LuckyDraw  {
    address payable[] public players;

    // 参与者需要发送0.01 以太
    function participate() public payable {
        require(msg.value >= .01 ether);
        players.push(payable(msg.sender));
    }

    // 随机数
    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, players)
                )
            );
    }

    // 选择幸运儿
    function pickWinner() public  {
        require(players.length > 0);

        uint256 index = random() % players.length;
        players[index].transfer(address(this).balance);

        players = new address payable[](0);
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
}
