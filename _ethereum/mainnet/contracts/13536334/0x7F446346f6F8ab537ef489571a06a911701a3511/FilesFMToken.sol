// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract FilesFMToken is IERC20 {
    using SafeERC20 for IERC20;

    uint256 private constant MAX_UINT256 = type(uint256).max;
    uint256 private constant MAX_CAP = 10_000_000_000e18;

    string public constant name = "Files.fm Cloud Token";
    string public constant symbol = "CLOUD";
    uint8 public constant decimals = 18;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    mapping(address => uint256) public reviewPeriods;
    mapping(address => uint256) public decisionPeriods;
    uint256 public reviewPeriod = 86400; // 1 day
    uint256 public decisionPeriod = 86400; // 1 day after review period
    address public governanceBoard;
    address public pendingGovernanceBoard;
    bool public paused = true;

    event Paused();
    event Unpaused();
    event Reviewing(address indexed account, uint256 reviewUntil, uint256 decideUntil);
    event Resolved(address indexed account);
    event ReviewPeriodChanged(uint256 reviewPeriod);
    event DecisionPeriodChanged(uint256 decisionPeriod);
    event GovernanceBoardChanged(address indexed from, address indexed to);
    event GovernedTransfer(address indexed from, address indexed to, uint256 amount);

    modifier whenNotPaused() {
        require(!paused || msg.sender == governanceBoard, "Pausable: paused");
        _;
    }

    modifier onlyGovernanceBoard() {
        require(msg.sender == governanceBoard, "Sender is not governance board");
        _;
    }

    modifier onlyPendingGovernanceBoard() {
        require(msg.sender == pendingGovernanceBoard, "Sender is not the pending governance board");
        _;
    }

    modifier onlyResolved(address account) {
        require(decisionPeriods[account] < block.timestamp, "Account is being reviewed");
        _;
    }

    constructor(address initialBalanceReceiver) {
        _setGovernanceBoard(msg.sender);
        _totalSupply = MAX_CAP;

        _balances[initialBalanceReceiver] = MAX_CAP;
        emit Transfer(address(0), initialBalanceReceiver, MAX_CAP);

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function pause() external onlyGovernanceBoard {
        require(!paused, "Pausable: paused");
        paused = true;
        emit Paused();
    }

    function unpause() external onlyGovernanceBoard {
        require(paused, "Pausable: unpaused");
        paused = false;
        emit Unpaused();
    }

    function review(address account) external onlyGovernanceBoard {
        _review(account);
    }

    function resolve(address account) external onlyGovernanceBoard {
        _resolve(account);
    }

    function electGovernanceBoard(address newGovernanceBoard) external onlyGovernanceBoard {
        pendingGovernanceBoard = newGovernanceBoard;
    }

    function takeGovernance() external onlyPendingGovernanceBoard {
        _setGovernanceBoard(pendingGovernanceBoard);
        pendingGovernanceBoard = address(0);
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
        external
        override
        onlyResolved(msg.sender)
        onlyResolved(recipient)
        whenNotPaused
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        external
        override
        onlyResolved(msg.sender)
        onlyResolved(spender)
        whenNotPaused
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        external
        override
        onlyResolved(msg.sender)
        onlyResolved(sender)
        onlyResolved(recipient)
        whenNotPaused
        returns (bool)
    {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] < MAX_UINT256) {
            // treat MAX_UINT256 approve as infinite approval
            _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        }
        return true;
    }

    /**
     * @dev Allows governance board to transfer funds.
     *
     * This allows to transfer tokens after review period have elapsed,
     * but before decision period is expired. So, basically governanceBoard have a time-window
     * to move tokens from reviewed account.
     * After decision period have been expired remaining tokens are unlocked.
     */
    function governedTransfer(
        address from,
        address to,
        uint256 value
    ) external onlyGovernanceBoard returns (bool) {
        require(block.timestamp > reviewPeriods[from], "Review period is not elapsed");
        require(block.timestamp <= decisionPeriods[from], "Decision period expired");

        _transfer(from, to, value);
        emit GovernedTransfer(from, to, value);
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
        external
        onlyResolved(msg.sender)
        onlyResolved(spender)
        whenNotPaused
        returns (bool)
    {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
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
        external
        onlyResolved(msg.sender)
        onlyResolved(spender)
        whenNotPaused
        returns (bool)
    {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function transferMany(address[] calldata recipients, uint256[] calldata amounts)
        external
        onlyResolved(msg.sender)
        whenNotPaused
    {
        require(recipients.length == amounts.length, "FilesFMToken: Wrong array length");

        uint256 total = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }

        _balances[msg.sender] -= total;

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];
            require(recipient != address(0), "ERC20: transfer to the zero address");
            require(decisionPeriods[recipient] < block.timestamp, "Account is being reviewed");

            _balances[recipient] += amount;
            emit Transfer(msg.sender, recipient, amount);
        }
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Need to unwrap modifiers to eliminate Stack too deep error
        require(decisionPeriods[owner] < block.timestamp, "Account is being reviewed");
        require(decisionPeriods[spender] < block.timestamp, "Account is being reviewed");
        require(!paused || msg.sender == governanceBoard, "Pausable: paused");
        require(deadline >= block.timestamp, "FilesFMToken: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);

        require(recoveredAddress != address(0) && recoveredAddress == owner, "FilesFMToken: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }

    function setReviewPeriod(uint256 _reviewPeriod) external onlyGovernanceBoard {
        reviewPeriod = _reviewPeriod;
        emit ReviewPeriodChanged(reviewPeriod);
    }

    function setDecisionPeriod(uint256 _decisionPeriod) external onlyGovernanceBoard {
        decisionPeriod = _decisionPeriod;
        emit DecisionPeriodChanged(decisionPeriod);
    }

    function recoverTokens(
        IERC20 token,
        address to,
        uint256 amount
    ) external onlyGovernanceBoard {
        token.safeTransfer(to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external onlyResolved(msg.sender) whenNotPaused {
        _burn(msg.sender, amount);
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
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
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
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

        _balances[account] -= amount;
        _totalSupply -= amount;
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
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _review(address account) internal {
        uint256 reviewUntil = block.timestamp + reviewPeriod;
        uint256 decideUntil = block.timestamp + reviewPeriod + decisionPeriod;
        reviewPeriods[account] = reviewUntil;
        decisionPeriods[account] = decideUntil;
        emit Reviewing(account, reviewUntil, decideUntil);
    }

    function _setGovernanceBoard(address newGovernanceBoard) internal {
        emit GovernanceBoardChanged(governanceBoard, newGovernanceBoard);
        governanceBoard = newGovernanceBoard;
    }

    function _resolve(address account) internal {
        reviewPeriods[account] = 0;
        decisionPeriods[account] = 0;
        emit Resolved(account);
    }
}
