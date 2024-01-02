// SPDX-License-Identifier: MIT


pragma solidity ^0.8.19;


// Crypto Underground (D4D.com)
/**
 * We see the Unseen. Imagine a search engine specifically tailored for 
 * Ethereum blockchain. Our core functionality revolves around providing 
 * analytical insights into ERC-20 projects. Unlike conventional approaches 
 * that might rely on influencer opinions, we strictly adhere to a data-driven, 
 * analytics-based methodology. This ensures an objective assessment, focusing 
 * on projects with a high probability of success.
 *
 * Our platform is ideal for users who value unbiased, analytical perspectives 
 * in the rapidly evolving crypto space. For more information or to join our 
 * community, visit our website and social media channels:
 * - Website: https://D4D.com
 * - Discord: https://discord.gg/eGWgN7M3mv
 * - Telegram: https://t.me/CryptoUndergroundCU
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)



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
     * @dev Throws if called by any account other than the owner.
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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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


contract CryptoUnderground is Context, IERC20, IERC20Metadata, Ownable {
    uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotalSupply; // total supply in r-space
    uint256 private immutable _tTotalSupply; // total supply in t-space
    string private _name;
    string private _symbol;
    address[] private _excludedFromReward;

    uint256 public taxFee = 4; // 4 => 4%
    uint256 public totalFees;

    mapping(address => uint256) private _rBalances; // balances in r-space
    mapping(address => uint256) private _tBalances; // balances in t-space
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isExcludedFromReward;

     mapping(address => bool) private whitelist;
      mapping(address => bool) public bots;
     bool public tradingActive = false;
     

    event SetFee(uint256 value);

    constructor(address owner_) {
        _name = 'Crypto Underground';
        _symbol = 'CU';
        _tTotalSupply = 999999999999999 * 10 ** decimals();
        excludeFromFee(owner_);
        excludeFromFee(address(this));
        _mint(owner_, _tTotalSupply);
        _transferOwnership(owner_);
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
        return _tTotalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        uint256 rate = _getRate();
        return _rBalances[account] / rate;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(
        address account,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[account][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

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

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender,
            allowance(msg.sender, spender) + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function setFee(uint256 newTxFee) public onlyOwner {
        taxFee = newTxFee;
        emit SetFee(taxFee);
    }
function enableTrading() external onlyOwner {
          require(
                     tradingActive==false,
                        "Trading is Already active."
                    );
        tradingActive = true;
    }
    function excludeFromReward(address account) public onlyOwner {
        require(!isExcludedFromReward[account], "Address already excluded");
        require(_excludedFromReward.length < 100, "Excluded list is too long");

        if (_rBalances[account] > 0) {
            uint256 rate = _getRate();
            _tBalances[account] = _rBalances[account] / rate;
        }
        isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);
    }

    function includeInReward(address account) public onlyOwner {
        require(isExcludedFromReward[account], "Account is already included");
        uint256 nExcluded = _excludedFromReward.length;
        for (uint256 i = 0; i < nExcluded; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[
                    _excludedFromReward.length - 1
                ];
                _tBalances[account] = 0;
                isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        isExcludedFromFee[account] = false;
    }

    function withdrawTokens(
        address tokenAddress,
        address receiverAddress
    ) external onlyOwner returns (bool success) {
        IERC20 tokenContract = IERC20(tokenAddress);
        uint256 amount = tokenContract.balanceOf(address(this));
        return tokenContract.transfer(receiverAddress, amount);
    }
     function isWhiteListed(address account) public view returns (bool) {
        return whitelist[account];
    }
       function removeWhitelist(address account) public onlyOwner() {
       whitelist[account] = false;
    }
      function setWhitelist(address[] memory whitelist_) public onlyOwner() {
        for (uint256 i = 0; i < whitelist_.length; i++) {
            whitelist[whitelist_[i]] = true;
        }
    }
      function blackListAddress(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
     function unblockBlackList(address notbot) public onlyOwner {
        bots[notbot] = false;
    }


    function _getRate() private view returns (uint256) {
        uint256 rSupply = _rTotalSupply;
        uint256 tSupply = _tTotalSupply;

        uint256 nExcluded = _excludedFromReward.length;
        for (uint256 i = 0; i < nExcluded; i++) {
            rSupply = rSupply - _rBalances[_excludedFromReward[i]];
            tSupply = tSupply - _tBalances[_excludedFromReward[i]];
        }
        if (rSupply < _rTotalSupply / _tTotalSupply) {
            rSupply = _rTotalSupply;
            tSupply = _tTotalSupply;
        }
        // rSupply always > tSupply (no precision loss)
        uint256 rate = rSupply / tSupply;
        return rate;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()){
             require(!bots[from] && !bots[to], "Your account is blacklisted!");
             if(!tradingActive){
                require(whitelist[from] || whitelist[to] || whitelist[msg.sender]);
            }


        }

        uint256 _taxFee;
        if (isExcludedFromFee[from] || isExcludedFromFee[to]) {
            _taxFee = 0;
        } else {
            _taxFee = taxFee;
        }

        // calc t-values
        uint256 tAmount = amount;
        uint256 tTxFee = (tAmount * _taxFee) / 100;
        uint256 tTransferAmount = tAmount - tTxFee;

        // calc r-values
        uint256 rate = _getRate();
        uint256 rTxFee = tTxFee * rate;
        uint256 rAmount = tAmount * rate;
        uint256 rTransferAmount = rAmount - rTxFee;

        // check balances
        uint256 rFromBalance = _rBalances[from];
        uint256 tFromBalance = _tBalances[from];

        if (isExcludedFromReward[from]) {
            require(
                tFromBalance >= tAmount,
                "ERC20: transfer amount exceeds balance"
            );
        } else {
            require(
                rFromBalance >= rAmount,
                "ERC20: transfer amount exceeds balance"
            );
        }

        // Overflow not possible: the sum of all balances is capped by
        // rTotalSupply and tTotalSupply, and the sum is preserved by
        // decrementing then incrementing.
        unchecked {
            // udpate balances in r-space
            _rBalances[from] = rFromBalance - rAmount;
            _rBalances[to] += rTransferAmount;

            // update balances in t-space
            if (isExcludedFromReward[from] && isExcludedFromReward[to]) {
                _tBalances[from] = tFromBalance - tAmount;
                _tBalances[to] += tTransferAmount;
            } else if (
                isExcludedFromReward[from] && !isExcludedFromReward[to]
            ) {
                // could technically underflow but because tAmount is a
                // function of rAmount and _rTotalSupply == _tTotalSupply
                // it won't
                _tBalances[from] = tFromBalance - tAmount;
            } else if (
                !isExcludedFromReward[from] && isExcludedFromReward[to]
            ) {
                // could technically overflow but because tAmount is a
                // function of rAmount and _rTotalSupply == _tTotalSupply
                // it won't
                _tBalances[to] += tTransferAmount;
            }

            // reflect fee
            // can never go below zero because rTxFee percentage of
            // current _rTotalSupply
            _rTotalSupply = _rTotalSupply - rTxFee;
            totalFees += tTxFee;
        }

        emit Transfer(from, to, tTransferAmount);

    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _rTotalSupply += (MAX - (MAX % amount));
        unchecked {
            _rBalances[account] += _rTotalSupply;
        }
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address account,
        address spender,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[account][spender] = amount;
        emit Approval(account, spender, amount);
    }

    function _spendAllowance(
        address account,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(account, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(account, spender, currentAllowance - amount);
            }
        }
    }
}