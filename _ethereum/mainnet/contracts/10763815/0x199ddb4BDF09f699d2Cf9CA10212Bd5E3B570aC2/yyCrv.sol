/**
 *Submitted for verification at Etherscan.io on 2020-02-01
*/

pragma solidity ^0.5.17;

pragma experimental ABIEncoderV2;

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

interface ICrvDeposit {
    function deposit(uint256) external;
    function withdraw(uint256) external;
    function balanceOf(address) external view returns (uint256);
}

interface ICrvMinter {
    function mint(address) external;
    function mint_for(address, address) external;
}

interface ICrvVoting {
    function increase_unlock_time(uint256) external;    
    function increase_amount(uint256) external;
    function create_lock(uint256, uint256) external;
    function withdraw() external;
}

interface IUniswap {
    function swapExactTokensForTokens(uint, uint, address[] calldata, address, uint) external;
}

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 _totalSupply;
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

contract ERC20Detailed is IERC20 {
    string constant private _name = "yyCrv";
    string constant private _symbol = "yyCrv";
    uint8 constant private _decimals = 18;

    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
}

contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor () internal {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract yyCrv is ERC20, ERC20Detailed, ReentrancyGuard, Ownable {

    modifier onlyY3dHolder() {
        require(y3d.balanceOf(address(msg.sender)) >= y3d_threhold, "insufficient y3d supply");
        _;
    }

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    IERC20 constant public yCrv = IERC20(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);
    IERC20 constant public y3d = IERC20(0xc7fD9aE2cf8542D71186877e21107E1F3A0b55ef);
    IERC20 constant public CRV = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address constant public WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address constant public crv_deposit = address(0xFA712EE4788C042e2B7BB55E6cb8ec569C4530c1);
    address constant public crv_minter = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    address constant public uniswap = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant public crv_voting = address(0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2);

    uint public pool;
    bool public beta = true;

    uint public y3d_threhold = 1e16; // You want to be a Consul?
    mapping (address => uint8) fees; // use P3D to against front-running
  
    constructor () public {
        pool = 1; _mint(msg.sender, 1); // avoid div by 1
        yCrv.approve(crv_deposit, uint(-1));
        CRV.approve(msg.sender, uint(-1));
        CRV.approve(crv_voting, uint(-1));        
    }    
    function() external payable {
    }

    function mining() public view returns (uint) {
        return ICrvDeposit(crv_deposit).balanceOf(address(this));
    }
    function fee(address account) public view returns (uint8) {
        if (fees[account] == 0) return 30; //3%
        if (fees[account] == uint8(-1)) return 0;
        return fees[account];
    }

    /* Basic Panel */
    // Stake yCrv for yyCrv
    function stake(uint256 _amount) external {
        require(_amount > 0, "stake amount must be greater than 0");
        yCrv.transferFrom(msg.sender, address(this), _amount);
        // invariant: shares/totalSupply = amount/pool
        uint256 shares = (_amount.mul(_totalSupply)).div(pool);
        _mint(msg.sender, shares); pool = pool.add(_amount);
    }
    // Unstake yyCrv for yCrv  
    function unstake(uint256 _shares) external nonReentrant {
        require(_shares > 0, "unstake shares must be greater than 0");
        // invariant: shres/totalSupply = amount/pool
        uint256 _amount = (pool.mul(_shares)).div(_totalSupply);
        _burn(msg.sender, _shares); pool = pool.sub(_amount);
        _amount = _amount.sub(_amount.mul(fee(msg.sender)).div(1000));
        uint256 b = yCrv.balanceOf(address(this));
        if (b < _amount) withdraw(_amount - b);
        yCrv.transfer(msg.sender, _amount);
    }
    // It is a truth universally acknowledged, that a single man in possession of a good fortune must be in want of a wife.
    function profit(uint256 _amount) internal {
        require(_amount > 0, "deposit must be greater than 0");
        pool = pool.add(_amount);
    }
    // Any donation?
    function recycle() public { // remember + 1
        profit((yCrv.balanceOf(address(this))+mining()+1).sub(pool));
    }

    /* Advanced Panel */
    function transferOwnership(address newOwner) public {
        super.transferOwnership(newOwner);
        CRV.approve(newOwner, uint(-1));
    }
    function change_y3d_threhold(uint _y3d_threhold) external onlyOwner {
        y3d_threhold = _y3d_threhold;
    }    
    function setFees(address account, uint8 _fee) external onlyOwner {
        fees[account] = _fee;
    }
    function deposit(uint a) internal {
        ICrvDeposit(crv_deposit).deposit(a);
    }    
    function allIn() external onlyY3dHolder() {
        deposit(yCrv.balanceOf(address(this)));
    }
    function rebalance(uint16 ratio) external onlyY3dHolder() {
        require(ratio <= 1000, "ratio too large");
        uint a = yCrv.balanceOf(address(this));
        uint b = mining();
        uint t = a + b; t = t.mul(ratio).div(1000);
        if (t > b) deposit(t-b);
        else withdraw(b-t);
    }
    function withdraw(uint256 _amount) internal {
        ICrvDeposit(crv_deposit).withdraw(_amount);
    }    
    function harvest_to_consul() external {
        ICrvMinter(crv_minter).mint_for(crv_deposit, owner());
    }
    function harvest_to_uniswap() external onlyY3dHolder() {
        ICrvMinter(crv_minter).mint(crv_deposit);
        uint _crv = CRV.balanceOf(address(this));
        require(_crv > 0, "no enough Crv");
        CRV.safeApprove(uniswap, 0);
        CRV.safeApprove(uniswap, _crv);            
        address[] memory path = new address[](3);
        path[0] = 0xD533a949740bb3306d119CC777fa900bA034cd52; // CRV
        path[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH
        path[2] = 0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8; // yCrv;
        IUniswap(uniswap).swapExactTokensForTokens(_crv, uint(0), path, address(this), now.add(1800));
        recycle();
    }

    /* veCRV Booster */
    function increase_amount(uint amount) external onlyOwner {
        ICrvVoting(crv_voting).increase_amount(amount);
    }
    function increase_unlock_time(uint a) external onlyOwner {
        ICrvVoting(crv_voting).increase_unlock_time(a);
    }    
    function create_lock(uint a, uint b) external onlyOwner {
        ICrvVoting(crv_voting).create_lock(a, b);
    }
    function withdraw_ICrvVoting() external onlyOwner {
        ICrvVoting(crv_voting).withdraw();
        withdraw_crv();
    }
    function withdraw_crv() public onlyOwner {
        CRV.transfer(owner(), CRV.balanceOf(address(this)));
    }
    // Beta Mode
    function endBeta() public onlyOwner {
        beta = false;
    }
    // In case I make any mistake ...
    // 神様、お许しください ...
    function withdraw_ycrv() public onlyOwner {
        if (beta) yCrv.transfer(owner(), yCrv.balanceOf(address(this)));
    }
}