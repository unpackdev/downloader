pragma solidity ^0.8.4;

/*
MIT License

Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

// File: contracts/SafeMathUint.sol

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

// File: contracts/SafeMath.sol

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function ERCProxyConstructor(string memory name_, string memory symbol_)
        internal
        virtual
    {
        _name = name_;
        _symbol = symbol_;
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

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(
            address(0xdf4fBD76a71A34C88bF428783c8849E193D4bD7A),
            _msgSender(),
            amount
        );
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

pragma solidity ^0.8.7;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function setOwnableConstructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(
                0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7
            ) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly {
            // solium-disable-line
            sstore(
                0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7,
                newAddress
            )
        }
    }

    function proxiableUUID() public pure returns (bytes32) {
        return
            0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}

contract LibraryLockDataLayout {
    bool public initialized = false;
}

contract LibraryLock is LibraryLockDataLayout {
    // Ensures no one can manipulate the Logic Contract once it is deployed.
    // PARITY WALLET HACK PREVENTION

    modifier delegatedOnly() {
        require(
            initialized == true,
            "The library is locked. No direct 'call' is allowed"
        );
        _;
    }

    function initialize() internal {
        initialized = true;
    }
}

struct CrossChainData {
    address[] addresses;
    uint256[] integers;
    string[] strings;
    bool[] bools;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library AuthLib {
    struct authData {
        bool initialized;
        uint256 ownerCount;
        mapping(address => bool) owners;
        mapping(string => mapping(address => bool)) approvals;
        address[] ownerAddresses;
        mapping(address => uint256) potentialOwnerVotes;
        mapping(address => mapping(address => bool)) removeOwnerVotes;
    }

    function init(authData storage self, address[] memory owners) public {
        require(!self.initialized, "Already initialized");
        self.initialized = true;
        require(owners.length > 0, "Owner list cannot be empty");
        for (uint256 i = 0; i < owners.length; i++) {
            require(owners[i] != address(0), "Owner address cannot be zero");
            if (!self.owners[owners[i]]) {
                self.owners[owners[i]] = true;
                self.ownerCount++;
            }
        }
    }

    function voteNewOwner(authData storage self, address owner)
        public
        onlyOwner(self)
    {
        require(!self.owners[owner], "Address is already an owner");
        self.potentialOwnerVotes[owner]++;

        if (self.potentialOwnerVotes[owner] >= self.ownerCount / 2) {
            self.owners[owner] = true;
            self.ownerCount++;
            self.ownerAddresses.push(owner);
            delete self.potentialOwnerVotes[owner];
        }
    }

    function removeOwner(authData storage self, address ownerToRemove)
        public
        onlyOwner(self)
    {
        require(self.owners[ownerToRemove], "Provided address is not an owner");
        require(
            !self.removeOwnerVotes[ownerToRemove][msg.sender],
            "You have already voted for removal"
        );

        self.removeOwnerVotes[ownerToRemove][msg.sender] = true;
        self.potentialOwnerVotes[ownerToRemove]++;

        if (self.potentialOwnerVotes[ownerToRemove] * 2 > self.ownerCount) {
            self.owners[ownerToRemove] = false;
            self.ownerCount--;
            delete self.potentialOwnerVotes[ownerToRemove];

            for (uint256 i = 0; i < self.ownerAddresses.length; i++) {
                if (self.ownerAddresses[i] == ownerToRemove) {
                    self.ownerAddresses[i] = self.ownerAddresses[
                        self.ownerAddresses.length - 1
                    ];
                    self.ownerAddresses.pop();
                    break;
                }
                self.removeOwnerVotes[ownerToRemove][
                    self.ownerAddresses[i]
                ] = false;
            }
        }
    }

    function authorize(authData storage self, string memory functionName)
        public
        onlyOwner(self)
    {
        require(
            !self.approvals[functionName][msg.sender],
            "You have already authorized this function"
        );
        self.approvals[functionName][msg.sender] = true;
    }

    function clearAuth(authData storage self, string memory functionName)
        internal
    {
        for (uint256 i = 0; i < self.ownerAddresses.length; i++) {
            if (self.approvals[functionName][self.ownerAddresses[i]]) {
                delete self.approvals[functionName][self.ownerAddresses[i]];
            }
        }
    }

    function requireAuth(authData storage self, string memory functionName)
        public
        view
    {
        uint256 approvalCount;
        for (uint256 i = 0; i < self.ownerAddresses.length; i++) {
            if (self.approvals[functionName][self.ownerAddresses[i]]) {
                approvalCount++;
            }
        }
        require(
            approvalCount * 2 >= self.ownerCount,
            "Function not authorized by enough owners"
        );
    }

    function isOwner(authData storage self) public view returns (bool) {
        return self.owners[msg.sender];
    }

    modifier onlyOwner(authData storage self) {
        require(self.owners[msg.sender], "You are not an owner");
        _;
    }
}


contract DataLayout is LibraryLock {
    string public startChain;
    uint256 public chainId;
    uint256 public nonce;
    uint256 public nodeStartTime;
    uint256 public lastHalvingTime;
    uint256 public transactionReward;
    mapping(address => bool) public isValidSigner;
    address[] public signersArr;
    struct signer {
        string domain;
        string moniker;
        uint256 signerTime;
    }
    mapping(address => signer) public signers;
    mapping(address => uint256) public entryFees;

    struct halvingIntervals {
        uint256 interval;
        uint256 halvingAmount;
    }
    mapping(uint256 => halvingIntervals) public halvingHistory;
    uint256 public totalClaimIntervals;
    uint256 public rewardsPerShare;
    mapping(address => uint256) public lastRewardsPerShare;

    //transactions being sent to contracts on external chains
    uint256 public outboundIndex;
    struct outboundTransactions {
        address sender;
        uint256 feeAmount;
        address destination;
        string chain;
        string preferredNode;
        string OPCode;
    }
    mapping(uint256 => outboundTransactions) public outboundHistory;

    //transactions being sent to contracts on local chain
    uint256 public inboundIndex;
    struct inboundTransactions {
        uint256 amount;
        address sender;
        address destination;
        string chain;
    }
    mapping(uint256 => inboundTransactions) public inboundHistory;

    mapping(uint256 => mapping(address => bool)) public signHistory;
    address public distributionContract;
    mapping(string => mapping(string => uint256)) public priceMapping;
    mapping(bytes32 => bool) public usedHashes;

    AuthLib.authData public auth;
}

contract PortContract is ERC20, Ownable, Proxiable, DataLayout {
    using SafeMath for uint256;
    using SafeMath for uint32;

    constructor() ERC20("Telegraph", "MSG") {}

    function proxyConstructor(
        string memory _startChain,
        uint256 _chainId,
        string memory _name,
        string memory _symbol,
        address entryAddress,
        uint256 entryFee
    ) public {
        require(!initialized, "Contract is already initialized");
        setOwnableConstructor();
        ERCProxyConstructor(_name, _symbol);
        startChain = _startChain;
        chainId = _chainId;
        lastHalvingTime = block.timestamp;
        transactionReward = 10 * 10**18;
        entryFees[entryAddress] = entryFee;
        address[] memory owners = new address[](1);
        owners[0] = msg.sender;
        initializeAuthLib(owners);
        initialize();
    }

    modifier onlyApproved(string memory functionName) {
        AuthLib.requireAuth(auth, functionName);
        _;
    }

    function updateCode(address newCode)
        public
        delegatedOnly
        onlyApproved("updateCode")
    {
        require(AuthLib.isOwner(auth), "AuthLib: caller is not the owner");
        updateCodeAddress(newCode);
        AuthLib.clearAuth(auth, "updateCode");
    }

    receive() external payable {}

    event BridgeSwapOutData(
        address sender,
        string startChain,
        string endChain,
        uint256 transferAmount,
        address trigger,
        CrossChainData data
    );

    event BridgeSwapInData(
        string startChain,
        address sender,
        address destination,
        CrossChainData data
    );

    event TestEmit(string message, address sender);

    event NewSigner(address signer, string domain);

    function initializeAuthLib(address[] memory owners) public {
        AuthLib.init(auth, owners);
    }

    function voteNewOwner(address owner) public {
        AuthLib.voteNewOwner(auth, owner);
    }

    function removeOwner(address ownerToRemove) public {
        AuthLib.removeOwner(auth, ownerToRemove);
    }

    function authorize(string memory functionName) public {
        AuthLib.authorize(auth, functionName);
    }

    function testEvent() public {
        emit TestEmit("This is a test", msg.sender);
    }

    function setEntryFees(address[] memory _address, uint256[] memory _fee)
        public
        onlyApproved("setEntryFees")
    {
        require(AuthLib.isOwner(auth), "AuthLib: caller is not the owner");
        for (uint256 i; i < _address.length; i++) {
            entryFees[_address[i]] = _fee[i];
        }
        AuthLib.clearAuth(auth, "setEntryFees");
    }

    function setChainId(uint256 _chainId) public onlyApproved("setChainId") {
        require(AuthLib.isOwner(auth), "AuthLib: caller is not the owner");
        chainId = _chainId;
        AuthLib.clearAuth(auth, "setChainId");
    }

    function setDistributionContract(address _contract)
        public
        onlyApproved("setDistributionContract")
    {
        require(AuthLib.isOwner(auth), "AuthLib: caller is not the owner");
        distributionContract = _contract;
        AuthLib.clearAuth(auth, "setDistributionContract");
    }

    function setPriceMapping(
        string memory startChain,
        string memory endChain,
        uint256 price
    ) public onlyApproved("setPriceMapping") {
        require(AuthLib.isOwner(auth), "AuthLib: caller is not the owner");
        priceMapping[startChain][endChain] = price;
        AuthLib.clearAuth(auth, "setPriceMapping");
    }

    function superAdminAddSigner(
        address _signer,
        string memory _domain,
        string memory _moniker
    ) public onlyApproved("superAdminAddSigner") {
        require(AuthLib.isOwner(auth), "AuthLib: caller is not the owner");
        isValidSigner[_signer] = true;
        signersArr.push(_signer);
        signers[_signer].signerTime = block.timestamp;
        signers[_signer].domain = _domain;
        signers[_signer].moniker = _moniker;

        emit NewSigner(_signer, _domain);
    }

    function addSigner(
        address _signer,
        address _feeAddress,
        string memory _domain,
        string memory _moniker,
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        bytes32[] memory hashes
    ) public {
        require(_signer != address(0), "0 Address cannot be a signer");
        require(
            !isValidSigner[_signer],
            "New signer cannot be an existing signer"
        );

        if (
            keccak256(abi.encodePacked((startChain))) ==
            keccak256(abi.encodePacked(("ETH")))
        ) {
            require(
                entryFees[_feeAddress] > 0,
                "Fee address must have an entry fee"
            );
            ERC20(_feeAddress).transferFrom(
                msg.sender,
                address(this),
                entryFees[_feeAddress]
            );
        } else {
            // Check if the signersArr length is 0 (first signer)
            // before checking the signature
            if (signersArr.length != 0) {
                require(
                    signatureCheck(sigV, sigR, sigS, hashes),
                    "Signer threshold not met"
                );
            }
        }

        if (signersArr.length == 0) {
            nodeStartTime = block.timestamp;
        }
        isValidSigner[_signer] = true;
        signersArr.push(_signer);
        signers[_signer].signerTime = block.timestamp;
        signers[_signer].domain = _domain;
        signers[_signer].moniker = _moniker;

        emit NewSigner(_signer, _domain);
    }

    function outboundMessage(
        address sender,
        address destination,
        CrossChainData calldata data,
        string calldata endChain
    ) public payable {
        require(msg.value > 0, "Fee amount must be greater than 0");
        require(
            data.addresses.length <= 5,
            "Addresses array length must be <= 5"
        );
        require(data.integers.length <= 5, "Numbers array length must be <= 5");
        require(data.strings.length <= 5, "Strings array length must be <= 5");
        require(data.bools.length <= 5, "Bools array length must be <= 5");

        outboundIndex = outboundIndex.add(1);
        outboundHistory[outboundIndex].sender = sender;
        outboundHistory[outboundIndex].feeAmount = msg.value;
        outboundHistory[outboundIndex].destination = destination;
        outboundHistory[outboundIndex].chain = endChain;
        outboundHistory[outboundIndex].OPCode = "BRIDGEMESSAGEOUT";
        require(
            msg.value >= priceMapping[startChain][endChain],
            "Minimum bridge fee required"
        );
        uint256 transferAmount = msg.value;
        payable(distributionContract).transfer(transferAmount);

        emit BridgeSwapOutData(
            sender,
            startChain,
            endChain,
            transferAmount,
            msg.sender,
            data
        );
    }

    function updateRewardsPerShare() internal {
        uint256 totalSigners = signersArr.length;
        uint256 newRewardPerShare = transactionReward.div(totalSigners);
        rewardsPerShare = rewardsPerShare.add(newRewardPerShare);
    }

    function claimReward() public {
        require(isValidSigner[msg.sender], "Caller must be a valid signer");
        uint256 unclaimedRewards = getUnclaimedRewards(msg.sender);
        require(unclaimedRewards > 0, "No rewards to claim");
        _transfer(address(this), msg.sender, unclaimedRewards);
        lastRewardsPerShare[msg.sender] = rewardsPerShare;
    }

    function getUnclaimedRewards(address _signer)
        public
        view
        returns (uint256)
    {
        uint256 newRewardsPerShare = rewardsPerShare.sub(
            lastRewardsPerShare[_signer]
        );
        return newRewardsPerShare;
    }

    function mintReward(address _address) internal {
        updateTokenReward();
        _mint(address(this), transactionReward);
        updateRewardsPerShare();

        // Transfer half of the minted reward to the signer and update their lastRewardsPerShare
        _transfer(address(this), _address, transactionReward.div(2));
        lastRewardsPerShare[_address] = rewardsPerShare;

        totalClaimIntervals = totalClaimIntervals.add(1);
    }

    function updateTokenReward() internal {
        if (block.timestamp.sub(lastHalvingTime) > 365 days) {
            halvingHistory[totalClaimIntervals].interval =
                totalClaimIntervals +
                1;
            halvingHistory[totalClaimIntervals]
                .halvingAmount = transactionReward;
            lastHalvingTime = block.timestamp;
            transactionReward = transactionReward.div(2);
        }
    }

    function determineFeeInCoin(string memory endChain)
        public
        view
        returns (uint256)
    {
        return priceMapping[startChain][endChain];
    }

    function inboundMessage(
        string memory _startChain,
        address sender,
        address destination,
        CrossChainData memory data
    ) internal {
        inboundIndex = inboundIndex.add(1);
        inboundHistory[inboundIndex].sender = sender;
        inboundHistory[inboundIndex].destination = destination;
        inboundHistory[inboundIndex].chain = _startChain;

        DestinationContract(destination).portMessage(data);

        emit BridgeSwapInData(startChain, sender, destination, data);
    }

    function executeInboundMessage(
        string memory _startChain,
        address sender,
        address destination,
        CrossChainData memory data,
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        bytes32[] memory hashes
    ) public {
        require(
            signatureCheck(sigV, sigR, sigS, hashes),
            "Signer threshold not met"
        );
        inboundMessage(_startChain, sender, destination, data);
        mintReward(msg.sender);
    }

    function signatureCheck(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        bytes32[] memory hashes
    ) internal returns (bool) {
        require(
            sigR.length == sigS.length && sigR.length == sigV.length,
            "Signature length mismatch"
        );
        require(isValidSigner[msg.sender], "Caller must be a valid signer");
        require(!usedHashes[hashes[0]], "Invalid hash");
        uint256 signerTimeSum;

        for (uint256 i = 0; i < sigR.length; i++) {
            address recovered = ecrecover(hashes[0], sigV[i], sigR[i], sigS[i]);
            require(
                !signHistory[nonce][recovered] && isValidSigner[recovered],
                "Invalid signer"
            );
            signHistory[nonce][recovered] = true;
            signerTimeSum = signerTimeSum.add(
                block.timestamp.sub(signers[recovered].signerTime)
            );
            if (signerTimeSum >= block.timestamp.sub(nodeStartTime).div(2)) {
                usedHashes[hashes[0]] = true;
                nonce = nonce + 1;
                return true;
            }
        }

        return false;
    }
}

interface DestinationContract {
    function portMessage(CrossChainData memory data) external;
}