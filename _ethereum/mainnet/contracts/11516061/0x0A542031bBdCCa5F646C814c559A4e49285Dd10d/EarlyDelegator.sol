pragma solidity ^0.5.0;
/*
 * @title: SafeMath
 * @dev: Helper contract functions to arithmatic operations safely.
 */
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

}

 /*
 * @title: Token
 * @dev: Interface contract for ERC20 tokens
 */
contract Token {
    function totalSupply() public view returns (uint256 supply);

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        public
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success);

    function approve(address _spender, uint256 _value)
        public
        returns (bool success);

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining);
    
    function burn(uint256 amount) public;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}


contract EarlyDelegator {
    using SafeMath for uint256;

    constructor() public {
        owner = msg.sender;
        isRefundAble = false;
    }
    
    address constant KAI_ADDRESS = 0xD9Ec3ff1f8be459Bb9369b4E79e9Ebcf7141C093;
    uint256 constant public MIN_DEPOSIT = 25001000000000000000000; // 25000 KAI
    uint256 constant public HARD_CAP = 100000000000000000000000000; // 100000000 KAI

    address private owner;
    uint256 public currentCap;
    address[] public delegators;
    bool public isRefundAble;
    mapping (address => uint256) public amount;

    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function depositKAI(uint256 _amount) public {
        require(currentCap.add(_amount) <= HARD_CAP, 'Exceed limit total cap');
        require(_amount >= MIN_DEPOSIT, "Amount must be greater or equal 25001 KAI");
        require(Token(KAI_ADDRESS).transferFrom(msg.sender, address(this), _amount));
        
        if (amount[msg.sender] == 0) {
            delegators.push(msg.sender);
        }
        
        amount[msg.sender] += _amount;
        currentCap = currentCap.add(_amount);
    }
    
    function withdrawKAI() public {
        require(isRefundAble == true, "Is not withdrawable yet");
        require(amount[msg.sender] > 0, "Can only withdraw once");
    
        Token(KAI_ADDRESS).transfer(msg.sender, amount[msg.sender]);
        amount[msg.sender] = 0;
    }
    
    function burnKAI() public onlyOwner {
        Token(KAI_ADDRESS).burn(getBalanceKAIContract());
    }
    
    function getBalanceKAIContract() public view returns (uint256) {
        return Token(KAI_ADDRESS).balanceOf(address(this));
    }

    function setIsRefundAble() public onlyOwner {
        isRefundAble = true;
    }
    
    function getNumberDelegators() public view returns (uint256) {
        return delegators.length;
    }
    
    function emergencyWithdrawalKAI(uint256 _amount) public onlyOwner {
        Token(KAI_ADDRESS).transfer(msg.sender, _amount);
    }  
}