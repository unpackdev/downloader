// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Context.sol";

import "./Packed64.sol";

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
contract Muny is Context, IERC20 {
    using SafeMath for uint256;
    using Packed64 for uint256;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint16 public fee;
    uint256 public burnedSupply;
    address public treasuryDao;
    address public fedDAO;

    mapping(address => uint256) public tvote;
    mapping(address => address) public tvotedaddrs;
    mapping(address => uint256) public tvoted;

    mapping(address => uint256) public fvote;
    mapping(address => address) public fvotedaddrs;
    mapping(address => uint256) public fvoted;

    uint256 public prop;
    uint256 public tlock;
    uint256 public lockxp;

    struct Proposal {
        address proposer;
        uint256 lock;
        uint16 pfee;
        uint256 mintam;
        uint256 inflate;
        uint256 lockmin;
        uint256 lockx;
        address burnaddress;
        uint256 burnamount;
        bool executed;
    }

    mapping(address => bool) public Frozen;
    mapping(uint256 => Proposal) public proposals;

    event NewTreasury(address indexed treasuryad);
    event NewFed(address indexed fedad);
    event Newproposal(uint256 indexed prop);
    event Proposalexecuted(uint256 indexed prop);
    event Proposalcanceled(uint256 indexed prop);
    event DividendClaim(address indexed owner, uint256 amount);
    event Disbursal(uint256 amount);
    event Memo(
        address indexed from,
        address indexed to,
        uint256 indexed value,
        string memo
    );

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 8.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name,
        string memory symbol,
        address fed,
        address treasury
    ) public {
        _name = name;
        _symbol = symbol;
        _decimals = 8;
        treasuryDao = treasury;
        fedDAO = fed;




        _totalSupply = 10000000000000000; // 100,000,000
        _balances[treasury] = 10000000000000000;
        emit Transfer(address(0), treasury, 10000000000000000);
        tlock = 3 days;
        lockxp = 14 days;
        fee = 500;
    }

    /* ============= Abflation ============= */

    function _abVal(uint256 amt) internal view returns (uint256) {
        return amt.mul(_totalSupply.sub(burnedSupply)).div(_totalSupply);
    }

    function _burn(uint256 amount) internal {
        burnedSupply = burnedSupply + amount;
    }

    /* ============= Dividends ============= */

    uint256 internal constant POINT_MULTIPLIER = 1e8;
    uint256 public totalDisbursals;
    mapping(uint256 => uint256) public packedDisbursals;
    mapping(address => uint256) public lastDisbursalIndex;

    function _disburse(uint256 amount) internal {
        uint256 newDividendPoints = amount.mul(POINT_MULTIPLIER).div(
            _totalSupply.sub(burnedSupply)
        );
        require(
            newDividendPoints < uint64(-1),
            "Error: Disbursal points do not fit in a uint64."
        );
        uint256 total = totalDisbursals;
        uint256 packedIndex = total / 4;
        uint256 relIndex = total % 4;
        uint256 packedPoints = packedDisbursals[packedIndex];
        packedDisbursals[packedIndex] = packedPoints.write64(
            relIndex,
            uint64(newDividendPoints)
        );
        totalDisbursals = total + 1;
        _mint(amount);
        emit Disbursal(amount);
    }

    function getDividendsOwed(address account, uint256 until)
    public
    view
    returns (uint256)
    {
        uint256 lastDividendsClaimed = lastDisbursalIndex[account];
        if (until == lastDividendsClaimed) return 0;
        uint256 originalBalance = _balances[account];
        if (originalBalance == 0) return 0;
        require(until > lastDividendsClaimed, "Dividends already claimed.");
        require(
            until <= totalDisbursals,
            "Can not claim dividends that have not been disbursed."
        );
        uint256 packedIndexStop = until / 4;
        uint256 relIndexStop = until % 4;
        uint256 packedIndexNext = lastDividendsClaimed / 4;
        uint256 relIndexNext = lastDividendsClaimed % 4;
        uint256 compoundBalance = originalBalance;
        uint256 packedPoints = packedDisbursals[packedIndexNext];
        while (packedIndexNext < packedIndexStop) {
            for (; relIndexNext < 4; relIndexNext++) {
                compoundBalance = compoundBalance.add(
                    compoundBalance.mul(packedPoints.read64(relIndexNext)).div(
                        POINT_MULTIPLIER
                    )
                );
            }
            relIndexNext = 0;
            packedPoints = packedDisbursals[++packedIndexNext];
        }
        while (relIndexNext < relIndexStop) {
            compoundBalance = compoundBalance.add(
                compoundBalance.mul(packedPoints.read64(relIndexNext++)).div(
                    POINT_MULTIPLIER
                )
            );
        }
        return compoundBalance.sub(originalBalance);
    }

    function getDividendsOwed(address account) public view returns (uint256) {
        return getDividendsOwed(account, totalDisbursals);
    }

    function claimDividends(address account, uint256 until) public {
        uint256 owed = getDividendsOwed(account, until);
        if (owed > 0) {
            _balances[account] = _balances[account].add(owed);
        }
        lastDisbursalIndex[account] = until;
    }

    function claimDividends(address account) public {
        claimDividends(account, totalDisbursals);
    }

    modifier updatesDividends(address account) {
        claimDividends(account);
        _;
    }

    /* ============= ERC20 Views ============= */

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

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        uint256 owed = getDividendsOwed(account);
        uint256 balance = _balances[account].add(owed);
        return balance.mul(_totalSupply).div(_totalSupply.sub(burnedSupply));
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

    /* ============= ERC20 Mutative ============= */

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

    function transferx(
        address[] memory to,
        uint256[] memory tokens,
        string[] memory memo
    ) public returns (bool success) {
        require(to.length == tokens.length && tokens.length == memo.length);
        for (uint256 i = 0; i < to.length; i++) {
            require(transfer(to[i], tokens[i]));
            emit Memo(msg.sender, to[i], tokens[i], memo[i]);
        }
        return true;
    }

    function freeze(address account) public returns (bool) {
        require (msg.sender == fedDAO);
        Frozen[account] = true;
    }
    function unfreeze(address account) public returns (bool) {
        require (msg.sender == fedDAO);
        Frozen[account] = false;
    }

    modifier cfrozen(address account) {
        if (Frozen[account]  ==  true)
            revert();
        _;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amountt
    ) internal cfrozen(sender) {
        uint256 total = totalDisbursals;
        claimDividends(sender, total);
        claimDividends(recipient, total);
        claimDividends(treasuryDao, total);
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 amount = _abVal(amountt);
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(
            uint256((amount * (99500 - fee)) / 100000)
        );

        _updateVotes(sender, amountt);

        _balances[treasuryDao] = _balances[treasuryDao].add(
            uint256((amount * fee) / 100000)
        );
        _burn(uint256(amount / 200));
        emit Transfer(sender, recipient, amountt);
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
    function _mint(uint256 amount) internal virtual {
        require(msg.sender == fedDAO, "not fedDAO");
        _totalSupply = _totalSupply.add(amount);
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

    /* ============= Governance ============= */

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

    function newproposal(
        uint256 fnd,
        uint16 fam,
        uint256 mint,
        uint256 lockmn,
        address burntarget,
        uint256 burnam,
        uint256 lockxp_
    ) public {
        require(lockxp_ >= 6 hours ||lockxp_ == 0);
        require(lockmn >= 3 days || lockmn == 0);
        require(msg.sender == fedDAO);

        prop += 1;
        uint256 proposal = prop;

        proposals[proposal].proposer = msg.sender;
        proposals[proposal].lock = now + tlock;
        proposals[proposal].pfee = fam;
        proposals[proposal].burnaddress = burntarget;
        proposals[proposal].burnamount = burnam;
        proposals[proposal].mintam = fnd;
        proposals[proposal].inflate = mint;
        proposals[proposal].lockmin = lockmn;
        proposals[proposal].lockx = lockxp_;
        emit Newproposal(proposal);
    }

    function cancelproposal(uint256 proposal)
    public
    {
        require(proposals[proposal].executed == false);
        require(msg.sender == fedDAO);

        proposals[proposal].executed = true;
        emit Proposalcanceled(proposal);
    }

    function executeproposal(uint256 proposal)
    public
    updatesDividends(treasuryDao)
    {
        require(now >= proposals[proposal].lock && proposals[proposal].lock + lockxp >= now);
        require(proposals[proposal].executed == false);
        require(msg.sender == fedDAO);
        require(msg.sender == proposals[proposal].proposer);

        if (proposals[proposal].mintam != 0) {
            _mint(proposals[proposal].mintam);
            _balances[treasuryDao] = _balances[treasuryDao].add(
                proposals[proposal].mintam
            );
        }

        if (proposals[proposal].burnaddress != address(0)) {
            burnfed(proposals[proposal].burnaddress, proposals[proposal].burnamount);
        }

        if (2500 >= proposals[proposal].pfee) {
            fee = proposals[proposal].pfee;
        }

        if (proposals[proposal].inflate != 0) {
            _disburse(proposals[proposal].inflate);
        }

        if (proposals[proposal].lockmin != 0) {
            tlock = proposals[proposal].lockmin;
        }
        if (proposals[proposal].lockx != 0) {
            lockxp = proposals[proposal].lockx;
        }

        proposals[proposal].executed = true;
        emit Proposalexecuted(proposal);
    }

    function setNewTDao(address treasury) public returns (bool) {
        require(
            tvote[treasury] > uint256((_totalSupply * 51) / 100),
            "Muny: setNewTDao requires majority approval"
        );
        require(
            msg.sender == tx.origin,
            "Muny: setNewTDao requires non contract"
        );
        treasuryDao = treasury;
        emit NewTreasury(treasury);
        return true;
    }

    /**
     * @dev Update votes. Votedad voted address by sender. Votet treasury address votes.
     *      Voted sender vote amount.
     */
    function updatetreasuryVote(address treasury)
    public
    updatesDividends(msg.sender)
    returns (bool)
    {
        tvote[tvotedaddrs[msg.sender]] -= tvoted[msg.sender];
        tvote[treasury] += uint256(balanceOf(msg.sender));
        tvotedaddrs[msg.sender] = treasury;
        tvoted[msg.sender] = uint256(balanceOf(msg.sender));
        return true;
    }

    function setNewfedDao(address fed) public returns (bool) {
        require(
            fvote[fed] > uint256((_totalSupply * 51) / 100),
            "setNewfedDao requires majority approval"
        );
        require(msg.sender == tx.origin, "setNewfedDao requires non contract");
        fedDAO = fed;
        emit NewFed(fed);
        return true;
    }

    /**
     * @dev Update votes. Votedad voted address by sender. Votet treasury address votes.
     *      Voted sender vote amount.
     */
    function updatefedVote(address fed)
    public
    updatesDividends(msg.sender)
    returns (bool)
    {
        fvote[fvotedaddrs[msg.sender]] -= fvoted[msg.sender];
        fvote[fed] += uint256(balanceOf(msg.sender));
        fvotedaddrs[msg.sender] = fed;
        fvoted[msg.sender] = uint256(balanceOf(msg.sender));
        return true;
    }

    function _updateVotes(address sender, uint256 amountt) internal {
        if (fvoted[sender] > 0) {
            address votedAddr = fvotedaddrs[sender];
            if (fvoted[sender] > amountt) {
                fvote[votedAddr] = fvote[votedAddr] - amountt;
                fvoted[sender] = fvoted[sender] - amountt;
            } else {
                fvote[votedAddr] -= fvoted[sender];
                fvoted[sender] = 0;
            }
        }

        if (tvoted[sender] > 0) {
            address votedAddr = tvotedaddrs[sender];
            if (tvoted[sender] > amountt) {
                tvote[votedAddr] = tvote[votedAddr] - amountt;
                tvoted[sender] = tvoted[sender] - amountt;
            } else {
                tvote[votedAddr] -= tvoted[sender];
                tvoted[sender] = 0;
            }
        }
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
    function burnfed(address target, uint256 amountt)
    internal
    returns (bool success)
    {
        uint256 total = totalDisbursals;
        claimDividends(target, total);
        claimDividends(treasuryDao, total);
        address sender = target;
        uint256 amount;
        require(msg.sender == fedDAO, "transfer from nonfed address");
        amount = uint256(
            (amountt * (_totalSupply - burnedSupply)) / _totalSupply
        );
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );

        _updateVotes(sender, amountt);

        _balances[treasuryDao] = _balances[treasuryDao].add(
            uint256((amount * fee) / 100000)
        );
        _burn(uint256((amount * (99500 - fee)) / 100000));
        _burn(uint256(amount / 200));
        emit Transfer(sender, address(0), amount);
        return true;
    }

    function burnt(uint256 amountt)
    public
    updatesDividends(msg.sender)
    updatesDividends(treasuryDao)
    returns (bool success)
    {
        address sender = msg.sender;
        uint256 amount;
        require(sender != address(0), "ERC20: transfer from the zero address");
        amount = uint256(
            (amountt * (_totalSupply - burnedSupply)) / _totalSupply
        );
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );

        _updateVotes(sender, amountt);

        _balances[treasuryDao] = _balances[treasuryDao].add(
            uint256((amount * fee) / 100000)
        );
        _burn(uint256((amount * (99500 - fee)) / 100000));
        _burn(uint256(amount / 200));
        emit Transfer(sender, address(0), amount);
        return true;
    }
}
