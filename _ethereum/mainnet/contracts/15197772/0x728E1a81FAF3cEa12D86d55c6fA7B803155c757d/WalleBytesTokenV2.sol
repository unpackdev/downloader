/**
 *Submitted for verification at BscScan.com on 2022-02-26
*/

/**
 *Submitted for verification at polygonscan.com on 2022-01-26
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.2/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.2/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.2/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.2/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

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
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.2/contracts/token/ERC20/extensions/IERC20Metadata.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.2/contracts/token/ERC20/ERC20.sol



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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

// File: contracts/WalleBytes.sol


pragma solidity ^0.8.0;
//WalleBytes ETH - SOD - IBN5X
contract WalleBytesTokenV2 is ERC20 {
    address public owner;
    address operationWallet; //contract
    uint256 reward;
    uint256 bonus;
    uint256 public price;
    bool burnPeriod;
 
    mapping(address => uint) balance; //maps user/Contract balance
    mapping(address => uint) public lockedBalance; //locked tokens
    mapping(address => uint) createdAt; //maps user time tokens staked
    mapping(address => uint) unlockDate; //maps user stake release time
    mapping(address => bool) hasStaked; //users can only have one stake at a time
    mapping(address => bool) purpleList;
   
    modifier greaterThanZero
        {
            require(msg.value > 0, "You have to enter a sum great than zero!");
            _;
        }
    modifier onlyOwner
        {
            require(msg.sender == owner, "Only owner");
            _;
        }
    modifier hasNoStake
        {
            require(hasStaked[msg.sender] == false, "Staked WALY balance must be zero");
            _;
        }    
    modifier burnTime
        {
            require(burnPeriod == true, "You can not burn tokens outside of alotted time");
            _;
        }
 
  
    event staked(address staker, uint256 amount, uint256 date, uint256 unlockDate);
    event unstaked(address staker, uint256 amount,uint256 remainingBalance, uint256 date);
    event contribution(address contributor, uint256 amount, uint256 date);
    event userBurn(address user, uint256 amount, uint256 date);
    event burningPeriod(address operator, bool onOff, uint256 date);
    event teamChange(address operator, address prevAddress, address newAddress, uint date);
    event ownerChange(address currentOwner, address newOwner, uint256 date);
    event priceSet(address operator, uint256 prevPrice, uint256 newPrice, uint256 date);
    event purged(address operator, uint256 amount, uint256 date); //owner burns token supply
 
    constructor() ERC20("WalleBytes", "WALY") {
        owner = msg.sender;
        operationWallet = 0xac55AD5aDF96E7caFe887d4DAbe0B92959758E19; 
        reward = 250000;
        bonus = 100;
        price = 0.004 ether;
        burnPeriod = false;
 
        _mint(msg.sender, 27000000000 *(10**18));
        _approve(owner,  address(this), 26000000000 *(10**18));
        _transfer(owner, address(this), 26000000000 *(10**18));
        balance[address(this)]+= 26000000000;
        balance[msg.sender]+= 1000000000;
   
    }
 
    //recevies ERC1155
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4)
    {
       
        require((balance[address(this)] - lockedBalance[address(this)]) >= bonus);
        require(balance[address(this)] >= bonus);
        require(burnPeriod == true, "can only be done during burn period");

        
        balance[address(this)]-= bonus;
        balance[from]+= bonus;
 
       _transfer(address(this), from, bonus *(10**18));
 
       return this.onERC1155Received.selector;
       
    }



   
    function setPrice(uint256 _price) public onlyOwner returns(bool success){
        uint256 prevPrice = price;
        price = _price;
 
        emit priceSet(msg.sender, prevPrice, _price, block.timestamp);
        return true;
    }
 
    function setOwner(address _owner) public onlyOwner returns(bool success){
        owner = _owner;
 
        emit ownerChange(msg.sender, owner, block.timestamp);
        return true;
    }
    
    function teamWallet(address _operationWallet) public onlyOwner returns(bool success){
        address oldAddress = operationWallet;
        operationWallet = _operationWallet;
 
        emit teamChange(owner, oldAddress, operationWallet, block.timestamp);
        return true;
       
    }
 
    function turnOnBurn(bool _state) public onlyOwner returns(bool success){
        burnPeriod = _state;
 
        emit burningPeriod(owner, _state, block.timestamp);
        return true;
       
    }
 
    function burn(uint256 amount) public returns(bool success){
        require(balance[msg.sender] >= amount, "You cannot burn this many WALY tokens");
        require(burnPeriod == true, "You can only burn during authorized times, check DApp");

        balance[msg.sender]-= amount;

        _burn(msg.sender, amount *(10**18));
        
        emit userBurn(msg.sender, amount, block.timestamp);
        return true;
    }
 
    function deplete(uint _amount) public onlyOwner returns(bool success){
        require((balance[address(this)] - lockedBalance[address(this)]) >= _amount,"You cannot burn locked funds");
       
        balance[address(this)]-=_amount;

        _burn(address(this), _amount *(10**18));
 
        
 
        emit purged(msg.sender, _amount, block.timestamp);
        return true;
    }
 
    function contribute() payable public {
        require(msg.value >= price);
        require((balance[address(this)] - lockedBalance[address(this)]) >= reward, "Contract empty, cannot contribute");
 
       
        rewards(msg.sender);
    }
 
    function rewards(address _user) private {
        uint256 prevBalance = balance[address(this)];
 
        address payable ownerAddress = payable(operationWallet);
        ownerAddress.transfer(msg.value);
 
        balance[address(this)]-= reward;
        balance[msg.sender]+= reward;
 
        _transfer(address(this), _user, reward *(10**18));
 
        assert(balance[address(this)] == prevBalance - reward);
        emit contribution(msg.sender, msg.value, block.timestamp);
    }
 
    function stake(uint _amount, uint _time) public hasNoStake returns(bool success){

        uint256 currentAllowance = allowance(msg.sender, address(this));
 
        if(currentAllowance < _amount){
            uint256 approveBal = balanceOf(msg.sender);
            _approve(msg.sender, address(this), approveBal);
        }
 

        createdAt[msg.sender] = block.timestamp;
        unlockDate[msg.sender] = createdAt[msg.sender] + _time;

        balance[address(this)]+= _amount;
        lockedBalance[msg.sender]+= _amount;
        lockedBalance[address(this)]+= _amount;
 
        hasStaked[msg.sender] = true;
        purpleList[msg.sender] = true;

        _transfer(msg.sender, address(this), _amount *(10**18));
 
        emit staked(msg.sender, _amount, block.timestamp, unlockDate[msg.sender]);
        return true;
 
    }  
 
   function unstake(uint _amount) public returns(bool success) {
       require(_amount <= lockedBalance[msg.sender], "You dont have this amount of WALY staked");
       require(block.timestamp >= unlockDate[msg.sender], "Your WALY stake still has time remaining before it can be unstaked");
 
       _unstake(_amount);
       
       return true;
   }      
 
   function _unstake(uint _amount) private {
       uint256 prevStakeBalance = lockedBalance[msg.sender];
 
       lockedBalance[msg.sender]-= _amount;
       lockedBalance[address(this)]-= _amount;
       
       balance[address(this)]-= _amount;
       
       if(lockedBalance[msg.sender] == 0){
            hasStaked[msg.sender] = false;
            purpleList[msg.sender] = false; 
       }

        _transfer(address(this), msg.sender, _amount *(10**18));
 
       assert(lockedBalance[msg.sender] == (prevStakeBalance - _amount));
       emit unstaked(msg.sender, _amount, lockedBalance[msg.sender], block.timestamp);
 
   }
 
      //Check Balances
    function userBalance() public view returns(uint){
        uint256 userBal = balanceOf(msg.sender);
        return userBal;
    }
    //tokens in contract
    function contractWalleBalance() public view returns (uint){
        return balance[address(this)];
    }
    //Locked contract tokens
    function totalLocked() public view returns (uint){
       
        return lockedBalance[address(this)];
    }

    function purpleLister() public view returns(bool){
        return purpleList[msg.sender]; 
    }
}