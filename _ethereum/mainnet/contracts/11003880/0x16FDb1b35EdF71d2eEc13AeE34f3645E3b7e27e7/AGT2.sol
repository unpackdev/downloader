pragma solidity 0.5.17;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) 
            return 0;
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }

}

contract ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 internal _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        if(_allowed[from][msg.sender] != uint256(-1))
            _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

}

contract ERC20Mintable is ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    function _mint(address to, uint256 amount) internal {
        _balances[to] = _balances[to].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        _balances[from] = _balances[from].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(from, address(0), amount);
    }
}



contract AGT2 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;
    mapping(address => uint256) public mask;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 internal constant _totalSupply = 100000000e18;
    uint256 public dividend;

    string public constant name = "ANGEL Token2";
    string public constant symbol = "AGT2";
    uint8 public constant decimals = 18;

    ERC20 token = ERC20(0xF6C5FcA9cA34C4b23045EFfFA576716Ff70542C1);
    address bank = address(0x84E8905aaD8cFA7f830a024AD274AD3F7CEc1C12);

    constructor() public {
        _balances[msg.sender] = _totalSupply;
    }

    function distribute(uint256 amount) external {
        require (msg.sender == bank);
        dividend = dividend.add( amount.mul(1e18).div(_totalSupply) );
    }

    function update(address holder) public {
        uint256 diff = dividend.sub(mask[holder]);
        mask[holder] = dividend;
        if(diff > 0)
            token.transfer(holder, diff.mul(_balances[holder].div(1e18)));
    }

    function totalSupply() public pure returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        if(_allowed[from][msg.sender] != uint256(-1))
            _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        update(from);
        update(to);
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
}

contract EGTBank {
    using SafeMath for *;

    struct Order {
        uint256 amount;
        uint256 startD;
        uint256 last;
    }

    ERC20 token = ERC20(0xF6C5FcA9cA34C4b23045EFfFA576716Ff70542C1);

    AGT2 angel = AGT2(0x16FDb1b35EdF71d2eEc13AeE34f3645E3b7e27e7);

    mapping(address => uint256) public count;
    mapping(address => mapping(uint256 => Order)) public Orders;

    function getRate(uint256 day) public pure returns (uint256 rate) {
        if(day < 201)
            rate = (0.005e18).mul(day);
        else if(day < 451)
            rate = (0.004e18).mul(day).add(0.2e18);
        else if(day < 763)
            rate = (0.0032e18).mul(day).add(0.56e18);
        else
            rate = 3e18;
    }

    function invest(address to, uint256 amount) public {
        require(amount >= 1000e18 && amount <= 30000e18);
        uint256 index = count[to];
        count[to] += 1;
        Order storage order = Orders[to][index];
        order.amount = amount;
        order.startD = now / 1 days + 1;
        order.last = now / 1 days + 1;

        require(token.transferFrom(msg.sender, address(this), amount));
        require(token.transferFrom(msg.sender, address(angel), amount/100));
        angel.distribute(amount/100);
    }

    function claim(uint256 index) public {
        Order storage order = Orders[msg.sender][index];
        uint256 today = now / 1 days;
        require(today > order.last);
        uint256 amount = order.amount.mul(getRate(today.sub(order.startD)).sub(getRate(order.last.sub(order.startD)))) / 1e18;
        order.last = today;
        if(amount > 0) {
            require(token.transferFrom(msg.sender, address(angel), amount/100));
            require(token.transfer(msg.sender, amount));
            angel.distribute(amount/100);
        }
    }
}