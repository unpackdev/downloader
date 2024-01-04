// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./console.sol";
import "./Ownable.sol";

import "./SafeMathInt.sol";
import "./ERC20UpgradeSafe.sol";
import "./ERC677Token.sol";


/**
 * @title BED ERC20 token
 * @dev This is part of an implementation of the BED Index Fund protocol.
 *      BED is a normal ERC20 token, but its supply can be adjusted by splitting and
 *      combining tokens proportionally across all wallets.
 *
 *      BED balances are internally represented with a hidden denomination, 'shares'.
 *      We support splitting the currency in expansion and combining the currency on contraction by
 *      changing the exchange rate between the hidden 'shares' and the public 'BED'.
 */
contract BedToken is ERC20UpgradeSafe, ERC677Token, OwnableUpgradeSafe {
    // PLEASE READ BEFORE CHANGING ANY ACCOUNTING OR MATH
    // Anytime there is division, there is a risk of numerical instability from rounding errors. In
    // order to minimize this risk, we adhere to the following guidelines:
    // 1) The conversion rate adopted is the number of shares that equals 1 BED.
    //    The inverse rate must not be used--totalShares is always the numerator and _totalSupply is
    //    always the denominator. (i.e. If you want to convert shares to BED instead of
    //    multiplying by the inverse rate, you should divide by the normal rate)
    // 2) Share balances converted into BedToken are always rounded down (truncated).
    //
    // We make the following guarantees:
    // - If address 'A' transfers x BedToken to address 'B'. A's resulting external balance will
    //   be decreased by precisely x BedToken, and B's external balance will be precisely
    //   increased by x BedToken.
    //
    // We do not guarantee that the sum of all balances equals the result of calling totalSupply().
    // This is because, for any conversion function 'f()' that has non-zero rounding error,
    // f(x0) + f(x1) + ... + f(xn) is not always equal to f(x0 + x1 + ... xn).
    using SafeMath for uint256;
    using SafeMathInt for int256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event LogMonetaryPolicyUpdated(address monetaryPolicy);
    event LogUserBanStatusUpdated(address user, bool banned);

    // Used for authentication
    address public monetaryPolicy;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_SUPPLY = 50000000 * 10**DECIMALS;
    uint256 private constant INITIAL_SHARES = (MAX_UINT256 / (10 ** 36)) - ((MAX_UINT256 / (10 ** 36)) % INITIAL_SUPPLY);
    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 public _totalShares;
    uint256 private _totalSupply;
    uint256 public _sharesPerBED;

    uint256 private PERCENTAGE_PRECISION;
    uint256 private BIG_TRANSFER_PERCENTAGE;
    address private bigTransferFeeWallet;
    uint256 private SMALL_TRANSFER_PERCENTAGE;
    address private smallTransferFeeWallet;

    mapping(address => bool) public isAddressWhitelisted;

    mapping(address => uint256) private _shareBalances;

    mapping(address => bool) public bannedUsers;


    // This is denominated in BedToken, because the shares-BED conversion might change before
    // it's fully paid.
    mapping (address => mapping (address => uint256)) private _allowedBED;

    bool public transfersPaused;
    bool public rebasesPaused;

    mapping(address => bool) public transferPauseExemptList;

    function setTransfersPaused(bool _transfersPaused)
        public
        onlyOwner
    {
        transfersPaused = _transfersPaused;
    }

    function setTransferPauseExempt(address user, bool exempt)
        public
        onlyOwner
    {
        if (exempt) {
            transferPauseExemptList[user] = true;
        } else {
            delete transferPauseExemptList[user];
        }
    }

    function setRebasesPaused(bool _rebasesPaused)
        public
        onlyOwner
    {
        rebasesPaused = _rebasesPaused;
    }

    function whitelistAddressFromTransferFees(
        address _address
    )
    public
    onlyOwner
    {
        isAddressWhitelisted[_address] = true;
    }

    function setBigPercentageTransferFee(
        uint percentage
    )
    public
    onlyOwner
    {
        BIG_TRANSFER_PERCENTAGE = percentage;
    }

    function setSmallPercentageTransferFee(
        uint percentage
    )
    public
    onlyOwner
    {
        SMALL_TRANSFER_PERCENTAGE = percentage;
    }

    /**
     * @param monetaryPolicy_ The address of the monetary policy contract to use for authentication.
     */
    function setMonetaryPolicy(address monetaryPolicy_)
        external
        onlyOwner
    {
        monetaryPolicy = monetaryPolicy_;
        emit LogMonetaryPolicyUpdated(monetaryPolicy_);
    }


    function setBigTransferFeeWalletReceiver(
        address _receiverWallet
    )
    external
    onlyOwner
    {
        require(_receiverWallet != address(0));
        bigTransferFeeWallet = _receiverWallet;
    }

    function setSmallTransferFeeWalletReceiver(
        address _receiverWallet
    )
    external
    onlyOwner
    {
        require(_receiverWallet != address(0));
        smallTransferFeeWallet = _receiverWallet;
    }


    /**
     * @dev Notifies BedToken contract about a new rebase cycle.
     * @param supplyDelta The number of new BED tokens to add into circulation via expansion.
     * @return The total number of BED after the supply adjustment.
     */
    function rebase(uint256 epoch, int256 supplyDelta)
        external
        returns (uint256)
    {
        require(msg.sender == monetaryPolicy, "only monetary policy");
        require(!rebasesPaused, "rebases paused");

        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(supplyDelta.abs()));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _sharesPerBED = _totalShares.div(_totalSupply);

        // From this point forward, _sharesPerBED is taken as the source of truth.
        // We recalculate a new _totalSupply to be in agreement with the _sharesPerBED
        // conversion rate.
        // This means our applied supplyDelta can deviate from the requested supplyDelta,
        // but this deviation is guaranteed to be < (_totalSupply^2)/(totalShares - _totalSupply).
        //
        // In the case of _totalSupply <= MAX_UINT128 (our current supply cap), this
        // deviation is guaranteed to be < 1, so we can omit this step. If the supply cap is
        // ever increased, it must be re-included.

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }

    function totalShares()
        public
        view
        returns (uint256)
    {
        return _totalShares;
    }

    function sharesOf(address user)
        public
        view
        returns (uint256)
    {
        return _shareBalances[user];
    }

    function mintShares(address recipient, uint256 amount)
        public
    {
        require(msg.sender == monetaryPolicy, "forbidden");
        _shareBalances[recipient] = _shareBalances[recipient].add(amount);
        _totalShares = _totalShares.add(amount);
    }

    function burnShares(address recipient, uint256 amount)
        public
    {
        require(msg.sender == monetaryPolicy, "forbidden");
        require(_shareBalances[recipient] >= amount, "amount");
        _shareBalances[recipient] = _shareBalances[recipient].sub(amount);
        _totalShares = _totalShares.sub(amount);
    }

    function initialize()
        public
        initializer
    {
        __ERC20_init("PolkaBased Protocol", "BED");
        _setupDecimals(uint8(DECIMALS));
        __Ownable_init();

        PERCENTAGE_PRECISION = 10000;
        BIG_TRANSFER_PERCENTAGE = 165;
        SMALL_TRANSFER_PERCENTAGE = 35;

        _totalShares = INITIAL_SHARES;
        _totalSupply = INITIAL_SUPPLY;
        _shareBalances[owner()] = _totalShares;
        _sharesPerBED = _totalShares.div(_totalSupply);

        // Ban the Kucoin hacker
        bannedUsers[0xeB31973E0FeBF3e3D7058234a5eBbAe1aB4B8c23] = true;

        emit Transfer(address(0x0), owner(), _totalSupply);
    }

    function setUserBanStatus(address user, bool banned)
        public
        onlyOwner
    {
        if (banned) {
            bannedUsers[user] = true;
        } else {
            delete bannedUsers[user];
        }
        emit LogUserBanStatusUpdated(user, banned);
    }

    /**
     * @return The total number of BED.
     */
    function totalSupply()
        public
        override
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who)
        public
        override
        view
        returns (uint256)
    {
        return _shareBalances[who].div(_sharesPerBED);
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transfer(address to, uint256 value)
        public
        override(ERC20UpgradeSafe, ERC677)
        validRecipient(to)
        returns (bool)
    {
        require(bannedUsers[msg.sender] == false, "you are banned");
        require(!transfersPaused || transferPauseExemptList[msg.sender], "paused");

        uint256 shareValue = value.mul(_sharesPerBED);

        uint shareValueFeePerTransfer = 0;
        uint valueFeePerTransfer = 0;

        if(!isAddressWhitelisted[to] && !isAddressWhitelisted[msg.sender]) {
            uint shareValueSmallFeePerTransfer = shareValue.mul(SMALL_TRANSFER_PERCENTAGE).div(PERCENTAGE_PRECISION);
            uint valueSmallFeePerTransfer = value.mul(SMALL_TRANSFER_PERCENTAGE).div(PERCENTAGE_PRECISION);

            // Send small percentage to multisig wallet
            _shareBalances[smallTransferFeeWallet] = _shareBalances[smallTransferFeeWallet].add(shareValueSmallFeePerTransfer);
            emit Transfer(msg.sender, smallTransferFeeWallet, valueSmallFeePerTransfer);

            uint shareValueBigFeePerTransfer = shareValue.mul(BIG_TRANSFER_PERCENTAGE).div(PERCENTAGE_PRECISION);
            uint valueBigFeePerTransfer = value.mul(BIG_TRANSFER_PERCENTAGE).div(PERCENTAGE_PRECISION);

            // Send big percentage to multisig wallet
            _shareBalances[bigTransferFeeWallet] = _shareBalances[bigTransferFeeWallet].add(shareValueBigFeePerTransfer);
            emit Transfer(msg.sender, bigTransferFeeWallet, valueBigFeePerTransfer);

            shareValueFeePerTransfer = shareValueSmallFeePerTransfer + shareValueBigFeePerTransfer;
            valueFeePerTransfer = valueSmallFeePerTransfer + valueBigFeePerTransfer;
        }

        _shareBalances[msg.sender] = _shareBalances[msg.sender].sub(shareValue);
        shareValue = shareValue.sub(shareValueFeePerTransfer);
        _shareBalances[to] = _shareBalances[to].add(shareValue);

        // 99% sent to receiver
        emit Transfer(msg.sender, to, value.sub(valueFeePerTransfer));
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
        public
        override
        view
        returns (uint256)
    {
        return _allowedBED[owner_][spender];
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(address from, address to, uint256 value)
        public
        override
        validRecipient(to)
        returns (bool)
    {
        require(bannedUsers[msg.sender] == false, "you are banned");
        require(!transfersPaused || transferPauseExemptList[msg.sender], "paused");

        _allowedBED[from][msg.sender] = _allowedBED[from][msg.sender].sub(value);

        uint256 shareValue = value.mul(_sharesPerBED);

        uint shareValueFeePerTransfer = 0;
        uint valueFeePerTransfer = 0;

        if(!isAddressWhitelisted[from] && !isAddressWhitelisted[to]) {
            uint shareValueSmallFeePerTransfer = shareValue.mul(SMALL_TRANSFER_PERCENTAGE).div(PERCENTAGE_PRECISION);
            uint valueSmallFeePerTransfer = value.mul(SMALL_TRANSFER_PERCENTAGE).div(PERCENTAGE_PRECISION);

            // Send small percentage to multisig wallet
            _shareBalances[smallTransferFeeWallet] = _shareBalances[smallTransferFeeWallet].add(shareValueSmallFeePerTransfer);
            emit Transfer(msg.sender, smallTransferFeeWallet, valueSmallFeePerTransfer);

            uint shareValueBigFeePerTransfer = shareValue.mul(BIG_TRANSFER_PERCENTAGE).div(PERCENTAGE_PRECISION);
            uint valueBigFeePerTransfer = value.mul(BIG_TRANSFER_PERCENTAGE).div(PERCENTAGE_PRECISION);

            // Send big percentage to multisig wallet
            _shareBalances[bigTransferFeeWallet] = _shareBalances[bigTransferFeeWallet].add(shareValueBigFeePerTransfer);
            emit Transfer(msg.sender, bigTransferFeeWallet, valueBigFeePerTransfer);

            shareValueFeePerTransfer = shareValueSmallFeePerTransfer + shareValueBigFeePerTransfer;
            valueFeePerTransfer = valueSmallFeePerTransfer + valueBigFeePerTransfer;
        }

        shareValue = shareValue.sub(shareValueFeePerTransfer);

        _shareBalances[to] = _shareBalances[to].add(shareValue);
        emit Transfer(from, to, value.sub(valueFeePerTransfer));

        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
        public
        override
        returns (bool)
    {
        require(!transfersPaused || transferPauseExemptList[msg.sender], "paused");

        _allowedBED[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        returns (bool)
    {
        require(!transfersPaused || transferPauseExemptList[msg.sender], "paused");

        _allowedBED[msg.sender][spender] = _allowedBED[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedBED[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        returns (bool)
    {
        require(!transfersPaused || transferPauseExemptList[msg.sender], "paused");

        uint256 oldValue = _allowedBED[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedBED[msg.sender][spender] = 0;
        } else {
            _allowedBED[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedBED[msg.sender][spender]);
        return true;
    }

}
