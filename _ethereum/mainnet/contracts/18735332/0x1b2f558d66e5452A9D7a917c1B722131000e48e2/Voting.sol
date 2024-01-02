//................................................................
//.....SSSSSSSSSSS......EEEEEEEEEEEEEEEEEE........AAAAAAAA........
//....SSSSSSSSSSSSSS....EEEEEEEEEEEEEEEEEE........AAAAAAAA........
//...SSSSSSSSSSSSSSS....EEEEEEEEEEEEEEEEEE.......AAAAAAAAA........
//...SSSSSSSSSSSSSSSS...EEEEEEEEEEEEEEEEEE.......AAAAAAAAAA.......
//..SSSSSSSS.SSSSSSSS...EEEEEE...................AAAAAAAAAA.......
//..SSSSSS.....SSSSSS...EEEEEE..................AAAAAAAAAAA.......
//..SSSSSSS.............EEEEEE..................AAAAAAAAAAAA......
//..SSSSSSSSS...........EEEEEE.................AAAAAA.AAAAAA......
//..SSSSSSSSSSSS........EEEEEE.................AAAAAA.AAAAAA......
//...SSSSSSSSSSSSSS.....EEEEEEEEEEEEEEEEE......AAAAAA..AAAAAA.....
//....SSSSSSSSSSSSSS....EEEEEEEEEEEEEEEEE.....AAAAAA...AAAAAA.....
//.....SSSSSSSSSSSSSS...EEEEEEEEEEEEEEEEE.....AAAAAA...AAAAAAA....
//.......SSSSSSSSSSSSS..EEEEEEEEEEEEEEEEE.....AAAAAA....AAAAAA....
//...........SSSSSSSSS..EEEEEE...............AAAAAAAAAAAAAAAAA....
//.............SSSSSSS..EEEEEE...............AAAAAAAAAAAAAAAAAA...
//.SSSSSS.......SSSSSS..EEEEEE...............AAAAAAAAAAAAAAAAAA...
//..SSSSSS......SSSSSS..EEEEEE..............AAAAAAAAAAAAAAAAAAA...
//..SSSSSSSS..SSSSSSSS..EEEEEE..............AAAAAA.......AAAAAAA..
//..SSSSSSSSSSSSSSSSSS..EEEEEEEEEEEEEEEEEE.AAAAAA.........AAAAAA..
//...SSSSSSSSSSSSSSSS...EEEEEEEEEEEEEEEEEE.AAAAAA.........AAAAAA..
//....SSSSSSSSSSSSSS....EEEEEEEEEEEEEEEEEE.AAAAAA.........AAAAAA..
//.....SSSSSSSSSSSS.....EEEEEEEEEEEEEEEEEE.AAAAA...........AAAAA..
//................................................................
//......................VOTING....................................

// Submitted 2023.12.05  (YYYY.MM.DD)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    address public owner;

    struct ElectionData {
        string name;
        string title;
        string description;
        bool status;
        address[] voters;
    }

    ElectionData[] public elections;

    mapping(address => mapping(uint256 => bool)) public hasVoted;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier notOwner(uint256 _electionIndex) {
        require(msg.sender != owner, "The election owner cannot vote in their own election");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createElection(string memory _name, string memory _title, string memory _description) external onlyOwner {
        elections.push(ElectionData({
            name: _name,
            title: _title,
            description: _description,
            status: true,
            voters: new address[](0)
        }));
    }

    function vote(uint256 _electionIndex) external notOwner(_electionIndex) {
        require(elections[_electionIndex].status, "Election is not active");
        require(!hasVoted[msg.sender][_electionIndex], "You have already voted");
        hasVoted[msg.sender][_electionIndex] = true;
        elections[_electionIndex].voters.push(msg.sender);
    }

    function stopElection(uint256 _electionIndex) external onlyOwner {
        require(elections[_electionIndex].status, "Election is not active");
        elections[_electionIndex].status = false;
    }

    function getAllElections() external view returns (ElectionData[] memory) {
        return elections;
    }

    function getVoters(uint256 _electionIndex) external view returns (address[] memory) {
        return elections[_electionIndex].voters;
    }

    function getElectionsByOwner() external view returns (ElectionData[] memory) {
        // Create an array to store the elections owned by the caller
        ElectionData[] memory ownedElections = new ElectionData[](elections.length);
        uint256 count = 0;

        // Iterate through all elections and add the ones owned by the caller to the array
        for (uint256 i = 0; i < elections.length; i++) {
            if (msg.sender == owner) {
                ownedElections[count] = elections[i];
                count++;
            }
        }

        // Resize the array to remove empty slots
        assembly {
            mstore(ownedElections, count)
        }

        return ownedElections;
    }
    
    function getTotalVoters(uint256 _electionIndex) external view returns (uint256) {
        return elections[_electionIndex].voters.length;
    }
}