// Ether Dragon Website: www.drac24.wtf
// Ether Dragon Twitter / X: https://twitter.com/etherdrago6969?s=21&t=6QMEGCnqvt9oYdYwpUUa8w
// Ether Dragon TG: https://t.me/etherdrago
// Ether Dragon Discord: https://discord.gg/af8e5HmC

//                __====-_  _-====___
//                _--^^^#####//      \#####^^^--_  - ( Ether Dragon ) Ticker ( DRAC24 )
//             _-^##########// (    ) \##########^-_
//            -############//  |\^^/|  \############-
//          _/############//   (@::@)   \############\_
//         /#############((     \\//     ))#############\
//        -###############\\    (oo)    //###############-
//       -#################\\  / " " \  //#################-
//      -###################\\/  (   )  //###################-
//  _#/|##########/\######(   ' _ '  )######/\##########|\#_
//  |/ |/ |/ |/ |/ |  |  |  |  |  |  |  |  |/ |/ |/ |/ |/ |


// Sources flattened with hardhat v2.7.0 https://hardhat.org

// File @openzeppelin/contracts/utils/Context.sol@v4.4.0

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v4.4.0


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.4.0


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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


// File @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol@v4.4.0


// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/token/ERC20/ERC20.sol@v4.4.0


// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;


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

    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

   
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

  
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }


    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}



pragma solidity ^0.8.0;

contract EtherDragonToken is Ownable, ERC20 {
    uint256 public tokenPrice; // token amount per 1 ETH
    uint256 public presale_supply;
    uint256 public sold_supply;
    uint256 public min_eth;
    address public receiver;

    uint256 public constant TOTAL_SUPPLY = 224e9; // 224 billion DRAC tokens

    // Define an event for the token purchase
    event TokenPurchased(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);

    // Define an event for the sale finish
    event SaleFinished(address indexed owner, uint256 remainingSupply, uint256 ethSent);

     bool public presaleActive = true; // Add a variable to track presale status

   constructor(address _receiver, uint256 initialTokenSupply) ERC20("Ether Dragon", "DRAC24") {
        require(initialTokenSupply > 0, "Initial token supply must be greater than zero");
        receiver = _receiver;
        tokenPrice = 500000000; // 500M DRAC24 = 1 ETH
        min_eth = 0.0001 ether; // minimum payable eth value

        // Mint tokens for the dev wallet (70% of the initial supply)
        uint256 devWalletAmount = (initialTokenSupply * 70) / 100;
        _mint(receiver, devWalletAmount);

        sold_supply = 0;
    }


    function saleToken() external payable {
        require(presaleActive, "Presale has ended");
        require(presale_supply >= sold_supply + msg.value * tokenPrice, "Presale max supply is reached");
        require(msg.value <= 1 ether, "Maximum contribution is 1 ETH");

        uint256 tokenAmount = msg.value * tokenPrice;
        _mint(msg.sender, tokenAmount);
        sold_supply += tokenAmount;

        // Emit the TokenPurchased event
        emit TokenPurchased(msg.sender, msg.value, tokenAmount);
    }

    function finishSale() public onlyOwner {
        require(presaleActive, "Presale has already ended");

        // Set presaleActive to false to stop further purchases
        presaleActive = false;

        // Emit an event to log the sale finish
        emit SaleFinished(msg.sender, 0, address(this).balance);
    }



    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function setTokenPrice(uint256 _price) external onlyOwner {
        tokenPrice = _price;
    }

    function setPresaleSupply(uint256 _supply) external onlyOwner {
        presale_supply = _supply;
    }

    function setReceiveAddress(address _receiver) external onlyOwner {
        receiver = _receiver;
    }

    function withdrawETH(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient contract balance");
        (bool result, ) = payable(owner()).call{value: amount}("");
        require(result, "Failed to withdraw ETH");
    }

    receive() external payable {}
}