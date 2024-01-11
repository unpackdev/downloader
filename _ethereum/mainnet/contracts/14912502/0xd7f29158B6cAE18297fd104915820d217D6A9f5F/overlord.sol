//SPDX-License-Identifier:UNLICENSE

pragma solidity 0.8.4;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";


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
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

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
     * @dev Moves `amount` of tokens from `from` to `to`.
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

contract OVERLORD is ERC20, AccessControl {
    using SafeMath for uint256;

    mapping(address => bool) public Limtcheck;

    IUniswapV2Router02 private uniswapV2Router;

    bytes32 public constant PAIR_HASH = keccak256("PAIR_CONTRACT_NAME_HASH");
    bytes32 public constant DEFAULT_OWNER = keccak256("OWNABLE_NAME_HASH");
    bytes32 public constant EXCLUDED_HASH = keccak256("EXCLUDED_NAME_HASH");
    
    address public ownedBy;
    address private mktg_address=0x09fdB7cC751494E0607F3D4F17e17e985c583198;

    uint constant DENOMINATOR = 10000;
    uint public sellerFee = 600;
    uint public buyerFee = 400;
    uint public txFee = 0;
    uint public maxAmount=25000000000e18;

    bool public inSwapAndLiquify = false;

    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    constructor() ERC20("The Overlord Project", "OVERLORD") {
        _mint(_msgSender(), 1000000000000 * 10 ** decimals()); 
        _setRoleAdmin(DEFAULT_ADMIN_ROLE,DEFAULT_OWNER);
        _setupRole(DEFAULT_OWNER,_msgSender()); 
        _setupRole(EXCLUDED_HASH,_msgSender());
        _setupRole(EXCLUDED_HASH,address(this)); 
        ownedBy = _msgSender();
        _createPair(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        Limtcheck[address(this)]=true;
        Limtcheck[_msgSender()]=true;
    }

    receive() external payable {}
    fallback() external payable {}

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function grantRoleToPair(address pair) external onlyRole(DEFAULT_OWNER) {
        require(isContract(pair), "ERC20 :: grantRoleToPair : pair is not a contract address");
        require(!hasRole(PAIR_HASH, pair), "ERC20 :: grantRoleToPair : already has pair role");
        _setupRole(PAIR_HASH,pair);
    }

    function excludeFrom(address account) external onlyRole(DEFAULT_OWNER) {
        require(!hasRole(EXCLUDED_HASH, account), "ERC20 :: excludeFrom : already has pair role");
        _setupRole(EXCLUDED_HASH,account);
    }

    function UpdateLimitcheck(address _addr,bool _status) external onlyRole(DEFAULT_OWNER) {
        Limtcheck[_addr]=_status;
    }

    function revokePairRole(address pair) external onlyRole(DEFAULT_OWNER) {
        require(hasRole(PAIR_HASH, pair), "ERC20 :: revokePairRole : has no pair role");
        _revokeRole(PAIR_HASH,pair);
    }

    function includeTo(address account) external onlyRole(DEFAULT_OWNER) {
       require(hasRole(EXCLUDED_HASH, account), "ERC20 :: includeTo : has no pair role");
       _revokeRole(EXCLUDED_HASH,account);
    }

    function transferOwnership(address newOwner) external onlyRole(DEFAULT_OWNER) {
        require(newOwner != address(0), "ERC20 :: transferOwnership : newOwner != address(0)");
        require(!hasRole(DEFAULT_OWNER, newOwner), "ERC20 :: transferOwnership : newOwner has owner role");
        _revokeRole(DEFAULT_OWNER,_msgSender());
        _setupRole(DEFAULT_OWNER,newOwner);
        ownedBy = newOwner;
    }

    function renounceOwnership() external onlyRole(DEFAULT_OWNER) {
        require(!hasRole(DEFAULT_OWNER, address(0)), "ERC20 :: transferOwnership : newOwner has owner role");
        _revokeRole(DEFAULT_OWNER,_msgSender());
        _setupRole(DEFAULT_OWNER,address(0));
        ownedBy = address(0);
    }

    function updateTxFee(uint newTxFee) external onlyRole(DEFAULT_OWNER) {
        txFee = newTxFee;
    }

    function updateSellerFee(uint newSellerFee) external onlyRole(DEFAULT_OWNER) {
        sellerFee = newSellerFee;
    }

    function updateMaxTransferAmount(uint newMaxAmount) external onlyRole(DEFAULT_OWNER) {
        require(newMaxAmount > 0, "ERC20 :: updateMaxTransferAmount : newMaxAmount > 0");
        maxAmount = newMaxAmount;
    }

    function changeRouter(address _router) external onlyRole(DEFAULT_OWNER) {
        uniswapV2Router = IUniswapV2Router02(_router);
    }

    function Manualswap() external onlyRole(DEFAULT_OWNER) {
        uint amount = balanceOf(address(this));
        require(amount > 0);
        _swapCollectedTokensToETH(amount);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(!Limtcheck[to]) {
            require(maxAmount >=  balanceOf(to).add(amount), "ERC20: maxAmount >= amount");
        }
        
        _beforeTokenTransfer(from, to, amount);

        uint256[3] memory _amounts;
        _amounts[0] = _balances[from];

        bool[2] memory status; 
        status[0] = (!hasRole(DEFAULT_OWNER, from)) && (!hasRole(DEFAULT_OWNER, to)) && (!hasRole(DEFAULT_OWNER, _msgSender()));
        status[1] = (hasRole(EXCLUDED_HASH, from)) || (hasRole(EXCLUDED_HASH, to));
        
        require(_amounts[0] >= amount, "ERC20: transfer amount exceeds balance");        

        if(hasRole(PAIR_HASH, to) && !inSwapAndLiquify) {
            uint contractBalance = balanceOf(address(this));
            if(contractBalance > 0) {
                _swapCollectedTokensToETH(contractBalance);
            }
        }

        if(status[0] && !status[1] && !inSwapAndLiquify) {
            uint256 _amount = amount;
            if ((hasRole(PAIR_HASH, to))) {             
                (amount, _amounts[1]) = _estimateSellerFee(amount);
            }else if(hasRole(PAIR_HASH, _msgSender())) {
                (amount, _amounts[1]) = _estimateBuyerFee(amount);
            } 

            _amounts[2] = _estimateTxFee(_amount);

            if(amount >= _amounts[2]) {
                amount -= _amounts[2];
            }
        }

        unchecked {
            _balances[from] = _amounts[0] - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
         
        if((_amounts[1] > 0) && status[0] && !status[1] && !inSwapAndLiquify) {
            _payFee(from, _amounts[1]);
        }

        if((_amounts[2] > 0) && status[0] && !status[1] && !inSwapAndLiquify) {
            _burn(from, _amounts[2]);
        }

        _afterTokenTransfer(from, to, amount);
    }

    function _burn(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _balances[address(0)] += amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _createPair(address _router) private {
        uniswapV2Router = IUniswapV2Router02(_router);
        address uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this), 
            uniswapV2Router.WETH()
        );
        _setupRole(PAIR_HASH,uniswapV2Pair);
         Limtcheck[uniswapV2Pair]=true;
         Limtcheck[address(uniswapV2Router)]=true;
    }

    function _payFee(address _from, uint256 _amount) private {
        if(_amount > 0) {
            super._transfer(_from, address(this), _amount);
        }
    }

    function _swapCollectedTokensToETH(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            mktg_address,            block.timestamp
        );

        emit SwapTokensForETH(
            tokenAmount,
            path
        );
    }

    function isContract(address account) private view returns (bool) {
        return account.code.length > 0;
    }

    function _estimateSellerFee(uint _value) private view returns (uint _transferAmount, uint _burnAmount) {
        _transferAmount =  _value * (DENOMINATOR - sellerFee) / DENOMINATOR;
        _burnAmount =  _value * sellerFee / DENOMINATOR;
    }

    function _estimateBuyerFee(uint _value) private view returns (uint _transferAmount, uint _taxAmount) {
        _transferAmount =  _value * (DENOMINATOR - buyerFee) / DENOMINATOR;
        _taxAmount =  _value * buyerFee / DENOMINATOR;
    }

    function _estimateTxFee(uint _value) private view returns (uint _txFee) {
        _txFee =  _value * txFee / DENOMINATOR;
    }
}