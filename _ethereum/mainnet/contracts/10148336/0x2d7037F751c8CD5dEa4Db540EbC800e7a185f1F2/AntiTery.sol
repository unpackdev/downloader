pragma solidity >=0.6.8;
// SPDX-License-Identifier: UNLICENSED

contract AntiTery {
    address payable owner;
    struct Person {
        address payable voter;
        uint amount;
        uint decision;
    }
    uint people_count;
    uint block_closed;
    uint max_votes;
    bool voting_in_progress;
    mapping(uint => Person) people;
    
    event RevealResult(uint);
    event VotingClosed();
    event EveryoneLosses();
    
    constructor() public {
        owner = msg.sender;
        voting_in_progress = true;
        max_votes = 32;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    function add_funds() public payable isOwner {}
    
    function withdraw_funds() public isOwner {
        require(address(this).balance>0, 'Balance is zero');
        owner.transfer(address(this).balance);
    }
    
    function change_maximum_of_maximum_voters(uint _max_votes) public isOwner {
        max_votes = _max_votes;
    }
    
    function make_vote(uint _decision) public payable {
        require(msg.value > 0, "You should pay something");
        require(voting_in_progress, "Voting is closed");
        people[people_count] = Person(msg.sender,msg.value,_decision);
        people_count ++;
        if (get_number_votes() >= max_votes) {
            voting_in_progress = false;
            block_closed = block.number;
            emit VotingClosed();
        }
    }
    
    function cancel_vote() public {
        require(voting_in_progress, "Voting is closed");
        for (uint i;i<people_count;i++) {
            if (people[i].voter == msg.sender) {
                msg.sender.transfer(people[i].amount);
                delete people[i];
            }
            
        }
    }

    function reveal_number_and_pay() public {
        require(!voting_in_progress, "Voting in progress");
        require(block.number > block_closed, "Wait for the next block");
        uint _result = uint256(blockhash(block_closed + 1)) ;
        if (_result == 0) { 
            emit EveryoneLosses();
            for (uint i;i<people_count;i++) 
                if (people[i].amount > 0) 
                    delete people[i];
            delete people_count;
            delete block_closed;
            voting_in_progress = true;
            return;
        }

        _result &= 0xf;
        emit RevealResult(_result);

        uint _money_to_give;
        uint _winners_count = 1;
        for (uint i;i<people_count;i++) {
            if (people[i].decision == _result) {
                _money_to_give += people[i].amount;
                delete people[i];
            } else if (people[i].amount > 0) {
                _winners_count ++;
            }
        }
        _money_to_give -= _money_to_give%_winners_count;
        uint _qty = _money_to_give/_winners_count;
        for (uint i;i<people_count;i++) {
            if (people[i].amount > 0) {
                people[i].voter.transfer(_qty+people[i].amount);
                delete people[i];
            }
        }
        delete people_count;
        delete block_closed;
        voting_in_progress = true;
    }
    
    
    function get_voting_balance() public view returns(uint _val){
        _val = 0;
        for (uint i;i<people_count;i++) {
            _val += people[i].amount;
        }
    }

    function get_number_votes() public view returns(uint _val){
        _val = 0;
        for (uint i;i<people_count;i++) {
            if (people[i].amount>0) {
                _val ++;
            }
        }
    }
 
    function destroy_contract() public isOwner{
        selfdestruct(owner);
    }
}