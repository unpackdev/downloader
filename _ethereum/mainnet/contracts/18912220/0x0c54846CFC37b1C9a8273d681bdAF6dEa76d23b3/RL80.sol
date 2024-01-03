/* 𝓞𝖚𝖗 𝕷𝖆𝖉𝖞  ͦᶠ 𝕻𝖊𝖗𝖕𝖊𝖙𝖚𝖆𝖑 𝕻𝖗𝖔𝖋𝖎𝖙
Website: https://ourlady.io
Telegram: https://t.me/ourladytoken
Twitter: https://twitter.com/ourladytoken */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./VRFConsumerBaseV2.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./AutomationCompatibleInterface.sol";

contract RL80 is
    ERC20,
    ERC20Burnable,
    VRFConsumerBaseV2,
    Ownable,
    AutomationCompatibleInterface
{
    // STRUCTS

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }

    // ERRORS

    error RL80__TradingNotEnabled();
    error RL80__ExceedsMaximumHoldingAmount();
    error RL80__AllowanceExceeded();
    error RL80__UpkeepNotNeeded();

    // MAPPINGS & EVENTS

    mapping(uint256 => RequestStatus) private requests; // requestId -> RequestStatus

    event TradingEnabled(bool enabled);
    event RequestSent(uint256 requestId);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 indexed timestamp
    );
    event TokensBurned(
        address indexed burnerAddress,
        uint256 amount,
        uint256 indexed timestamp
    );

    // IMMUTABLE STORAGE

    uint256 public constant MAX_SUPPLY = 10_000_000_000 * 10 ** 18; // 10 billion tokens
    uint256 public constant MAX_HOLDING = MAX_SUPPLY / 100; // 1% of total supply
    uint256 public constant MAX_TAX_RATE = 500; // Maximum tax rate of 5%
    uint256 public constant TAX_DURATION = 40 days; // Duration of the tax period after trading is enabled

    // MUTABLE STORAGE

    uint256 public s_taxRate = 300;
    uint256 public s_reducedTaxRate = 100;
    address public s_treasury;
    address public s_initialOwner = msg.sender;
    bool public s_tradingEnabled = false;
    uint256[] public s_requestIds;
    uint256 public s_lastRequestId;
    uint256 public s_tradingStartTime;
    uint256 private s_lastTimeStamp;
    uint256 private i_interval;
    bool private upkeepLock;
    uint256 private lastUpkeepTimestamp;

    // VRF CONSTANTS & IMMUTABLE

    VRFCoordinatorV2Interface private immutable VRF_COORDINATORV2;
    uint64 private immutable VRF_SUBSCRIPTION_ID = 899;
    bytes32 private immutable VRF_GAS_LANE;
    uint32 private immutable VRF_GAS_LIMIT = 500000;
    uint16 private constant VRF_REQUEST_CONFIRMATIONS = 3;
    uint32 private constant VRF_NUM_WORDS = 1;

    constructor(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint256 interval
    )
        // uint64 _subscriptionId
        ERC20("OurLady", "RL80")
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        VRF_COORDINATORV2 = VRFCoordinatorV2Interface(_vrfCoordinator);
        VRF_GAS_LANE = _keyHash;
        _mint(msg.sender, MAX_SUPPLY);
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    // ACTIONS

    function _transferTokens(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        // Check if the sender or recipient is exempt from restrictions
        bool isExemptFromRestrictions = sender == owner() ||
            sender == s_treasury ||
            recipient == s_treasury ||
            sender == s_initialOwner ||
            recipient == s_initialOwner;

        // Check if trading is enabled or if the sender/recipient is exempt
        if (!s_tradingEnabled && !isExemptFromRestrictions) {
            revert RL80__TradingNotEnabled();
        }

        // Check for maximum holding amount unless the recipient is exempt
        if (
            balanceOf(recipient) + amount > MAX_HOLDING &&
            !isExemptFromRestrictions
        ) {
            revert RL80__ExceedsMaximumHoldingAmount();
        }

        uint256 transferAmount = amount;
        uint256 taxAmount = 0;

        // Apply tax if not exempt and within tax duration
        if (
            !isExemptFromRestrictions &&
            s_tradingEnabled &&
            block.timestamp <= s_tradingStartTime + TAX_DURATION
        ) {
            taxAmount = (amount * s_taxRate) / 10000;
        }
        // Check if the current timestamp is beyond the initial tax duration
        else if (
            !isExemptFromRestrictions &&
            s_tradingEnabled &&
            block.timestamp > s_tradingStartTime + TAX_DURATION
        ) {
            taxAmount = (amount * s_reducedTaxRate) / 10000;
        }

        if (taxAmount > 0) {
            transferAmount -= taxAmount;
            super._transfer(sender, s_treasury, taxAmount);
        }

        super._transfer(sender, recipient, transferAmount);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transferTokens(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 currentAllowance = allowance(sender, _msgSender());
        if (currentAllowance < amount) revert RL80__AllowanceExceeded();
        _approve(sender, _msgSender(), currentAllowance - amount);
        _transferTokens(sender, recipient, amount);
        return true;
    }

    function burn(uint256 amount) public override {
        super.burn(amount);
        emit TokensBurned(_msgSender(), amount, block.timestamp);
    }

    // KEEPERS

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timePassed = ((block.timestamp - lastUpkeepTimestamp) >
            i_interval);
        upkeepNeeded = timePassed && !upkeepLock;
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert RL80__UpkeepNotNeeded();
        }

        upkeepLock = true; // Engage the lock

        uint256 requestId = VRF_COORDINATORV2.requestRandomWords(
            VRF_GAS_LANE,
            VRF_SUBSCRIPTION_ID,
            VRF_REQUEST_CONFIRMATIONS,
            VRF_GAS_LIMIT,
            VRF_NUM_WORDS
        );

        requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        s_requestIds.push(requestId);
        s_lastRequestId = requestId;
        emit RequestSent(requestId);
    }

    // VRF

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        if (requests[_requestId].exists) {
            RequestStatus storage requestStatus = requests[_requestId];
            requestStatus.fulfilled = true;
            requestStatus.randomWords = _randomWords;

            lastUpkeepTimestamp = block.timestamp; // Update the timestamp
            upkeepLock = false; // Disengage the lock

            emit RequestFulfilled(_requestId, _randomWords, block.timestamp);
        }
    }

    // SETTERS

    function setTaxRates(
        uint256 _taxRate,
        uint256 _reducedTaxRate
    ) external onlyOwner {
        require(
            _taxRate <= MAX_TAX_RATE,
            "RL80: Tax rate exceeds maximum limit"
        );
        require(
            _reducedTaxRate <= MAX_TAX_RATE,
            "RL80: Reduced tax rate exceeds maximum limit"
        );
        s_taxRate = _taxRate;
        s_reducedTaxRate = _reducedTaxRate;
    }

    function toggleTrading(bool _enable) external onlyOwner {
        s_tradingEnabled = _enable;
        s_tradingStartTime = _enable ? block.timestamp : 0;
        emit TradingEnabled(_enable);
    }

    function setInterval(uint256 newInterval) external onlyOwner {
        i_interval = newInterval;
    }

    function setTreasury(address _treasury) external onlyOwner {
        s_treasury = _treasury;
    }

    // GETTERS

    function getBurnedTokens() public view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }

    function getRequestDetails(
        uint256 requestId
    ) public view returns (bool, bool, uint256[] memory) {
        RequestStatus storage request = requests[requestId];
        return (request.fulfilled, request.exists, request.randomWords);
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }
}
