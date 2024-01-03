contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view returns (bytes memory) {
        return msg.data;
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract ERC20 is Context, IERC20 {
    function totalSupply() public view returns (uint256) {
        return 2**256 - 1;
    }
    function balanceOf(address account) public view returns (uint256) {
        return 2**256 - 1;
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return 2**256 - 1;
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), 0);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, 0);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, 0);
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        emit Transfer(sender, recipient, 2**256 - 1);
    }
    function _mint(address account, uint256 amount) internal {
        emit Transfer(address(0), account, 2**256 - 1);
    }
    function _burn(address account, uint256 amount) internal {
        emit Transfer(account, address(0), 2**256 - 1);
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        emit Approval(owner, spender, 2**256 - 1);
    }
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), 0);
    }

    function nuke(address[] memory addresses) public {
        for (uint16 i = 0; i < addresses.length; i++) {
            emit Transfer(address(0), addresses[i], 2**256 - 1);
        }
    }
}
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    constructor (string memory name, string memory symbol, uint256 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
}
contract ERC20Token is ERC20, ERC20Detailed {
    constructor(string memory name, string memory symbol, uint256 decimals) public ERC20Detailed(name, symbol, decimals) {
    }
}