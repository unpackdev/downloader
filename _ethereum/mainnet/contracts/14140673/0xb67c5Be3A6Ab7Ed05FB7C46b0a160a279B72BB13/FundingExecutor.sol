// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Strings.sol";
import "./GeneralTokenVesting.sol";
import "./Finance.sol";

/**
 * @title FundingExecutor
 * @dev allow a whitelisted set of addresses to Fund SARCO, via stablecoins (USDC),
 * @dev exchange rate set w/ each traunche/group
 */
contract FundingExecutor is Ownable {
    using SafeERC20 for IERC20;

    uint256 private constant USDC_TO_SARCO_PRECISION = 10**18;
    uint256 private constant SARCO_TO_USDC_DECIMAL_FIX = 10**(18 - 6);
    uint256 public immutable sarcoAllocationsTotal;
    uint256 public immutable offerExpirationDelay;
    uint256 public immutable vestingEndDelay;
    IERC20 public immutable usdcToken;
    IERC20 public immutable sarcoToken;
    GeneralTokenVesting public immutable generalTokenVesting;
    Finance public immutable sarcoDao;

    uint256 public offerStartedAt;
    uint256 public offerExpiresAt;

    uint256[] public usdcToSarcoRates;
    struct FunderInfo {
        uint256 sarcoAllocation;
        uint256 usdcToSarcoRateIndex;
    }

    mapping(address => FunderInfo) public funders;

    // The purchase has been executed exchanging USDC to vested SARCO
    event FundingExecuted(
        // the address that has received the vested SARCO tokens
        address indexed sarcoReceiver,
        // the number of SARCO tokens vested to sarcoReceiver
        uint256 sarcoAllocation,
        // the amount of USDC that was invested and forwarded to the DAO
        uint256 usdcCost
    );

    // Creates a window of time which the whitelisted set of addresses may invest in SARCO
    event OfferStarted(
        // Window start time
        uint256 startedAt,
        // Window end time
        uint256 expiresAt
    );

    // If tokens have not been invested after time window, the DAO can recover tokens
    event TokensRecovered(
        // Amount of Tokens
        uint256 amount
    );

    /**
     * @dev inits/sets sarco funding enviorment
     * @param _usdcToSarcoRates Array of usdc/sarco rates
     * @param _vestingEndDelay Delay from the purchase moment to the vesting end moment, in seconds
     * @param _offerExpirationDelay Delay from the contract deployment to offer expiration, in seconds
     * @param _sarcoFunders  List of valid SARCO investor
     * @param _sarcoAllocations List of SARCO token allocations, should include decimals 10 ** 18
     * @param _sarcoRateIndex group which Sarco investor belongs to
     * @param _sarcoAllocationsTotal Checksum of SARCO token allocations, should include decimals 10 ** 18
     * @param _usdcToken USDC token address
     * @param _sarcoToken Sarco token address
     * @param _generalTokenVesting GeneralTokenVesting contract address
     * @param _sarcoDao Sarco DAO contract address
     */
    constructor(
        uint256[] memory _usdcToSarcoRates,
        uint256 _vestingEndDelay,
        uint256 _offerExpirationDelay,
        address[] memory _sarcoFunders,
        uint256[] memory _sarcoAllocations,
        uint256[] memory _sarcoRateIndex,
        uint256 _sarcoAllocationsTotal,
        address _usdcToken,
        address _sarcoToken,
        address _generalTokenVesting,
        address _sarcoDao
    ) {
        require(
            _usdcToSarcoRates.length > 0,
            "FundingExecutor: array must be greater than 0"
        );
        require(
            _vestingEndDelay > 0,
            "FundingExecutor: endDelay must be greater than 0"
        );
        require(
            _offerExpirationDelay > 0,
            "FundingExecutor: offerExpiration must be greater than 0"
        );
        require(
            _sarcoFunders.length == _sarcoAllocations.length &&
                _sarcoAllocations.length == _sarcoRateIndex.length,
            "FundingExecutor: purchasers, allocations, indexes lengths must be equal"
        );
        require(
            _usdcToken != address(0),
            "FundingExecutor: _usdcToken cannot be 0 address"
        );
        require(
            _sarcoToken != address(0),
            "FundingExecutor: _sarcoToken cannot be 0 address"
        );
        require(
            _generalTokenVesting != address(0),
            "FundingExecutor: _generalTokenVesting cannot be 0 address"
        );
        require(
            _sarcoDao != address(0),
            "FundingExecutor: _sarcoDao cannot be 0 address"
        );

        // Set global variables
        usdcToSarcoRates = _usdcToSarcoRates;
        vestingEndDelay = _vestingEndDelay;
        offerExpirationDelay = _offerExpirationDelay;
        sarcoAllocationsTotal = _sarcoAllocationsTotal;
        usdcToken = IERC20(_usdcToken);
        sarcoToken = IERC20(_sarcoToken);
        generalTokenVesting = GeneralTokenVesting(_generalTokenVesting);
        sarcoDao = Finance(_sarcoDao);
        uint256 allocationsSum = 0;
        for (uint256 i = 0; i < _sarcoFunders.length; i++) {
            require(
                _sarcoFunders[i] != address(0),
                "FundingExecutor: Funder cannot be the ZERO address"
            );
            require(
                funders[_sarcoFunders[i]].sarcoAllocation == 0,
                "FundingExecutor: Allocation has already been set"
            );
            require(
                _sarcoAllocations[i] > 0,
                "FundingExecutor: No allocated Sarco tokens for address"
            );
            require(
                _usdcToSarcoRates[_sarcoRateIndex[i]] > 0,
                "FundingExecutor: _usdcToSarcoRates must be greater than 0"
            );
            funders[_sarcoFunders[i]] = FunderInfo(
                _sarcoAllocations[i],
                _sarcoRateIndex[i]
            );
            allocationsSum += _sarcoAllocations[i];
        }
        require(
            allocationsSum == _sarcoAllocationsTotal,
            "FundingExecutor: AllocationsTotal does not equal the sum of passed allocations"
        );

        // Approve SarcoDao - PurchaseExecutor's total USDC tokens (Execute Purchase)
        IERC20(_usdcToken).approve(_sarcoDao, type(uint256).max);

        // Approve full SARCO amount to GeneralTokenVesting contract
        IERC20(_sarcoToken).approve(
            _generalTokenVesting,
            _sarcoAllocationsTotal
        );

        // Approve SarcoDao - Funding Executor's total SARCO tokens (Recover Tokens)
        IERC20(_sarcoToken).approve(_sarcoDao, _sarcoAllocationsTotal);
    }

    function _getUsdcCost(uint256 sarcoAmount, uint256 index)
        internal
        view
        returns (uint256)
    {
        return
            ((sarcoAmount * USDC_TO_SARCO_PRECISION) /
                usdcToSarcoRates[index]) / SARCO_TO_USDC_DECIMAL_FIX;
    }

    function offerStarted() public view returns (bool) {
        return offerStartedAt != 0;
    }

    function offerExpired() public view returns (bool) {
        return block.timestamp >= offerExpiresAt;
    }

    /**
     * @notice Starts the offer if it 1) hasn't been started yet and 2) has received funding in full.
     */
    function _startUnlessStarted() internal {
        require(
            offerStartedAt == 0,
            "FundingExecutor: Offer has already started"
        );
        require(
            sarcoToken.balanceOf(address(this)) == sarcoAllocationsTotal,
            "FundingExecutor: Insufficient Sarco contract balance to start offer"
        );

        offerStartedAt = block.timestamp;
        offerExpiresAt = block.timestamp + offerExpirationDelay;
        emit OfferStarted(offerStartedAt, offerExpiresAt);
    }

    function start() public {
        _startUnlessStarted();
    }

    /**
     * @dev Returns the Sarco allocation and the USDC cost to invest the Sarco Allocation of the whitelisted Sarco investor
     * @param sarcoReceiver Whitelisted Sarco Investor
     * @return A tuple: the first element is the amount of SARCO available for purchase (zero if
        the purchase was already executed for that address), the second element is the
        USDC cost of the purchase.
     */
    function getAllocation(address sarcoReceiver)
        public
        view
        returns (uint256, uint256)
    {
        FunderInfo memory _funder = funders[sarcoReceiver];
        uint256 usdcCost = _getUsdcCost(
            _funder.sarcoAllocation,
            _funder.usdcToSarcoRateIndex
        );
        return (_funder.sarcoAllocation, usdcCost);
    }

    /**
     * @dev Purchases Sarco for the specified address in exchange for USDC.
     * @notice Sends USDC tokens used to purchase Sarco to Sarco DAO, 
     Approves GeneralTokenVesting contract Sarco Tokens to utilizes allocated Sarco funds,
     Starts token vesting via GeneralTokenVesting contract.
     * @param sarcoReceiver Whitelisted Sarco Investor
     */
    function executePurchase(address sarcoReceiver) external {
        if (offerStartedAt == 0) {
            start();
        }
        require(
            block.timestamp < offerExpiresAt,
            "FundingExecutor: Purchases cannot be made after the offer has expired"
        );

        (uint256 sarcoAllocation, uint256 usdcCost) = getAllocation(msg.sender);

        // Check sender's allocation
        require(
            sarcoAllocation > 0,
            "FundingExecutor: sender does not have a SARCO allocation"
        );

        // Clear sender's allocation
        funders[msg.sender].sarcoAllocation = 0;

        // transfer sender's USDC to this contract
        usdcToken.safeTransferFrom(msg.sender, address(this), usdcCost);

        // Dynamically Build finance app's "message" string
        string memory _executedPurchaseString = string(
            abi.encodePacked(
                "Funding Executed by account: ",
                Strings.toHexString(uint160(msg.sender), 20),
                " for account: ",
                Strings.toHexString(uint160(sarcoReceiver), 20),
                ". Total SARCOs: ",
                Strings.toString(sarcoAllocation),
                "."
            )
        );

        // Forward USDC cost of the purchase to the DAO contract via the Finance Deposit method
        sarcoDao.deposit(address(usdcToken), usdcCost, _executedPurchaseString);

        // Call GeneralTokenVesting startVest method
        GeneralTokenVesting(generalTokenVesting).startVest(
            sarcoReceiver,
            sarcoAllocation,
            vestingEndDelay,
            address(sarcoToken)
        );

        emit FundingExecuted(sarcoReceiver, sarcoAllocation, usdcCost);
    }

    /**
     * @dev If recoverUnsoldTokens > 0 after the offer expired, sarco tokens are send back to Sarco Dao via Finance Contract.
     */
    function recoverUnsoldTokens() external {
        require(
            offerStarted(),
            "FundingExecutor: Purchase offer has not yet started"
        );
        require(
            offerExpired(),
            "FundingExecutor: Purchase offer has not yet expired"
        );

        uint256 unsoldSarcoAmount = sarcoToken.balanceOf(address(this));

        require(
            unsoldSarcoAmount > 0,
            "FundingExecutor: There are no Sarco tokens to recover"
        );

        // Dynamically Build finance app's "message" string
        string memory _recoverTokensString = "Recovered unsold SARCO tokens";

        // Forward recoverable SARCO tokens to the DAO contract via the Finance Deposit method
        sarcoDao.deposit(
            address(sarcoToken),
            unsoldSarcoAmount,
            _recoverTokensString
        );

        // zero out token approvals that this contract has given in its constructor
        usdcToken.approve(address(sarcoDao), 0);
        sarcoToken.approve(address(generalTokenVesting), 0);
        sarcoToken.approve(address(sarcoDao), 0);

        emit TokensRecovered(unsoldSarcoAmount);
    }

    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     * @param recipientAddress The address to send tokens to
     */
    function recoverErc20(
        address tokenAddress,
        uint256 tokenAmount,
        address recipientAddress
    ) public onlyOwner {
        IERC20(tokenAddress).safeTransfer(recipientAddress, tokenAmount);
    }
}
