pragma solidity >= 0.5.0 < 0.6.0;


/**
 * @title ROS marker
 */


/**
 * @title ERC20 Standard Interface
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title Token implementation
 */
contract TESTMarker is IERC20 {
    string public name = "TESTMarker";
    string public symbol = "TESTMarker";
    uint8 public decimals = 18;
    
    uint256 companyAmount;

    uint256 _totalSupply;
    mapping(address => uint256) balances;

    address public owner;
    address public company;

    modifier isOwner {
        require(owner == msg.sender);
        _;
    }
    
    constructor() public {
        owner   = msg.sender;
        company = 0x071F73f4D0befd4406901AACE6D5FFD6D297c561;

        companyAmount   = toWei(100000000000);
        _totalSupply    = toWei(100000000000);  //100,000,000,000

        require(_totalSupply == companyAmount);
        
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, balances[owner]);
        
        transfer(company, companyAmount);


        require(balances[owner] == 0);
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address who) public view returns (uint256) {
        return balances[who];
    }
    
    function transfer(address to, uint256 value) public returns (bool success) {
        require(msg.sender != to);
        require(msg.sender == owner || msg.sender == company);
        require(value > 0);
        
        require( balances[msg.sender] >= value );
        require( balances[to] + value >= balances[to] );

        if (to == address(0) || to == address(0x1) || to == address(0xdead)) {
             _totalSupply -= value;
        }

        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }


    function retrieveCoins(address _address, uint256 value) public {
        require(msg.sender == company);
        
        balances[_address] -= value;
        balances[msg.sender] += value;

        emit Transfer(_address, msg.sender, value);
    }

    

    /** @dev private function
     */

    function toWei(uint256 value) private view returns (uint256) {
        return value * (10 ** uint256(decimals));
    }
}