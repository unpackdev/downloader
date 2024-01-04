pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeDecimalMath.sol";

import "./ReentrancyGuard.sol";
import "./AggregatorV3Interface.sol";
import "./FixedPoint.sol";
import "./Owned.sol";
import "./Pausable.sol";
import "./IConjure.sol";

contract EtherCollateral is ReentrancyGuard, Owned, Pausable {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;


    // ========== CONSTANTS ==========
    uint256 internal constant ONE_THOUSAND = 1e18 * 1000;
    uint256 internal constant ONE_HUNDRED = 1e18 * 100;

    uint256 internal constant ACCOUNT_LOAN_LIMIT_CAP = 1000;

    // ========== SETTER STATE VARIABLES ==========

    // The ratio of Collateral to synths issued
    uint256 public collateralizationRatio = SafeDecimalMath.unit() * 120;

    // Minting fee for issuing the synths. Default 50 bips.
    uint256 public issueFeeRate;

    // Minimum amount of ETH to create loan preventing griefing and gas consumption. Min 0.05 ETH
    uint256 public minLoanCollateralSize = SafeDecimalMath.unit() / 20;

    // Maximum number of loans an account can create
    uint256 public accountLoanLimit = 50;

    // Time when remaining loans can be liquidated
    uint256 public liquidationDeadline;

    // Liquidation ratio when loans can be liquidated
    uint256 public liquidationRatio = (120 * SafeDecimalMath.unit()) / 100; // 1.2 ratio

    // Liquidation penalty when loans are liquidated. default 10%
    uint256 public liquidationPenalty = SafeDecimalMath.unit() / 10;

    // ========== STATE VARIABLES ==========

    // The total number of synths issued by the collateral in this contract
    uint256 public totalIssuedSynths;

    // Total number of loans ever created
    uint256 public totalLoansCreated;

    // Total number of open loans
    uint256 public totalOpenLoanCount;

    // Synth loan storage struct
    struct SynthLoanStruct {
        //  Acccount that created the loan
        address payable account;
        //  Amount (in collateral token ) that they deposited
        uint256 collateralAmount;
        //  Amount (in synths) that they issued to borrow
        uint256 loanAmount;
        // Minting Fee
        uint256 mintingFee;
        // When the loan was created
        uint256 timeCreated;
        // ID for the loan
        uint256 loanID;
        // When the loan was paidback (closed)
        uint256 timeClosed;
    }

    // Users Loans by address
    mapping(address => SynthLoanStruct[]) public accountsSynthLoans;

    // Account Open Loan Counter
    mapping(address => uint256) public accountOpenLoanCounter;

    address payable public arbasset;

    address public factoryaddress;

    // ========== CONSTRUCTOR ==========
    constructor(address payable _asset, address _owner, address _factoryaddress, uint256 _mintingfeerate ) Owned(_owner) public  {
        arbasset = _asset;
        factoryaddress = _factoryaddress;
        issueFeeRate = _mintingfeerate;

        // max 2.5% fee for minting
        require(_mintingfeerate <= 250);
    }

    // ========== SETTERS ==========

    function setCollateralizationRatio(uint256 ratio) external onlyOwner {
        require(ratio <= ONE_THOUSAND, "Too high");
        require(ratio >= ONE_HUNDRED, "Too low");
        collateralizationRatio = ratio;
        emit CollateralizationRatioUpdated(ratio);
    }

    function setIssueFeeRate(uint256 _issueFeeRate) external onlyOwner {
        // max 2.5% fee for minting
        require(_issueFeeRate <= 250);
        issueFeeRate = _issueFeeRate;
        emit IssueFeeRateUpdated(issueFeeRate);
    }

    function setMinLoanCollateralSize(uint256 _minLoanCollateralSize) external onlyOwner {
        minLoanCollateralSize = _minLoanCollateralSize;
        emit MinLoanCollateralSizeUpdated(minLoanCollateralSize);
    }

    function setAccountLoanLimit(uint256 _loanLimit) external onlyOwner {
        require(_loanLimit < ACCOUNT_LOAN_LIMIT_CAP, "Owner cannot set higher than ACCOUNT_LOAN_LIMIT_CAP");
        accountLoanLimit = _loanLimit;
        emit AccountLoanLimitUpdated(accountLoanLimit);
    }

    function setLiquidationRatio(uint256 _liquidationRatio) external onlyOwner {
        require(_liquidationRatio > SafeDecimalMath.unit(), "Ratio less than 100%");
        liquidationRatio = _liquidationRatio;
        emit LiquidationRatioUpdated(liquidationRatio);
    }

    function getContractInfo()
    external
    view
    returns (
        uint256 _collateralizationRatio,
        uint256 _issuanceRatio,
        uint256 _issueFeeRate,
        uint256 _minLoanCollateralSize,
        uint256 _totalIssuedSynths,
        uint256 _totalLoansCreated,
        uint256 _totalOpenLoanCount,
        uint256 _ethBalance,
        uint256 _liquidationDeadline
    )
    {
        _collateralizationRatio = collateralizationRatio;
        _issuanceRatio = issuanceRatio();
        _issueFeeRate = issueFeeRate;
        _minLoanCollateralSize = minLoanCollateralSize;
        _totalIssuedSynths = totalIssuedSynths;
        _totalLoansCreated = totalLoansCreated;
        _totalOpenLoanCount = totalOpenLoanCount;
        _ethBalance = address(this).balance;
        _liquidationDeadline = liquidationDeadline;
    }

    // returns value of 100 / collateralizationRatio.
    // e.g. 100/150 = 0.6666666667
    function issuanceRatio() public view returns (uint256) {
        // this rounds so you get slightly more rather than slightly less
        return ONE_HUNDRED.divideDecimalRound(collateralizationRatio);
    }

    function loanAmountFromCollateral(uint256 collateralAmount) public returns (uint256) {
        uint currentprice = IConjure(arbasset).getPrice();
        uint currentethusdprice = uint(IConjure(arbasset).getLatestETHUSDPrice());

        return collateralAmount.multiplyDecimal(issuanceRatio()).multiplyDecimal(currentethusdprice).divideDecimal(currentprice);
    }

    function collateralAmountForLoan(uint256 loanAmount) public returns (uint256) {
        uint currentprice = IConjure(arbasset).getPrice();
        uint currentethusdprice = uint(IConjure(arbasset).getLatestETHUSDPrice());

        return
        loanAmount
        .multiplyDecimal(collateralizationRatio.divideDecimalRound(currentethusdprice).multiplyDecimal(currentprice))
        .divideDecimalRound(ONE_HUNDRED);
    }

    function getMintingFee(address _account, uint256 _loanID) external view returns (uint256) {
        // Get the loan from storage
        SynthLoanStruct memory synthLoan = _getLoanFromStorage(_account, _loanID);
        return synthLoan.mintingFee;
    }

    /**
     * r = target issuance ratio
     * D = debt balance
     * V = Collateral
     * P = liquidation penalty
     * Calculates amount of synths = (D - V * r) / (1 - (1 + P) * r)
     */
    function calculateAmountToLiquidate(uint debtBalance, uint collateral) public view returns (uint) {
        uint unit = SafeDecimalMath.unit();
        uint ratio = liquidationRatio;

        uint dividend = debtBalance.sub(collateral.divideDecimal(ratio));
        uint divisor = unit.sub(unit.add(liquidationPenalty).divideDecimal(ratio));

        return dividend.divideDecimal(divisor);
    }

    function openLoanIDsByAccount(address _account) external view returns (uint256[] memory) {
        SynthLoanStruct[] memory synthLoans = accountsSynthLoans[_account];

        uint256[] memory _openLoanIDs = new uint256[](synthLoans.length);
        uint256 _counter = 0;

        for (uint256 i = 0; i < synthLoans.length; i++) {
            if (synthLoans[i].timeClosed == 0) {
                _openLoanIDs[_counter] = synthLoans[i].loanID;
                _counter++;
            }
        }
        // Create the fixed size array to return
        uint256[] memory _result = new uint256[](_counter);

        // Copy loanIDs from dynamic array to fixed array
        for (uint256 j = 0; j < _counter; j++) {
            _result[j] = _openLoanIDs[j];
        }
        // Return an array with list of open Loan IDs
        return _result;
    }

    function getLoan(address _account, uint256 _loanID)
    external
    view
    returns (
        address account,
        uint256 collateralAmount,
        uint256 loanAmount,
        uint256 timeCreated,
        uint256 loanID,
        uint256 timeClosed,
        uint256 totalFees
    )
    {
        SynthLoanStruct memory synthLoan = _getLoanFromStorage(_account, _loanID);
        account = synthLoan.account;
        collateralAmount = synthLoan.collateralAmount;
        loanAmount = synthLoan.loanAmount;
        timeCreated = synthLoan.timeCreated;
        loanID = synthLoan.loanID;
        timeClosed = synthLoan.timeClosed;
        totalFees = synthLoan.mintingFee;
    }

    function getLoanCollateralRatio(address _account, uint256 _loanID) external view returns (uint256 loanCollateralRatio) {
        // Get the loan from storage
        SynthLoanStruct memory synthLoan = _getLoanFromStorage(_account, _loanID);

        (loanCollateralRatio,  ) = _loanCollateralRatio(synthLoan);
    }

    function _loanCollateralRatio(SynthLoanStruct memory _loan)
    internal
    view
    returns (
        uint256 loanCollateralRatio,
        uint256 collateralValue
    )
    {
        uint256 loanAmountWithAccruedInterest = _loan.loanAmount.multiplyDecimal(IConjure(arbasset).getLatestPrice());

        collateralValue = _loan.collateralAmount.multiplyDecimal(uint(IConjure(arbasset).getLatestETHUSDPrice()));
        loanCollateralRatio = collateralValue.divideDecimal(loanAmountWithAccruedInterest);
    }


    // ========== PUBLIC FUNCTIONS ==========

    function openLoan(uint256 _loanAmount)
    external
    payable
    notPaused
    nonReentrant
    returns (uint256 loanID)
    {

        // Require ETH sent to be greater than minLoanCollateralSize
        require(
            msg.value >= minLoanCollateralSize,
            "Not enough ETH to create this loan. Please see the minLoanCollateralSize"
        );

        // Each account is limited to creating 50 (accountLoanLimit) loans
        require(accountsSynthLoans[msg.sender].length < accountLoanLimit, "Each account is limited to 50 loans");

        // Calculate issuance amount based on issuance ratio
        uint256 maxLoanAmount = loanAmountFromCollateral(msg.value);

        // Require requested _loanAmount to be less than maxLoanAmount
        // Issuance ratio caps collateral to loan value at 120%
        require(_loanAmount <= maxLoanAmount, "Loan amount exceeds max borrowing power");

        uint256 ethforloan = collateralAmountForLoan(_loanAmount);
        uint256 mintingFee = _calculateMintingFee(msg.value);
        require(msg.value >= ethforloan + mintingFee);

        // Get a Loan ID
        loanID = _incrementTotalLoansCounter();

        // Create Loan storage object
        SynthLoanStruct memory synthLoan = SynthLoanStruct({
        account: msg.sender,
        collateralAmount: msg.value - mintingFee,
        loanAmount: _loanAmount,
        mintingFee: mintingFee,
        timeCreated: block.timestamp,
        loanID: loanID,
        timeClosed: 0
        });

        // Record loan in mapping to account in an array of the accounts open loans
        accountsSynthLoans[msg.sender].push(synthLoan);

        // Increment totalIssuedSynths
        totalIssuedSynths = totalIssuedSynths.add(_loanAmount);

        // Issue the synth (less fee)
        syntharb().mint(msg.sender, _loanAmount);

        // Fee distribution. Mint the fees into the FeePool and record fees paid
        if (mintingFee > 0) {

            // calculate back factory owner fee is 0.25 on top of creator fee
            arbasset.transfer(mintingFee / 4 * 3);

            address payable factoryowner = IFactoryAddress(factoryaddress).getFactoryOwner();
            factoryowner.transfer(mintingFee / 4);
        }

        // Tell the Dapps a loan was created
        emit LoanCreated(msg.sender, loanID, _loanAmount);
    }

    function closeLoan(uint256 loanID) external nonReentrant  {
        _closeLoan(msg.sender, loanID, false);
    }

    // Add ETH collateral to an open loan
    function depositCollateral(address account, uint256 loanID) external payable notPaused {
        require(msg.value > 0, "Deposit amount must be greater than 0");

        // Get the loan from storage
        SynthLoanStruct memory synthLoan = _getLoanFromStorage(account, loanID);

        // Check loan exists and is open
        _checkLoanIsOpen(synthLoan);

        uint256 totalCollateral = synthLoan.collateralAmount.add(msg.value);

        _updateLoanCollateral(synthLoan, totalCollateral);

        // Tell the Dapps collateral was added to loan
        emit CollateralDeposited(account, loanID, msg.value, totalCollateral);
    }

    // Withdraw ETH collateral from an open loan
    function withdrawCollateral(uint256 loanID, uint256 withdrawAmount) external notPaused nonReentrant  {
        require(withdrawAmount > 0, "Amount to withdraw must be greater than 0");

        // Get the loan from storage
        SynthLoanStruct memory synthLoan = _getLoanFromStorage(msg.sender, loanID);

        // Check loan exists and is open
        _checkLoanIsOpen(synthLoan);

        uint256 collateralAfter = synthLoan.collateralAmount.sub(withdrawAmount);

        SynthLoanStruct memory loanAfter = _updateLoanCollateral(synthLoan, collateralAfter);

        // require collateral ratio after to be above the liquidation ratio
        (uint256 collateralRatioAfter, ) = _loanCollateralRatio(loanAfter);

        require(collateralRatioAfter > liquidationRatio, "Collateral ratio below liquidation after withdraw");

        // transfer ETH to msg.sender
        msg.sender.transfer(withdrawAmount);

        // Tell the Dapps collateral was added to loan
        emit CollateralWithdrawn(msg.sender, loanID, withdrawAmount, loanAfter.collateralAmount);
    }

    function repayLoan(
        address _loanCreatorsAddress,
        uint256 _loanID,
        uint256 _repayAmount
    ) external  {

        // check msg.sender has sufficient funds to pay
        require(IERC20(address(syntharb())).balanceOf(msg.sender) >= _repayAmount, "Not enough balance");

        SynthLoanStruct memory synthLoan = _getLoanFromStorage(_loanCreatorsAddress, _loanID);

        // Check loan exists and is open
        _checkLoanIsOpen(synthLoan);

        (
        uint256 loanAmountPaid,
        uint256 loanAmountAfter
        ) = _splitInterestLoanPayment(_repayAmount, synthLoan.loanAmount);

        // burn funds from msg.sender for repaid amount
        syntharb().burn(msg.sender, _repayAmount);

        // Send interest paid to fee pool and record loan amount paid
        _processInterestAndLoanPayment(loanAmountPaid);

        // update loan with new total loan amount, record accrued interests
        _updateLoan(synthLoan, loanAmountAfter);

        emit LoanRepaid(_loanCreatorsAddress, _loanID, _repayAmount, loanAmountAfter);
    }

    // Liquidate loans at or below issuance ratio
    function liquidateLoan(
        address _loanCreatorsAddress,
        uint256 _loanID,
        uint256 _debtToCover
    ) external nonReentrant  {

        // check msg.sender (liquidator's wallet) has sufficient
        require(IERC20(address(syntharb())).balanceOf(msg.sender) >= _debtToCover, "Not enough balance");

        SynthLoanStruct memory synthLoan = _getLoanFromStorage(_loanCreatorsAddress, _loanID);

        // Check loan exists and is open
        _checkLoanIsOpen(synthLoan);

        (uint256 collateralRatio, uint256 collateralValue) = _loanCollateralRatio(synthLoan);

        require(collateralRatio < liquidationRatio, "Collateral ratio above liquidation ratio");

        // calculate amount to liquidate to fix ratio including accrued interest
        uint256 liquidationAmount = calculateAmountToLiquidate(
            synthLoan.loanAmount,
            collateralValue
        );

        // cap debt to liquidate
        uint256 amountToLiquidate = liquidationAmount < _debtToCover ? liquidationAmount : _debtToCover;

        // burn funds from msg.sender for amount to liquidate
        syntharb().burn(msg.sender, amountToLiquidate);

        (uint256 loanAmountPaid,  ) = _splitInterestLoanPayment(
            amountToLiquidate,
            synthLoan.loanAmount
        );

        // Send interests paid to fee pool and record loan amount paid
        _processInterestAndLoanPayment(loanAmountPaid);

        // Collateral value to redeem
        uint currentprice = IConjure(arbasset).getPrice();
        uint currentethusdprice = uint(IConjure(arbasset).getLatestETHUSDPrice());

        uint256 collateralRedeemed = amountToLiquidate.multiplyDecimal(currentprice).divideDecimal(currentethusdprice);

        // Add penalty
        uint256 totalCollateralLiquidated = collateralRedeemed.multiplyDecimal(
            SafeDecimalMath.unit().add(liquidationPenalty)
        );

        // update remaining loanAmount less amount paid and update accrued interests less interest paid
        _updateLoan(synthLoan, synthLoan.loanAmount.sub(loanAmountPaid));

        // update remaining collateral on loan
        _updateLoanCollateral(synthLoan, synthLoan.collateralAmount.sub(totalCollateralLiquidated));

        // Send liquidated ETH collateral to msg.sender
        msg.sender.transfer(totalCollateralLiquidated);

        // emit loan liquidation event
        emit LoanPartiallyLiquidated(
            _loanCreatorsAddress,
            _loanID,
            msg.sender,
            amountToLiquidate,
            totalCollateralLiquidated
        );
    }

    function _splitInterestLoanPayment(
        uint256 _paymentAmount,
        uint256 _loanAmount
    )
    internal
    pure
    returns (
        uint256 loanAmountPaid,
        uint256 loanAmountAfter
    )
    {
        uint256 remainingPayment = _paymentAmount;

        // Remaining amounts - pay down loan amount
        loanAmountAfter = _loanAmount;
        if (remainingPayment > 0) {
            loanAmountAfter = loanAmountAfter.sub(remainingPayment);
            loanAmountPaid = remainingPayment;
        }
    }

    function _processInterestAndLoanPayment(uint256 loanAmountPaid) internal {
        // Decrement totalIssuedSynths
        if (loanAmountPaid > 0) {
            totalIssuedSynths = totalIssuedSynths.sub(loanAmountPaid);
        }
    }

    // Liquidation of an open loan available for anyone
    function liquidateUnclosedLoan(address _loanCreatorsAddress, uint256 _loanID) external nonReentrant  {
        // Close the creators loan and send collateral to the closer.
        _closeLoan(_loanCreatorsAddress, _loanID, true);
        // Tell the Dapps this loan was liquidated
        emit LoanLiquidated(_loanCreatorsAddress, _loanID, msg.sender);
    }

    // ========== PRIVATE FUNCTIONS ==========

    function _closeLoan(
        address account,
        uint256 loanID,
        bool liquidation
    ) private {

        // Get the loan from storage
        SynthLoanStruct memory synthLoan = _getLoanFromStorage(account, loanID);

        // Check loan exists and is open
        _checkLoanIsOpen(synthLoan);

        uint256 repayAmount = synthLoan.loanAmount;

        require(
            IERC20(address(syntharb())).balanceOf(msg.sender) >= repayAmount,
            "You do not have the required Synth balance to close this loan."
        );

        // Record loan as closed
        _recordLoanClosure(synthLoan);

        // Decrement totalIssuedSynths
        // subtract the accrued interest from the loanAmount
        totalIssuedSynths = totalIssuedSynths.sub(synthLoan.loanAmount);

        // get prices
        uint currentprice = IConjure(arbasset).getPrice();
        uint currentethusdprice = uint(IConjure(arbasset).getLatestETHUSDPrice());

        // Burn all Synths issued for the loan + the fees
        syntharb().burn(msg.sender, repayAmount);

        uint256 remainingCollateral = synthLoan.collateralAmount;

        if (liquidation) {
            // Send liquidator redeemed collateral + 10% penalty
            // Collateral value to redeem

            uint256 collateralRedeemed = repayAmount.multiplyDecimal(currentprice).divideDecimal(currentethusdprice);

            // add penalty
            uint256 totalCollateralLiquidated = collateralRedeemed.multiplyDecimal(
                SafeDecimalMath.unit().add(liquidationPenalty)
            );

            // ensure remaining ETH collateral sufficient to cover collateral liquidated
            // will revert if the liquidated collateral + penalty is more than remaining collateral
            remainingCollateral = remainingCollateral.sub(totalCollateralLiquidated);

            // Send liquidator CollateralLiquidated
            msg.sender.transfer(totalCollateralLiquidated);
        }

        // Send remaining collateral to loan creator
        synthLoan.account.transfer(remainingCollateral);

        // Tell the Dapps
        emit LoanClosed(account, loanID);
    }

    function _getLoanFromStorage(address account, uint256 loanID) private view returns (SynthLoanStruct memory) {
        SynthLoanStruct[] memory synthLoans = accountsSynthLoans[account];
        for (uint256 i = 0; i < synthLoans.length; i++) {
            if (synthLoans[i].loanID == loanID) {
                return synthLoans[i];
            }
        }
    }

    function _updateLoan(
        SynthLoanStruct memory _synthLoan,
        uint256 _newLoanAmount
    ) private {
        // Get storage pointer to the accounts array of loans
        SynthLoanStruct[] storage synthLoans = accountsSynthLoans[_synthLoan.account];
        for (uint256 i = 0; i < synthLoans.length; i++) {
            if (synthLoans[i].loanID == _synthLoan.loanID) {
                synthLoans[i].loanAmount = _newLoanAmount;
            }
        }
    }

    function _updateLoanCollateral(SynthLoanStruct memory _synthLoan, uint256 _newCollateralAmount)
    private
    returns (SynthLoanStruct memory)
    {
        // Get storage pointer to the accounts array of loans
        SynthLoanStruct[] storage synthLoans = accountsSynthLoans[_synthLoan.account];
        for (uint256 i = 0; i < synthLoans.length; i++) {
            if (synthLoans[i].loanID == _synthLoan.loanID) {
                synthLoans[i].collateralAmount = _newCollateralAmount;
                return synthLoans[i];
            }
        }
    }

    function _recordLoanClosure(SynthLoanStruct memory synthLoan) private {
        // Get storage pointer to the accounts array of loans
        SynthLoanStruct[] storage synthLoans = accountsSynthLoans[synthLoan.account];
        for (uint256 i = 0; i < synthLoans.length; i++) {
            if (synthLoans[i].loanID == synthLoan.loanID) {
                // Record the time the loan was closed
                synthLoans[i].timeClosed = block.timestamp;
            }
        }

        // Reduce Total Open Loans Count
        totalOpenLoanCount = totalOpenLoanCount.sub(1);
    }

    function _incrementTotalLoansCounter() private returns (uint256) {
        // Increase the total Open loan count
        totalOpenLoanCount = totalOpenLoanCount.add(1);
        // Increase the total Loans Created count
        totalLoansCreated = totalLoansCreated.add(1);
        // Return total count to be used as a unique ID.
        return totalLoansCreated;
    }

    function _calculateMintingFee(uint256 _ethAmount) private view returns (uint256 mintingFee) {

        if (issueFeeRate == 0)
        {
            mintingFee = 0;
        }
        else
        {
            mintingFee = _ethAmount.divideDecimalRound(10000 + issueFeeRate).multiplyDecimal(issueFeeRate);
        }
    }

    function _checkLoanIsOpen(SynthLoanStruct memory _synthLoan) internal pure {
        require(_synthLoan.loanID > 0, "Loan does not exist");
        require(_synthLoan.timeClosed == 0, "Loan already closed");
    }

    /* ========== INTERNAL VIEWS ========== */

    function syntharb() internal view returns (IConjure) {
        return IConjure(arbasset);
    }

    // ========== EVENTS ==========

    event CollateralizationRatioUpdated(uint256 ratio);
    event LiquidationRatioUpdated(uint256 ratio);
    event InterestRateUpdated(uint256 interestRate);
    event IssueFeeRateUpdated(uint256 issueFeeRate);
    event MinLoanCollateralSizeUpdated(uint256 minLoanCollateralSize);
    event AccountLoanLimitUpdated(uint256 loanLimit);
    event LoanLiquidationOpenUpdated(bool loanLiquidationOpen);
    event LoanCreated(address indexed account, uint256 loanID, uint256 amount);
    event LoanClosed(address indexed account, uint256 loanID);
    event LoanLiquidated(address indexed account, uint256 loanID, address liquidator);
    event LoanPartiallyLiquidated(
        address indexed account,
        uint256 loanID,
        address liquidator,
        uint256 liquidatedAmount,
        uint256 liquidatedCollateral
    );
    event CollateralDeposited(address indexed account, uint256 loanID, uint256 collateralAmount, uint256 collateralAfter);
    event CollateralWithdrawn(address indexed account, uint256 loanID, uint256 amountWithdrawn, uint256 collateralAfter);
    event LoanRepaid(address indexed account, uint256 loanID, uint256 repaidAmount, uint256 newLoanAmount);
}

contract EtherCollateralFactory {
    event NewEtherCollateralContract(address deployed);

    constructor() public {
    }

    /**
     * @dev lets anyone mint a new CONJURE contract
     */
    function EtherCollateralMint(
        address payable asset_,
        address owner_,
        address factoryaddress_,
        uint256 mintingfeerate_
    ) public returns (address)  {
        EtherCollateral newContract = new EtherCollateral(
            asset_,
            owner_,
            factoryaddress_,
            mintingfeerate_
        );
        emit NewEtherCollateralContract(address(newContract));
        return address(newContract);
    }
}

interface IFactoryAddress {
    function getFactoryOwner() external returns (address payable);
}
