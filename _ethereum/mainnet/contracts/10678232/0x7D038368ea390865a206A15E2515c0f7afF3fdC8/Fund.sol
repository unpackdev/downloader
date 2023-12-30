pragma solidity ^0.5.14;


contract Etherbank_Interface {
    function getUserStatusReferrers(address _user, uint _now) public view returns (bool);
}

contract Fund {

    address public owner;
    address public developers;
    address public payments;
    address public etherbank;
    uint public priceAction = 50000000000000000;
    uint public finishedCount = 100;
    uint public lastRound;
    uint public earnings;

    struct RoundStruct {
        bool isExist;
        bool turn;
        uint id;
        uint start;
        uint finish;
        uint totalParticipants;
        uint amount;
    }
    mapping(uint => RoundStruct) public Rounds;
    mapping(uint => mapping (uint => address)) public RoundsParticipants;


    modifier onlyOwner{
        require(owner == msg.sender, "Only owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setAddrDevelopers(address payable _addr) external onlyOwner {
        developers = _addr;
    }

    function setAddrEtherBank(address payable _addr) external onlyOwner {
        etherbank = _addr;
    }

    function setAddrPayments(address payable _addr) external onlyOwner {
        payments = _addr;
    }

    function () external payable {}

    function checkTurns() public view returns(uint){
        uint x = 0;
        for(uint i = 0; i<=Rounds[lastRound].totalParticipants; i++){
            if( RoundsParticipants[lastRound][i] == msg.sender ){
                x++;
            }
        }
        return x;
    }

    function Game(uint _turns) external payable {
        require((_turns * priceAction) == msg.value, "The quantity sent is not correct");
        require(Rounds[lastRound].turn == false, "The voting is over");
        require(_turns <= 5, "You can only vote 5 turns");
        require((checkTurns() + _turns) <= 5, "You can only vote 5 turns");
        require((_turns + Rounds[lastRound].totalParticipants) <= finishedCount, "Only 100 total turns");
        require(Etherbank_Interface(etherbank).getUserStatusReferrers(msg.sender, now) == true, "Registered users only");
        if( Rounds[lastRound].isExist == false ){
            RoundStruct memory round_struct;
            round_struct = RoundStruct({
                isExist: true,
                turn: false,
                id: lastRound,
                start: now,
                finish: 0,
                totalParticipants: 0,
                amount: 0
            });
            Rounds[lastRound] = round_struct;
        }
        for(uint i = 1; i<=_turns; i++){
            RoundsParticipants[lastRound][Rounds[lastRound].totalParticipants] = msg.sender;
            Rounds[lastRound].totalParticipants++;
        }
        emit eventGame(msg.sender, _turns, lastRound);
        if( Rounds[lastRound].totalParticipants >= (finishedCount) ){
            Rounds[lastRound].turn = true;
            finishTurns();
        }
    }

    function finishGame() external onlyOwner {
        finishTurns();
    }

    function finishTurns() private {
        require(Rounds[lastRound].turn == true, "The voting is over");
        if( Rounds[lastRound].totalParticipants >= (finishedCount) ){
            finishedGame();
            Rounds[lastRound].finish = now;
            lastRound++;
        }
    }

    function randomness(uint nonce) public view returns (uint) {
        return uint(uint(keccak256(abi.encode(block.timestamp, block.difficulty, nonce)))%(Rounds[lastRound].totalParticipants+1));
    }

    function getPercentage(uint x) private pure returns (uint){
        if(x == 1){return 20;}
        else if(x == 2){return 15;}
        else if(x == 3){return 10;}
        else if(x == 4){return 5;}
        else if(x == 5){return 4;}
        else if(x == 6){return 3;}
        else {return 2;}
    }

    function sendEth(address _user, uint _amount, uint _x) private {
        if( _amount > 0 && _user != address(0)){
            address(uint160(_user)).transfer(_amount);
            emit eventWinner(_user, lastRound, _amount, _x);
        }
    }

    function sendBalanceDeveloper() private {
        if( address(this).balance > 0){
            address(uint160(developers)).transfer(address(this).balance);
        }
    }

    function sendBalancePayments() private {
        if( address(this).balance > 0){
            uint amount = address(this).balance * 5 / 100;
            address(uint160(payments)).transfer(amount);
        }
    }

    function finishedGame() private {
        uint count = 0;
        uint x = 1;
        uint balance = address(this).balance;
        earnings += balance;
        Rounds[lastRound].amount = balance;
        sendBalancePayments();
        while(x <= 20){
            count++;
            address _userCheck = RoundsParticipants[lastRound][randomness(count)];
            uint percentage = getPercentage(x);
            uint amount = balance * percentage / 100;
            sendEth(_userCheck, amount, x);
            x++;
        }
        sendBalanceDeveloper();
    }

    event eventWinner(address indexed _user, uint indexed _game, uint _amount, uint indexed _level);
    event eventGame(address indexed _user, uint _turns, uint indexed _game);

}