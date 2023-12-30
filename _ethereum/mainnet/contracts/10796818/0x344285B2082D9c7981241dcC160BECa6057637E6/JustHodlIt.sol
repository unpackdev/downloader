pragma solidity 0.6.7;

contract JustHodlIt {

    uint256 public MINIMUM_INVEST = 0.1 ether;
    uint256 public REFERRAL_PERCENT = 3;
    uint256 public CASHBACK_PERCENT = 2;

    uint256 internal _totalBank;
    uint256 internal _profitPerShare;
    uint256 internal _magnitude = 1e18;

    address[] accounts;
    mapping (address => User) public users;
    struct User {
        uint256 deposit;
        address payable referrer;
        uint256 lastActivity;
        uint256 payoutsTo;
    }

    address payable defaultReferrer;
    address public owner;

    event OnInvest(address indexed account, uint256 value);
    event OnReinvest(address indexed account, uint256 value);
    event OnWithdraw(address indexed account, uint256 value);
    event OnRefBonus(address indexed account, address indexed referral, uint256 value);
    event OnCashback(address indexed account, uint256 value);
    event OnLostFunds(address indexed account, uint256 value);

    constructor(address payable defaultReferrerAddr) public {
        require(!_isContract(defaultReferrerAddr));
        defaultReferrer = defaultReferrerAddr;
    }

    fallback() external payable {
        if (msg.value >= MINIMUM_INVEST) {
            invest(_bytesToAddress(msg.data));
        } else {
            withdrawAll();
        }
    }

    receive() external payable {
        if (msg.value >= MINIMUM_INVEST) {
            invest(address(0));
        } else {
            withdrawDividends();
        }
    }

    function invest(address payable referrer) public payable {
        require(msg.value >= MINIMUM_INVEST, "Investment must be more or equal to the minimum");

        _invest(msg.sender, referrer, msg.value);
    }

    function _invest(address payable account, address payable referrer, uint256 value) internal {
        User storage user = users[account];

        uint256 dividends = user.referrer == address(0) ? (value * 5 / 100) : (value * 7 / 100);
        if (_totalBank > 0) {
            _profitPerShare += dividends * _magnitude / _totalBank;
            user.payoutsTo += _profitPerShare * value;
        } else {
            _profitPerShare += dividends * _magnitude / value;
        }

        _totalBank += value;
        user.deposit += value;
        user.lastActivity = block.timestamp;

        emit OnInvest(account, value);

        if (user.referrer == address(0)) {
            address payable recipient;
            if (users[referrer].referrer != address(0)) {
                user.referrer = referrer;
                recipient = account;
            } else {
                user.referrer = defaultReferrer;
                recipient = defaultReferrer;
            }
            accounts.push(msg.sender);
            (recipient.send(value * CASHBACK_PERCENT / 100));
            emit OnCashback(recipient, value * CASHBACK_PERCENT / 100);
		}

        (user.referrer.send(value * REFERRAL_PERCENT / 100));
        emit OnRefBonus(user.referrer, account, value * REFERRAL_PERCENT / 100);
    }

    function withdrawAll() public {
        User storage user = users[msg.sender];
        uint256 deposit = user.deposit;
        uint256 dividends = getDividends(msg.sender);

        require(deposit > 0, "User has no deposit");

        user.payoutsTo += (deposit + dividends) * _magnitude;
        _totalBank -= user.deposit;
        if (_totalBank > 0) {
            _profitPerShare += (deposit * 20 / 100) * _magnitude / _totalBank;
            deposit -= deposit * (20 + 10) / 100;
        } else {
            _profitPerShare = 0;
            deposit = 0;
            dividends = address(this).balance;
        }
        user.deposit = 0;
        user.payoutsTo = 0;
        user.lastActivity = block.timestamp;

        msg.sender.transfer(deposit + dividends);

        emit OnWithdraw(msg.sender, deposit + dividends);
    }

    function withdrawDividends() public {
        User storage user = users[msg.sender];
        uint256 payout = getDividends(msg.sender);

        require(payout > 0, "User has no dividends");

        user.payoutsTo += payout * _magnitude;
        user.lastActivity = block.timestamp;

        msg.sender.transfer(payout);

        emit OnWithdraw(msg.sender, payout);
    }

    function reinvest() public {
        uint256 payout = getDividends(msg.sender);

        require(payout > 0, "User has no dividends");

        users[msg.sender].payoutsTo += payout * _magnitude;

        _invest(msg.sender, address(0), payout);

        emit OnReinvest(msg.sender, payout);
    }

    function distributeLostFunds(address[] memory lostAccounts) public {
        for (uint256 i = 0; i < lostAccounts.length; i++) {
            if (users[lostAccounts[i]].deposit > 0 && block.timestamp - users[lostAccounts[i]].lastActivity >= 365 days) {
                uint256 lostFunds = users[lostAccounts[i]].deposit * 90 / 100 + getDividends(lostAccounts[i]);
                _totalBank -= users[lostAccounts[i]].deposit;
                users[lostAccounts[i]].deposit = 0;
                users[lostAccounts[i]].payoutsTo = 0;
                _profitPerShare += lostFunds * _magnitude / _totalBank;
                emit OnLostFunds(lostAccounts[i], lostFunds);
            }
        }
    }

    function checkAccounts(uint256 startIndex, uint256 amount) public view returns(address[] memory) {
        require(startIndex + amount <= accounts.length);

        uint256[] memory indexes = new uint256[](startIndex + amount);
        uint256 count;

        for (uint256 i = startIndex; i < amount; i++) {
            if (users[accounts[i]].deposit > 0 && block.timestamp - users[accounts[i]].lastActivity >= 365 days) {
                indexes[count] = i;
                count++;
            }
        }

        address[] memory lost = new address[](count);

        for (uint256 i = 0; i < count; i++) {
            lost[i] = accounts[indexes[i]];
        }

        return lost;
    }

    function amountOfUsers() public view returns(uint256) {
        return accounts.length;
    }

    function contractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getAll(address account) public view returns(uint256) {
        if (users[account].deposit < _totalBank) {
            return (users[account].deposit * 70 / 100) + getDividends(account);
        } else {
            return address(this).balance;
        }
    }

    function getDividends(address account) public view returns(uint256) {
        return (_profitPerShare * users[account].deposit - users[account].payoutsTo) / _magnitude;
    }

    function _bytesToAddress(bytes memory source) internal pure returns(address payable parsedreferrer) {
        assembly {
            parsedreferrer := mload(add(source,0x14))
        }
    }

    function _isContract(address account) internal view returns(bool) {
        uint size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}