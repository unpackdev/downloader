// SPDX-License-Identifier: UNLICENSED
// Hubchain Technologies - Smart Contracts (https://hubchain.com)

pragma solidity ^0.8.18;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

contract Forwarder {
    address public routerAddress;
    address public destinationAddress;

    receive() external payable {
        payable(destinationAddress).transfer(msg.value);
    }

    fallback() external payable {
        payable(destinationAddress).transfer(msg.value);
    }

    function flushTokens(address tokenAddress) public {
        ERC20 tokenContract = ERC20(tokenAddress);
        uint256 forwarderBalance = tokenContract.balanceOf(address(this));
        require(forwarderBalance > 0, "Forwarder: NO TOKEN BALANCE");
        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", destinationAddress, forwarderBalance)
        );
        require(success, "Forwarder: flushTokens Failed.");
    }

    function flushTokensAmount(address tokenAddress, uint256 amount) public {
        ERC20 tokenContract = ERC20(tokenAddress);
        uint256 forwarderBalance = tokenContract.balanceOf(address(this));
        require(forwarderBalance >= amount, "Forwarder: NO amount TOKEN BALANCE");
        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", destinationAddress, amount)
        );
        require(success, "Forwarder: flushTokensAmount Failed.");
    }

    function flush() public {
        uint256 forwarderBalance = address(this).balance;
        require(forwarderBalance > 0, "Forwarder: NO BALANCE");
        payable(destinationAddress).transfer(address(this).balance);
    }

    function flushToRouterOwner() public {
        uint256 forwarderBalance = address(this).balance;
        require(forwarderBalance > 0, "Forwarder: NO BALANCE");
        payable(routerAddress).transfer(address(this).balance);
    }

    function flushTokensToRouterOwner(address tokenAddress) public {
        ERC20 tokenContract = ERC20(tokenAddress);
        uint256 forwarderBalance = tokenContract.balanceOf(address(this));
        require(forwarderBalance > 0, "Forwarder: NO TOKEN BALANCE");
        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", routerAddress, forwarderBalance)
        );
        require(success, "Forwarder: flushTokensToRouterOwner Failed.");
    }

    function flushTokensAmountToRouterOwner(address tokenAddress, uint256 amount) public payable {
        ERC20 tokenContract = ERC20(tokenAddress);
        uint256 forwarderBalance = tokenContract.balanceOf(address(this));
        require(forwarderBalance >= amount, "Forwarder: NO amount TOKEN BALANCE");
        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", routerAddress, amount)
        );
        require(success, "Forwarder: flushTokensAmountToRouterOwner Failed.");
    }

    function initialize(address router, address destination) public {
        require(destinationAddress == address(0x0), "Forwarder: instance has already been initialized.");
        routerAddress = router;
        destinationAddress = destination;
    }

    function version() external pure returns (string memory) {
        return "1";
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    //     function transferOwnership(address newOwner) public onlyOwner {
    //         if (newOwner != address(0x0)) {
    //             owner = newOwner;
    //         }
    //     }
}

