// File: contracts/_Interfaces.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface myPoints {
    // launch code "AT ADDRESS"  0xBac9EF6a9eBF7e109c1011C68b0Dbac8C309fCc6

    //see your points
    function balanceOf(address _address) external view returns(uint256);
    
    //see the discount of an address in base 1000 (20 = 2%)
    function viewDiscountOf(address _address) external view returns(uint256);
    
    //check the eligibility of a discount. Returns a "tranche" -> 1 = 10%, 2 = 20%
    function viewEligibilityOf(address _address) external view returns (uint256 tranche);
    
    //update my discount: check my eligibility and activates the highest discount I can get.
    function updateMyDiscountOf() external returns (bool);
    
    /*Discount Table nbLoyalty Points -> discount
    0       -> 0%
    5       -> 10%
    10      -> 20%
    25      -> 30%
    50      -> 40%
    100     -> 50%
    250     -> 60%
    500     -> 70%
    1000    -> 80%
    100000  -> 90%
    */
    
    
    //force discount: gives an arbitrary discount (should not work for the pleb... only governance):
    function overrideDiscount(address _address, uint256 _newDiscount) external;
}

interface Governance{
    // launch code "AT ADDRESS"  0x064FD7D9C228e8a4a2bF247b432a34D6E1CB9442

    //shows burn and fees rate. Base 1000 ( 1 = 0.1%   10 = 1%   100 = 10%)
    function viewBurnRate() external returns (uint256); 
    function viewFeeRate() external returns (uint256); 

    //for governors only (should not work with plebls)
    //use base1000 numbers. 1 = 0.1%, 10 = 1%
    function changeBurnRate(uint _burnRate) external;     //base 1000
    function changeFeeRate(uint _feeRate) external;   //base 1000
    function setFeeDestination(address _nextDest) external view;
}

interface IDeFiat_Gov {
    function setActorLevel(address _address, uint256 _newLevel) external;
    function changeBurnRate(uint _burnRate) external;
    function changeFeeRate(uint _feeRate) external;
    function setFeeDestination(address _nextDest) external;

    //== SET EXTERNAL VARIABLES on the DeFiat_Points contract ==  
    function setTxTreshold(uint _amount) external;
    function overrideDiscount(address _address, uint256 _newDiscount) external;
    function overrideLoyaltyPoints(address _address, uint256 _newPoints) external;
    function setDiscountTranches(uint256 _tranche, uint256 _pointsNeeded) external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
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

interface X_DFTfarming {
    // at address: 
    function stake(uint256 amount) external; //stake shitcoins
    function unStake(uint256 amount) external; //wd Stake only
    function takeReward() external; //wd reward

    function myRewards() external view returns(uint256);
    function myStake() external view returns(uint256);
    // 100000000000000000000 = 100 TOKENS
}

interface X_Defiat_Token {
    // at address: 0xB571d40e4A7087C1B73ce6a3f29EaDfCA022C5B2
    function balanceOf(address account) external view returns(uint256);
    function approve(address spender, uint256 amount) external;
}

interface X_Defiat_Points {
    // 0x70C7d7856E1558210CFbf27b7F17853655752453
    function overrideDiscount(address _address, uint256 _newDiscount) external;
    function overrideLoyaltyPoints(address _address, uint256 _newPoints) external;
    function approve(address spender, uint256 amount) external;
        //whitelist the Locking Contract at 100 (100%) discount
}

interface X_flusher {
    function flushPool(address _recipient, address _ERC20address) external;
}

interface IDungeon {
    function myStake(address _address) external view returns(uint256);
    function myRewards(address _address) external view returns(uint256);
}

interface I_Defiat_Points {
    // 0x70c7d7856e1558210cfbf27b7f17853655752453
    function overrideDiscount(address _address, uint256 _newDiscount) external;
    //whitelist the Locking Contract at 100 (100%) discount
}

interface IDeFiat_Points {
    function setTxTreshold(uint _amount) external;
}

// File: contracts/SafeMath.sol

// File: @openzeppelin/contracts/math/Math.sol
//

// File: @openzeppelin/contracts/math/SafeMath.sol
pragma solidity ^0.6.0;
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath{
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    
        /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: contracts/Context.sol

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/Allowable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


contract Allowable is Context {
    mapping(address => bool) allowed;
    
    modifier onlyAllowed() {
        require(allowed[_msgSender()] == true, "onlyAllowed");
        _;
    }
    function manageAllowed(address _address, bool _bool) public onlyAllowed {
        allowed[_address] = _bool;
    }
}

// File: contracts/ERC20_Utils.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;



contract ERC20_Utils is Allowable {
    //ERC20_utils  
    function withdrawAnyToken(address _token) external onlyAllowed returns (bool) {
        uint256 _amount = IERC20(_token).balanceOf(address(this));
        _withdrawAnyToken(_msgSender(), _token, _amount);
        return true;
    } //get tokens sent by error to contract

    function _withdrawAnyToken(address _recipient, address _ERC20address, uint256 _amount) internal returns (bool) {
        IERC20(_ERC20address).transfer(_recipient, _amount); //use of the _ERC20 traditional transfer
        return true;
    } //get tokens sent by error

    function kill() public onlyAllowed{
        selfdestruct(_msgSender());
    } //frees space on the ETH chain
}

// File: contracts/_ERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;




contract _ERC20 is Context, IERC20 { 
    using SafeMath for uint256;
    //using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function _constructor(string memory name, string memory symbol) internal {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

//Public Functions
    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


//Internal Functions
    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }  //overriden in Defiat_Token

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}  //ERC20 without constructor

// File: contracts/Uni_Price_v2.sol

//SPDX-License-Identifier: stupid


pragma solidity >= 0.6;





// oracle for on-chain uniswap prices w/ support for LP tokens
contract Uni_Price_v2 is ERC20_Utils {
    using SafeMath for uint112;
    using SafeMath for uint256;
    
    address public UNIfactory;
    address public wETHaddress;
    address public owner;
    string public uniSymbol;
 
    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _;
    }
    
