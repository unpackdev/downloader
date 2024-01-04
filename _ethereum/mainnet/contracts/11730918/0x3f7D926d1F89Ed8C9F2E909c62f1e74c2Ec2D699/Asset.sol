pragma solidity <=0.5.4;

contract Ownable {

    string public contractName;
    address public owner;
    address public manager;

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
    event ManagerChanged(address indexed previousManager, address indexed newManager);

    constructor() internal {
        owner = msg.sender;
        manager = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyManager(bytes32 managerName) {
        require(msg.sender == manager, "Ownable: caller is not the manager");
        _;
    }


    function setOwner(address _owner) public onlyOwner {
        require(_owner != address(0), "Ownable: new owner is the zero address");
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    function setManager(address _manager) public onlyOwner {
        require(_manager != address(0), "Ownable: new manager is the zero address");
        emit ManagerChanged(manager, _manager);
        manager = _manager;
    }

    function setContractName(bytes32 _contractName) internal {
        contractName = string(abi.encodePacked(_contractName));
    }

}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory concatString) internal pure returns (uint256) {
        require(b <= a, concatString);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory concatString) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, concatString);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory concatString) internal pure returns (uint256) {
        require(b != 0, concatString);
        return a % b;
    }
}


interface IERC20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function transfer(address recipient, uint value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address sender, address recipient, uint value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

}


contract Token is Ownable, IERC20 {

    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint public totalSupply;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    function balanceOf(address account) external view returns (uint) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        uint delta = _allowances[sender][msg.sender].sub(amount, "Token: transfer amount exceeds allowance");
        _approve(sender, msg.sender, delta);
        return true;
    }

    function _approve(address owner, address spender, uint amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        _balances[sender] = _balances[sender].sub(amount, "Token: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint amount) internal {
        totalSupply = totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint amount) internal {
        _balances[account] = _balances[account].sub(amount, "Token: burn amount exceeds balance");
        totalSupply = totalSupply.sub(amount, "Token: burn amount exceeds totalSupply");
        emit Transfer(account, address(0), amount);
    }

}

interface IAsset {

    function mint(address account, uint amount) external returns (bool);
    function burn(address account, uint amount) external returns (bool);

}


contract Asset is Token, IAsset {

    function initialize(string memory _name, string memory _symbol, address _manager) public onlyOwner {
        name = _name;
        symbol = _symbol;
        contractName = _symbol;
        setManager(_manager);
    }

    function mint(address account, uint amount) external onlyManager("ISSUER") returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(address account, uint amount) external onlyManager("ISSUER") returns (bool) {
        _burn(account, amount);
        return true;
    }

}