contract ForwarderFactory is Ownable {
    // using SafeMath for uint;

    mapping(address => uint256) public forwardCreateAddresses;
    mapping(address => uint256) public forwardCloneAddresses;

    event ForwarderCreate(address indexed parentForwarder, address destinationAddress);
    event ForwarderClone(address indexed parentForwarder, address indexed forwarder, address destinationAddress);

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        payable(owner).transfer(msg.value);
    }

    fallback() external payable {
        payable(owner).transfer(msg.value);
    }

    function flushTokens(address forwarderAddress, address tokenAddress) public {
        (bool success, ) = payable(forwarderAddress).call(
            abi.encodeWithSignature("flushTokens(address)", tokenAddress)
        );
        require(success, "ForwarderFactory: flushTokens failed.");
    }

    function flush(address payable forwarderAddress) public {
        (bool success, ) = payable(forwarderAddress).call(abi.encodeWithSignature("flush()"));
        require(success, "ForwarderFactory: flush failed.");
    }

    function flushTokens(address tokenAddress) public {
        ERC20 tokenContract = ERC20(tokenAddress);
        uint256 forwarderBalance = tokenContract.balanceOf(address(this));
        require(forwarderBalance > 0, "NO TOKEN BALANCE");
        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", owner, forwarderBalance)
        );
        require(success, "ForwarderFactory: flushTokens Failed.");
    }

    function flush() public {
        uint256 forwarderBalance = address(this).balance;
        require(forwarderBalance > 0, "NO BALANCE");
        payable(owner).transfer(address(this).balance);
    }

    function forwarderCreateSaltOf(address forwarderAddress) public view returns (uint256) {
        return forwardCreateAddresses[forwarderAddress];
    }

    function forwarderCloneSaltOf(address forwarderAddress) public view returns (uint256) {
        return forwardCloneAddresses[forwarderAddress];
    }

    function getForwarderByteCode() public pure returns (bytes memory) {
        bytes memory bytecode = type(Forwarder).creationCode;
        return abi.encodePacked(bytecode);
    }

    function computeForwarderCreateAddressSalt(
        address signerAddress,
        address destinationAddress,
        uint256 salt
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(signerAddress, destinationAddress, bytes32(salt)));
    }

    function computeForwarderCreateAddress(
        address signerAddress,
        address destinationAddress,
        uint256 salt
    ) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                computeForwarderCreateAddressSalt(signerAddress, destinationAddress, salt),
                keccak256(getForwarderByteCode())
            )
        );
        return address(uint160(uint(hash)));
    }

    function createForwarder(address destinationAddress, uint256 salt) public payable returns (address) {
        bytes32 _salt = computeForwarderCreateAddressSalt(msg.sender, destinationAddress, salt);
        require(_salt != 0x0, "ForwarderFactory: salt is not valid (must to be greater than zero).");
        require(
            forwardCreateAddresses[computeForwarderCreateAddress(msg.sender, destinationAddress, salt)] == 0x0,
            "ForwarderFactory: salt has already been used at another address. please try another one."
        );

        Forwarder forwarder = new Forwarder{salt: _salt}();
        forwarder.initialize(address(this), destinationAddress);
        address forwarderAddress = address(forwarder);

        emit ForwarderCreate(forwarderAddress, destinationAddress);
        forwardCreateAddresses[forwarderAddress] = uint256(_salt);
        return forwarderAddress;
    }

    function createForwarderFlush(address destinationAddress, uint256 salt) public returns (address) {
        address createAddress = createForwarder(destinationAddress, salt);
        flush(payable(createAddress));
        return createAddress;
    }

    function createForwarderFlushTokens(
        address destinationAddress,
        uint256 salt,
        address tokenAddress
    ) public returns (address) {
        address createdAddress = createForwarder(destinationAddress, salt);
        flushTokens(payable(createdAddress), tokenAddress);
        return createdAddress;
    }

    function createForwarderFlushAll(
        address destinationAddress,
        uint256 salt,
        address tokenAddress
    ) public returns (address) {
        address createdAddress = createForwarder(destinationAddress, salt);
        flushTokens(payable(createdAddress), tokenAddress);
        flush(payable(createdAddress));
        return createdAddress;
    }

    function cloneForwarder(address forwarderAddress, uint256 salt) public returns (address) {
        require(salt != 0x0, "ForwarderFactory: salt is not valid (must to be greater than zero).");
        require(
            forwardCreateAddresses[forwarderAddress] != 0x0,
            "ForwarderFactory: forwarderAddress is not a cloneable contract address."
        );
        address clonedAddress = createForwarderClone(forwarderAddress, salt);
        Forwarder parentForwarder = Forwarder(payable(forwarderAddress));
        require(
            parentForwarder.destinationAddress() != address(0x0),
            "ForwarderFactory: forwarderAddress is a cloneable contract address, but it has not yet been initialized."
        );

        Forwarder clonedForwarder = Forwarder(payable(clonedAddress));
        clonedForwarder.initialize(address(this), parentForwarder.destinationAddress());

        emit ForwarderClone(forwarderAddress, clonedAddress, parentForwarder.destinationAddress());
        forwardCloneAddresses[clonedAddress] = salt;
        return clonedAddress;
    }

    function cloneForwarderFlush(address forwarderAddress, uint256 salt) public returns (address) {
        address clonedAddress = cloneForwarder(forwarderAddress, salt);
        flush(payable(clonedAddress));
        return clonedAddress;
    }

    function cloneForwarderFlushTokens(
        address forwarderAddress,
        uint256 salt,
        address tokenAddress
    ) public returns (address) {
        address clonedAddress = cloneForwarder(forwarderAddress, salt);
        flushTokens(payable(clonedAddress), tokenAddress);
        return clonedAddress;
    }

    function cloneForwarderFlushAll(
        address forwarderAddress,
        uint256 salt,
        address tokenAddress
    ) public returns (address) {
        address clonedAddress = cloneForwarder(forwarderAddress, salt);
        flushTokens(payable(clonedAddress), tokenAddress);
        flush(payable(clonedAddress));
        return clonedAddress;
    }

    function createForwarderClone(address forwarderAddress, uint256 salt) private returns (address result) {
        bytes20 targetBytes = bytes20(forwarderAddress);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create2(0, clone, 0x37, salt)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicCloneAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    function computeForwarderCloneAddress(address forwarderAddress, uint256 salt) public view returns (address) {
        return predictDeterministicCloneAddress(forwarderAddress, bytes32(salt), address(this));
    }

    function version() external pure returns (string memory) {
        return "1";
    }
}