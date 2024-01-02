// SPDX-License-Identifier: None

/*

    Amamus pizzam, et pizza pars nostri est. *-* (this is in Latin)
    
    Narrative: Simply born out of love for pizza - we love pizza so much!
    So if you love pizza as well, grab a slice, hold it tight and vibe with us! :)

    Telegram: https://www.t.me/degenpizza
    
    Website: https://www.degenpizza.com

    Twitter: https://www.x.com/degenpizzaslice

    Tax:
    A dynamic tax system that ranges between 0.25 % and 4.00 %, and adapts on its own.
    If there is a high volume of sales and the price of pizza decreases, the tax increases.
    If there is a high volume of purchases and the price of pizza increases, the tax decreases.
    Set slippage to at least 5.00 % when using a decentralized exchange to smoothly swap pizza.
    Alternatively, refer to the currentTax() function for more details about the current tax.

    Max Wallet and Max Tx:
    2.00 % of the total Supply until supply shock is reached,
    then both max Wallet and max Tx limits will be lifted forever.

    Total Supply:
    100000000 (100 million Pizzas)

    This contract was created by NodeReverend.eth - all rights reserved.

    Terms and conditions apply - refer to the website for more details.

 */

pragma solidity 0.8.23;


// Interface for the standard ERC20 token functionality.
interface IERC20 {
    // Event emitted when tokens are transferred.
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // Event emitted when an approval is granted to spend tokens.
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // Returns the total supply of tokens.
    function totalSupply() external view returns (uint256);
    
    // Returns the balance of tokens for a specific account.
    function balanceOf(address account) external view returns (uint256);
    
    // Transfers tokens to a specified address.
    function transfer(address to, uint256 value) external returns (bool);
    
    // Returns the remaining number of tokens that a spender is allowed to spend.
    function allowance(address owner, address spender) external view returns (uint256);
    
    // Sets a specific amount of tokens for a spender to use.
    function approve(address spender, uint256 value) external returns (bool);
    
    // Transfers tokens on behalf of an owner to a specified address.
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


// Interface for ERC20 token metadata.
interface IERC20Metadata is IERC20 {
    // Returns the name of the token.
    function name() external view returns (string memory);
    
    // Returns the symbol of the token.
    function symbol() external view returns (string memory);
    
    // Returns the number of decimals the token uses.
    function decimals() external view returns (uint8);
}


// Interface for ERC20 token-specific errors.
interface IERC20Errors {
    // Error for insufficient allowance.
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    
    // Error for insufficient balance.
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    
    // Error for invalid receiver.
    error ERC20InvalidReceiver(address receiver);
    
    // Error for invalid approver.
    error ERC20InvalidApprover(address approver);
    
    // Error for invalid spender.
    error ERC20InvalidSpender(address spender);
    
    // Error for invalid sender.
    error ERC20InvalidSender(address sender);
    
    // Error for exceeding maximum wallet limit.
    error ERC20MaxWallet();
    
    // Error for exceeding maximum transaction amount.
    error ERC20MaxTx();
}


// Interface for a decentralized exchange router.
interface IDRouter {
    // Returns the address of the wrapped ETH.
    function WETH() external pure returns (address);
    
    // Returns the address of the factory contract.
    function factory() external pure returns (address);
    