    constructor(address _UNIfactory, address _wETHaddress) public {
        owner = msg.sender;
        UNIfactory = _UNIfactory; 
        //0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; MAINNET ETH
        //0x5c69bee701ef814a2b6a3edd4b1652cb9cc5aa6f; RINKEBY ETH

        wETHaddress = _wETHaddress; 
        //0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2; MAINNET ETH
        //0xc778417E063141139Fce010982780140Aa0cD5Ab; RINKEBY ETH
        uniSymbol = "UNI-V2";
    }

    function isUniLiquidityToken(address _token) public view returns (bool) {
        if (keccak256(bytes(_ERC20(_token).symbol())) == keccak256(bytes(uniSymbol))) {
            return true;
        }
        return false;
    }
    
    function getUniPair(address _token) internal view returns(address) {
        if (isUniLiquidityToken(_token)) {
            return _token;
        }
        return IUniswapV2Factory(UNIfactory).getPair(_token, wETHaddress);
    }

    function _getUint256Reserves(address _token) internal view returns(uint256 rToken, uint256 rWETH) {
        address _token0;
        uint112 _rTKN;
        uint112 _rWETH;

        if (isUniLiquidityToken(_token)) {
            _token0 = IUniswapV2Pair(_token).token0();

            if(_token0 == wETHaddress) {
                (_rWETH, _rTKN, ) = IUniswapV2Pair(_token).getReserves(); //returns r0, r1, time
            }
            else {
                (_rTKN, _rWETH, ) = IUniswapV2Pair(_token).getReserves();
            }
            // formula for eth price of lp tokens in WETH is 2 * wethReserves / totalSupplyLpTokens()
            return (_rWETH.mul(2), _ERC20(_token).totalSupply());
        } else {
            address _UNIpair = getUniPair(_token);
            _token0 = IUniswapV2Pair(_UNIpair).token0();
            if(_token0 == wETHaddress) {
                (_rWETH, _rTKN, ) = IUniswapV2Pair(_UNIpair).getReserves(); //returns r0, r1, time
            }
            else {
                (_rTKN, _rWETH, ) = IUniswapV2Pair(_UNIpair).getReserves();
            }
            return (uint256(_rTKN),uint256(_rWETH)); //price in gwei, needs to be corrected by nb of decimals of _token
            //price of 1 token in GWEI
        }
    }  
    
    function adjuster(address _token) internal view returns(uint256) {
        uint8 _decimals = _ERC20(_token).decimals();
        require(_decimals <= 18,"OverFlow risk, not supported");
        uint256 _temp = 36 - uint256(_decimals);
        return 10**_temp;
    }
    
    function getUniPrice(address _token) public view returns(uint) {

        uint256 rToken; uint256 rWETH; uint256 _adjuster;
        (rToken, rWETH) = _getUint256Reserves(_token);
        _adjuster = adjuster(_token);
        

        return ( (rToken).mul(_adjuster) ).div(rWETH);       //IN GWEI
    }
    
