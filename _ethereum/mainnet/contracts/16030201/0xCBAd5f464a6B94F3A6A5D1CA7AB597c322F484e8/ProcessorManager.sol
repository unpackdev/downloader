// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./Initializable.sol";
import "./TransferHelper.sol";

import "./IProcessorManager.sol";
import "./IProcessorValidationManager.sol";
import "./CommonState.sol";
import "./Constants.sol";

/**
 * @title Base contract for handling processor-related functions
 * @author Shane van Coller, Jonas Sota
 */
abstract contract ProcessorManager is
    IProcessorManager,
    Ownable,
    Initializable,
    CommonState,
    Constants
{
    /**
     * @dev Structure for keeping balances of fees earned for a processor. Balances are kept per token
     * per processor. Fees are accumulated in the token taken for payment
     *
     * @dev Processor Address => Token Address => Token Balance
     */
    mapping(address => mapping(address => uint256)) public processorBalances;

    /**
     * @dev The maximum number of items to process per batch. Prevents unbounded loops and ensures
     * that the transaction will not run out of gas by processing too many items
     */
    uint8 public maxFeeWithdrawalBatchSize;

    /**
     * @dev The base or 'fixed' fee added to `fee` (i.e. variable fee).
     * @dev This value is denominated in USD @ 8 decimal places.
     */
    uint256 public baseFee;

    event FeesWithdrawn(
        address indexed caller,
        address indexed token,
        uint256 amount,
        uint256 createdAt
    );

    event MaxFeeWithdrawalBatchSizeUpdated(
        address indexed caller,
        uint8 oldValue,
        uint8 newValue,
        uint256 createdAt
    );

    event BaseFeeUpdated(
        address indexed caller,
        uint256 oldValue,
        uint256 newValue,
        uint256 createdAt
    );

    // solhint-disable-next-line func-name-mixedcase
    function __ProcessorManager_init(
        uint8 maxFeeWithdrawalBatchSize_,
        uint256 baseFee_
    ) internal onlyInitializing {
        maxFeeWithdrawalBatchSize = maxFeeWithdrawalBatchSize_;
        baseFee = baseFee_;
    }

    /**********************************************/
    /********   MODIFIER FUNCTIONS   *******/
    /**********************************************/
    /**
     * @notice Validates that the given caller is a validated payment processor
     *
     * @dev Can only be called by senders that have been added to the allow list
     *
     */
    modifier onlyValidProcessorExt() {
        require(
            IProcessorValidationManager(factory).validProcessors(msg.sender),
            "LC:CALLER_NOT_ALLOWED"
        );
        _;
    }

    /**********************************************/
    /********   PUBLIC/EXTERNAL FUNCTIONS   *******/
    /**********************************************/
    /**
     * @notice Allows a processor to withdraw their accumulated fees
     *
     * @dev Fees are accumulated per token and balances kept individually for each
     *
     * @param tokenAddresses_ list of token addresses to withdraw the balance from
     */
    function withdrawProcessorFees(address[] calldata tokenAddresses_)
        external
        virtual
    {
        require(
            tokenAddresses_.length <= maxFeeWithdrawalBatchSize,
            "LC:BATCH_SIZE_TOO_BIG"
        );

        for (uint8 i = 0; i < tokenAddresses_.length; i++) {
            address _token = tokenAddresses_[i];
            uint256 _totalFeesForToken = processorBalances[msg.sender][_token];
            require(_totalFeesForToken > 0, "LC:NO_PROCESSOR_FEES");

            processorBalances[msg.sender][_token] = 0;
            TransferHelper.safeTransfer(_token, msg.sender, _totalFeesForToken);

            emit FeesWithdrawn(
                msg.sender,
                _token,
                _totalFeesForToken,
                block.timestamp // solhint-disable-line not-rely-on-time
            );
        }
    }

    /**********************************************/
    /**********   OWNER ONLY FUNCTIONS   **********/
    /**********************************************/
    /**
     * @notice Update max number of iterations to process in any given batch
     *
     * @dev Should be small enough as to not reach the block gas limit
     *
     * @param newBatchSize_ new max batch size
     */
    function updateMaxFeeWithdrawalBatchSize(uint8 newBatchSize_)
        external
        onlyOwner
    {
        emit MaxFeeWithdrawalBatchSizeUpdated(
            msg.sender,
            maxFeeWithdrawalBatchSize,
            newBatchSize_,
            block.timestamp // solhint-disable-line not-rely-on-time
        );
        maxFeeWithdrawalBatchSize = newBatchSize_;
    }

    /**
     * @notice Update the base fee
     *
     * @param newBaseFee_ new base fee
     */
    function updateBaseFee(uint256 newBaseFee_) external onlyOwner {
        emit BaseFeeUpdated(msg.sender, baseFee, newBaseFee_, block.timestamp); // solhint-disable-line not-rely-on-time
        baseFee = newBaseFee_;
    }

    /**********************************************/
    /***********   INTERNAL FUNCTIONS   ***********/
    /**********************************************/
    /**
     * @notice Calculate the processing fee for the given percentage based on the total amount due.
     *
     * @dev baseFee_ and totalPayable_ need to be denominated in the same token.
     *
     * @param baseFee_ the base or 'fixed' fee, denominated in a ERC-20 token.
     * @param feePercentage_ the percentage fee to take. Must be 6 decimal precision.
     * @param totalPayable_ the amount to calculate the fee on, denominated in a ERC-20 token.
     *
     * @return processingFee - the processing fee amount.
     */
    function _calculateProcessingFee(
        uint256 baseFee_,
        uint256 feePercentage_,
        uint256 totalPayable_
    ) internal virtual returns (uint256 processingFee) {
        processingFee =
            baseFee_ +
            ((totalPayable_ * feePercentage_) / FEE_PRECISION);
    }

    uint256[17] private __gap;
}
