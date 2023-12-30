pragma solidity =0.5.16;


contract ZeusERC20 {
        /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'SafeMath: addition overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        return sub(x, y, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 x, uint256 y, string memory errorMessage) internal pure returns (uint256 z) {
        require((z = x - y) <= x, errorMessage);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

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

    string public constant name = "Aureus Coin";
    string public constant symbol = "AUREUS";
    string public constant version = "1";
    uint8 public constant decimals = 18;

    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    mapping(address => mapping(address => uint256)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32
        public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    constructor() public {
        uint256 chainId;
        assembly {
            chainId := chainid
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );

        _mint(msg.sender, uint(-1));
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
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
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        balanceOf[sender] = sub(balanceOf[sender],
            amount,
            "ZeusERC20: transfer amount exceeds balance"
        );
        balanceOf[recipient] = add(balanceOf[recipient], amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        totalSupply = add(totalSupply, amount);
        balanceOf[account] = add(balanceOf[account], amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev See {IERC20-burn}.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` must have at least `amount` tokens.
     *
     * Note: An allowance of uint(-1) is treated as "infinity" and
     * will not cause the allowance to decrease.
     */
    function burn(address account, uint256 amount) external {
        if (
            account != msg.sender &&
            allowance[account][msg.sender] != uint256(-1)
        ) {
            allowance[account][msg.sender] = sub(allowance[account][msg.sender],
                amount,
                "ZeusERC20: burn amount exceeds allowance"
            );
        }

        balanceOf[account] = sub(balanceOf[account],
            amount,
            "ZeusERC20: burn amount exceeds balance"
        );
        totalSupply = sub(totalSupply, amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits a {Transfer} event.
     *
     * Note: An allowance of uint(-1) is treated as "infinity" and
     * will not cause the allowance to decrease.
     *
     * Requirements:
     *
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        _transferFrom(sender, recipient, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * This is internal function is equivalent to {transferFrom}.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     *
     * Note: An allowance of uint(-1) is treated as "infinity" and
     * will not cause the allowance to decrease.
     */
    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (allowance[sender][msg.sender] != uint256(-1)) {
            allowance[sender][msg.sender] = sub(allowance[sender][msg.sender],
                amount,
                "ZeusERC20: transfer amount exceeds allowance"
            );
        }

        _transfer(sender, recipient, amount);
    }

    /**
     * @dev See {IERC20-permit}.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "ZeusERC20: expired");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        amount,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "ZeusERC20: invalid signature"
        );
        _approve(owner, spender, amount);
    }
}