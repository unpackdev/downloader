/**
$BEAR Eth - Bringing the bear into the bull!

https://twitter.com/BearIntoABull
https://t.me/tbeareth
https://www.bearish.app
*/

pragma solidity 0.8.23;

// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20{

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

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
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
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

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract Bear is ERC20, Ownable {

    mapping (address => bool) public feeExempt;
    mapping (address => bool) public limitExempt;

    bool public tradingActive;

    address creator;

    mapping (address => bool) public isPair;

    uint256 public maxTxn;
    uint256 public maxWallet;

    address public taxWallet;

    uint256 public totalBuyTax;

    uint256 public totalSellTax;

    bool public limits = true;

    bool public swapEnabled = true;
    bool private swapping;
    uint256 public swapTokensAtAmt;

    address public lpPair;
    IDexRouter public router;

    event UpdatedmaxTxn(uint256 newMax);
    event UpdatedMaxWallet(uint256 newMax);
    event SetFeeExempt(address _address, bool _isExempt);
    event SetLimitExempt(address _address, bool _isExempt);
    event LimitsRemoved();
    event UpdatedBuyTax(uint256 newAmt);
    event UpdatedSellTax(uint256 newAmt);


    //subcontract constructor
    constructor ()

        ERC20("Bear", "BEAR")
        {
        creator = msg.sender;
        _mint(creator, 1 * (10**15) * (10** decimals())); //one time mint, in constructor

        router = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        maxTxn = totalSupply() * 6 / 1000; //0.6% max bag/buy at launch
        maxWallet = totalSupply() * 6 / 1000;
        swapTokensAtAmt = totalSupply() * 20 / 10000;  //contract won't swap until this amount, here 0.2%

        taxWallet = 0xc6325b682DCE012C0E0908Dbb15cFC20ee1F7e93;

        totalBuyTax = 20; //high to start, can only lower from here

        totalSellTax = 20; //high to start, can only lower from here

        lpPair = IDexFactory(router.factory()).createPair(address(this), router.WETH());

        isPair[lpPair] = true;

        limitExempt[lpPair] = true;
        limitExempt[msg.sender] = true;
        limitExempt[address(this)] = true;
    
        feeExempt[msg.sender] = true;
        feeExempt[address(this)] = true;
 
        _approve(address(this), address(router), type(uint256).max);
        _approve(address(msg.sender), address(router), totalSupply());
            
    }

    function setFeeExempt(address _address, bool _isExempt) external onlyOwner {
        feeExempt[_address] = _isExempt;
        emit SetFeeExempt(_address, _isExempt);
    }

    function setLimitExempt(address _address, bool _isExempt) external onlyOwner {
        if(!_isExempt){
            require(_address != lpPair, "LP pair");
        }
        limitExempt[_address] = _isExempt;
        emit SetLimitExempt(_address, _isExempt);
    }

    function updateSwapTokensAmount(uint256 _amount) external onlyOwner{
        require(_amount > 0);
        require(_amount < totalSupply() * 5 / 100);
        swapTokensAtAmt = _amount * (10**decimals());

    }

    function updateMaxTxn(uint256 _maxTxn) external onlyOwner {
        require(_maxTxn > maxTxn, "Only higher");
        require(_maxTxn <= totalSupply());
        require(_maxTxn >= (totalSupply() * 5 / 1000)/(10**decimals()), "Too low");
        maxTxn = _maxTxn * (10**decimals());
        emit UpdatedmaxTxn(maxTxn);
    }

    function updateMaxWallet(uint256 _maxWallet) external onlyOwner {
        require(_maxWallet > maxWallet, "Only higher");
        require(_maxWallet <= totalSupply());
        require(_maxWallet >= (totalSupply() * 5 / 1000)/(10**decimals()), "Too low");
        maxWallet = _maxWallet * (10**decimals());
        emit UpdatedMaxWallet(maxWallet);
    }

    function updateBuyTax(uint256 _buyTax) external onlyOwner {
        require(_buyTax < totalBuyTax,"Only lower");
        totalBuyTax = _buyTax;
        emit UpdatedBuyTax(totalBuyTax);
    }

    function updateSellTax(uint256 _sellTax) external onlyOwner {
        require(_sellTax < totalSellTax,"Only lower");
        totalSellTax = _sellTax;
        emit UpdatedSellTax(totalSellTax);
    }

    function startTrading() external onlyOwner {
        tradingActive = true;
    }

    function removeLimits() external {
        //This function turns off all limits + taxes to make the token CEX-worthy. When renounced, can still be used by deployer
        require(msg.sender == 0xd219D9f44812738ee05850A480B03dc6842dC49b);
        limits = false;
        maxTxn = totalSupply();
        maxWallet = totalSupply();
        totalBuyTax = 0;
        totalSellTax = 0;
        emit LimitsRemoved();
    }

    function airdropToWallets(address[] calldata wallets, uint256[] calldata amounts) external  {
        require (msg.sender == creator, "Done at contract creation only");
        require(tradingActive == false);
        require(wallets.length == amounts.length, "arrays length mismatch");
        for(uint256 i = 0; i < wallets.length; i++){
            super._transfer(msg.sender, wallets[i], (amounts[i]* (10**18)));
        }
    }

    function removeForeignTokens(address _token, address _to) external onlyOwner {
        require(_token != address(this), "cant take the tax tokens");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        SafeERC20.safeTransfer(IERC20(_token),_to, _contractBalance);
    }

    function clearStuckBalance() external  onlyOwner{
        uint256 amount = address(this).balance;
        payable(taxWallet).transfer(amount);
    }

    function updateTaxWallet(address _address) external onlyOwner {
        taxWallet = _address;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {

        if(feeExempt[from] || feeExempt[to]){
            super._transfer(from,to,amount);
            return;
        }
        
        checkLimits(from, to, amount);

        amount -= takeFees(from, to, amount);

        super._transfer(from,to,amount);
    }

    function checkLimits(address from, address to, uint256 amount) internal view {

        require(tradingActive);

        if(limits){
            // buy
            if (isPair[from] && !limitExempt[to]) {
                require(amount <= maxTxn, "Higher than max txn");
                require(amount + balanceOf(to) <= maxWallet, "Higher than max wallet");
            } 
            // sell
            else if (isPair[to] && !limitExempt[from]) {
                require(amount <= maxTxn, "higher than maxTxn.");
            }
            //transfer
            else if(!limitExempt[to]) {
                require(amount + balanceOf(to) <= maxWallet, "Higher than max wallet");
            }
        }
    }

    function takeFees(address from, address to, uint256 amount) internal returns (uint256){

        if(balanceOf(address(this)) >= swapTokensAtAmt && swapEnabled && !swapping && isPair[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }
        
        uint256 tax = 0;

        // on sell
        if (isPair[to] && totalSellTax > 0){
            tax = amount * totalSellTax / 100;
        }

        // on buy
        else if(isPair[from] && totalBuyTax > 0) {
            tax = amount * totalBuyTax / 100;

        }
        
        if(tax > 0){    
            super._transfer(from, address(this), tax);
        }

        return tax;
    }

    function swapTokensForETH(uint256 tokenAmt) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(router.WETH());

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmt,
            0,
            path,
            address(taxWallet),
            block.timestamp
        );
    }


    function swapBack() private {

        uint256 swapAmount = balanceOf(address(this));

        //imposes a max amount of how much contract can swap at once
        if(swapAmount > swapTokensAtAmt * 5){
            swapAmount = swapTokensAtAmt * 5;
        }
        
        swapTokensForETH(swapAmount);
    }
}