    function getTokenInfo(address _token) public view returns(
        string memory name, string memory symbol, uint8 decimals, address uniPair, uint256 tokensPerETH) {
        return(
            _ERC20(_token).name(), 
            _ERC20(_token).symbol(), 
            _ERC20(_token).decimals(), 
            getUniPair(_token), 
            getUniPrice(_token)
        ); //normalized as if every token is 18 decimals
    }
}

// File: contracts/DeFiat_VotingPower.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;






contract DeFiat_VotingPower is ERC20_Utils, Uni_Price_v2 {
    using SafeMath for uint256;
    
    address public defiat;
    address public wethAddress;
    uint internal stackPointer; // pointer for staking pool stack
    
    struct PoolStruct {
        address poolAddress;
        address stakedAddress;
        address rewardAddress;
    }
    mapping (uint => PoolStruct) public stakingPools; // pools to calculate voting power from

    constructor() 
        Uni_Price_v2(
            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f, 
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        ) // MAINNET
        // Uni_Price_v2(
        //     0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f, 
        //     0xc778417E063141139Fce010982780140Aa0cD5Ab
        // ) // RINKEBY
    public {
        defiat = address(0xB6eE603933E024d8d53dDE3faa0bf98fE2a3d6f1); // MAINNET
        // defiat = address(0xB571d40e4A7087C1B73ce6a3f29EaDfCA022C5B2); // RINKEBY
    }

    function myVotingPower(address _address) public view returns (uint256) {
        // power initialized to DFT Balance
        uint256 _power = _ERC20(defiat).balanceOf(_address);
        for (uint i = 0; i < stackPointer; i++) {
            PoolStruct memory pool = stakingPools[i];
            // get base staked tokens
            uint256 stakedTokens = getStake(_address, pool.poolAddress);

            // if its an LP token, we convert to total DFT value of tokens
            // essentially x2 multiplier for LP votes
            if (isUniLiquidityToken(pool.stakedAddress)) {
                stakedTokens = getLiquidityTokenPower(pool.stakedAddress, stakedTokens);
            }

            // get reward tokens if the pool rewards in DFT
            uint256 rewardTokens;
            if (pool.rewardAddress == defiat) {
                rewardTokens = getRewards(_address, pool.poolAddress);
            }
            

            _power = _power + stakedTokens + rewardTokens;
        }

        return _power;
    }

    function getLiquidityTokenPower(address tokenAddress, uint256 stakedTokens) public view returns (uint256) {
        uint112 tokenReserves;
        uint112 wethReserves;
        uint256 tokensPerEth; 
        address token0 = IUniswapV2Pair(tokenAddress).token0();
        address token1 = IUniswapV2Pair(tokenAddress).token1();
        
        if (token0 == wethAddress) {
            (wethReserves, tokenReserves, ) = IUniswapV2Pair(tokenAddress).getReserves();
            tokensPerEth = getUniPrice(token1);
        } else {
            (tokenReserves, wethReserves, ) = IUniswapV2Pair(tokenAddress).getReserves();
            tokensPerEth = getUniPrice(token0);
        }

        uint256 wethInTokens = uint256(wethReserves)
            .mul(tokensPerEth)
            .div(1e18);

        uint256 totalSupply = _ERC20(tokenAddress).totalSupply();
        uint256 tokensPerLiquidityToken = wethInTokens
            .add(uint256(tokenReserves))
            .mul(1e18)
            .div(totalSupply);

        return stakedTokens.mul(tokensPerLiquidityToken).div(1e18);
    }

    function getStake(address _address, address _poolAddress) internal view returns (uint256) {
        return IDungeon(_poolAddress).myStake(_address);
    }

    function getRewards(address _address, address _poolAddress) internal view returns (uint256) {
        return IDungeon(_poolAddress).myRewards(_address);
    }

    // Owner functions

    function pushStakingPool(address _poolAddress, address _stakedAddress, address _rewardAddress) external onlyOwner {
        stakingPools[stackPointer++] = PoolStruct(_poolAddress, _stakedAddress, _rewardAddress);
    }

    function popStakingPool() external onlyOwner {
        require(stackPointer > 0, "Nothing to pop!");
        delete(stakingPools[--stackPointer]);
    }

    function flushPools() external onlyOwner {
        require(stackPointer > 0, "Nothing to pop!");
        while (stackPointer > 0) {
            delete(stakingPools[--stackPointer]);
        }
    }
}
