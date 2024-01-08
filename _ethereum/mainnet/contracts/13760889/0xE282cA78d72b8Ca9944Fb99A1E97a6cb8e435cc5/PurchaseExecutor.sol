// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Strings.sol";
import "./GeneralTokenVesting.sol";
import "./Finance.sol";

/**
 * @title PurchaseExecutor
 * @dev allow a whitelisted set of addresses to purchase SARCO tokens, for stablecoins (USDC), at a set rate
 */
contract PurchaseExecutor is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public USDC_TOKEN;
    IERC20 public SARCO_TOKEN;
    address public GENERAL_TOKEN_VESTING;
    address public SARCO_DAO;
    uint256 public usdc_to_sarco_precision = 10**18;
    uint256 public sarco_to_usdc_decimal_fix = 10**(18 - 6);

    uint256 public usdc_to_sarco_rate;
    uint256 public sarco_allocations_total;
    mapping(address => uint256) public sarco_allocations;

    // Timing in seconds
    uint256 public offer_expiration_delay;
    uint256 public offer_started_at;
    uint256 public offer_expires_at;
    uint256 public vesting_end_delay;

    // The purchase has been executed exchanging USDC to vested SARCO
    event PurchaseExecuted(
        // the address that has received the vested SARCO tokens
        address indexed sarco_receiver,
        // the number of SARCO tokens vested to sarco_receiver
        uint256 sarco_allocation,
        // the amount of USDC that was paid and forwarded to the DAO
        uint256 usdc_cost
    );

    // Creates a window of time which the whitelisted set of addresses may purchase SARCO
    event OfferStarted(
        // Window start time
        uint256 started_at,
        // Window end time
        uint256 expires_at
    );

    // If tokens have not been purchased after time window, the DAO can recover tokens
    event TokensRecovered(
        // Amount of Tokens
        uint256 amount
    );

    /**
     * @dev inits/sets sarco purchase enviorment
     * @param _usdc_to_sarco_rate How much SARCO one gets for one USDC
     * @param _vesting_end_delay Delay from the purchase moment to the vesting end moment, in seconds
     * @param _offer_expiration_delay Delay from the contract deployment to offer expiration, in seconds
     * @param _sarco_purchasers  List of valid SARCO purchasers
     * @param _sarco_allocations List of SARCO token allocations, should include decimals 10 ** 18
     * @param _sarco_allocations_total Checksum of SARCO token allocations, should include decimals 10 ** 18
     * @param _usdc_token USDC token address
     * @param _sarco_token Sarco token address
     * @param _general_token_vesting GeneralTokenVesting contract address
     * @param _sarco_dao Sarco DAO contract address
     */
    constructor(
        uint256 _usdc_to_sarco_rate,
        uint256 _vesting_end_delay,
        uint256 _offer_expiration_delay,
        address[] memory _sarco_purchasers,
        uint256[] memory _sarco_allocations,
        uint256 _sarco_allocations_total,
        address _usdc_token,
        address _sarco_token,
        address _general_token_vesting,
        address _sarco_dao
    ) {
        require(
            _usdc_to_sarco_rate > 0,
            "PurchaseExecutor: _usdc_to_sarco_rate must be greater than 0"
        );
        require(
            _vesting_end_delay > 0,
            "PurchaseExecutor: end_delay must be greater than 0"
        );
        require(
            _offer_expiration_delay > 0,
            "PurchaseExecutor: offer_expiration must be greater than 0"
        );
        require(
            _sarco_purchasers.length == _sarco_allocations.length,
            "PurchaseExecutor: purchasers and allocations lengths must be equal"
        );
        require(
            _usdc_token != address(0),
            "PurchaseExecutor: _usdc_token cannot be 0 address"
        );
        require(
            _sarco_token != address(0),
            "PurchaseExecutor: _sarco_token cannot be 0 address"
        );
        require(
            _general_token_vesting != address(0),
            "PurchaseExecutor: _general_token_vesting cannot be 0 address"
        );
        require(
            _sarco_dao != address(0),
            "PurchaseExecutor: _sarco_dao cannot be 0 address"
        );

        // Set global variables
        usdc_to_sarco_rate = _usdc_to_sarco_rate;
        vesting_end_delay = _vesting_end_delay;
        offer_expiration_delay = _offer_expiration_delay;
        sarco_allocations_total = _sarco_allocations_total;
        USDC_TOKEN = IERC20(_usdc_token);
        SARCO_TOKEN = IERC20(_sarco_token);
        GENERAL_TOKEN_VESTING = _general_token_vesting;
        SARCO_DAO = _sarco_dao;

        uint256 allocations_sum = 0;

        for (uint256 i = 0; i < _sarco_purchasers.length; i++) {
            address purchaser = _sarco_purchasers[i];
            require(
                purchaser != address(0),
                "PurchaseExecutor: Purchaser cannot be the ZERO address"
            );
            require(
                sarco_allocations[purchaser] == 0,
                "PurchaseExecutor: Allocation has already been set"
            );
            uint256 allocation = _sarco_allocations[i];
            require(
                allocation > 0,
                "PurchaseExecutor: No allocated Sarco tokens for address"
            );
            sarco_allocations[purchaser] = allocation;
            allocations_sum += allocation;
        }
        require(
            allocations_sum == _sarco_allocations_total,
            "PurchaseExecutor: Allocations_total does not equal the sum of passed allocations"
        );

        // Approve SarcoDao - PurchaseExecutor's total USDC tokens (Execute Purchase)
        USDC_TOKEN.approve(
            _sarco_dao,
            get_usdc_cost(_sarco_allocations_total)
        );

        // Approve full SARCO amount to GeneralTokenVesting contract
        SARCO_TOKEN.approve(GENERAL_TOKEN_VESTING, _sarco_allocations_total);

        // Approve SarcoDao - Purchase Executor's total SARCO tokens (Recover Tokens)
        SARCO_TOKEN.approve(_sarco_dao, _sarco_allocations_total);
    }

    function get_usdc_cost(uint256 sarco_amount)
        internal
        view
        returns (uint256)
    {
        return
            ((sarco_amount * usdc_to_sarco_precision) / usdc_to_sarco_rate) /
            sarco_to_usdc_decimal_fix;
    }

    function offer_started() public view returns (bool) {
        return offer_started_at != 0;
    }

    function offer_expired() public view returns (bool) {
        return block.timestamp >= offer_expires_at;
    }

    /**
     * @notice Starts the offer if it 1) hasn't been started yet and 2) has received funding in full.
     */
    function _start_unless_started() internal {
        require(
            offer_started_at == 0,
            "PurchaseExecutor: Offer has already started"
        );
        require(
            SARCO_TOKEN.balanceOf(address(this)) == sarco_allocations_total,
            "PurchaseExecutor: Insufficient Sarco contract balance to start offer"
        );

        offer_started_at = block.timestamp;
        offer_expires_at = block.timestamp + offer_expiration_delay;
        emit OfferStarted(offer_started_at, offer_expires_at);
    }

    function start() external {
        _start_unless_started();
    }

    /**
     * @dev Returns the Sarco allocation and the USDC cost to purchase the Sarco Allocation of the whitelisted Sarco Purchaser
     * @param sarco_receiver Whitelisted Sarco Purchaser
     * @return A tuple: the first element is the amount of SARCO available for purchase (zero if
        the purchase was already executed for that address), the second element is the
        USDC cost of the purchase.
     */
    function get_allocation(address sarco_receiver)
        public
        view
        returns (uint256, uint256)
    {
        uint256 sarco_allocation = sarco_allocations[sarco_receiver];
        uint256 usdc_cost = get_usdc_cost(sarco_allocation);

        return (sarco_allocation, usdc_cost);
    }

    /**
     * @dev Purchases Sarco for the specified address in exchange for USDC.
     * @notice Sends USDC tokens used to purchase Sarco to Sarco DAO, 
     Approves GeneralTokenVesting contract Sarco Tokens to utilizes allocated Sarco funds,
     Starts token vesting via GeneralTokenVesting contract.
     * @param sarco_receiver Whitelisted Sarco Purchaser
     */
    function execute_purchase(address sarco_receiver) external {
        if (offer_started_at == 0) {
            _start_unless_started();
        }
        require(
            block.timestamp < offer_expires_at,
            "PurchaseExecutor: Purchases cannot be made after the offer has expired"
        );

        (uint256 sarco_allocation, uint256 usdc_cost) = get_allocation(msg.sender);

        // Check sender's allocation
        require(
            sarco_allocation > 0,
            "PurchaseExecutor: sender does not have a SARCO allocation"
        );

        // Clear sender's allocation
        sarco_allocations[msg.sender] = 0;

        // transfer sender's USDC to this contract
        USDC_TOKEN.safeTransferFrom(msg.sender, address(this), usdc_cost);

        // Dynamically Build finance app's "message" string
        string memory _executedPurchaseString = string(
            abi.encodePacked(
                "Purchase Executed by account: ",
                Strings.toHexString(uint160(msg.sender), 20),
                " for account: ",
                Strings.toHexString(uint160(sarco_receiver), 20),
                ". Total SARCOs Purchased: ",
                Strings.toString(sarco_allocation),
                "."
            )
        );

        // Forward USDC cost of the purchase to the DAO contract via the Finance Deposit method
        Finance(SARCO_DAO).deposit(
            address(USDC_TOKEN),
            usdc_cost,
            _executedPurchaseString
        );

        // Call GeneralTokenVesting startVest method
        GeneralTokenVesting(GENERAL_TOKEN_VESTING).startVest(
            sarco_receiver,
            sarco_allocation,
            vesting_end_delay,
            address(SARCO_TOKEN)
        );

        emit PurchaseExecuted(sarco_receiver, sarco_allocation, usdc_cost);
    }

    /**
     * @dev If unsold_sarco_amount > 0 after the offer expired, sarco tokens are send back to Sarco Dao via Finance Contract.
     */
    function recover_unsold_tokens() external {
        require(
            offer_started(),
            "PurchaseExecutor: Purchase offer has not yet started"
        );
        require(
            offer_expired(),
            "PurchaseExecutor: Purchase offer has not yet expired"
        );

        uint256 unsold_sarco_amount = SARCO_TOKEN.balanceOf(address(this));

        require(
            unsold_sarco_amount > 0,
            "PurchaseExecutor: There are no Sarco tokens to recover"
        );

        // Dynamically Build finance app's "message" string
        string memory _recoverTokensString = "Recovered unsold SARCO tokens";

        // Forward recoverable SARCO tokens to the DAO contract via the Finance Deposit method
        Finance(SARCO_DAO).deposit(
            address(SARCO_TOKEN),
            unsold_sarco_amount,
            _recoverTokensString
        );

        // zero out token approvals that this contract has given in its constructor
        USDC_TOKEN.approve(SARCO_DAO, 0);
        SARCO_TOKEN.approve(GENERAL_TOKEN_VESTING, 0);
        SARCO_TOKEN.approve(SARCO_DAO, 0);

        emit TokensRecovered(unsold_sarco_amount);
    }

    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     * @param recipientAddress The address to send tokens to
     */
    function recover_erc20(address tokenAddress, uint256 tokenAmount, address recipientAddress) public onlyOwner {
        IERC20(tokenAddress).safeTransfer(recipientAddress, tokenAmount);
    }
}
