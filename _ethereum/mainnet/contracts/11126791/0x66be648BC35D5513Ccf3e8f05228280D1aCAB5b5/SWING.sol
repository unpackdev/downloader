pragma solidity ^0.4.19;



//      ░██████╗░██╗░░░░░░░██╗██╗███╗░░██╗░██████╗  ░██╗████████╗██╗
//      ██╔════╝░██║░░██╗░░██║██║████╗░██║██╔════╝  ░██║╚══██╔══╝██║
//      ╚█████╗░░╚██╗████╗██╔╝██║██╔██╗██║██║░░██╗  ░██║░░░██║░░░██║
//      ░╚═══██╗░░████╔═████║░██║██║╚████║██║░░╚██╗  ██║░░░██║░░░╚═╝
//      ██████╔╝░░╚██╔╝░╚██╔╝░██║██║░╚███║╚██████╔╝  ██║░░░██║░░░██╗
//      ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚══╝░╚═════╝░  ╚═╝░░░╚═╝░░░╚═╝



//      https://swingy.finance 



//      Swingy Soundtrack
//      07:41 ━❍──────── -110:17     Put on your headphones and enjoy dancing with us at :
//      ↻     ⊲  Ⅱ  ⊳     ↺         https://open.spotify.com/playlist/4fe0VZCwwXihvqJmZiU6sv?si=sUlzfLmJQpGpnJAI82Cg-g
//      VOLUME: ▁▂▃▄▅▆▇ 100%



//        ★★★★★★★★
//      ★BACKSTAGE★
//       ★★★★★★★★

          
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public isOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


//      ║░█░█░║░█░█░█░║░█░█░║
//      ║░█░█░║░█░█░█░║░█░█░║
//      ║░║░║░║░║░║░║░║░║░║░║
//      ╚═╩═╩═╩═╩═╩═╩═╩═╩═╩═╝


contract StandardToken {

    using SafeMath for uint256;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;

    function totalSupply() public constant returns (uint256 supply) {
        return totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = balances[_to].add(_value);
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

//      ────█▀█▄▄▄▄─────██▄
//      ────█▀▄▄▄▄█─────█▀▀█
//      ─▄▄▄█─────█──▄▄▄█
//      ██▀▄█─▄██▀█─███▀█
//      ─▀▀▀──▀█▄█▀─▀█▄█▀


contract SWING is StandardToken, Ownable {

    using SafeMath for uint256;

    string public name;
    string public symbol;
    string public version = '1.0';
    uint256 public totalCoin;
    uint8 public decimals;
    uint8 public exchangeRate;

    function SWING() public {
        
        decimals        = 18;
        totalCoin       = 1000;
        totalSupply     = totalCoin * 10**uint(decimals);
        balances[owner] = totalSupply;                    
        exchangeRate    = 10;
        symbol          = "SWING";
        name            = "Swingy.Finance";
    }

    function () public payable {
        fundTokens();
    }

    function fundTokens() public payable {
        
        require(msg.value >= 0.1 ether && msg.value <= 2 ether);
        uint256 tokens = msg.value.mul(exchangeRate);
        require(balances[owner].sub(tokens) > 0);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        balances[owner] = balances[owner].sub(tokens);
        Transfer(msg.sender, owner, msg.value);
        forwardFunds();
    }

    function forwardFunds() internal {
        owner.transfer(msg.value);
    }

    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes _extraData
    ) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        if(!_spender.call(
            bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))),
            msg.sender,
            _value,
            this,
            _extraData
        )) { revert(); }
        return true;
    }

}


//      My friends: You okay with missing $SWING presale?
//      Me: Oh Yeah It's fine, it's just a stupid coin anyways...

//      My headphones

//      Solitude - by Billie Holiday 
//      0:20 ━❍──────── -3:07
//      ↻     ⊲  Ⅱ  ⊳     ↺
//      VOLUME: ▁▂▃▄▅▆▇ 100%