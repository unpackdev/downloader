// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC11554K.sol";
import "./IGuardians.sol";
import "./IERC11554KController.sol";

/**
 * @dev Fees Manager that receives and manages fees
 * from items trading and guardian fees paid to guardians.
 */
contract FeesManager is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    /// @dev Trading fees split struct.
    struct TradingFeeSplit {
        uint256 protocol;
        uint256 guardian;
    }
    /// @notice Percentage factor for 0.01%.
    uint256 public constant PERCENTAGE_FACTOR = 10000;
    /// @notice Bucket size ~1 month.
    uint256 public constant BUCKET_SIZE = 30 * 24 * 60 * 60;
    /// @notice Global trading fee.
    uint256 public globalTradingFee;
    /// @notice TradingFeeSplit struct, trading fee split between protocol (default 80%) and guardian (default 20%).
    TradingFeeSplit public tradingFeeSplit;
    /// @notice Exchange contract.
    address public exchange;
    /// @notice Guardians contract.
    IGuardians public guardians;
    /// @notice Accumulated erc20 trading fees.
    mapping(IERC20Upgradeable => mapping(address => uint256)) public fees;
    /// @notice Anchor time, which is startig point for buckets, which is initialize time.
    uint256 public anchorTime;
    /// @notice Factory conract.
    IERC11554KController public controller;
    /// @notice Accumulated guardians fees by bucket.
    mapping(address => mapping(uint256 => uint256)) public guardiansFees;
    /// @notice Last withdrawn fee bucket.
    mapping(address => uint256) public lastWithdrawnBucket;
    /// @dev Trading Fees from an exchange have been received and organized for the beneficiaries - the protocol, the guardian, and the royalty receiver.
    event ReceivedFees(
        uint256 id,
        uint256 salePrice,
        IERC20Upgradeable asset,
        uint256 feeForProtocol,
        uint256 feeForGuardian,
        address guardian,
        uint256 feeForOriginator,
        address originator
    );
    ///@dev Guardian fees for an item have been paid.
    event PaidGuardianFee(
        address indexed payer,
        address indexed guardian,
        uint256 amount
    );
    ///@dev Guardian fees have been refunded by a guardian.
    event RefundedGuardianFee(
        address indexed recepient,
        address indexed guardian,
        uint256 amount
    );
    /// @dev Guardian fees moved from one guardian to another
    event MovedGuardianFees(
        address indexed guardianFrom,
        address indexed guardianTo
    );
    /// @dev Guardian has withdrawn guardian fees.
    event WithdrawnGuardianFees(address indexed guardian, uint256 amount);
    /// @dev Trading Fees have been claimed and withdrawn by a beneficiary- the protocol, the guardian, or the royalty receiver.
    event ClaimFees(address indexed claimer, uint256 fees);

    /**
     * @dev Only 4k exchange modifier.
     */
    modifier onlyExchange() {
        require(_msgSender() == exchange, "Callable only by 4K exchange");
        _;
    }

    /**
     * @dev Only 4k guardians modifier.
     */
    modifier onlyGuardians() {
        require(
            _msgSender() == address(guardians),
            "Callable only by guardians contract"
        );
        _;
    }

    /**
     * @notice Initialize FeesManager contract.
     * @param controller_ ERC11554K controller contract address.
     * @param guardians_ Guardians contract address.
     */
    function initialize(IERC11554KController controller_, IGuardians guardians_)
        external
        virtual
        initializer
    {
        __Ownable_init();
        globalTradingFee = 100;
        anchorTime = block.timestamp;
        controller = controller_;
        tradingFeeSplit = TradingFeeSplit(8000, 2000);
        guardians = guardians_;
    }

    /**
     * @notice Sets guardians to guardians_.
     *
     * Requirements:
     *
     * 1) The caller must be the owner.
     * @param guardians_, new Guardians contract address.
     */
    function setGuardians(IGuardians guardians_) external virtual onlyOwner {
        guardians = guardians_;
    }

    /**
     * @notice Sets controller to controller_.
     *
     * Requirements:
     *
     * 1) The caller must be the owner.
     * @param controller_ New Controller contract address.
     */
    function setController(IERC11554KController controller_)
        external
        virtual
        onlyOwner
    {
        controller = controller_;
    }

    /**
     * @notice Sets globalTradingFee to globalTradingFee_.
     *
     * Requirements:
     *
     * 1) The caller must be the owner.
     * @param globalTradingFee_ New global trading fee.
     */
    function setGlobalTradingFee(uint256 globalTradingFee_)
        external
        virtual
        onlyOwner
    {
        globalTradingFee = globalTradingFee_;
    }

    /**
     * @notice Sets tradingFeeSplit.
     *
     * Requirements:
     *
     * 1) The caller must be the owner.
     * @param protocolSplit, new protocol fees share.
     * @param guardianSplit, new guardians fees share.
     */
    function setTradingFeeSplit(uint256 protocolSplit, uint256 guardianSplit)
        external
        virtual
        onlyOwner
    {
        require(
            protocolSplit + guardianSplit == PERCENTAGE_FACTOR,
            "Percentages sum must be 100%"
        );
        tradingFeeSplit.protocol = protocolSplit;
        tradingFeeSplit.guardian = guardianSplit;
    }

    /**
     * @notice Sets exchange to exchange_.
     *
     * Requirements:
     *
     * 1) The caller must be the owner.
     * @param exchange_ New Exchange contract address.
     */
    function setExchange(address exchange_) external onlyOwner {
        exchange = exchange_;
    }

    /**
     * @dev Receive fees fee from exchange for item with id.
     *
     * Requirements:
     *
     * 1) the caller must be the Exchange contract.
     * 2) the item must be stored at a guardian.
     * 3) asset the asset that was used for the transaction and the unit of the salesprice. ie. USDT WBTC etc
     * 4) salePrice the total of the transaction. Scales up as more tokens are purchased.
     * @param erc11554k ERC11554K collection contract address.
     * @param id Item id, for which fees received during trade.
     * @param asset The asset that was used for the transaction and the unit of the salesprice. ie. USDT WBTC etc
     * @param salePrice The total of the transaction. Scales up as more tokens are purchased.
     */
    function receiveFees(
        IERC11554K erc11554k,
        uint256 id,
        IERC20Upgradeable asset,
        uint256 salePrice
    ) external virtual onlyExchange {
        address guardianAddress = guardians.whereItemStored(
            address(erc11554k),
            id
        );
        require(
            guardianAddress != address(0),
            "Item is not stored in any guardian"
        );
        address protocolBeneficiary = owner();

        uint256 feeForGuardian = (salePrice *
            globalTradingFee *
            tradingFeeSplit.guardian) / (PERCENTAGE_FACTOR * PERCENTAGE_FACTOR);
        uint256 feeForProtocol = (salePrice *
            globalTradingFee *
            tradingFeeSplit.protocol) / (PERCENTAGE_FACTOR * PERCENTAGE_FACTOR);
        (address originatorAddress, uint256 feeForOriginator) = erc11554k
            .royaltyInfo(id, salePrice);

        fees[asset][guardianAddress] += feeForGuardian;
        fees[asset][protocolBeneficiary] += feeForProtocol;
        fees[asset][originatorAddress] += feeForOriginator;

        emit ReceivedFees(
            id,
            salePrice,
            asset,
            feeForProtocol,
            feeForGuardian,
            guardianAddress,
            feeForOriginator,
            originatorAddress
        );
    }

    /**
     * @notice Claim ERC20 asset fees from fees manager.
     * @param asset ERC20 asset for which to claim fees.
     * @return claimed a number.
     */
    function claimFees(IERC20Upgradeable asset)
        external
        virtual
        returns (uint256 claimed)
    {
        address claimer = _msgSender();
        claimed = fees[asset][claimer];
        fees[asset][claimer] = 0;
        if (claimed > 0) {
            asset.safeTransfer(claimer, claimed);
        }
        emit ClaimFees(claimer, claimed);
    }

    /**
     * @dev Pays guardian fee for an item to guardian by payer.
     * Goes through corresponding time buckets of the guardian, derived
     * from storagePaidUntil and storage paid time before,
     * and increments proportional storageFeeAmount, using
     * guardianClassFeeRateMultiplied and bucket time span. Transfers payment.
     *
     * Requirements:
     *
     * 1) The caller must be Guardians contract.
     * 2) Fees payer must have approved storageFeeAmount for FeesManager on current 4K paymentToken
     * @param guardianFeeAmount guardian fee amount paid by user to guardian.
     * @param guardianClassFeeRateMultiplied guardian class fee rate multiplied by items held by user.
     * @param guardian guardian address.
     * @param storagePaidUntil storage fee paid until timestamp.
     * @param payer payer address.
     */
    function payGuardianFee(
        uint256 guardianFeeAmount,
        uint256 guardianClassFeeRateMultiplied,
        address guardian,
        uint256 storagePaidUntil,
        address payer
    ) external virtual onlyGuardians {
        /// Storage paid until timestamp was updated in ERC11554K, calculates older one.
        uint256 storagePaidUntilBefore = storagePaidUntil -
            guardianFeeAmount /
            guardianClassFeeRateMultiplied;
        uint256 firstBucket = getBucket(storagePaidUntilBefore);
        uint256 lastBucket = getBucket(storagePaidUntil);
        for (uint256 i = firstBucket + 1; i < lastBucket; ++i) {
            guardiansFees[guardian][i] +=
                BUCKET_SIZE *
                guardianClassFeeRateMultiplied;
        }
        if (lastBucket > firstBucket) {
            uint256 bucketStorageTime = ((firstBucket + 1) *
                BUCKET_SIZE +
                anchorTime) - storagePaidUntilBefore;
            guardiansFees[guardian][firstBucket] +=
                bucketStorageTime *
                guardianClassFeeRateMultiplied;
            bucketStorageTime =
                storagePaidUntil -
                (lastBucket * BUCKET_SIZE + anchorTime);
            guardiansFees[guardian][lastBucket] +=
                bucketStorageTime *
                guardianClassFeeRateMultiplied;
        } else {
            guardiansFees[guardian][firstBucket] += guardianFeeAmount;
        }
        controller.paymentToken().transferFrom(
            payer,
            address(this),
            guardianFeeAmount
        );
        emit PaidGuardianFee(payer, guardian, guardianFeeAmount);
    }

    /**
     * @dev Refunds guardian fee guardianFeeAmount for an item from guardian to recipient,
     * based on guardianClassFeeRateMultiplied, storagePaidUntil. Iterates over buckets and
     * subtracts corresponding bucket storage fee amount. Accumulates it and transfers to the recipient.
     *
     * Requirements:
     *
     * 1) The caller must be Guardians contract.
     * @param guardianFeeAmount guardian fee amount to refund to recipient from guardian.
     * @param guardianClassFeeRateMultiplied guardian class fee rate multiplied by items held by user.
     * @param guardian guardian address.
     * @param storagePaidUntil storage fee paid until timestamp.
     * @param recipient recipient address.
     */
    function refundGuardianFee(
        uint256 guardianFeeAmount,
        uint256 guardianClassFeeRateMultiplied,
        address guardian,
        uint256 storagePaidUntil,
        address recipient
    ) external virtual onlyGuardians {
        // Storage paid until timestamp was updated in ERC11554K, calculates older one.
        uint256 unusedStorageTimestamp = storagePaidUntil -
            guardianFeeAmount /
            guardianClassFeeRateMultiplied;
        uint256 firstBucket = getBucket(unusedStorageTimestamp);
        uint256 lastBucket = getBucket(storagePaidUntil);
        for (uint256 i = firstBucket + 1; i < lastBucket; ++i) {
            guardiansFees[guardian][i] -=
                BUCKET_SIZE *
                guardianClassFeeRateMultiplied;
        }
        if (lastBucket > firstBucket) {
            uint256 bucketStorageTime = ((firstBucket + 1) *
                BUCKET_SIZE +
                anchorTime) - unusedStorageTimestamp;
            guardiansFees[guardian][firstBucket] -=
                bucketStorageTime *
                guardianClassFeeRateMultiplied;
            bucketStorageTime =
                storagePaidUntil -
                (lastBucket * BUCKET_SIZE + anchorTime);
            guardiansFees[guardian][lastBucket] -=
                bucketStorageTime *
                guardianClassFeeRateMultiplied;
        } else {
            guardiansFees[guardian][firstBucket] -= guardianFeeAmount;
        }
        controller.paymentToken().transfer(recipient, guardianFeeAmount);
        emit RefundedGuardianFee(recipient, guardian, guardianFeeAmount);
    }

    /**
     * @notice Moves all guardian fees between guardians.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param guardianFrom guardian address, from which fees are moved.
     * @param guardianTo guardian address, to which fees are moved.
     */
    function moveFeesBetweenGuardians(address guardianFrom, address guardianTo)
        external
        virtual
        onlyOwner
    {
        uint256 curBucket = getBucket(block.timestamp) + 1;
        while (true) {
            uint256 amount = guardiansFees[guardianFrom][curBucket];
            if (amount == 0) {
                break;
            }
            guardiansFees[guardianFrom][curBucket] = 0;
            guardiansFees[guardianTo][curBucket] = amount;
            ++curBucket;
        }
        emit MovedGuardianFees(guardianFrom, guardianTo);
    }

    /**
     * @notice Withdraws all guardian fees by guardian until currentBucket-1 based on current block.timestamp.
     *
     * Requirements:
     *
     * 1) Last withdrawn bucket must be less than current bucket.
     */
    function withdrawGuardianFees() external virtual {
        uint256 currentBucket = getBucket(block.timestamp);
        uint256 firstBucket = lastWithdrawnBucket[_msgSender()];
        uint256 amount = 0;
        for (uint256 i = firstBucket; i < currentBucket; ++i) {
            amount += guardiansFees[_msgSender()][i];
            guardiansFees[_msgSender()][i] = 0;
        }
        require(amount > 0, "No guardian fees to withdraw");
        lastWithdrawnBucket[_msgSender()] = currentBucket - 1;
        controller.paymentToken().transfer(_msgSender(), amount);
        emit WithdrawnGuardianFees(_msgSender(), amount);
    }

    /**
     * @notice Calculate fees for an item with erc11554k id and salePrice.
     * @param erc11554k the token contract/collection that will be traded and whose total fees the caller wants to know about.
     * @param id the id of the specific token that will be traded and whose total fees the caller wants to know about.
     * @param salePrice the total of the transaction. Scales up as more tokens are purchased.
     */
    function calculateTotalFee(
        IERC11554K erc11554k,
        uint256 id,
        uint256 salePrice
    ) public view virtual returns (uint256) {
        uint256 totalTradingFee = (salePrice * globalTradingFee) /
            PERCENTAGE_FACTOR;
        (, uint256 feeForOriginator) = erc11554k.royaltyInfo(id, salePrice);
        return feeForOriginator + totalTradingFee;
    }

    /**
     * @notice Returns bucket based on timestamp.
     * @param timestamp Timestamp from which bucket is derived.
     * @return returns corresponding uint256 bucket.
     */
    function getBucket(uint256 timestamp)
        public
        view
        virtual
        returns (uint256)
    {
        return (timestamp - anchorTime) / BUCKET_SIZE;
    }

    /**
     * @dev Internal method, moves fee amount from one guardian to another.
     * @param guardianFrom, guardian class fee rate multiplied by items held by user.
     * @param guardianTo, guardian address.
     * @param bucket, bucket for which movement happens.
     * @param amount, amount to move.
     */
    function _moveFee(
        address guardianFrom,
        address guardianTo,
        uint256 bucket,
        uint256 amount
    ) internal virtual {
        guardiansFees[guardianFrom][bucket] -= amount;
        guardiansFees[guardianTo][bucket] += amount;
    }
}
