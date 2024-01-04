// SPDX-License-Identifier: <SPDX-License>


/*

▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓
▓▓░░░░░░░░░░░░░░░░░░░░░▒▒▒▒░░░▒▒▒▒░░░░░░▓▓
▓▓░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒░▒▒▒▒▒▒░░░░░▓▓
▓▓░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░▓▓
▓▓░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒░░░░░░▓▓
▓▓░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒░░░░░░░▓▓
▓▓░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒░░░░░░░░░▓▓
▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░░░░░░░▓▓
▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓
▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒░▒▒▒░░░▓▓
▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒░░▓▓
▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒░░░▓▓
▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒░░░░▓▓
▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒░░░░░▓▓
▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░░▓▓
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
_______▒__________▒▒▒▒▒▒▒▒▒▒▒▒▒▒
______▒_______________▒▒▒▒▒▒▒▒
_____▒________________▒▒▒▒▒▒▒▒
____▒___________▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
___▒
__▒______▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
_▒______▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓
▒▒▒▒___▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓
▒▒▒▒__▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓▒▓
▒▒▒__▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
*/




pragma solidity 0.6.12;

import "./Ownable.sol";
import "./SafeMathInt.sol";
import "./ERC20UpgradeSafe.sol";
import "./ERC677Token.sol";

/**
 * @title AP3L ERC20 token
 * @dev This is part of an implementation of the AP3L Index Fund protocol.
 *      AP3L is an ERC20 token with 1% Premium Tax distributed on every transaction.
 *      AP3L balances are internally represented with a hidden denomination, 'shares'.
 *      We support splitting the currency in expansion and combining the currency on contraction by
 *      changing the exchange rate between the hidden 'shares' and the public 'AP3L' token.
 */

contract AP3LToken is ERC20UpgradeSafe, ERC677Token, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    event LogReAP3L(uint256 indexed epoch, uint256 totalSupply);
    event LogMonetaryPolicyUpdated(address monetaryPolicy);
    event LogUserBanStatusUpdated(address user, bool banned);
    event Premium(uint256 amount, uint256 time);

    // Used for authentication
    address public monetaryPolicy;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_SUPPLY = 186_282 * 10**DECIMALS;
    uint256 private constant INITIAL_SHARES = (MAX_UINT256 / (10 ** 32)) - ((MAX_UINT256 / (10 ** 32)) % INITIAL_SUPPLY);
    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 private _totalShares;
    uint256 private _totalSupply;
    uint256 private _sharesPerAP3L;
    mapping(address => uint256) private _shareBalances;

    mapping(address => bool) public bannedUsers;

    // This is denominated in AP3LToken, because the sharesperAP3L conversion might change before
    // it's fully paid.
    mapping (address => mapping (address => uint256)) private _allowedAP3L;

    bool public transfersPaused;
    bool public reAP3LsPaused;

    mapping(address => bool) public transferPauseExemptList;





    function setReAP3LsPaused(bool _reAP3LsPaused)
        public
        onlyOwner
    {
        reAP3LsPaused = _reAP3LsPaused;
    }

    /*
     * @param monetaryPolicy_ The address of the monetary policy contract to use for authentication.
     */




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


    function initialize()
        public
        initializer
    {
        __ERC20_init("AP3LINK", "AP3L");
        _setupDecimals(uint8(DECIMALS));

        _totalShares = INITIAL_SHARES;
        _totalSupply = INITIAL_SUPPLY;
        _shareBalances[owner()] = _totalShares.mul(90000).div(1e5);
        _shareBalances[0x0000000000000000000000000000000000000000] = _totalShares.mul(10000).div(1e5);
        _sharesPerAP3L = _totalShares.div(_totalSupply);

        emit Transfer(address(0x0), owner(), _totalSupply);
    }



    /**
     * @return The total number of AP3L.
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
        uint256 shareAmount =  _shareBalances[who];

        return shareAmount.div(_sharesPerAP3L);
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
        require(value > 100000, "Sending too little");

        //Transfer to recepient
        uint256 sharesToTransfer = (value.mul(1e5).div(1e5)).mul(_sharesPerAP3L); //99%
        _shareBalances[msg.sender] = _shareBalances[msg.sender].sub(sharesToTransfer);
        _shareBalances[to] = _shareBalances[to].add(sharesToTransfer);

        //_Premium 1% of the transaction
        uint256 burnAmount = value.mul(1000).div(1e5); //1%
        _Premium(msg.sender, burnAmount);

        emit Transfer(msg.sender, to, value);
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
        return _allowedAP3L[owner_][spender];
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
        require(value > 100000, "Sending too little");

        _allowedAP3L[from][msg.sender] = _allowedAP3L[from][msg.sender].sub(value);


        //Transfer to recepient
        uint256 sharesToTransfer = (value.mul(1e5).div(1e5)).mul(_sharesPerAP3L); //99%
        _shareBalances[from] = _shareBalances[from].sub(sharesToTransfer);
        _shareBalances[to] = _shareBalances[to].add(sharesToTransfer);

        //_Premium 1% of the transaction
        uint256 burnAmount = value.mul(1000).div(1e5);
        _Premium(from, burnAmount);

        emit Transfer(from, to, value);
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

        _allowedAP3L[msg.sender][spender] = value;
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

        _allowedAP3L[msg.sender][spender] = _allowedAP3L[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedAP3L[msg.sender][spender]);
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

        uint256 oldValue = _allowedAP3L[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedAP3L[msg.sender][spender] = 0;
        } else {
            _allowedAP3L[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedAP3L[msg.sender][spender]);
        return true;
    }

    function _Premium(address account, uint256 amount) internal {
        require(amount != 0);
        require(amount <= _shareBalances[account].div(_sharesPerAP3L));

        //convert this amount to shares
        uint256 shareAmount = amount.mul(_sharesPerAP3L);

        //subtract this amount of fragments from their balance
        _shareBalances[account] = _shareBalances[account].sub(shareAmount);

        //update total shares
        _totalShares = _totalShares.sub(shareAmount);

        //update shares per token
        _sharesPerAP3L = _totalShares.div(_totalSupply);

        //emit Burn and yield
        emit Transfer(account, address(0), amount);
        emit Premium(amount, now);
    }

}
