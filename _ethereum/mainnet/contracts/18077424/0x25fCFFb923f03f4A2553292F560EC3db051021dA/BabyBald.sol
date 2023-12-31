// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library SafeMath {
  function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      uint256 c = a + b;
      if (c < a) return (false, 0);
      return (true, c);
    }
  }

  function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b > a) return (false, 0);
      return (true, a - b);
    }
  }

  function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (a == 0) return (true, 0);
      uint256 c = a * b;
      if (c / a != b) return (false, 0);
      return (true, c);
    }
  }

  function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b == 0) return (false, 0);
      return (true, a / b);
    }
  }

  function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b == 0) return (false, 0);
      return (true, a % b);
    }
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    return a + b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    return a * b;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return a % b;
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    unchecked {
      require(b <= a, errorMessage);
      return a - b;
    }
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    unchecked {
      require(b > 0, errorMessage);
      return a / b;
    }
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    unchecked {
      require(b > 0, errorMessage);
      return a % b;
    }
  }
}

interface IERC20 {
  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(
    address _owner,
    address spender
  ) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
  address internal owner;
  // Contract manager has the ability to change some settings regardless of ownership.
  address internal manager;

  constructor(address _owner) {
    owner = _owner;
    manager = _owner;
  }

  modifier onlyOwner() {
    require(isOwner(msg.sender), "!OWNER");
    _;
  }

  modifier onlyManager() {
    require(isManager(msg.sender), "!MANAGER");
    _;
  }

  function isOwner(address account) public view returns (bool) {
    return account == owner;
  }

  function isManager(address account) public view returns (bool) {
    return account == manager;
  }

  function transferOwnership(address payable adr) external onlyOwner {
    owner = adr;
    emit OwnershipTransferred(adr);
  }

  event OwnershipTransferred(address owner);
}

interface IFactory {
  function createPair(
    address tokenA,
    address tokenB
  ) external returns (address pair);

  function getPair(
    address tokenA,
    address tokenB
  ) external view returns (address pair);
}

interface IRouter {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
}

