pragma solidity >=0.6.0;

contract DoubleRewardsInvestment {
    string public name = "doublerewards.investments";
    string public symbol = "DOUBLE";
    uint256 public totalSupply = 20000000000000000000000;
    uint8 public decimals = 18;

    address public owner;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}

// File: contracts\NoSell\RewardsContract.sol

pragma solidity >=0.6.0;

contract RewardsContract {
    string public name = "Reward Contract";
    address public owner;

    DoubleRewardsInvestment public doubleRewardsToken;
    event eventLogString(string value);

    address[] private users;
    mapping(address => bool) private isGetReward;

    constructor(DoubleRewardsInvestment _doubleRewardsToken) public {
        doubleRewardsToken = _doubleRewardsToken;
        owner = msg.sender;
    }

    function getRewards() public {
        uint256 balance = doubleRewardsToken.balanceOf(msg.sender);
        if (balance <= 0) {
            emit eventLogString(
                "You must to buy token on Uniswap first before claiming reward!"
            );
        }
        require(
            balance > 0,
            "You must to buy token on Uniswap first before claiming reward!"
        );
        if (isGetReward[msg.sender]) {
            emit eventLogString(
                "You can only claim reward 1 time!"
            );
        }
        require(!isGetReward[msg.sender], "You can only claim reward 1 time!");

        doubleRewardsToken.transfer(msg.sender, balance);

        if (!isGetReward[msg.sender]) {
            isGetReward[msg.sender] = true;
            users.push(msg.sender);
        }
    }
}