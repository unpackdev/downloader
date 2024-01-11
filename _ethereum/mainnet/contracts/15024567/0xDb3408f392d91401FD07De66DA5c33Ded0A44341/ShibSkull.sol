pragma solidity ^0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./IDC.sol";
import "./IUniswapV3Pool.sol";
import "./IUniswapV3Factory.sol";
import "./ISwapRouter.sol";
import "./OracleLibrary.sol";

contract ShibSkull is Context, IERC20, Ownable {
    /*
        ShibSkull wraps DogCatcher's instaminting.
        It awards ShibSkulls as a fun token for depositing target dog tokens.
    */
    // Shib Skull
    string private _name = "ShibSkull";
    string private _symbol = "SHIBSKULL";
    uint256 private _totalSupply = 0;
    uint8 private _decimals = 18;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    IDC private DC = IDC(0x679A0B65a14b06B44A0cC879d92B8bB46a818633);
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    mapping(address => bool) public targeted;
    mapping(address => IERC20) dogs; 

    address dev1 = 0x7190A1826F69829522d7B8Fa042613C9377badDC;
    address dev2 = 0x1Dc1560F9C4622361788357aC7ee8dd2DE71816e;
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeMath for uint32;
    using SafeMath for uint8;

    constructor () {
        _mint(dev1, 5000000000000000000000000000);
        _mint(dev2, 5000000000000000000000000000);
        addTarget(0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE); 
    }

    function name() public view returns (string memory) {return _name;}
    function symbol() public view returns (string memory) {return _symbol;}
    function decimals() public view returns (uint8) {return _decimals;}
    function totalSupply() public view override returns (uint256) {return _totalSupply;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    
    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        uint256 fromBalance = balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint256 transferAmount = amount;
        if (DC.balanceOf(from) < 100000000000000) {
            transferAmount = transferAmount.mul(900).div(1000);
            uint256 notEnoughDCHeldFeeSplit = (amount - transferAmount).mul(1000).div(2000);
            balances[dev1] += notEnoughDCHeldFeeSplit;
            balances[dev2] += notEnoughDCHeldFeeSplit;
        }
 
        balances[from] = fromBalance - amount; 
        balances[to] += transferAmount;

        emit Transfer(from, to, transferAmount);
    }

  function approve(address spender, uint256 amount) public override returns (bool) {
      _approve(_msgSender(), spender, amount);
      return true;
  }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

     function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function addTarget(address token) public {
      require(_msgSender() == dev1 || _msgSender() == dev2, "Permission denied!");
      IERC20 targetedToken = IERC20(token);
      targetedToken.approve(address(DC), type(uint256).max);
      targeted[token] = true;
      dogs[token] = targetedToken;
    }

    function instaMint(address token, uint256 amount) public {
      require(targeted[token] == true, "Not targeted.");
      IERC20 targetedToken = dogs[token];
      targetedToken.transferFrom(_msgSender(), address(this), amount);
      DC.instaMint(token, amount);
      uint256 dcMinted = DC.balanceOf(address(this));
      DC.transfer(_msgSender(), dcMinted);
      _mint(_msgSender(), amount);
    }

    //Fail-safe function for releasing non-target tokens, not meant to be used.
    function release(address token) public {
        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
    }
}
