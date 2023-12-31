// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RNDMPicker {
    address public owner;
    address[] public participants;
    address public winner;
    bool public winnerSelected = false;

    event WinnerSelected(address indexed winnerAddress);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
        
        // Pre-populate participants with the given addresses
    participants = [
            0x6d9A6835d7562D0458C821EB7b1438A313B9AE13,
        0x6d9A6835d7562D0458C821EB7b1438A313B9AE13,
        0x6d9A6835d7562D0458C821EB7b1438A313B9AE13,
        0x6d9A6835d7562D0458C821EB7b1438A313B9AE13,
        0x6d9A6835d7562D0458C821EB7b1438A313B9AE13,
        0xf25B4C6BA808Cb44c438B46032A2f1476eF92FbD,
        0xf25B4C6BA808Cb44c438B46032A2f1476eF92FbD,
        0xf25B4C6BA808Cb44c438B46032A2f1476eF92FbD,
        0xf25B4C6BA808Cb44c438B46032A2f1476eF92FbD,
        0x1c4633F750ccdF4f40C9e88f5986A80c814B851f,
        0x1c4633F750ccdF4f40C9e88f5986A80c814B851f,
        0x1c4633F750ccdF4f40C9e88f5986A80c814B851f,
        0x1092Ce83D3D0cBab16ba6Aa352F43DA25f9eC48D,
        0x1092Ce83D3D0cBab16ba6Aa352F43DA25f9eC48D,
        0xe2C18738A2200740991eb29782DFBFEBF6D7a207,
        0xe2C18738A2200740991eb29782DFBFEBF6D7a207,
        0x1C86d5e842B7addeC2467eD054250C05f1b13a13,
        0x1C86d5e842B7addeC2467eD054250C05f1b13a13,
        0x04B7f4D0Dbbf5b0DDE858878fbE8b3DA69413D2e,
        0xF566c12516D171b451DACB93C114753C07f980E0,
        0xAB6cA2017548A170699890214bFd66583A0C1754,
        0x05E71df45A51C7092516a39de35077fEBe35E164,
        0x89135f8ffa1E107799cAef5328C6d3ae6e7D849C,
        0x66472EE4287A5aBf1B5f448AC08399f69aAb9eE6,
        0x8B9A3A156A32a7Cf1b29b370B005A458D870176e,
        0x438a9DDe518a5510925289DEf9815161ff49B00f,
        0x2B3EC2D5Ff9ada834FEf215fF30857920A33E022,
        0x000000697bB288F2528042e8844b65Cd32BeafCa,
        0x4b2ef7127640964Bf5CEf3d1Bf8D8F72d8D386f5,
        0xF1637ADede8b89559C70481C3CB4F74EBAC80D82,
        0xa9cA30Dd78684CB5EFa6Bdb854E6fd5bA07398B0,
        0x78272D01168dcBCCd0F610DF27141883f1bCE7f0,
        0x4375ea74C4D082385A8e39c4D5eeA0eAb6129093,
        0x7a2De3Dd2D5cf29dC38E4809D4964388C322e449,
        0x2Debdf4427CcBcfDbC7f29D63964499a0ec184F6,
        0xA75C04F3434EA0414A4cC5a4A2D895d283AE399d,
        0xfDeD90A3B1348425577688866f798f94d77A0D02,
        0x7Dcb39fe010A205f16ee3249F04b24d74C4f44F1,
        0x807EA4C5D7945dfEA05D358473FeE6042E92Cf37,
        0xA355065597f1C213160E664B65Beda6cABF07BB0,
        0xcBfb7d9A4e9b3a4A592AF854ee520E3fc59fe49E,
        0x51787a2C56d710c68140bdAdeFD3A98BfF96FeB4,
        0x57c25777BD6dffb3251306C0A6449BEBb58a7aF0,
        0x81e388D5139f109e859F38230101e4F8B036d8e8,
        0xD39a360f26B7A235b96981AfD8C7Eafe42c9D08b,
        0x3457E4bE673eF3b584E3D26764b4e22F4589e216,
        0x934b83DAF8446b44E0DD8A557C1f81864663FD24
        ];

    }

    function participate() external {
        require(!winnerSelected, "Winner has already been selected");
        participants.push(msg.sender);
    }

    function selectWinner() external onlyOwner {
        require(!winnerSelected, "Winner has already been selected");
        
        uint256 randomNumber = random() % participants.length;
        winner = participants[randomNumber];
        winnerSelected = true;
        
        emit WinnerSelected(winner);
    }

    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants.length)));
    }

    function getParticipants() external view returns (address[] memory) {
        return participants;
    }

    // This function will send back ether immediately if sent to this contract
    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}