    // Executes a swap of tokens for ETH, supporting tokens with fees on transfer.
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


// Interface for a decentralized exchange factory.
interface IDFactory {
    // Creates a liquidity pair for two tokens.
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


// Abstract contract that provides context for inheriting contracts.
abstract contract Context {
    // Returns the address of the sender of the current message/call.
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}


// Abstract contract for ownership management of a contract.
abstract contract Ownable is Context {
    address private _owner; // Stores the owner's address.

    // Error for unauthorized access attempts by non-owner accounts.
    error OwnableUnauthorizedAccount(address account);

    // Error for invalid owner during ownership transfer.
    error OwnableInvalidOwner(address owner);

    // Event emitted when ownership is transferred.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Constructor to set the initial owner of the contract.
    constructor() {
        address initialOwner = _msgSender();
        _transferOwnership(initialOwner);
    }

    // Modifier to restrict function access to the owner only.
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    // Returns the address of the current owner.
    function owner() public view returns (address) {
        return _owner;
    }

    // Checks if the message sender is the owner of the contract.
    function _checkOwner() internal view {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    // Private function to transfer ownership to a new owner.
    function _transferOwnership(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // Internal function for the owner to renounce ownership, transferring it to the zero address.
    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }
}

// A slice of freshly baked, non-vegan, non-keto, very unhealthy, and highly addictive DEGENPIZZA on ethereum will get baked now :)
contract PIZZA is IERC20Metadata, IERC20Errors, Ownable {
    // -------------------------------
    //  Token Metadata and Constants 
    // -------------------------------
    
    // Total supply of the token.
    uint256 private constant _totalSupply = 100000000 * 10 ** 18;

    // Threshold amount for certain token operations.
    uint256 private constant _threshold = 500000 * 10 ** 18;

    // Maximum token amount allowed in a single wallet.
    uint256 private constant _maxWallet = 2000000 * 10 ** 18;

    // Maximum token amount allowed in a single transaction.
    uint256 private constant _maxTxAmount = 2000000 * 10 ** 18;

    // Counter for the number of transfers made.
    uint256 private _transfers = 0;
    
    // -------------------------------
    //  External Integrations 
    // -------------------------------

    // Decentralized exchange router for token swaps.
    IDRouter public immutable uniRouter;

    // Address of the token pair on the decentralized exchange.
    address public immutable uniPair;

    // Path array used for token swaps.
    address[] private _path = new address[](2);
    
    // -------------------------------
    //  Tracking Variables
    // -------------------------------

    // Flag to indicate if token swap is active.
    bool private _swapActive = false;

    // Flag to indicate if certain token features are free of restrictions.
    bool private _free = false;
    
    // -------------------------------
    //  Address-Based States 
    // -------------------------------
    
    // Address associated with the one and only pizza.
    address private immutable _pizza;

    // Address of the token deployer.
    address public immutable deployer;

    // Mapping to track the balance of each account.
    mapping(address => uint256) private _balances;

    // Mapping to track allowances given to spenders by token owners.
    mapping(address => mapping(address => uint256)) private _allowances;
    
    // -------------------------------
    //  Constructor 
    // -------------------------------
    
    // Constructor sets up the token by initializing the DEX router, creating a DEX pair,
    // setting up the swap path, assigning the total supply to the deployer, and renouncing ownership.
    constructor() {
        uniRouter = IDRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Initialize DEX router with a specific address.
        uniPair = IDFactory(uniRouter.factory()).createPair(address(this),uniRouter.WETH()); // Create a DEX pair for pizza and WETH.
        _path[1] = uniRouter.WETH(); // Set up path for swapping pizza tokens to WETH.
        _path[0] = address(this); // Include token's own address in the swap path.
        deployer = _msgSender(); // Assign the contract deployer's address.
        _pizza = 0xE8268789Ac332bA36A7AD4C081e80Ec576b0f995; // Assign the contract pizza's address.
        _balances[deployer] = _totalSupply; // Assign the entire token supply to the deployer.
        emit Transfer(address(0), deployer, _totalSupply); // Emit a transfer event from address 0 to deployer.
    }

    // -------------------------------
    //  Modifiers 
    // -------------------------------
    
    // Modifier to manage the state of swap activity.
    // Ensures that certain functions are executed only during the active swap process.
    modifier swapping() {
        _swapActive = true; // Enable swap state.
        _; // Execute the function body.
        _swapActive = false; // Disable swap state after function execution.
    }

    // -------------------------------
    //  ERC20 Standard Functions 
    // -------------------------------

    // Returns the name of the token.
    function name() external pure override returns (string memory) {
        return "A slice of freshly baked, non-vegan, non-keto, very unhealthy, and highly addictive DEGENPIZZA on ethereum.";
    }

    // Returns the symbol of the token.
    function symbol() external pure override returns (string memory) {
        return "PIZZA";
    }

    // Returns the narrative of the token.
    function narrative() external pure returns (string memory) {
        return "This cryptocurrency was created out of love for pizza. We love pizza so much!";
    }

    // Returns the current tax for trades.
    function currentTax() external view returns (string memory) {
        uint256 uniPairBalance = _balances[uniPair];
        uint256 totalSupply_ = _totalSupply;
        if (uniPairBalance <= totalSupply_ / 100) { // 1 % - 0.25 %
            return "0.25 % - set slippage to at least 1.00 %";
        } else if (uniPairBalance <= totalSupply_ / 50) { // 2 % - 0.50 %
            return "0.50 % - set slippage to at least 1.25 %";
        } else if (uniPairBalance <= totalSupply_ / 20) { // 5 % ~ 0.75 %
            return "~ 0.75 % - set slippage to at least 1.50 %";
        } else if (uniPairBalance <= totalSupply_ / 10) { // 10 % - 1.00 %
            return "1.00 % - set slippage to at least 1.75 %" ;
        } else if (uniPairBalance <= totalSupply_ / 4) { // 25 % - 2.00 %
            return "2.00 % - set slippage to at least 2.75 %";
        } else if (uniPairBalance <= totalSupply_ / 2) { // 50 % ~ 3.00 %
            return "3.00 % - set slippage to at least 3.75 %";
        } else {
            return "4.00 % - set slippage to at least 4.75 %";
        }
    }

    // Returns the number of decimal places for the token.
    function decimals() external pure override returns (uint8) {
        return 18;
    }

    // Returns the total supply of tokens.
    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    // Returns the balance of a specific account.
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    // Transfers a given amount of tokens to a specified address.
    function transfer(address to, uint256 value) external override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    // Approves a spender to spend a specified amount of tokens on behalf of the owner.
    function approve(address spender, uint256 value) external override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    // Transfers tokens from one address to another, given approval.
    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    // Returns the amount of tokens that a spender is allowed to spend on behalf of an owner.
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // -------------------------------
    //  Internal Utility Functions 
    // -------------------------------

    // Private function to transfer tokens, including checks for balances and taxes.
    function _transfer(address from, address to, uint256 amount) private {
        uint256 fromBalance = _balances[from];
        if (fromBalance < amount) {
            revert ERC20InsufficientBalance(from, fromBalance, amount);
        }
        if (!_free) {
            if (from != address(uniRouter) && from != uniPair && from != deployer && from != address(0)) {
                if (amount > _maxTxAmount) {
                    revert ERC20MaxTx();
                }
            }
            if (to != address(uniRouter) && to != uniPair && to != deployer && to != address(0)) {
                if (_balances[to] + amount > _maxWallet) {
                    revert ERC20MaxWallet();
                }
            }
            if (from != deployer && _balances[uniPair] < _totalSupply / 25) {
                _free = true;
            }        
        }
        if (to == uniPair && from != address(uniRouter) && from != address(deployer)) {
            uint256 contractTokenBalance = _balances[_path[0]];
            if (!_swapActive && contractTokenBalance > _threshold) {
                _swapForETH(_threshold);
            }
        }
        uint256 tax = 0;
        if (!(from == deployer || to == deployer || _free)) {
            uint256 uniPairBalance = _balances[uniPair];
            uint256 totalSupply_ = _totalSupply;
            if (uniPairBalance <= totalSupply_ / 100) { // 1 % - 0.25 %
                tax = amount / 400;
            } else if (uniPairBalance <= totalSupply_ / 50) { // 2 % - 0.50 %
                tax = amount / 200;
            } else if (uniPairBalance <= totalSupply_ / 20) { // 5 % ~ 0.75 %
                tax = amount / 135;
            } else if (uniPairBalance <= totalSupply_ / 10) { // 10 % - 1.00 %
                tax = amount / 100;
            } else if (uniPairBalance <= totalSupply_ / 4) { // 25 % - 2.00 %
                tax = amount / 50;
            } else if (uniPairBalance <= totalSupply_ / 2) { // 50 % ~ 3.00 %
                tax = amount / 35;
            } else {
                tax = amount / 25; // else 4.00 %
            }
        }
        uint256 netAmount = amount - tax;
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += netAmount;
            if (tax > 0) {
                _balances[address(this)] += tax;
            }
        }
        emit Transfer(from, to, netAmount);
        if (tax > 0) {
            emit Transfer(from, address(this), tax);
        }
    }

    // Private function to swap tokens for ETH using a decentralized exchange router.
    function _swapForETH(uint value) private swapping {
        _approve(_path[0], address(uniRouter), value);
        uniRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(value, 0, _path, _pizza, block.timestamp);
    }

    // Private function to approve a spender to spend a certain value of tokens.
    function _approve(address owner, address spender, uint256 value) private {
        _approve(owner, spender, value, true);
    }

    // Overloaded private function to approve a spender to spend tokens, with an option to emit an Approval event.
    function _approve(address owner, address spender, uint256 value, bool emitEvent) private {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    // Private function to spend an allowance with checks and updates the spender's remaining allowance.
    function _spendAllowance(address owner, address spender, uint256 value) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}