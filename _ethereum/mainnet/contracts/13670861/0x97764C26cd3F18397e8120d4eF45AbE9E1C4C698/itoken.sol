pragma solidity 0.5.17;

import "./token.sol";

contract itoken is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address public owner;
    address public daaaddress;
    address[] public alladdress;
    mapping(address =>bool) public whitelistedaddress;
    mapping(address =>bool) public managerAddress;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol,address _daaaddress,address _managerAddress) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
        daaaddress = _daaaddress;
        managerAddress[_managerAddress] = true;
        managerAddress[msg.sender] = true;
        owner = msg.sender;
        addChefAddress(msg.sender);
        addChefAddress(daaaddress);
    }

    /**
     * @dev Check if itoken can be transfered between the sender and reciepents.
     * Only whitelisted address has permission like DAA contract/chef contract.
     */

    function validateTransaction(address to, address from) public view returns(bool){
        if(whitelistedaddress[to] || whitelistedaddress[from]){
            return true;
        }
        else{
            return false;
        }
    }

    /**
     * @dev Add Chef address so that itoken can be deposited/withdraw from 
     * @param _address Address of Chef contract
     */
    function addChefAddress(address _address) public returns(bool){
        require(managerAddress[msg.sender],"Only manager can add address");
        require(_address != address(0), "Zero Address");
        require(!whitelistedaddress[_address],"Already white listed");
        whitelistedaddress[_address] = true;
        alladdress.push(msg.sender);
        return true;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(validateTransaction(msg.sender,recipient),"itoken::transfer: Can only be traded with DAA pool/chef");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(validateTransaction(sender,recipient),"itoken::transferfrom: Can only be traded with DAA pool/chef");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Mint new itoken for new deposit can only be called by 
     * @param account Account to which tokens will be minted
     * @param amount amount to mint
     */
	function mint(address account, uint256 amount) external returns (bool) {
        require(msg.sender == daaaddress, "itoken::mint:Only daa can mint");
        _mint(account, amount);
        return true;
    }

    /**
     * @dev Burn itoken during withdraw can only be called by DAA 
     * @param account Account from which tokens will be burned
     * @param amount amount to burn
     */
    function burn(address account, uint256 amount) external returns (bool) {
        require(msg.sender == daaaddress, "itoken::burn:Only daa can burn");
        _burn(account, amount);
        return true;
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
    function _approve(address owner, address spender, uint256 amount) internal {
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
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal { }
}

contract itokendeployer {
    using SafeMath for uint256;

    // Owner account address
    address public owner;
    // DAA contract address
    address public daaaddress;
    // List of deployed itokens
    address[] public deployeditokens;
    // Total itoken.
    uint256 public totalItokens;

    /**
     * @dev Modifier to check if the caller is owner or not
     */
    modifier onlyOnwer{
        require(msg.sender == owner, "Only owner call");
        _;
    }
    /**
     * @dev Modifier to check if the caller is daa contract or not
     */
    modifier onlyDaa{
        require(msg.sender == daaaddress, "Only DAA contract can call");
        _;
    }
    /**
     * @dev Constructor.
     */
    constructor() public {
		owner = msg.sender;
	}

    /**
     * @dev Create new itoken when a new pool is created. Mentioned in Public Facing ASTRA TOKENOMICS document  itoken distribution 
       section that itoken need to be given a user for deposit in pool.
     * @param _name name of the token
     * @param _symbol symbol of the token, 3-4 chars is recommended
     */
    function createnewitoken(string calldata _name, string calldata _symbol) external onlyDaa returns(address) {
		itoken _itokenaddr = new itoken(_name,_symbol,msg.sender,owner);  
        deployeditokens.push(address(_itokenaddr));
        totalItokens = totalItokens.add(1);
		return address(_itokenaddr);  
	}

    /**
     * @dev Get the address of the itoken based on the pool Id.
     * @param pid Daa Pool Index id.
     */
    function getcoin(uint256 pid) external view returns(address){
        return deployeditokens[pid];
    }

    /**
     * @dev Add the address DAA pool configurtaion contrac so that only Pool contract can create the itokens.
     * @param _address Address of the DAA contract.
     */
    function addDaaAdress(address _address) public onlyOnwer { 
        require(_address != address(0), "Zero Address");
        require(daaaddress != _address, "Already set Daa address");
	    daaaddress = _address;
	}
    
}