contract BabyBald is IERC20, Ownable {
  // **************** Global parameters ****************
  using SafeMath for uint256;
  string private constant _name = "BabyBald.obamainushibacoin";
  string private constant _symbol = "BabyBald.inu";
  address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
  uint8 private constant _decimals = 9;
  uint256 private _totalSupply = 453000000000 * (10 ** _decimals);
  mapping(address => uint256) _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  mapping(address => bool) private isFeeExempt;

  IRouter router;
  address public pair;
  bool private tradingAllowed = false;
  bool private swapping;

  // **************** Token settings ****************
  uint256 public _maxSellAmount = (_totalSupply * 200) / 10000;
  uint256 public _maxWalletToken = (_totalSupply * 2000) / 10000;

  // **************** Fees ****************

  // ---------- Settings ------------------
  uint256 private buyFee = 200;
  uint256 private sellFee = 200;
  uint256 private transferFee = 0;
  uint256 private feeDenominator = 10000;

  // ---------- Distribution ------------------
  uint256 private marketingFee = 500;
  uint256 private stakingFee = 500;

  // ---------- Recipients ------------------
  address internal staking_receiver = DEAD;
  address internal marketing_receiver = DEAD;

  // **************** Main Logic ****************
  constructor() Ownable(msg.sender) {
    IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address _pair = IFactory(_router.factory()).createPair(
      address(this),
      _router.WETH()
    );
    router = _router;
    pair = _pair;
    isFeeExempt[address(this)] = true;
    isFeeExempt[marketing_receiver] = true;
    isFeeExempt[staking_receiver] = true;
    isFeeExempt[msg.sender] = true;
    _balances[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  receive() external payable {}

  function name() public pure returns (string memory) {
    return _name;
  }

  function symbol() public pure returns (string memory) {
    return _symbol;
  }

  function decimals() public pure returns (uint8) {
    return _decimals;
  }

  function startTrading() external onlyOwner {
    tradingAllowed = true;
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));
  }

  function getOwner() external view override returns (address) {
    return owner;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function _approve(address owner, address spender, uint256 amount) private {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function shouldTakeFee(
    address sender,
    address recipient
  ) internal view returns (bool) {
    return !isFeeExempt[sender] && !isFeeExempt[recipient];
  }

  function getTotalFee(
    address sender,
    address recipient
  ) internal view returns (uint256) {
    if (recipient == pair) {
      return sellFee;
    }
    if (sender == pair) {
      return buyFee;
    }
    return transferFee;
  }

  function takeFee(
    address sender,
    address recipient,
    uint256 amount
  ) internal returns (uint256) {
    if (getTotalFee(sender, recipient) > 0) {
      uint256 feeAmount = amount.div(feeDenominator).mul(
        getTotalFee(sender, recipient)
      );
      uint256 totalFee = marketingFee.add(stakingFee);

      if (marketingFee > 0) {
        _balances[marketing_receiver] = _balances[marketing_receiver].add(
          feeAmount.mul(marketingFee).div(totalFee)
        );
        emit Transfer(
          sender,
          marketing_receiver,
          feeAmount.mul(marketingFee).div(totalFee)
        );
      }
      if (stakingFee > 0) {
        _balances[staking_receiver] = _balances[staking_receiver].add(
          feeAmount.mul(stakingFee).div(totalFee)
        );
        emit Transfer(
          sender,
          staking_receiver,
          feeAmount.mul(stakingFee).div(totalFee)
        );
      }
      return amount.sub(feeAmount);
    }
    return amount;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) private {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    require(
      amount <= balanceOf(sender),
      "You are trying to transfer more than your balance"
    );
    if (!isFeeExempt[sender] && !isFeeExempt[recipient]) {
      require(tradingAllowed, "tradingAllowed");
    }
    if (
      !isFeeExempt[sender] &&
      !isFeeExempt[recipient] &&
      recipient != address(pair) &&
      recipient != address(DEAD)
    ) {
      require(
        (_balances[recipient].add(amount)) <= _maxWalletToken,
        "Exceeds maximum wallet amount."
      );
    }
    if (sender != pair) {
      require(
        amount <= _maxSellAmount ||
          isFeeExempt[sender] ||
          isFeeExempt[recipient],
        "TX Limit Exceeded"
      );
    }

    _balances[sender] = _balances[sender].sub(amount);
    uint256 amountReceived = shouldTakeFee(sender, recipient)
      ? takeFee(sender, recipient, amount)
      : amount;
    _balances[recipient] = _balances[recipient].add(amountReceived);
    emit Transfer(sender, recipient, amountReceived);
  }

  function transfer(
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function setisExempt(address _address, bool _enabled) external onlyOwner {
    isFeeExempt[_address] = _enabled;
  }

  function setTransactionRequirements(
    uint256 _marketing,
    uint256 _staking,
    uint256 _buy,
    uint256 _sell,
    uint256 _trans
  ) external onlyOwner {
    marketingFee = _marketing;
    stakingFee = _staking;
    buyFee = _buy;
    sellFee = _sell;
    transferFee = _trans;
    require(
      buyFee <= feeDenominator.div(5) &&
        sellFee <= feeDenominator.div(5) &&
        transferFee <= feeDenominator.div(5),
      "fees cannot be more than 20%"
    );
  }

  function allowance(
    address owner,
    address spender
  ) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(
    address spender,
    uint256 amount
  ) public override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function setInternalAddresses(
    address _marketing,
    address _staking
  ) external onlyOwner {
    marketing_receiver = _marketing;
    staking_receiver = _staking;
    isFeeExempt[_marketing] = true;
    isFeeExempt[_staking] = true;
  }

  // Minimum permission to edit staking address fee recipient (used for future-proof staking activities)
  function setStakingAddress(address _staking) external onlyManager {
    staking_receiver = _staking;
    isFeeExempt[_staking] = true;
  }

  function rescueERC20(address _address, uint256 percent) external onlyManager {
    uint256 _amount = IERC20(_address)
      .balanceOf(address(this))
      .mul(percent)
      .div(100);
    IERC20(_address).transfer(marketing_receiver, _amount);
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      msg.sender,
      _allowances[sender][msg.sender].sub(
        amount,
        "ERC20: transfer amount exceeds allowance"
      )
    );
    return true;
  }
}
