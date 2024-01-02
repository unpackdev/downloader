// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    address payable public owner ;
    struct ElectionData {
        string name;
        string title;
        string description;
        bool status;
        address[] voters;
    }
    struct ElectionData2{
        bool status;
        address[] voters;
    }
   ElectionData2[] public  elections2;
    uint256 votingFee = 0 ether;
   
    ElectionData[] public elections;

    mapping(address => mapping(uint256 => bool)) public hasVoted;
    mapping(address => mapping(uint256 => bool)) public hasNoVoted;
    mapping(address => bool) public allowedVoters;

    mapping(address => bool) public admins;
    address[] adminAddresses;
 
    modifier onlyAdmin(){
        require(admins[msg.sender], "only admin can call this function");
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
  

    modifier notOwner(uint256 _electionIndex) {
        require(msg.sender != owner, "The election owner cannot vote in their own election");
        _;
    }

   
    
    function addAllowedVoter(address _voter) external onlyAdmin {
    require(!allowedVoters[_voter], "Address is already an allowed voter");

    allowedVoters[_voter] = true;
   }

     function updatedVotingFee(uint256 _fee) public onlyOwner{
         votingFee = _fee;
     }
     function addAdminByOwner(address _admin) public onlyOwner{
          admins[_admin] = true;
          adminAddresses.push(_admin);
     }

    function addAdminByAdmins(address _admin) public onlyAdmin{
        admins[_admin] = true;
        adminAddresses.push(_admin);
    }
        function checkAdmin(address _admin) public view returns (bool) {
        return admins[_admin];
    } 


        constructor() {
            owner = payable(0xc96A15BE51E8a76C34b058A70a717d52FF282E54);
        }

     function getAdmins() public view returns(address[] memory){
        return adminAddresses;
    }
  
    function createElection(string memory _name, string memory _title, string memory _description) payable external  {
          require(msg.value >= votingFee , "insufficient Balance");
        elections.push(ElectionData({
            name: _name,
            title: _title,
            description: _description,
            status: true,
            voters: new address[](0)
        }));
         elections2.push(ElectionData2({status:true, voters: new address[](0)}));

        owner.transfer(msg.value);
    }

  function vote(uint256 _electionIndex) external payable notOwner(_electionIndex) {
    require(msg.value >= votingFee, "Insufficient Balance");
    require(elections[_electionIndex].status, "Election is not active");
    require(!hasVoted[msg.sender][_electionIndex], "You have already voted");
 
    hasVoted[msg.sender][_electionIndex] = true;
    elections[_electionIndex].voters.push(msg.sender);
    owner.transfer(msg.value);
}

function voteNo(uint256 _electionIndex) external payable notOwner(_electionIndex) {
    require(msg.value >= votingFee, "Insufficient Balance");
    require(elections[_electionIndex].status, "Election is not active");
    require(!hasNoVoted[msg.sender][_electionIndex], "You have already voted");
    require(!hasVoted[msg.sender][_electionIndex], "You have already voted");
 
    hasNoVoted[msg.sender][_electionIndex] = true;
    hasVoted[msg.sender][_electionIndex] = true;
    elections2[_electionIndex].voters.push(msg.sender);
    owner.transfer(msg.value);
}

    function stopElection(uint256 _electionIndex) external payable onlyAdmin {
         require(msg.value >= votingFee, "insufficient Balance");
        require(elections[_electionIndex].status, "Election is not active");
        elections[_electionIndex].status = false;
        owner.transfer(msg.value);
    }

    function getAllElections() external view returns (ElectionData[] memory) {
        return elections;
    }
    function getAllElections2() external view returns (ElectionData2[] memory) {
        return elections2;
    }


    function getVoters(uint256 _electionIndex) external view returns (address[] memory) {
        return elections[_electionIndex].voters;
    }

      function getVoters2(uint256 _electionIndex) external view returns (address[] memory) {
        return elections2[_electionIndex].voters;
    }

function getElectionsByOwner() external view returns (ElectionData[] memory) {
    
    ElectionData[] memory ownedElections = new ElectionData[](elections.length);
    uint256 count = 0;

 
    for (uint256 i = 0; i < elections.length; i++) {
        if (admins[msg.sender]) {
            ownedElections[count] = elections[i];
            count++;
        }
    }

    assembly {
        mstore(ownedElections, count)
    }

    return ownedElections;
}

    
    function getTotalVoters(uint256 _electionIndex) external view returns (uint256) {
        return elections[_electionIndex].voters.length;
    }
     function getTotalVoters2(uint256 _electionIndex) external view returns (uint256) {
        return elections2[_electionIndex].voters.length;
    }
}