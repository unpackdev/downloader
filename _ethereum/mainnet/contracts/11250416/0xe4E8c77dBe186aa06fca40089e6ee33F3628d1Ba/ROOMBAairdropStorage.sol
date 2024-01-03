pragma solidity >=0.5.10;

contract ROOMBAairdropStorage {
    address distributorContract;
    address owner;
    
    constructor() public {
        owner = msg.sender;
    }
    mapping(address => uint256) public participants;

    function getParticipant(address _key) public view returns (uint256) {
        return participants[_key];
    }

    function registerParticipant() public {
        //store default airdrop token value
        participants[msg.sender] = 500;
    }

    function setDistributor(address _distributorContract) public {
        require(msg.sender == owner);
        distributorContract = _distributorContract;
        //set distribution contract after airdrop stop
    }

    function updateAllocaion(address _participant, uint256 _amount) public {
        require(msg.sender == owner);
        //update default airdrop token value to actual amount after airdrop stop
        participants[_participant] += _amount;
    }
}