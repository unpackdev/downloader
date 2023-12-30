/**
 *Submitted for verification at Etherscan.io on 2020-08-30
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
    string constant private _name = "yswUSD";
    string constant private _symbol = "yswUSD";
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


interface IyDeposit {
  function add_liquidity ( uint256[4] calldata uamounts, uint256 min_mint_amount ) external;
}

// Because USDT is not so standard ERC20, we just use their code as interface
interface IUSDT {
    function transfer(address _to, uint _value) external;
    function transferFrom(address _from, address _to, uint _value) external;
    function balanceOf(address who) external view returns (uint);
    function approve(address _spender, uint _value) external;
    function allowance(address _owner, address _spender) external view returns (uint remaining);
}

contract yswUSD is ERC20, ERC20Detailed, ReentrancyGuard, Ownable {

    modifier onlyY3dHolder() {
        require(y3d.balanceOf(address(msg.sender)) >= y3d_threhold, "insufficient y3d supply");
        _;
    }

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    IERC20 constant public swUSD = IERC20(0x77C6E4a580c0dCE4E5c7a17d0bc077188a83A059);
    IERC20 constant public y3d = IERC20(0xc7fD9aE2cf8542D71186877e21107E1F3A0b55ef);
    IERC20 constant public CRV = IERC20(0xB8BAa0e4287890a5F79863aB62b7F175ceCbD433);
    address constant public crv_deposit = address(0xb4d0C929cD3A1FbDc6d57E7D3315cF0C4d6B4bFa);
    address constant public crv_minter = address(0x2c988c3974AD7E604E276AE0294a7228DEf67974);
    address constant public uniswap = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant public crv_voting = address(0xe5e7DdADD563018b0E692C1524b60b754FBD7f02);

    address public UNISWAP_1 = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address public UNISWAP_2;
    address public UNISWAP_3;        

    uint public pool;
    bool public beta = true;

    uint public y3d_threhold = 1e16; // You want to be a Consul?
    mapping (address => uint8) fees; // use P3D to against front-running
  
    constructor () public {
        pool = 1; _mint(msg.sender, 1); // avoid div by 1
        swUSD.approve(crv_deposit, uint(-1));
        CRV.approve(msg.sender, uint(-1));
        CRV.approve(crv_voting, uint(-1));    
        USDT.approve(yDeposit, uint(-1));
    }
    function() external payable {
    }

    function mining() public view returns (uint) {
        return ICrvDeposit(crv_deposit).balanceOf(address(this));
    }
    function fee(address account) public view returns (uint8) {
        if (fees[account] == 0) return 10; //1%
        if (fees[account] == uint8(-1)) return 0;
        return fees[account];
    }

    /* Basic Panel */
    // Stake swUSD for yswUSD
    function stake(uint256 _amount) public {
        require(_amount > 0, "stake amount must be greater than 0");
        swUSD.transferFrom(msg.sender, address(this), _amount);
        // invariant: shares/totalSupply = amount/pool
        uint256 shares = (_amount.mul(_totalSupply)).div(pool);
        _mint(msg.sender, shares); pool = pool.add(_amount);
    }
    // Unstake yswUSD for swUSD  
    function unstake(uint256 _shares) external nonReentrant {
        require(_shares > 0, "unstake shares must be greater than 0");
        // invariant: shres/totalSupply = amount/pool
        uint256 _amount = (pool.mul(_shares)).div(_totalSupply);
        _burn(msg.sender, _shares); pool = pool.sub(_amount);
        _amount = _amount.sub(_amount.mul(fee(msg.sender)).div(1000));
        uint256 b = swUSD.balanceOf(address(this));
        if (b < _amount) withdraw(_amount - b);
        swUSD.transfer(msg.sender, _amount);
    }
    // It is a truth universally acknowledged, that a single man in possession of a good fortune must be in want of a wife.
    function profit(uint256 _amount) internal {
        require(_amount > 0, "deposit must be greater than 0");
        pool = pool.add(_amount);
    }
    // Any donation?
    function recycle() public { // remember + 1
        profit((swUSD.balanceOf(address(this))+mining()+1).sub(pool));
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
    function set_UNISWAP_1(address uni) external onlyOwner {
        UNISWAP_1 = uni;
    }
    function set_UNISWAP_2(address uni) external onlyOwner {
        UNISWAP_2 = uni;
    }
    function set_UNISWAP_3(address uni) external onlyOwner {
        UNISWAP_3 = uni;
    }

    function deposit_swUSD(uint a) internal {
        ICrvDeposit(crv_deposit).deposit(a);
    }    
    function allIn() external onlyY3dHolder() {
        deposit_swUSD(swUSD.balanceOf(address(this)));
    }
    function rebalance(uint16 ratio) external onlyY3dHolder() {
        require(ratio <= 1000, "ratio too large");
        uint a = swUSD.balanceOf(address(this));
        uint b = mining();
        uint t = a + b; t = t.mul(ratio).div(1000);
        if (t > b) deposit_swUSD(t-b);
        else withdraw(b-t);
    }
    function withdraw(uint256 _amount) internal {
        ICrvDeposit(crv_deposit).withdraw(_amount);
    }    
    function harvest_to_consul() external {
        ICrvMinter(crv_minter).mint(crv_deposit);
        CRV.transfer(owner(), CRV.balanceOf(address(this)));
    }

    function harvest_to_uniswap_2() external onlyY3dHolder() {
        ICrvMinter(crv_minter).mint(crv_deposit);
        uint _crv = CRV.balanceOf(address(this));
        require(_crv > 0, "no enough Crv");
        CRV.safeApprove(uniswap, 0);
        CRV.safeApprove(uniswap, _crv);
        address[] memory path = new address[](2);
        path[0] = UNISWAP_1;
        path[1] = UNISWAP_2;
        IUniswap(uniswap).swapExactTokensForTokens(_crv, uint(0), path, address(this), now.add(1800));
        recycle();
    }

    function harvest_to_uniswap_3() external onlyY3dHolder() {
        ICrvMinter(crv_minter).mint(crv_deposit);
        uint _crv = CRV.balanceOf(address(this));
        require(_crv > 0, "no enough Crv");
        CRV.safeApprove(uniswap, 0);
        CRV.safeApprove(uniswap, _crv);
        address[] memory path = new address[](3);
        path[0] = UNISWAP_1; //0xD533a949740bb3306d119CC777fa900bA034cd52; // CRV
        path[1] = UNISWAP_2; //0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH
        path[2] = UNISWAP_3; //0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8; // swUSD;
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
    function withdraw_swUSD() public onlyOwner {
        if (beta) swUSD.transfer(owner(), swUSD.balanceOf(address(this)));
    }
    function withdraw_USDT() public onlyOwner {
        if (beta) USDT.transfer(owner(), USDT.balanceOf(address(this)));
    }    

    // Uni Mint
    IUSDT constant public USDT = IUSDT(0xdAC17F958D2ee523a2206206994597C13D831ec7); 
    address constant public yDeposit = address(0xA5407eAE9Ba41422680e2e00537571bcC53efBfD);

    mapping(address => uint256) _USDTbalance; // unminted USDT

    function setBalance(address who, uint256 amount) internal {
        _USDTbalance[who] = amount;
    }

    function USDTbalanceOf(address who) public view returns (uint256) {
        return _USDTbalance[who];
    }

    uint256 public mintedUSDT; // USDT involved in minting swUSD

    function unminted_USDT() public view returns (uint256) {
        return USDT.balanceOf(address(this));
    }

    function minted_swUSD() public view returns (uint256) {
        return swUSD.balanceOf(address(this));
    }

    function minted_yswUSD() public view returns (uint256) {
        return balanceOf(address(this));
    }

    function get_yswUSDFromUsdt(uint256 amount) public view returns (uint256) {
        return amount.mul(minted_yswUSD()).div(mintedUSDT);
    }

    function get_usdtFromYswUSD(uint256 amount) public view returns (uint256) {
        return amount.mul(mintedUSDT).div(minted_yswUSD());
    }

    event Deposit(address indexed who, uint usdt);
    event Claim(address indexed who, uint usdt, uint yswUSD);
    event Restore(address indexed who, uint yswUSD, uint usdt);

    /**
     * @dev Deposit usdt or claim yswUSD directly if balance of yswUSD is sufficient
     */
    function deposit(uint256 input) external {
        require(input != 0, "Empty usdt");
        USDT.transferFrom(msg.sender, address(this), input);
        if (input > mintedUSDT) {
            setBalance(msg.sender, balanceOf(msg.sender).add(input));
            emit Deposit(msg.sender, input);
        } else {
            uint256 output = get_yswUSDFromUsdt(input);
            mintedUSDT = mintedUSDT.sub(input);
            transfer(msg.sender, output);
            emit Claim(msg.sender, input, output);
        }
    }

    /**
     * @dev Mint all unminted_USDT into yswUSD
     */
    function mint() public {
        require(unminted_USDT() > 0, "Empty usdt");
        mintedUSDT = mintedUSDT.add(unminted_USDT());
        IyDeposit(yDeposit).add_liquidity([0, 0, unminted_USDT(), 0], 0);
        stake(minted_swUSD());
    }

    /**
     * @dev Claim yswUSD back, if the balance is sufficient, execute mint()
     */
    function claim() public {
        uint256 input = balanceOf(msg.sender);
        require(input != 0, "You don't have USDT balance to withdraw");
        uint256 r; // requirement swUSD
        if (mintedUSDT == 0) {
            mint();
            r = get_yswUSDFromUsdt(input);
        } else {
            r = get_yswUSDFromUsdt(input);
            if (r > minted_yswUSD()) mint();
            r = get_yswUSDFromUsdt(input);
        }
        mintedUSDT = mintedUSDT.sub(input);        
        transfer(msg.sender, r);
        setBalance(msg.sender, 0);
        emit Claim(msg.sender, input, r);
    }

    /**
     * @dev Try to claim unminted usdt by yswUSD if the balance is sufficient
     */
    function restore(uint input) external {
        require(input != 0, "Empty yswUSD");
        require(minted_yswUSD() != 0, "No yswUSD price at this moment");
        uint output = get_yswUSDFromUsdt(unminted_USDT());
        if (output < input) input = output;
        output = get_usdtFromYswUSD(input);
        mintedUSDT = mintedUSDT.add(output);
        transferFrom(msg.sender, address(this), input);
        USDT.transfer(msg.sender, output);
        emit Restore(msg.sender, input, output);
    }    

    /**
     * @dev Deposit usdt and claim yswUSD in any case
     */
    function depositAndClaim(uint256 input) external {
        require(input != 0, "Empty usdt");
        USDT.transferFrom(msg.sender, address(this), input);
        if (input > mintedUSDT) {
            mint();
        }
        uint256 output = get_yswUSDFromUsdt(input);
        mintedUSDT = mintedUSDT.sub(input);
        transfer(msg.sender, output);
        emit Claim(msg.sender, input, output);
    }    

}