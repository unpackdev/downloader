// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC721Upgradeable.sol";

import "./IFactory.sol";
import "./ICyanVaultV2.sol";
import "./ICyanPaymentPlanV2.sol";
import "./ICryptoPunk.sol";
import "./IWETH.sol";
import "./ICyanConduit.sol";
import "./AddressProvider.sol";

import "./PaymentPlanV2Logic.sol";
import "./BendDaoMigrationLogic.sol";
import "./CyanWalletLogic.sol";

/// @title Cyan Payment Plan - Main logic of BNPL and Pawn plan
/// @author Bulgantamir Gankhuyag - <bulgaa@usecyan.com>
/// @author Naranbayar Uuganbayar - <naba@usecyan.com>
contract CyanPaymentPlanV2 is ICyanPaymentPlanV2, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    AddressProvider private constant addressProvider = AddressProvider(0xCF9A19D879769aDaE5e4f31503AAECDa82568E55);

    using SafeERC20Upgradeable for IERC20Upgradeable;

    event CreatedBNPL(uint256 indexed planId);
    event CreatedPawn(uint256 indexed planId);
    event CreatedPawnFromBendDao(uint256 indexed planId);
    event UpdatedBNPL(uint256 indexed planId, PaymentPlanStatus indexed planStatus);
    event LiquidatedPaymentPlan(uint256 indexed planId, uint256 indexed estimatedPrice, uint256 indexed unpaidAmount);
    event Paid(uint256 indexed planId);
    event Completed(uint256 indexed planId);
    event CompletedByRevival(uint256 indexed planId, uint256 penaltyAmount);
    event CompletedEarly(uint256 indexed planId, uint256 indexed baseDiscountRate, uint8 indexed paidNumOfPayment);
    event EarlyUnwind(uint256 indexed planId, uint256 indexed baseDiscountRate, uint8 indexed paidNumOfPayment);
    event Revived(uint256 indexed planId, uint256 penaltyAmount);
    event UpdatedCyanSigner(address indexed signer);
    event UpdateBaseDiscountRate(uint256 indexed baseDiscountRate);
    event ClaimedServiceFee(address indexed currency, uint256 indexed amount);
    event UpdatedWalletFactory(address indexed factory);
    event SetAutoRepayStatus(uint256 indexed planId, uint8 indexed autoRepayStatus);

    mapping(uint256 => Item) public items;
    mapping(uint256 => PaymentPlan) public paymentPlan;
    mapping(address => uint256) public claimableServiceFee;

    bytes32 private constant CYAN_ROLE = keccak256("CYAN_ROLE");
    bytes32 private constant CYAN_AUTO_OPERATOR_ROLE = keccak256("CYAN_AUTO_OPERATOR_ROLE");
    address private cyanSigner;
    address private walletFactory;
    uint256 private BASE_DISCOUNT_RATE;

    function initialize(
        address _cyanSigner,
        address _cyanSuperAdmin,
        address _walletFactory,
        uint256 _baseDiscountRate
    ) external initializer {
        if (_cyanSigner == address(0) || _cyanSuperAdmin == address(0) || _walletFactory == address(0)) {
            revert InvalidAddress();
        }
        if (_baseDiscountRate > 10000) revert InvalidBaseDiscountRate();

        cyanSigner = _cyanSigner;
        walletFactory = _walletFactory;
        _setupRole(DEFAULT_ADMIN_ROLE, _cyanSuperAdmin);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        BASE_DISCOUNT_RATE = _baseDiscountRate;

        __AccessControl_init();
        __ReentrancyGuard_init();

        emit UpdatedCyanSigner(_cyanSigner);
        emit UpdatedWalletFactory(_walletFactory);
        emit UpdateBaseDiscountRate(_baseDiscountRate);
    }

    /**
     * @notice Creating a BNPL plan
     * @param item Item detail to BNPL
     * @param plan BNPL plan detail
     * @param planId Plan ID
     * @param signedBlockNum Signed block number
     * @param signature Signature from Cyan
     */
    function createBNPL(
        Item calldata item,
        Plan calldata plan,
        uint256 planId,
        uint256 signedBlockNum,
        bytes memory signature
    ) external payable nonReentrant {
        PaymentPlanV2Logic.requireCorrectPlanParams(item, plan, signedBlockNum);
        PaymentPlanV2Logic.verifySignature(item, plan, planId, signedBlockNum, cyanSigner, signature);

        if (paymentPlan[planId].plan.totalNumberOfPayments != 0) revert PaymentPlanAlreadyExists();
        if (plan.downPaymentPercent == 0 || plan.downPaymentPercent >= 10000) revert InvalidDownPaymentPercent();
        if (plan.totalNumberOfPayments <= 1) revert InvalidTotalNumberOfPayments();
        if (plan.counterPaidPayments != 1) revert InvalidPaidCount();

        (, , uint256 singleServiceFee, , , , uint256 downPaymentAmount, ) = PaymentPlanV2Logic.calculatePaymentInfo(
            plan
        );

        address currencyAddress = getCurrencyAddressByVaultAddress(item.cyanVaultAddress);
        if (singleServiceFee + downPaymentAmount == 0) revert InvalidDownPayment();
        receiveCurrency(currencyAddress, singleServiceFee + downPaymentAmount, msg.sender);

        address cyanWalletAddress = IFactory(walletFactory).getOrDeployWallet(msg.sender);
        paymentPlan[planId] = PaymentPlan(plan, block.timestamp, cyanWalletAddress, PaymentPlanStatus.BNPL_CREATED);
        items[planId] = item;
        emit CreatedBNPL(planId);
    }

    /**
     * @notice Lending ETH from Vault for BNPL payment plan
     * @param planIds Payment plan IDs
     */
    function fundBNPL(uint256[] calldata planIds) external nonReentrant onlyRole(CYAN_ROLE) {
        for (uint256 i; i < planIds.length; ++i) {
            uint256 planId = planIds[i];
            ICyanVaultV2(payable(items[planId].cyanVaultAddress)).lend(msg.sender, paymentPlan[planId].plan.amount);

            if (paymentPlan[planId].plan.counterPaidPayments != 1) revert InvalidPaidCount();
            if (paymentPlan[planId].status != PaymentPlanStatus.BNPL_CREATED) revert InvalidStage();

            paymentPlan[planId].status = PaymentPlanStatus.BNPL_FUNDED;
            emit UpdatedBNPL(planId, PaymentPlanStatus.BNPL_FUNDED);
        }
    }

    /**
     * @notice Activate BNPL payment plan
     * @param planIds Payment plan IDs
     */
    function activateBNPL(uint256[] calldata planIds) external nonReentrant onlyRole(CYAN_ROLE) {
        for (uint256 i; i < planIds.length; ++i) {
            uint256 planId = planIds[i];
            if (paymentPlan[planId].plan.counterPaidPayments != 1) revert InvalidPaidCount();
            if (
                paymentPlan[planId].status != PaymentPlanStatus.BNPL_CREATED &&
                paymentPlan[planId].status != PaymentPlanStatus.BNPL_FUNDED
            ) revert InvalidStage();

            (, , uint256 singleServiceFee, , , , uint256 downPaymentAmount, ) = PaymentPlanV2Logic.calculatePaymentInfo(
                paymentPlan[planId].plan
            );

            address _cyanVaultAddress = items[planId].cyanVaultAddress;
            address currencyAddress = getCurrencyAddressByVaultAddress(_cyanVaultAddress);
            claimableServiceFee[currencyAddress] += singleServiceFee;
            if (paymentPlan[planId].status == PaymentPlanStatus.BNPL_CREATED) {
                // Admin already funded the plan, so Vault is transfering equal amount of ETH back to admin.
                ICyanVaultV2(payable(_cyanVaultAddress)).lend(msg.sender, paymentPlan[planId].plan.amount);
            }
            CyanWalletLogic.transferItemAndLock(msg.sender, paymentPlan[planId].cyanWalletAddress, items[planId]);
            transferEarnedAmountToCyanVault(_cyanVaultAddress, downPaymentAmount, 0);

            paymentPlan[planId].status = PaymentPlanStatus.BNPL_ACTIVE;
            emit UpdatedBNPL(planId, PaymentPlanStatus.BNPL_ACTIVE);
        }
    }

    /**
     * @notice Rejecting a BNPL payment plan
     * @param planId Payment Plan ID
     */
    function rejectBNPL(uint256 planId) external payable nonReentrant onlyRole(CYAN_ROLE) {
        if (paymentPlan[planId].plan.counterPaidPayments != 1) revert InvalidPaidCount();
        if (
            paymentPlan[planId].status != PaymentPlanStatus.BNPL_CREATED &&
            paymentPlan[planId].status != PaymentPlanStatus.BNPL_FUNDED
        ) {
            revert InvalidStage();
        }

        (, , uint256 singleServiceFee, , , , uint256 downPaymentAmount, ) = PaymentPlanV2Logic.calculatePaymentInfo(
            paymentPlan[planId].plan
        );

        // Returning downpayment to created user address
        address currencyAddress = getCurrencyAddressByPlanId(planId);
        address createdUserAddress = getMainWalletAddress(paymentPlan[planId].cyanWalletAddress);
        if (currencyAddress == address(0)) {
            (bool success, ) = payable(createdUserAddress).call{ value: downPaymentAmount + singleServiceFee }("");
            if (!success) revert EthTransferFailed();
        } else {
            IERC20Upgradeable erc20Contract = IERC20Upgradeable(currencyAddress);
            erc20Contract.safeTransfer(createdUserAddress, downPaymentAmount + singleServiceFee);
        }
        if (paymentPlan[planId].status == PaymentPlanStatus.BNPL_FUNDED) {
            receiveCurrency(currencyAddress, paymentPlan[planId].plan.amount, msg.sender);

            // Returning funded amount back to Vault
            transferEarnedAmountToCyanVault(items[planId].cyanVaultAddress, paymentPlan[planId].plan.amount, 0);
        } else if (msg.value > 0) {
            revert InvalidAmount();
        }
        paymentPlan[planId].status = PaymentPlanStatus.BNPL_REJECTED;
        emit UpdatedBNPL(planId, PaymentPlanStatus.BNPL_REJECTED);
    }

    function createPawn(
        Item calldata item,
        Plan calldata plan,
        uint256 planId,
        uint256 signedBlockNum,
        bytes memory signature
    ) external nonReentrant {
        createPawn(item, plan, planId, false, signedBlockNum, signature);
    }

    function createPawnFromBendDao(
        Item calldata item,
        Plan calldata plan,
        uint256 planId,
        uint256 signedBlockNum,
        bytes memory signature
    ) external nonReentrant {
        createPawn(item, plan, planId, true, signedBlockNum, signature);
    }

    /**
     * @notice Creating a pawn plan
     * @param item Item detail to pawn
     * @param plan Pawn plan detail
     * @param planId Plan ID
     * @param signedBlockNum Signed block number
     * @param signature Signature from Cyan
     */
    function createPawn(
        Item calldata item,
        Plan calldata plan,
        uint256 planId,
        bool isBendDao,
        uint256 signedBlockNum,
        bytes memory signature
    ) private {
        PaymentPlanV2Logic.requireCorrectPlanParams(item, plan, signedBlockNum);
        PaymentPlanV2Logic.verifySignature(item, plan, planId, signedBlockNum, cyanSigner, signature);

        if (paymentPlan[planId].plan.totalNumberOfPayments != 0) revert PaymentPlanAlreadyExists();
        if (plan.downPaymentPercent != 0) revert InvalidDownPaymentPercent();
        if (plan.totalNumberOfPayments == 0) revert InvalidTotalNumberOfPayments();
        if (plan.counterPaidPayments != 0) revert InvalidPaidCount();

        address cyanWalletAddress = IFactory(walletFactory).getOrDeployWallet(msg.sender);

        if (isBendDao) {
            address currencyAddress = getCurrencyAddressByVaultAddress(item.cyanVaultAddress);
            ICyanVaultV2(payable(item.cyanVaultAddress)).lend(cyanWalletAddress, plan.amount);

            BendDaoMigrationLogic.migrateBendDaoPlan(item, plan, cyanWalletAddress, currencyAddress);

            if (IERC721Upgradeable(item.contractAddress).ownerOf(item.tokenId) != cyanWalletAddress) {
                revert InvalidBendDaoPlan();
            }

            CyanWalletLogic.setLockState(cyanWalletAddress, item, true);
            emit CreatedPawnFromBendDao(planId);
        } else {
            address mainAddress = msg.sender;
            if (cyanWalletAddress == msg.sender) {
                mainAddress = getMainWalletAddress(cyanWalletAddress);
            }
            bool isTransferRequired = false;
            if (item.itemType == 1) {
                // ERC721, check if item is already in Cyan wallet
                if (IERC721Upgradeable(item.contractAddress).ownerOf(item.tokenId) != cyanWalletAddress) {
                    isTransferRequired = true;
                }
            } else if (item.itemType == 2) {
                // ERC1155, check if message sender is Cyan wallet
                if (msg.sender != cyanWalletAddress) {
                    isTransferRequired = true;
                }
            } else if (item.itemType == 3) {
                // CryptoPunk, check if item is already in Cyan wallet
                if (ICryptoPunk(item.contractAddress).punkIndexToAddress(item.tokenId) != cyanWalletAddress) {
                    isTransferRequired = true;
                }
            }
            if (isTransferRequired) {
                CyanWalletLogic.transferItemAndLock(mainAddress, cyanWalletAddress, item);
            } else {
                CyanWalletLogic.setLockState(cyanWalletAddress, item, true);
            }
            ICyanVaultV2(payable(item.cyanVaultAddress)).lend(mainAddress, plan.amount);
            emit CreatedPawn(planId);
        }

        items[planId] = item;
        paymentPlan[planId] = PaymentPlan(plan, block.timestamp, cyanWalletAddress, PaymentPlanStatus.PAWN_ACTIVE);
    }

    /**
     * @notice Make a payment for the payment plan
     * @param planId Payment Plan ID
     * @param isEarlyPayment If true, payment will be made for the whole plan
     */
    function pay(uint256 planId, bool isEarlyPayment) external payable nonReentrant {
        requireActivePlan(planId);
        Plan memory plan = paymentPlan[planId].plan;

        uint8 numOfRemainingPayments = plan.totalNumberOfPayments - plan.counterPaidPayments;
        bool shouldComplete = isEarlyPayment || numOfRemainingPayments == 1;

        (
            uint256 payAmountForCollateral,
            uint256 payAmountForInterest,
            uint256 payAmountForService,
            uint256 currentPayment,

        ) = getPaymentInfoByPlanId(planId, shouldComplete);

        address currencyAddress = getCurrencyAddressByPlanId(planId);
        receiveCurrency(currencyAddress, currentPayment, msg.sender);

        claimableServiceFee[currencyAddress] += payAmountForService;
        transferEarnedAmountToCyanVault(items[planId].cyanVaultAddress, payAmountForCollateral, payAmountForInterest);

        if (shouldComplete) {
            paymentPlan[planId].plan.counterPaidPayments = plan.totalNumberOfPayments;
            paymentPlan[planId].status = PaymentPlanV2Logic.isBNPL(paymentPlan[planId].status)
                ? PaymentPlanStatus.BNPL_COMPLETED
                : PaymentPlanStatus.PAWN_COMPLETED;
            CyanWalletLogic.setLockState(paymentPlan[planId].cyanWalletAddress, items[planId], false);

            if (isEarlyPayment) {
                emit CompletedEarly(planId, BASE_DISCOUNT_RATE, numOfRemainingPayments);
            } else {
                emit Completed(planId);
            }
        } else {
            ++paymentPlan[planId].plan.counterPaidPayments;
            emit Paid(planId);
        }
    }

    function getPaymentInfoByPlanId(uint256 planId, bool isEarlyPayment)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Plan memory plan = paymentPlan[planId].plan;
        if (plan.totalNumberOfPayments == 0) revert PaymentPlanNotFound();

        uint8 nextPaymentCount = plan.counterPaidPayments + (plan.downPaymentPercent > 0 ? 0 : 1);
        uint256 dueDate = paymentPlan[planId].createdDate + plan.term * nextPaymentCount;

        (
            uint256 payAmountForCollateral,
            uint256 payAmountForInterest,
            uint256 payAmountForService,
            uint256 currentPayment
        ) = PaymentPlanV2Logic.getPaymentInfo(plan, isEarlyPayment);
        uint256 interestDiscount;
        if (isEarlyPayment && plan.totalNumberOfPayments - plan.counterPaidPayments != 1) {
            interestDiscount = PaymentPlanV2Logic.calculateInterestFeeDiscount(
                BASE_DISCOUNT_RATE,
                payAmountForInterest,
                plan
            );
        }
        return (
            payAmountForCollateral,
            payAmountForInterest - interestDiscount,
            payAmountForService,
            currentPayment - interestDiscount,
            dueDate
        );
    }

    /**
     * @notice Liquidate defaulted payment plan
     * @param planIds Array of plan Ids [CyanPlan ID, BAYC/MAYC Ape Plan ID, BAKC Ape Plan ID]
     * @param estimatedValue Estimated value of defaulted assets
     */
    function liquidate(uint256[3] calldata planIds, uint256 estimatedValue) external nonReentrant onlyRole(CYAN_ROLE) {
        if (estimatedValue == 0) revert InvalidAmount();
        requireDefaultedPlan(planIds[0]);

        PaymentPlan storage _paymentPlan = paymentPlan[planIds[0]];
        Item storage _item = items[planIds[0]];

        PaymentPlanV2Logic.checkAndCompleteApePlans(
            _paymentPlan.cyanWalletAddress,
            _item.contractAddress,
            _item.tokenId,
            [planIds[1], planIds[2]]
        );

        (uint256 unpaidAmount, , , , ) = getPaymentInfoByPlanId(planIds[0], true);
        address _cyanVaultAddress = _item.cyanVaultAddress;

        CyanWalletLogic.setLockState(_paymentPlan.cyanWalletAddress, _item, false);
        CyanWalletLogic.transferNonLockedItem(_paymentPlan.cyanWalletAddress, _cyanVaultAddress, _item);

        _paymentPlan.status = PaymentPlanV2Logic.isBNPL(_paymentPlan.status)
            ? PaymentPlanStatus.BNPL_LIQUIDATED
            : PaymentPlanStatus.PAWN_LIQUIDATED;
        ICyanVaultV2(payable(_cyanVaultAddress)).nftDefaulted(unpaidAmount, estimatedValue);

        emit LiquidatedPaymentPlan(planIds[0], estimatedValue, unpaidAmount);
    }

    /**
     * @notice Triggers auto repayment from the cyan wallet
     * @param planId Payment Plan ID
     */
    function triggerAutoRepay(uint256 planId) external onlyRole(CYAN_AUTO_OPERATOR_ROLE) {
        uint8 autoRepayStatus = paymentPlan[planId].plan.autoRepayStatus;
        if (autoRepayStatus != 1 && autoRepayStatus != 2) revert InvalidAutoRepaymentStatus();
        requireActivePlan(planId);

        (, , , uint256 payAmount, uint256 dueDate) = getPaymentInfoByPlanId(planId, false);
        if ((dueDate - 1 days) > block.timestamp) revert InvalidAutoRepaymentDate();

        address cyanWalletAddress = paymentPlan[planId].cyanWalletAddress;
        if (autoRepayStatus == 2) {
            // Auto-repay from main wallet
            address mainWalletAddress = getMainWalletAddress(cyanWalletAddress);
            address currencyAddress = getCurrencyAddressByPlanId(planId);
            ICyanConduit conduit = ICyanConduit(addressProvider.addresses("CYAN_CONDUIT"));

            // Using WETH when currency is native currency
            if (currencyAddress == address(0)) {
                currencyAddress = addressProvider.addresses("WETH");
                if (currencyAddress == address(0)) revert AddressProvider.AddressNotFound("WETH");
            }

            conduit.transferERC20(mainWalletAddress, cyanWalletAddress, currencyAddress, payAmount);
        }
        CyanWalletLogic.executeAutoPay(cyanWalletAddress, planId, payAmount, autoRepayStatus);
    }

    /**
     * @notice Triggers auto repayment from the cyan wallet
     * @param planId Payment Plan ID
     * @param offer Offer data to fulfill seaport order
     */
    function earlyUnwind(
        uint256 planId,
        uint256 sellPrice,
        ISeaport.OfferData calldata offer
    ) external nonReentrant {
        PaymentPlan storage _paymentPlan = paymentPlan[planId];
        Item memory _item = items[planId];
        requireActivePlan(planId);

        if (msg.sender != _paymentPlan.cyanWalletAddress) {
            address mainWalletAddress = getMainWalletAddress(_paymentPlan.cyanWalletAddress);
            if (msg.sender != mainWalletAddress) revert InvalidSender();
        }
        address currencyAddress = getCurrencyAddressByPlanId(planId);
        if (currencyAddress != address(0)) revert InvalidCurrency();

        (
            uint256 payAmountForCollateral,
            uint256 payAmountForInterest,
            uint256 payAmountForService,
            uint256 currentPayment,

        ) = getPaymentInfoByPlanId(planId, true);

        IWallet(_paymentPlan.cyanWalletAddress).executeModule(
            abi.encodeWithSelector(
                IWallet.earlyUnwind.selector,
                currentPayment,
                sellPrice,
                _item.contractAddress,
                _item.tokenId,
                offer
            )
        );
        IWETH weth = IWETH(addressProvider.addresses("WETH"));
        weth.transferFrom(_paymentPlan.cyanWalletAddress, address(this), currentPayment);
        weth.withdraw(currentPayment);

        uint8 numOfRemainingPayments = _paymentPlan.plan.totalNumberOfPayments - _paymentPlan.plan.counterPaidPayments;
        claimableServiceFee[currencyAddress] += payAmountForService;
        transferEarnedAmountToCyanVault(_item.cyanVaultAddress, payAmountForCollateral, payAmountForInterest);
        _paymentPlan.plan.counterPaidPayments = _paymentPlan.plan.totalNumberOfPayments;
        _paymentPlan.status = PaymentPlanV2Logic.isBNPL(paymentPlan[planId].status)
            ? PaymentPlanStatus.BNPL_COMPLETED
            : PaymentPlanStatus.PAWN_COMPLETED;
        CyanWalletLogic.setLockState(_paymentPlan.cyanWalletAddress, _item, false);

        emit EarlyUnwind(planId, BASE_DISCOUNT_RATE, numOfRemainingPayments);
    }

    receive() external payable {}

    /**
     * @notice Revive defaulted payment plan with penalty
     * @param planId Payment Plan ID
     * @param penaltyAmount Amount that penalizes Defaulted plan revival
     * @param signatureExpiryDate Signature expiry date
     * @param signature Signature signed by Cyan signer
     */
    function revive(
        uint256 planId,
        uint256 penaltyAmount,
        uint256 signatureExpiryDate,
        bytes memory signature
    ) external payable nonReentrant {
        if (signatureExpiryDate < block.timestamp) revert InvalidReviveDate();
        PaymentPlanV2Logic.verifyRevivalSignature(
            planId,
            penaltyAmount,
            signatureExpiryDate,
            paymentPlan[planId].plan.counterPaidPayments,
            cyanSigner,
            signature
        );
        requireDefaultedPlan(planId);

        (
            uint256 payAmountForCollateral,
            uint256 payAmountForInterest,
            uint256 payAmountForService,
            uint256 currentPayment,
            uint256 dueDate
        ) = getPaymentInfoByPlanId(planId, false);
        if (dueDate + paymentPlan[planId].plan.term <= block.timestamp) revert InvalidReviveDate();

        address currencyAddress = getCurrencyAddressByPlanId(planId);
        receiveCurrency(currencyAddress, currentPayment + penaltyAmount, msg.sender);

        ++paymentPlan[planId].plan.counterPaidPayments;
        claimableServiceFee[currencyAddress] += payAmountForService;

        transferEarnedAmountToCyanVault(
            items[planId].cyanVaultAddress,
            payAmountForCollateral,
            payAmountForInterest + penaltyAmount
        );
        if (paymentPlan[planId].plan.counterPaidPayments == paymentPlan[planId].plan.totalNumberOfPayments) {
            paymentPlan[planId].status = PaymentPlanV2Logic.isBNPL(paymentPlan[planId].status)
                ? PaymentPlanStatus.BNPL_COMPLETED
                : PaymentPlanStatus.PAWN_COMPLETED;
            CyanWalletLogic.setLockState(paymentPlan[planId].cyanWalletAddress, items[planId], false);
            emit CompletedByRevival(planId, penaltyAmount);
        } else {
            emit Revived(planId, penaltyAmount);
        }
    }

    /**
     * @notice Transfer earned amount to Cyan Vault
     * @param cyanVaultAddress Original price of the token
     * @param paidTokenPayment Paid token payment
     * @param paidInterestFee Paid interest fee
     */
    function transferEarnedAmountToCyanVault(
        address cyanVaultAddress,
        uint256 paidTokenPayment,
        uint256 paidInterestFee
    ) private {
        address currencyAddress = getCurrencyAddressByVaultAddress(cyanVaultAddress);
        if (currencyAddress == address(0)) {
            ICyanVaultV2(payable(cyanVaultAddress)).earn{ value: paidTokenPayment + paidInterestFee }(
                paidTokenPayment,
                paidInterestFee
            );
        } else {
            IERC20Upgradeable erc20Contract = IERC20Upgradeable(currencyAddress);
            erc20Contract.approve(cyanVaultAddress, paidTokenPayment + paidInterestFee);
            ICyanVaultV2(payable(cyanVaultAddress)).earn(paidTokenPayment, paidInterestFee);
        }
    }

    /**
     * @notice Return expected payment plan for given price and interest rate
     * @param plan Plan details
     * @return Expected down payment amount
     * @return Expected total interest fee
     * @return Expected total service fee
     * @return Estimated subsequent payments after down payment
     * @return Expected total financing amount
     */
    function getExpectedPlan(Plan calldata plan)
        external
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return PaymentPlanV2Logic.getExpectedPlan(plan);
    }

    /**
     * @notice Check if payment plan is pending
     * @param planId Payment Plan ID
     * @return PaymentPlanStatus
     */
    function getPlanStatus(uint256 planId) public view returns (PaymentPlanStatus) {
        if (
            paymentPlan[planId].status == PaymentPlanStatus.BNPL_ACTIVE ||
            paymentPlan[planId].status == PaymentPlanStatus.PAWN_ACTIVE
        ) {
            (, , , , uint256 dueDate) = getPaymentInfoByPlanId(planId, false);
            bool isDefaulted = block.timestamp > dueDate;

            if (isDefaulted) {
                return
                    paymentPlan[planId].status == PaymentPlanStatus.BNPL_ACTIVE
                        ? PaymentPlanStatus.BNPL_DEFAULTED
                        : PaymentPlanStatus.PAWN_DEFAULTED;
            }
        }

        return paymentPlan[planId].status;
    }

    /**
     * @notice Updating base discount rate
     * @param _baseDiscountRate New base discount rate
     */
    function updateBaseDiscountRate(uint256 _baseDiscountRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_baseDiscountRate > 10000) revert InvalidBaseDiscountRate();
        BASE_DISCOUNT_RATE = _baseDiscountRate;
        emit UpdateBaseDiscountRate(_baseDiscountRate);
    }

    /**
     * @notice Updating Cyan signer address
     * @param _cyanSigner New Cyan signer address
     */
    function updateCyanSignerAddress(address _cyanSigner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_cyanSigner == address(0)) revert InvalidAddress();
        cyanSigner = _cyanSigner;
        emit UpdatedCyanSigner(_cyanSigner);
    }

    /**
     * @notice Claiming collected service fee amount
     * @param currencyAddress Currency address
     */
    function claimServiceFee(address currencyAddress) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        emit ClaimedServiceFee(currencyAddress, claimableServiceFee[currencyAddress]);
        if (currencyAddress == address(0)) {
            (bool success, ) = payable(msg.sender).call{ value: claimableServiceFee[currencyAddress] }("");
            if (!success) revert EthTransferFailed();
        } else {
            IERC20Upgradeable erc20Contract = IERC20Upgradeable(currencyAddress);
            erc20Contract.safeTransfer(msg.sender, claimableServiceFee[currencyAddress]);
        }
        claimableServiceFee[currencyAddress] = 0;
    }

    /**
     * @notice Updating Cyan wallet factory address that used for deploying new wallets
     * @param factory New Cyan wallet factory address
     */
    function updateWalletFactoryAddress(address factory) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (factory == address(0)) revert InvalidAddress();
        walletFactory = factory;
        emit UpdatedWalletFactory(factory);
    }

    /**
     * @notice Setting auto repay status for a payment plan
     * @param planId Payment plan ID
     * @param autoRepayStatus Auto repay status
     */
    function setAutoRepayStatus(uint256 planId, uint8 autoRepayStatus) external {
        address mainWalletAddress = getMainWalletAddress(paymentPlan[planId].cyanWalletAddress);
        if (mainWalletAddress != msg.sender && paymentPlan[planId].cyanWalletAddress != msg.sender) {
            revert InvalidSender();
        }
        paymentPlan[planId].plan.autoRepayStatus = autoRepayStatus;
        emit SetAutoRepayStatus(planId, autoRepayStatus);
    }

    /**
     * @notice Getting currency address by plan ID
     * @param planId Payment plan ID
     */
    function getCurrencyAddressByPlanId(uint256 planId) public view returns (address) {
        return getCurrencyAddressByVaultAddress(items[planId].cyanVaultAddress);
    }

    /**
     * @notice Getting currency address by vault address
     * @param vaultAddress Cyan Vault address
     */
    function getCurrencyAddressByVaultAddress(address vaultAddress) private view returns (address) {
        return ICyanVaultV2(payable(vaultAddress)).getCurrencyAddress();
    }

    /**
     * @notice Getting main wallet address by Cyan wallet address
     * @param cyanWalletAddress Cyan wallet address
     */
    function getMainWalletAddress(address cyanWalletAddress) private view returns (address) {
        return IFactory(walletFactory).getWalletOwner(cyanWalletAddress);
    }

    function requireActivePlan(uint256 planId) private view {
        PaymentPlanStatus status = getPlanStatus(planId);
        if (status != PaymentPlanStatus.BNPL_ACTIVE && status != PaymentPlanStatus.PAWN_ACTIVE) revert InvalidStage();
    }

    function requireDefaultedPlan(uint256 planId) private view {
        PaymentPlanStatus status = getPlanStatus(planId);
        if (status != PaymentPlanStatus.BNPL_DEFAULTED && status != PaymentPlanStatus.PAWN_DEFAULTED)
            revert InvalidStage();
    }

    function receiveCurrency(
        address currency,
        uint256 amount,
        address from
    ) private {
        if (currency == address(0)) {
            if (amount != msg.value) revert InvalidAmount();
        } else {
            if (msg.value != 0) revert InvalidAmount();
            ICyanConduit(addressProvider.addresses("CYAN_CONDUIT")).transferERC20(
                from,
                address(this),
                currency,
                amount
            );
        }
    }
}
