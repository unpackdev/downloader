// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

/// @title PrivateSaleB
/// @dev A token sale contract that accepts only desired USD stable coins as a payment. Blocks any direct ETH deposits.
contract PrivateSaleB is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    // token sale beneficiary
    address public beneficiary;

    // token sale limits per account in USD with 2 decimals (cents)
    uint256 public minPerAccount;
    uint256 public maxPerAccount;

    // cap in USD for token sale with 2 decimals (cents)
    uint256 public cap;

    // timestamp and duration are expressed in UNIX time, the same units as block.timestamp
    uint256 public startTime;
    uint256 public duration;

    // used to prevent gas usage when sale is ended
    bool private _ended;

    // account balance in USD with 2 decimals (cents)
    mapping(address => uint256) public balances;
    EnumerableSet.AddressSet private _participants;

    struct ParticipantData {
        address _address;
        uint256 _balance;
    }

    // collected stable coins balances
    mapping(address => uint256) private _deposited;

    // collected amount in USD with 2 decimals (cents)
    uint256 public collected;

    // whitelist users in rounds
    mapping(uint256 => mapping(address => bool)) public whitelisted;
    uint256 public whitelistRound = 1;
    bool public whitelistedOnly = true;

    // list of supported stable coins
    EnumerableSet.AddressSet private stableCoins;

    event WhitelistChanged(bool newEnabled);
    event WhitelistRoundChanged(uint256 round);
    event Purchased(address indexed purchaser, uint256 amount);

    /// @dev creates a token sale contract that accepts only USD stable coins
    /// @param _owner address of the owner
    /// @param _beneficiary address of the owner
    /// @param _minPerAccount min limit in USD cents that account needs to spend
    /// @param _maxPerAccount max allocation in USD cents per account
    /// @param _cap sale limit amount in USD cents
    /// @param _startTime the time (as Unix time) of sale start
    /// @param _duration duration in seconds of token sale
    /// @param _stableCoinsAddresses array of ERC20 token addresses of stable coins accepted in the sale
    constructor(
        address _owner,
        address _beneficiary,
        uint256 _minPerAccount,
        uint256 _maxPerAccount,
        uint256 _cap,
        uint256 _startTime,
        uint256 _duration,
        address[] memory _stableCoinsAddresses
    ) Ownable(_owner) {
        require(_beneficiary != address(0), "Sale: zero address");
        require(_cap > 0, "Sale: Cap is 0");
        require(_duration > 0, "Sale: Duration is 0");
        require(_startTime + _duration > block.timestamp, "Sale: Final time is before current time");

        beneficiary = _beneficiary;
        minPerAccount = _minPerAccount;
        maxPerAccount = _maxPerAccount;
        cap = _cap;
        startTime = _startTime;
        duration = _duration;

        for (uint256 i; i < _stableCoinsAddresses.length; i++) {
            stableCoins.add(_stableCoinsAddresses[i]);
        }
    }

    // -----------------------------------------------------------------------
    // GETTERS
    // -----------------------------------------------------------------------

    /// @return the end time of the sale
    function endTime() external view returns (uint256) {
        return startTime + duration;
    }

    /// @return the balance of the account in USD cents
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /// @return the max allocation for account
    function maxAllocationOf(address account) external view returns (uint256) {
        if (!whitelistedOnly || whitelisted[whitelistRound][account]) {
            return maxPerAccount;
        } else {
            return 0;
        }
    }

    /// @return the amount in USD cents of remaining allocation
    function remainingAllocation(address account) external view returns (uint256) {
        if (!whitelistedOnly || whitelisted[whitelistRound][account]) {
            if (maxPerAccount > 0) {
                return maxPerAccount - balances[account];
            } else {
                return cap - collected;
            }
        } else {
            return 0;
        }
    }

    /// @return information if account is whitelisted
    function isWhitelisted(address account) external view returns (bool) {
        if (whitelistedOnly) {
            return whitelisted[whitelistRound][account];
        } else {
            return true;
        }
    }

    /// @return addresses with all stable coins supported in the sale
    function acceptableStableCoins() external view returns (address[] memory) {
        uint256 length = stableCoins.length();
        address[] memory addresses = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            addresses[i] = stableCoins.at(i);
        }

        return addresses;
    }

    /// @return info if sale is still ongoing
    function isLive() public view returns (bool) {
        return !_ended && block.timestamp > startTime && block.timestamp < startTime + duration;
    }

    function getParticipantsNumber() external view returns (uint256) {
        return _participants.length();
    }

    /// @return participants data at index
    function getParticipantDataAt(uint256 index) external view returns (ParticipantData memory) {
        require(index < _participants.length(), "Incorrect index");

        address pAddress = _participants.at(index);
        ParticipantData memory data = ParticipantData(pAddress, balances[pAddress]);

        return data;
    }

    /// @return participants data in range
    function getParticipantsDataInRange(uint256 from, uint256 to) external view returns (ParticipantData[] memory) {
        require(from <= to, "Incorrect range");
        require(to < _participants.length(), "Incorrect range");

        uint256 length = to - from + 1;
        ParticipantData[] memory data = new ParticipantData[](length);

        for (uint256 i; i < length; i++) {
            address pAddress = _participants.at(i + from);
            data[i] = ParticipantData(pAddress, balances[pAddress]);
        }

        return data;
    }

    // -----------------------------------------------------------------------
    // INTERNAL
    // -----------------------------------------------------------------------

    function _isBalanceSufficient(uint256 _amount) private view returns (bool) {
        return _amount + collected <= cap;
    }

    // -----------------------------------------------------------------------
    // MODIFIERS
    // -----------------------------------------------------------------------

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Sale: Caller is not the beneficiary");
        _;
    }

    modifier onlyWhitelisted() {
        require(!whitelistedOnly || whitelisted[whitelistRound][msg.sender], "Sale: Account is not whitelisted");
        _;
    }

    modifier isOngoing() {
        require(isLive(), "Sale: Sale is not active");
        _;
    }

    modifier isEnded() {
        require(_ended || block.timestamp > startTime + duration, "Sale: Not ended");
        _;
    }

    // -----------------------------------------------------------------------
    // SETTERS
    // -----------------------------------------------------------------------

    /// @notice buy tokens using USD stable coins
    /// @dev use approve/transferFrom flow
    /// @param stableCoinAddress stable coin token address
    /// @param amount amount of USD cents
    function buyWith(address stableCoinAddress, uint256 amount) external isOngoing onlyWhitelisted {
        require(stableCoins.contains(stableCoinAddress), "Sale: Stable coin not supported");
        require(amount > 0, "Sale: Amount is 0");
        require(_isBalanceSufficient(amount), "Sale: Insufficient remaining amount");
        require(amount + balances[msg.sender] >= minPerAccount, "Sale: Amount too low");
        require(maxPerAccount == 0 || balances[msg.sender] + amount <= maxPerAccount, "Sale: Amount too high");

        uint8 decimals = IERC20(stableCoinAddress).safeDecimals();
        uint256 stableCoinUnits = amount * (10**(decimals - 2));

        // solhint-disable-next-line max-line-length
        require(IERC20(stableCoinAddress).allowance(msg.sender, address(this)) >= stableCoinUnits, "Sale: Insufficient stable coin allowance");
        IERC20(stableCoinAddress).safeTransferFrom(msg.sender, stableCoinUnits);

        balances[msg.sender] += amount;
        collected += amount;
        _deposited[stableCoinAddress] += stableCoinUnits;

        if (!_participants.contains(msg.sender)) {
            _participants.add(msg.sender);
        }

        emit Purchased(msg.sender, amount);
    }

    function endPresale() external onlyOwner {
        require(collected >= cap, "Sale: Limit not reached");
        _ended = true;
    }

    function withdrawFunds() external onlyBeneficiary isEnded {
        _ended = true;

        uint256 amount;

        for (uint256 i; i < stableCoins.length(); i++) {
            address stableCoin = address(stableCoins.at(i));
            amount = IERC20(stableCoin).balanceOf(address(this));
            if (amount > 0) {
                IERC20(stableCoin).safeTransfer(beneficiary, amount);
            }
        }
    }

    function recoverErc20(address token) external onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        amount -= _deposited[token];
        if (amount > 0) {
            IERC20(token).safeTransfer(owner, amount);
        }
    }

    function recoverEth() external onlyOwner isEnded {
        payable(owner).transfer(address(this).balance);
    }

    function setBeneficiary(address newBeneficiary) public onlyOwner {
        require(newBeneficiary != address(0), "Sale: zero address");
        beneficiary = newBeneficiary;
    }

    function setWhitelistedOnly(bool enabled) public onlyOwner {
        whitelistedOnly = enabled;
        emit WhitelistChanged(enabled);
    }

    function setWhitelistRound(uint256 round) public onlyOwner {
        whitelistRound = round;
        emit WhitelistRoundChanged(round);
    }

    function addWhitelistedAddresses(address[] calldata addresses) external onlyOwner {
        for (uint256 i; i < addresses.length; i++) {
            whitelisted[whitelistRound][addresses[i]] = true;
        }
    }
}
