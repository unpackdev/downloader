/*
just for testing installer and interface

900-
*/

pragma solidity ^0.6.6;


// just for testing interface
contract Token {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    uint8 public constant decimals = 18;
    string public name;
    string public symbol;
    mapping(address => uint256) public refDividendsOf;

    event Send(address indexed _sender, uint256 _value);

    constructor(string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
    }

    function sell(uint256 _tokens) external {
        balanceOf[msg.sender] -= _tokens;
        totalSupply -= _tokens;
        emit Send(msg.sender, _tokens);
    }

    /// @notice withdraws all
    function withdraw() external {
        msg.sender.transfer(address(this).balance);
        emit Send(msg.sender, 0);
    }

    /// "some comments";/
    function reinvest() external {
        totalSupply -= balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        refDividendsOf[msg.sender] = 0;
        emit Send(msg.sender, 0);
    }

    function buy(address _ref) public payable {
        balanceOf[msg.sender] += msg.value;
        totalSupply += msg.value;
        emit Send(msg.sender, msg.value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        refDividendsOf[msg.sender] += _value;
        emit Send(msg.sender, _value);
        return true;
    }

    function dividendsOf(address _owner) public view returns (uint256) {
        return refDividendsOf[_owner] * 100;
    }
}