// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: re.sol

//SPDX-License-Identifier: NONE
pragma solidity ^0.8.10;



interface IXEN {
    function claimRank(uint256 term) external;
    function claimMintReward() external;
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function userMints(address) external view returns (address, uint256, uint256, uint256, uint256, uint256);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract XENDAO is ERC20("Xen DAO", "XD"), ReentrancyGuard {
	struct UserInfo {
        uint256 amount;         // tokens burned from user
        uint256 rewardDebt;     // Reward debt
    }
	
    uint256 public constant INITIALARTIFICIALBURN = 10000; // avoids division by 0 on first deposit
    uint256 public immutable MAXFEE; 

	mapping (address => UserInfo) public userInfo;
	
	uint256 public accEthPerShare;
	uint256 public latestBalance; //latest Fee balance
	
	uint256 public reward = 1e24; //1 million xenDao per mint 
	uint256 public rewardWbonus = 125 * 1e22; // +25% bonus if referred
	uint256 public refbonus = 250 * 1e21; // 250K tokens referral bonus
	
    uint256 public fee; // max fee
	uint256 public claimAgainFee; // claim again fee
	uint256 public lastRewardUpdate;
	uint256 public launchDate;
	uint256 public dayCount = 1;
	uint256 public totalBurned = 10000; //amount staked(to calculate total supply)
	
    XENBatchMint[] contracts;
	XENBatchMintDisposable[] contractsDisposable;
	
	uint256 public alreadyMinted = 0;
	address public noExpectationAddress;

    mapping(address => uint256 []) public userMintFirst;
    mapping(address => uint256 []) public userMintLast;
	
	mapping(address => uint256 []) public userMintFirstDisposable;
    mapping(address => uint256 []) public userMintLastDisposable;
	
	constructor(uint256 _fee, uint256 _claimAgainFee, uint256 _maxFee, address _noExpect) {
		lastRewardUpdate = block.timestamp + 13 * 24 * 3600; //steady for first 14 days
		launchDate = block.timestamp;
        fee = _fee;
        claimAgainFee = _claimAgainFee;
        MAXFEE = _maxFee;
        noExpectationAddress = _noExpect;
	}

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function createContract (uint256 term, uint256 quantity) external payable {
		require(msg.value == fee*quantity, "ETH sent is incorrect");
        userMintFirst[msg.sender].push(contracts.length);
        for(uint i=0; i<quantity; i++) {
            contracts.push(new XENBatchMint(msg.sender, term));
        }
        userMintLast[msg.sender].push(contracts.length-1);
		_mint(msg.sender, quantity * reward);
    }
	
	function createContractDisposable (uint256 term, uint256 quantity) external payable {
        require(msg.value == fee*quantity, "ETH sent is incorrect");
        userMintFirstDisposable[msg.sender].push(contractsDisposable.length);
        for(uint i=0; i<quantity; i++) {
            contractsDisposable.push(new XENBatchMintDisposable(msg.sender, term));
        }
        userMintLastDisposable[msg.sender].push(contractsDisposable.length-1);
		_mint(msg.sender, quantity * reward);
    }
	
    function createContractRef (uint256 term, uint256 quantity, address referral) external payable {
        require(msg.value == fee*quantity, "ETH sent is incorrect");
        userMintFirst[msg.sender].push(contracts.length);
        for(uint i=0; i<quantity; i++) {
            contracts.push(new XENBatchMint(msg.sender, term));
        }
        userMintLast[msg.sender].push(contracts.length-1);
		_mint(msg.sender, quantity * rewardWbonus);
		if(referral != msg.sender) {_mint(referral, quantity * refbonus); }
    }
	
	function createContractDisposableRef (uint256 term, uint256 quantity, address referral) external payable {
        require(msg.value == fee*quantity, "ETH sent is incorrect");
        userMintFirstDisposable[msg.sender].push(contractsDisposable.length);
        for(uint i=0; i<quantity; i++) {
            contractsDisposable.push(new XENBatchMintDisposable(msg.sender, term));
        }
        userMintLastDisposable[msg.sender].push(contractsDisposable.length-1);
		_mint(msg.sender, quantity * rewardWbonus);
		if(referral != msg.sender) { _mint(referral, quantity * refbonus); }
    }
	
	function stake(uint256 _amount) external nonReentrant {
		uint256 _tokenChange = address(this).balance - latestBalance;
		accEthPerShare = accEthPerShare + _tokenChange * 1e12 / totalBurned;
		
		_burn(msg.sender, _amount);
		totalBurned+= _amount;
		
		if(userInfo[msg.sender].amount == 0) { //no previous balance
			userInfo[msg.sender].amount = _amount;
            userInfo[msg.sender].rewardDebt = userInfo[msg.sender].amount * accEthPerShare / 1e12; 
		} else {
			uint256 _pending = userInfo[msg.sender].amount * accEthPerShare / 1e12 - userInfo[msg.sender].rewardDebt;
			userInfo[msg.sender].amount+= _amount;
            userInfo[msg.sender].rewardDebt = userInfo[msg.sender].amount * accEthPerShare / 1e12 - _pending; 
		}
		latestBalance = address(this).balance;
	}

	function harvest() public nonReentrant {
		uint256 _tokenChange = address(this).balance - latestBalance;
		accEthPerShare = accEthPerShare + _tokenChange * 1e12 / totalBurned;
		uint256 _pending = userInfo[msg.sender].amount * accEthPerShare / 1e12 - userInfo[msg.sender].rewardDebt;
		
		userInfo[msg.sender].rewardDebt = userInfo[msg.sender].amount * accEthPerShare / 1e12; // reset 
		payable(msg.sender).transfer(_pending);
		latestBalance = address(this).balance;
	}
	
	function withdraw() external nonReentrant {
		uint256 _tokenChange = address(this).balance - latestBalance;
		accEthPerShare = accEthPerShare + _tokenChange * 1e12 / totalBurned;
		
		uint256 _pending = userInfo[msg.sender].amount * accEthPerShare / 1e12 - userInfo[msg.sender].rewardDebt;
		
		uint256 _tokensStaked = userInfo[msg.sender].amount;
		
		userInfo[msg.sender].amount = 0;
		userInfo[msg.sender].rewardDebt = 0;
		
		payable(msg.sender).transfer(_pending);
		latestBalance = address(this).balance;
		
		_mint(msg.sender, _tokensStaked);
		totalBurned-= _tokensStaked;
	}
	
    function mintAll(uint256 _startId, uint256 _stopId) external {
        XENBatchMint x;
        for(uint256 i=_startId; i <= _stopId; i++) {
            x = contracts[i];
            x.mint();
        }
    }
	
	function mintAllDisposable(uint256 _startId, uint256 _stopId) external {
        XENBatchMintDisposable x;
        for(uint256 i=_startId; i <= _stopId; i++) {
            x = contractsDisposable[i];
            x.mint();
        }
    }

    function claimAgain(uint256 _startId, uint256 _stopId, uint256 _term) external {
       XENBatchMint x;
        for(uint256 i=_startId; i <= _stopId; i++) {
            x = contracts[i];
            x.claim(_term);
        }
    }

    function claimAgainWithFee(uint256 _startId, uint256 _stopId, uint256 _term, address _referral) external payable {
        uint256 _quantity = _stopId - _startId + 1;
        uint256 _tAmount = claimAgainFee * _quantity;
        require(msg.value == _tAmount, "ETH sent is incorrect");
        XENBatchMint x;
        for(uint256 i=_startId; i <= _stopId; i++) {
            x = contracts[i];
            x.claim(_term);
        }
        
        if(_referral != msg.sender) {
            _mint(msg.sender, _quantity * rewardWbonus);
            _mint(_referral, _quantity * refbonus);
        } else {
            _mint(msg.sender, _quantity * reward);
        }
    }

    //returns earnings, amount staked and total Staked
	function userStakeEarnings(address _user) external view returns (uint256, uint256, uint256) {
		uint256 _tokenChange = address(this).balance - latestBalance;
		uint256 _tempAccEthPerShare = accEthPerShare + _tokenChange * 1e12 / totalBurned;
		
		uint256 _pending = userInfo[_user].amount * _tempAccEthPerShare / 1e12 - userInfo[_user].rewardDebt;
		
		return (_pending, userInfo[_user].amount, totalBurned);
	}
	
    function userMints(address _user) external view returns(uint256, uint256) {
        return (userMintFirst[_user].length, userMintFirstDisposable[_user].length); 
    }

    function totalMints() external view returns(uint256, uint256) {
        return (contracts.length, contractsDisposable.length);
    }

    function contractAddress(uint256 _id) public view returns (XENBatchMint) {
        return contracts[_id];
    }
	
	function contractAddressDisposable(uint256 _id) public view returns (XENBatchMintDisposable) {
        return contractsDisposable[_id];
    }

    function multiData(address _user, uint256 _id) external view returns (uint256, uint256, uint256) {
        return (userMintFirst[_user][_id], userMintLast[_user][_id], getMaturationDate(userMintFirst[_user][_id]));
    }
	
	 function multiDataDisposable(address _user, uint256 _id) external view returns (uint256, uint256, uint256) {
        return (userMintFirstDisposable[_user][_id], userMintLastDisposable[_user][_id], getMaturationDateDisposable(userMintFirstDisposable[_user][_id]));
    }

    function getMaturationDate(uint256 _id) public view returns (uint256) {
        (, , uint256 maturation, , , ) = IXEN(0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8).userMints(address(contractAddress(_id)));
        return maturation;
    }

    function getMaturationDateDisposable(uint256 _id) public view returns (uint256) {
        (, , uint256 maturation, , , ) = IXEN(0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8).userMints(address(contractAddressDisposable(_id)));
        return maturation;
    }
	
	function totalSupply() public view virtual override returns (uint256) {
        return super.totalSupply() + totalBurned - INITIALARTIFICIALBURN;
    }
	
	// inflationary only for the first 3-4 months
	function decreaseRewards() external {
		require(block.timestamp - lastRewardUpdate > 86400, "Decrease not yet eligible. Must wait 1 day between calls");
		reward = reward * (100 - dayCount) / 100;
		rewardWbonus = rewardWbonus * (100 - dayCount) / 100;
		refbonus = refbonus * (100 - dayCount) / 100;
		
		dayCount++;
	}
	
	function killInflation() external {
		require(block.timestamp > 1673740800, "Must wait until 15th Jan 2023");
		reward = 0;
		rewardWbonus = 0;
		refbonus = 0;
	}
	
	function mintNoExpectation() external nonReentrant {
        require(msg.sender == noExpectationAddress, "not allowed");
		uint256 _totalAllowed = totalSupply() / 10;
		uint256 _toMint = _totalAllowed - alreadyMinted;
		alreadyMinted+= _toMint;
		_mint(noExpectationAddress, _toMint);
	}

    function setFee(uint256 _newFee, uint256 _againFee) external {
        require(_newFee <= MAXFEE && _againFee <= MAXFEE, "over limit");
        require(msg.sender == noExpectationAddress);
        fee = _newFee;
        claimAgainFee = _againFee;
    }
	
	function changeAddress(address _noExpect) external nonReentrant {
		require(msg.sender == noExpectationAddress);
		noExpectationAddress = _noExpect;
	}
}

contract XENBatchMint {
    address private owner;

    constructor (address _owner, uint256 term) {
        owner = _owner;
        IXEN(0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8).claimRank(term);
    }

    function mint() external {
        IXEN(0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8).claimMintReward();
        IXEN(0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8).transfer(owner, IXEN(0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8).balanceOf(address(this)));
    }

    function claim(uint256 _term) external {
        require(tx.origin == owner);
        IXEN(0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8).claimRank(_term);
    }
}

contract XENBatchMintDisposable {
    address private owner;

    constructor (address _owner, uint256 term) {
        owner = _owner;
        IXEN(0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8).claimRank(term);
    }

    function mint() external {
        IXEN(0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8).claimMintReward();
        IXEN(0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8).transfer(owner, IXEN(0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8).balanceOf(address(this)));
    }
}