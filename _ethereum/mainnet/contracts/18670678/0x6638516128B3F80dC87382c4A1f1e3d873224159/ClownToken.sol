/**
                                                                       ,----,
                                                                     ,/   .`|
  ,----..    ,--,                                                  ,`   .'  :
 /   /   \ ,--.'|                                                ;    ;     /
|   :     :|  | :     ,---.           .---.      ,---,         .'___,/    ,'  ,---.           .---.      ,---,
.   |  ;. /:  : '    '   ,'\         /. ./|  ,-+-. /  |        |    :     |  '   ,'\         /. ./|  ,-+-. /  |
.   ; /--` |  ' |   /   /   |     .-'-. ' | ,--.'|'   |        ;    |.';  ; /   /   |     .-'-. ' | ,--.'|'   |
;   | ;    '  | |  .   ; ,. :    /___/ \: ||   |  ,"' |        `----'  |  |.   ; ,. :    /___/ \: ||   |  ,"' |
|   : |    |  | :  '   | |: : .-'.. '   ' .|   | /  | |            '   :  ;'   | |: : .-'.. '   ' .|   | /  | |
.   | '___ '  : |__'   | .; :/___/ \:     '|   | |  | |            |   |  ''   | .; :/___/ \:     '|   | |  | |
'   ; : .'||  | '.'|   :    |.   \  ' .\   |   | |  |/             '   :  ||   :    |.   \  ' .\   |   | |  |/
'   | '/  :;  :    ;\   \  /  \   \   ' \ ||   | |--'              ;   |.'  \   \  /  \   \   ' \ ||   | |--'
|   :    / |  ,   /  `----'    \   \  |--" |   |/                  '---'     `----'    \   \  |--" |   |/
 \   \ .'   ---`-'              \   \ |    '---'                                        \   \ |    '---'
  `---`                          '---"                                                   '---"

Its 🤡 clown's 🤡
.
all the
.
.
way
.
.
.
down
.
.
.
.
**/

// SPDX-License-Identifier: CLOWNWARE
pragma solidity 0.8.19;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IClownTownStaking.sol";

contract ClownToken is Context, IERC20, IERC20Metadata, Ownable {
    string private _name;
    string private _symbol;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public excludeFromFees;

    uint256 private _totalSupply;

    uint16 public feeBpsTotal;
    uint16 public feeBpsToStakers;
    uint16 public maxBpsPerWallet;
    uint16 public clownVersion = 54321;

    address public uniswapPair;
    address public feeWallet;
    IClownTownStaking public stakingContract;

    constructor(
        string memory name_,
        string memory symbol_,
        address feeWallet_,
        uint16 feeBpsTotal_,
        uint16 feeBpsToStakers_,
        uint16 maxBpsPerWallet_) {
        require(feeWallet_!=address(0));

        _name = name_;
        _symbol = symbol_;
        feeWallet = feeWallet_;

        feeBpsTotal = feeBpsTotal_;
        feeBpsToStakers = feeBpsToStakers_;
        maxBpsPerWallet = maxBpsPerWallet_;

        excludeFromFees[msg.sender] = true;
        excludeFromFees[feeWallet_] = true;

        // First and last mint
        _mint(msg.sender, 1000 * 1000 * 1000 * (10**18));
    }

// my boss will pay me
// for every line of code
// i make many lines

    function initUniswapPair(IUniswapV2Router02 router) public onlyOwner {
        require(address(router)!=address(0));
       IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
       uniswapPair = factory.createPair(address(this), router.WETH());
    }

    function setUniswapPair(address uniswapPair_) public onlyOwner {
      require(uniswapPair_!=address(0));
      uniswapPair = uniswapPair_;
    }

    function setFees(uint16 feeBptsTotal_, uint16 feeBpsToStakers_) public onlyOwner {
      require(feeBptsTotal_ <= 10000);
      require(feeBpsToStakers_ <= feeBptsTotal_);

      feeBpsTotal = feeBptsTotal_;
      feeBpsToStakers = feeBpsToStakers_;
    }

    function setMaxBpsPerWallet(uint16 maxBpsPerWallet_) public onlyOwner {
      require(maxBpsPerWallet_ <= 10000);
      maxBpsPerWallet = maxBpsPerWallet_;
    }

    function setExcludeFromFees(address account, bool value) public onlyOwner {
      excludeFromFees[account] = value;
    }

    function setFeeWallet(address feeWallet_) public onlyOwner {
      require(feeWallet_!=address(0));
      feeWallet = feeWallet_;
      excludeFromFees[feeWallet_] = true;
    }

// clowns have red noses
// but sometimes they are scary
// their noses go honk

    function setStakingContract(IClownTownStaking stakingContract_) public onlyOwner {
      require(address(stakingContract_)!=address(0));
      stakingContract = stakingContract_;
      excludeFromFees[address(stakingContract_)] = true;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

// all good code should have
// very very good comments
// just like this one here

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        if ((from==uniswapPair || to==uniswapPair) &&
            !excludeFromFees[from] &&
            !excludeFromFees[to]) {
            uint256 feeTotal = amount * feeBpsTotal / 10000;
            uint256 feeToStakers = amount * feeBpsToStakers / 10000;
            require(feeToStakers <= feeTotal); // Sanity check
            uint256 feeRemaining = feeTotal - feeToStakers;

            uint256 receiveAmount = amount - feeTotal;

            _balances[from] = fromBalance - amount;

            // whales are very big
            // they are very very big
            // that is what she said
            require(
                to==uniswapPair ||
                maxBpsPerWallet == 0 ||
                (_balances[to]+receiveAmount) <= (_totalSupply * maxBpsPerWallet / 10000)
            );

            _balances[to] += receiveAmount;
            emit Transfer(from, to, receiveAmount);

            if (feeRemaining > 0) {
                require(feeWallet!=address(0));

                _balances[feeWallet] += feeRemaining;
                emit Transfer(from, feeWallet, feeRemaining);
            }
            if (feeToStakers > 0) {
                require(address(stakingContract)!=address(0));

                _balances[address(stakingContract)] += feeToStakers;
                stakingContract.postProcessClownReward(feeToStakers);
                emit Transfer(from, address(stakingContract), feeToStakers);
            }
        }
        else {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;

            emit Transfer(from, to, amount);
        }
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

// chatgpt will
// one day take my job away
// and write many lines

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}