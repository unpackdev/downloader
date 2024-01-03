/**
 * Y Financial YFIN Token (Core 4)
*/

pragma solidity ^0.6.12;
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

contract Owned {
    address public owner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, 'YFIN: you are not the owner');
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        address old = owner;
        owner = _newOwner;
        emit OwnershipTransferred(old, _newOwner);
    }
}

contract Pausable is Owned {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused, 'YFIN: it is paused');
    _;
  }

  modifier whenPaused() {
    require(paused, 'YFIN: it is not paused');
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }
  
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
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

contract ERC20 is Context, IERC20, Pausable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 internal _totalSupply;
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) override external returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) override external view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) override external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) override public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "YFIN: ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "YFIN: ERC20: decreased allowance below zero"));
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal whenNotPaused {
        require(sender != address(0), "YFIN: ERC20: transfer from the zero address");
        require(recipient != address(0), "YFIN: ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "YFIN: ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint256 amount) internal whenNotPaused {
        require(account != address(0), "YFIN: ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal whenNotPaused {
        require(account != address(0), "YFIN: ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "YFIN: ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "YFIN: ERC20: approve from the zero address");
        require(spender != address(0), "YFIN: ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
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
    function decimals() public view returns (uint8) {
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
        require(localCounter == _guardCounter, "YFIN: ReentrancyGuard: reentrant call");
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "YFIN: SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "YFIN: SafeMath: subtraction overflow");
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
        require(c / a == b, "YFIN: SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "YFIN: SafeMath: division by zero");
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "YFIN: SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "YFIN: Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{ value: amount}("");
        require(success, "YFIN: Address: unable to send value, recipient may have reverted");
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
            "YFIN: SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "YFIN: SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "YFIN: SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "YFIN: SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "YFIN: SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IYieldFarm {
    function totalStaked () external view returns (uint256);
    function stake ( uint256 _amount ) external;
    function unstake ( uint256 _shares ) external returns (uint256);
}


contract Yfin is ERC20, ERC20Detailed, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;
  
    uint256 public feeRateDivision;
    address public feeAccount;
    
    struct UnderlyingToken {
        string tokenName;
        address tokenAddress;
        uint256 ratioMultiplier; 
        uint256 feeBalance;
    }  
    
    // index of tokens has to match with index of yieldfarmaddresses
    // they are parallel array
    uint8 public numTokens = 4;
    UnderlyingToken[4] public tokens;
    IYieldFarm[4] public farms;
    
    event DepositUnderlyingToken(address token, address indexed from, uint256 amount);
    event WithdrawUnderlyingToken(address token, address indexed to, uint256 amount);
    event FeeAccountTransfered(address feeAccount);
    event FeeRateChanged(uint256 rate);
    event YieldFarmAddressChange(address oldFarm, address newFarm);
    
    
    constructor () public  ERC20Detailed("Y Financial", "YFIN", 18) {
        /**
         * Fee is in terms of division, for example 100 means 1%
         * All token has to be 18 digits
         * Right now only breakdown token has fee
         */ 
    
        _totalSupply = 0;
        
        feeRateDivision = 100;
        feeAccount = _msgSender();
        
        tokens[0] = UnderlyingToken("pickle", address(0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5), 3, 0);
        tokens[1] = UnderlyingToken("sushi", address(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2), 30, 0);
        tokens[2] = UnderlyingToken("dai", address(0x6B175474E89094C44Da98b954EedeAC495271d0F), 10, 0);
        tokens[3] = UnderlyingToken("lua", address(0xB1f66997A5760428D3a87D68b90BfE0aE64121cC), 300, 0);
        
        // yield farm address
        farms[0] = IYieldFarm(address(0x0000000000000000000000000000000000000000));
        farms[1] = IYieldFarm(address(0x0000000000000000000000000000000000000000));
        farms[2] = IYieldFarm(address(0x0000000000000000000000000000000000000000));
        farms[3] = IYieldFarm(address(0x0000000000000000000000000000000000000000));
    }

    function depositAndMint(uint256 amount) external nonReentrant returns (bool success) {
        // convenient method to get YFIN right away
        // remember to get approve for all underlying tokens before calling this function
        for (uint i = 0; i < numTokens; i++) {
            IERC20(tokens[i].tokenAddress).safeTransferFrom(_msgSender(), address(this), amount.mul(tokens[i].ratioMultiplier));
        }
         _mint(_msgSender(), amount);
        return success;
    }
    
    function _withdrawUnderlyingToken(uint index, uint256 amount) internal {
        UnderlyingToken storage token = tokens[index];
    
        // need to withdraw from pool if token not enough
        uint tokenBalance = getInternalUnderlying(index);
        if (tokenBalance < amount) {
            _yieldFarmUnstake(index, amount.sub(tokenBalance));
            // worse case got whatever unstaked from the pool
            tokenBalance = getInternalUnderlying(index); 
        }
        
        uint256 withdrawAmount;
        if (_msgSender() == feeAccount) {
            if (tokenBalance < amount) {
                withdrawAmount = tokenBalance;
            } else {
                withdrawAmount = amount;
            }
        } else {
            uint256 fee = amount.div(feeRateDivision);
            withdrawAmount = amount.sub(fee);
            // this happen when pool withdraw fee greater than yfin burn fee
            if (tokenBalance <= withdrawAmount) {
                withdrawAmount = tokenBalance;
            } else {
                if (tokenBalance.sub(withdrawAmount) >= fee) {
                    token.feeBalance = token.feeBalance.add(fee);
                } else {
                    token.feeBalance = token.feeBalance.add(tokenBalance.sub(withdrawAmount));
                }
            }
        }
        
        IERC20(token.tokenAddress).safeTransfer(_msgSender(), withdrawAmount);
        emit WithdrawUnderlyingToken(token.tokenAddress, _msgSender(), withdrawAmount);
    }
    
    function pushFeeForToken(uint index, uint amount) public nonReentrant {
        require (amount <= tokens[index].feeBalance, "YFIN: requested more than available fees");
        tokens[index].feeBalance = tokens[index].feeBalance.sub(amount);
        IERC20(tokens[index].tokenAddress).safeTransfer(feeAccount, amount);
    }
    
    function pushAllFeeForToken(uint index) public {
        pushFeeForToken(index, tokens[index].feeBalance);
    }
    
    function pushAllFeeForAllTokens() external {
        for (uint i = 0; i < numTokens; i++) {
            pushAllFeeForToken(i);
        }
    }
    
    function breakdownAndWithdrawUnderlying(uint256 amount) public nonReentrant returns (bool success) {
        require (balanceOf(_msgSender()) >= amount, "YFIN: Breakdown amount excess balance");
        _burn(_msgSender(), amount);
        
        for (uint i = 0; i < numTokens; i++) {
            _withdrawUnderlyingToken(i, amount.mul(tokens[i].ratioMultiplier));
        }
        return true;
    }
    
    function getExternalUnderlying(uint index ) public view returns (uint256 balance) {
        return farms[index].totalStaked();
    }
    
    function getInternalUnderlying (uint index ) public view returns (uint256 balance) {
        return IERC20(tokens[index].tokenAddress).balanceOf(address(this)).sub(tokens[index].feeBalance);
    }
    
    function balanceOfUnderlying(uint index) public view returns (uint256 balance) {
         return getInternalUnderlying(index).add(getExternalUnderlying(index));
    }
    
    function changeFeeRate(uint rate) external onlyOwner returns (bool success) {
        feeRateDivision = rate;
        emit FeeRateChanged(rate);
        return true;
    }
    
    function changeYieldFarmAddress(uint index, address newModuleAddress) external onlyOwner returns (bool success) {
        address old = address(farms[index]);
        farms[index] = IYieldFarm(newModuleAddress);
        emit YieldFarmAddressChange(old, newModuleAddress);
        
        // approve the token with the same index
        _approveModule(tokens[index].tokenAddress, newModuleAddress);
        return true;
    }

    function _approveModule(address tokenAddress, address approveAddress) internal returns (bool success) {
        // note that this is approve for unlimited amount
        IERC20(tokenAddress).safeApprove(approveAddress, uint256(-1)); //also add to constructor
        return true;
     }
  
    function disapproveModule(address tokenAddress, address approveAddress) external onlyOwner returns (bool success) {
        // note that this is approve for unlimited amount
        IERC20(tokenAddress).safeApprove(approveAddress, 0); //also add to constructor
        return true;
     }
     
    function approveModule(address tokenAddress, address approveAddress) external onlyOwner returns (bool success) {
        _approveModule(tokenAddress, approveAddress);
        return true;
     }
     
    function yieldFarmStake(uint index, uint256 amount) public onlyOwner nonReentrant returns (bool success) {
        require(getInternalUnderlying(index) >= amount, "YFIN: Balance not enough");
        farms[index].stake(amount);
        return true;
    }
    
    function yieldFarmStakeAll(uint index) external onlyOwner returns (bool success) {
        require(getInternalUnderlying(index) > 0, 'YFIN: you have nothing to stake');
        yieldFarmStake(index, getInternalUnderlying(index));
        return true;
    }
    
    function _yieldFarmUnstake(uint index, uint256 amount) internal returns (uint256) {
        require(getExternalUnderlying(index) >= amount, "YFIN: Balance not enough");
        return farms[index].unstake(amount); 
    }
    
    // if the yield farm address only has one token
    function yieldFarmUnstake(uint index, uint256 amount) external onlyOwner nonReentrant returns (uint256) {
        require(amount > 0, "YFIN: You can not unstake non-positive number");
        return _yieldFarmUnstake(index, amount);
    }

    function yieldFarmUnstakeAll(uint index) public onlyOwner returns (bool success) {
        require(getExternalUnderlying(index) > 0, 'YFIN: you have nothing to unstake');
        _yieldFarmUnstake(index, getExternalUnderlying(index));
        return true; 
    }
    
    function changeFeeAccount(address newFeeAccount) external onlyOwner returns (bool success) {
        feeAccount = newFeeAccount;
        emit FeeAccountTransfered(newFeeAccount);
        return true;
    }
}