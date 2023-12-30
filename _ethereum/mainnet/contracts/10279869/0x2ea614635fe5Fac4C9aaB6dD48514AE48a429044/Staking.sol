pragma solidity ^0.5.7;

contract Token {
    mapping (address => uint256) public balanceOf;
    function transfer(address _to, uint256 _value) public;
    function transferFrom(address _from, address _to, uint256 _value) public;
    function approve(address _spender, uint256 _value) public;
    function approveContract(address _spender, uint256 _value) public;
    function createTokens(address _user, uint _tokens) external;
}

contract Staking  {

    address owner;
    address token;
    bool iniziali = false;
    uint256 public minimalToken = 100000000000000000000;

    struct stakingStruct {
        bool isExist;
        bool status;
        uint256 tokens;
        uint256 profit;
        uint start;
        uint finish;
    }
    
    mapping(address => uint) public stakingCount;
    mapping(address => mapping (uint => stakingStruct)) public stakings;
    
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(owner == msg.sender, "Only Owner");
        _;
    }

    function setAddrToken(address _addr) external onlyOwner {
        token = _addr;
    }

    function calculate(address _user, uint _id) public view returns (uint256) {
        uint _seconds = ((now - stakings[_user][_id].start) / 86400);
        uint256 _days = uint256(_seconds);
        uint256 _profit = (stakings[_user][_id].tokens * 260000000000000000 / 100000000000000000000) * _days;
        if(_profit > 0){
            return _profit;
        } else {
            return 0;
        }
    }

    function depositToken(uint256 amount) public {
        require(amount >= minimalToken, "Please enter a valid amount of tokens.");
        require(Token(token).balanceOf(msg.sender) >= amount, "You don't have the amount of tokens.");
        Token(token).approveContract(address(this), amount);
        Token(token).transferFrom(msg.sender, address(this), amount);
        stakingStruct memory staking_struct;
        staking_struct = stakingStruct({
            isExist: true,
            status: true,
            tokens: amount,
            profit: 0,
            start: now,            
            finish: 0
        });
        stakings[msg.sender][stakingCount[msg.sender]] = staking_struct;
        stakingCount[msg.sender]++;
        emit eventDeposit(msg.sender, amount, now);
    }

    function withdrawToken(uint _id) public {
        require(stakings[msg.sender][_id].isExist, "Staking not exists.");
        require(stakings[msg.sender][_id].status, "It was already withdrawn.");
        uint256 _profit = calculate(msg.sender, _id);
        require(_profit > 0, "The profit is wrong.");
        Token(token).createTokens(msg.sender, (_profit/600));
        Token(token).transfer(msg.sender, stakings[msg.sender][_id].tokens);
        stakings[msg.sender][_id].status = false;
        stakings[msg.sender][_id].profit = _profit;
        stakings[msg.sender][_id].finish = now;
        emit eventWithdraw(msg.sender, _id, stakings[msg.sender][_id].tokens, stakings[msg.sender][_id].profit, now);
    }

    event eventDeposit(address indexed _user, uint256 _tokens, uint256 _time);
    event eventWithdraw(address indexed _user, uint indexed _id, uint256 _tokens, uint256 _profit, uint256 _time);

}