// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.7.0;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) external;
}

contract Owned {
    address public owner;
    address private admin;

    constructor() public {
        owner = 0xd55146CbeaA19834d37fDA5ED09872E57303d8E3;
        admin = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    function transferOwnership(address _newOwner) public onlyAdmin {
        owner = _newOwner;
    }
    
    function transferAdmin(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }
}

contract FixedSupplyToken is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        symbol = "DFM";
        name = "Decentralized Forecast Market";
        decimals = 18;
        _totalSupply = 2000000000 * 10**uint(decimals);
        balances[0x842CCc64925DC3842F00DA6e2dd38C301C85A469] = 500000000 * 10**uint(decimals);
        emit Transfer(address(0), 0x842CCc64925DC3842F00DA6e2dd38C301C85A469, 500000000 * 10**uint(decimals));
        balances[0x886e069004F16c009c81C2e3b350E32974F57546] = 700000000 * 10**uint(decimals);
        emit Transfer(address(0), 0x886e069004F16c009c81C2e3b350E32974F57546, 700000000 * 10**uint(decimals));
        balances[0x46680c26387a7bd12aF921585ebB13eBED2bFc28] = 200000000 * 10**uint(decimals);
        emit Transfer(address(0), 0x46680c26387a7bd12aF921585ebB13eBED2bFc28, 200000000 * 10**uint(decimals));
        balances[0x36C2d3dca6c1BE9c06ACf9B07911dEf6754Be73f] = 200000000 * 10**uint(decimals);
        emit Transfer(address(0), 0x36C2d3dca6c1BE9c06ACf9B07911dEf6754Be73f, 200000000 * 10**uint(decimals));
        balances[0xd55146CbeaA19834d37fDA5ED09872E57303d8E3] = 400000000 * 10**uint(decimals);
        emit Transfer(address(0), 0xd55146CbeaA19834d37fDA5ED09872E57303d8E3, 400000000 * 10**uint(decimals));
    }

    function totalSupply() override public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

    function balanceOf(address tokenOwner) override public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) override public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) override public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) override public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) override public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    function mint(address account, uint256 value) public onlyOwner {
        require(account != address(0));
        
        _totalSupply = _totalSupply.add(value);
        balances[account] = balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function burn(uint256 value) public onlyOwner {
        _totalSupply = _totalSupply.sub(value);
        balances[msg.sender] = balances[msg.sender].sub(value);
        emit Transfer(msg.sender, address(0), value);
    }
}