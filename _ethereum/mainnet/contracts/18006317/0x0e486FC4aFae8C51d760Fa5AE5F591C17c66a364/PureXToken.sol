// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;
// optimized ERC20 token code 
// from Math library all unused functions are removed (only add & sub are used, mod/div/mul are removed)
// ! deploy with optimization, 200 runs
//


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





//ONLY USE FOR SOLIDITY 8.X
library SafeMath {
    string public constant SAFEMATH_ADD_OVERFLOW = "SAFEMATH: ADD OVERFLOW";
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
        unchecked{
            uint256 c = a + b;
            require(c >= a, SAFEMATH_ADD_OVERFLOW);
            return c;
        }     
    }

    

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{
            require(b <= a, errorMessage);
            uint256 c = a - b;
            return c;
        }

        
    }

   
}



contract PureXToken is IERC20 {
    string public constant TRANSFER_FROM_THE_ZERO_ADDRESS = "transfer from the 0 address";
    string public constant TRANSFER_TO_THE_ZERO_ADDRESS = "transfer to the 0 address";

    
    string public constant MINT_TO_THE_ZERO_ADDRESS = "mint to the 0 address";
    string public constant BURN_FROM_THE_ZERO_ADDRESS = "burn from the 0 address";
    string public constant APPROVE_FROM_THE_ZERO_ADDRESS = "apprv from the 0 address";
    string public constant APPROVE_TO_THE_ZERO_ADDRESS = "apprv to the 0 address";


    //as they are passed _always_ and will be more gas saved if we do not convert them
    string public constant TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE = "transfer amount > allowance";
    string public constant DECREASED_ALLOWANCE_BELOW_ZERO = "decreased allowance < 0";
    string public constant TRANSFER_AMOUNT_EXCEEDS_BALANCE = "transfer amount > balance";
    string public constant BURN_AMOUNT_EXCEEDS_TOTALSUPPLY = "burn amount > totalSupply";
    string public constant BURN_AMOUNT_EXCEEDS_BALANCE = "burn amount > balance";

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;

   
    constructor (address destination){
        _name = 'PURE-X';
        _symbol = 'PURE-X';
        _mint(destination, 5000000*1e18);
        _decimals = 18;
    }

    
    function name() external view returns (string memory) {
        return _name;
    }

    
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

   
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

   
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

   
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, DECREASED_ALLOWANCE_BELOW_ZERO));
        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), TRANSFER_FROM_THE_ZERO_ADDRESS);
        require(recipient != address(0), TRANSFER_TO_THE_ZERO_ADDRESS);

        _balances[sender] = _balances[sender].sub(amount, TRANSFER_AMOUNT_EXCEEDS_BALANCE);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), MINT_TO_THE_ZERO_ADDRESS);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

   
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), APPROVE_FROM_THE_ZERO_ADDRESS);
        require(spender != address(0), APPROVE_TO_THE_ZERO_ADDRESS);

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}