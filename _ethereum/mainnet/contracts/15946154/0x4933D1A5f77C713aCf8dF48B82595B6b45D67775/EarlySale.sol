// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./AccessControl.sol";
import "./ERC165Checker.sol";
import "./PriceCalculator.sol";
import "./ISale.sol";
import "./IEarlySaleReceiver.sol";
import "./IterableMapping.sol";

/// @title Contract which allows early investors to deposit ETH to reserve STK for the upcoming private sale
/// @notice Sends purchase orders to StaakeSale contract when the Staake team calls `withdraw` and investorToBalance is empty
contract EarlySale is ISale, PriceCalculator, AccessControl {
    using IterableMapping for IterableMapping.Map;

    bytes32 public constant INVESTOR_ROLE = keccak256("INVESTOR");

    uint256 public availableTokens;
    IterableMapping.Map private investorToBalance;

    IEarlySaleReceiver public receiver;

    bool public isPublic = true;
    bool public isClosed = false;

    uint256 public immutable MIN_INVESTMENT;
    uint256 public immutable MAX_INVESTMENT;

    event TokenReserved(address indexed investor, uint256 eth, uint256 stk);

    constructor(
        address _priceFeed,
        uint256 _remainingTokens,
        uint256 _minInvestment,
        uint256 _maxInvestment,
        address[] memory _earlyInvestors
    ) PriceCalculator(_priceFeed) {
        availableTokens = _remainingTokens;
        MIN_INVESTMENT = _minInvestment;
        MAX_INVESTMENT = _maxInvestment;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        for (uint256 i = 0; i < _earlyInvestors.length; i++)
            _grantRole(INVESTOR_ROLE, _earlyInvestors[i]);
    }

    /**
     * @notice Reserves STK tokens at the current ETH/USD exchange rate
     */
    function buy() external payable {
        require(!isClosed, "early sale is closed");
        require(
            isPublic || hasRole(INVESTOR_ROLE, msg.sender),
            "early sale is private"
        );

        require(msg.value >= MIN_INVESTMENT, "amount should be at least 5 ETH");

        (uint256 eth, ) = investorToBalance.get(msg.sender);
        require(eth + msg.value <= MAX_INVESTMENT, "max investment is 50 ETH");

        uint256 stk = getPriceConversion(msg.value);
        require(stk <= availableTokens, "not enough tokens available");

        investorToBalance.increment(msg.sender, msg.value, stk);
        availableTokens -= stk;

        emit TokenReserved(msg.sender, msg.value, stk);
    }

    /**
     * @notice Initializes the receiver of the STK buy orders
     * @notice Makes `withdrawAll()` available
     * @notice Contract must implement ERC165 and IEarlySaleReceiver
     * @param _address, contract address
     */
    function setReceiver(address _address)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(address(receiver) == address(0), "address already set");
        require(
            ERC165Checker.supportsInterface(
                _address,
                type(IEarlySaleReceiver).interfaceId
            ),
            "address is not a compatible receiver"
        );

        receiver = IEarlySaleReceiver(_address);
    }

    /**
     * @notice Transfers a batch of buy orders to the receiver contract
     * @notice Withdraws the ETH to the caller's wallet and self-destructs if there are no buy orders left
     * @notice Ends the sale and locks the `buy` function
     * @notice Can only be called if the receiver address has been set
     */
    function withdrawBatch(uint256 count)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(address(receiver) != address(0), "receiver not set yet");
        require(
            count <= investorToBalance.size(),
            "count above investor count"
        );

        isClosed = true;

        for (uint256 i = 0; i < count; i++) {
            address investor = investorToBalance.getKeyAtIndex(0);
            (uint256 eth, uint256 stk) = investorToBalance.get(investor);
            investorToBalance.remove(investor);

            receiver.earlyDeposit(investor, eth, stk);
        }

        if (investorToBalance.size() == 0) selfdestruct(payable(msg.sender));
    }

    /**
     * @notice Allows new addresses to invest (i.e. to call the `buy` function)
     * @param _earlyInvestors, array of addresses of the investors
     */
    function addToWhitelist(address[] calldata _earlyInvestors)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i; i < _earlyInvestors.length; i++)
            _grantRole(INVESTOR_ROLE, _earlyInvestors[i]);
    }

    /**
     * @notice Revoke access to the `buy` function from investors
     * @param _earlyInvestors, array of addresses of the investors
     */
    function removeFromWhitelist(address[] calldata _earlyInvestors)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i; i < _earlyInvestors.length; i++)
            _revokeRole(INVESTOR_ROLE, _earlyInvestors[i]);
    }

    /**
     * @notice Set whether the sale is public or whitelist-only
     */
    function setIsPublic(bool _isPublic) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isPublic = _isPublic;
    }

    /**
     * @notice View the number of distinct investors
     */
    function investorCount() external view returns (uint256) {
        return investorToBalance.size();
    }

    /**
     * @notice View the amount of STK a user currently has reserved
     * @param _user, address of the user
     */
    function balanceOf(address _user) external view returns (uint256) {
        (, uint256 stk) = investorToBalance.get(_user);
        return stk;
    }

    /**
     * @notice View the amount of ETH spent by a user
     * @param _user, address of the user
     */
    function getETHSpent(address _user) external view returns (uint256) {
        (uint256 eth, ) = investorToBalance.get(_user);
        return eth;
    }
}
