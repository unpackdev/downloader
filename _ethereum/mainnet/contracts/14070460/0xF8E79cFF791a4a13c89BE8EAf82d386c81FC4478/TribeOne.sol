// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./ERC721Holder.sol";
import "./ERC1155Holder.sol";
import "./ITribeOne.sol";
import "./IAssetManager.sol";
import "./Ownable.sol";
import "./TribeOneHelper.sol";

contract TribeOne is ERC721Holder, ERC1155Holder, ITribeOne, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    enum Status {
        AVOID_ZERO, // just for avoid zero
        LISTED, // after the loan has been created --> the next status will be APPROVED
        APPROVED, // in this status the loan has a lender -- will be set after approveLoan(). loan fund => borrower
        LOANACTIVED, // NFT was brought from opensea by agent and staked in TribeOne - relayNFT()
        LOANPAID, // loan was paid fully but still in TribeOne
        WITHDRAWN, // the final status, the collateral returned to the borrower or to the lender withdrawNFT()
        FAILED, // NFT buying order was failed in partner's platform such as opensea...
        CANCELLED, // only if loan is LISTED - cancelLoan()
        DEFAULTED, // Grace period = 15 days were passed from the last payment schedule
        LIQUIDATION, // NFT was put in marketplace
        POSTLIQUIDATION, /// NFT was sold
        RESTWITHDRAWN, // user get back the rest of money from the money which NFT set is sold in marketplace
        RESTLOCKED, // Rest amount was forcely locked because he did not request to get back with in 2 weeks (GRACE PERIODS)
        REJECTED // Loan should be rejected when requested loan amount is less than fund amount because of some issues such as big fluctuation in marketplace
    }

    struct Asset {
        uint256 amount;
        address currency; // address(0) is ETH native coin
    }

    struct LoanRules {
        uint16 tenor;
        uint16 LTV; // 10000 - 100%
        uint16 interest; // 10000 - 100%
    }

    struct Loan {
        uint256 fundAmount; // the amount which user put in TribeOne to buy NFT
        uint256 paidAmount; // the amount that has been paid back to the lender to date
        uint256 loanStart; // the point when the loan is approved
        uint256 postTime; // the time when NFT set was sold in marketplace and that money was put in TribeOne
        uint256 restAmount; // rest amount after sending loan debt(+interest) and 5% penalty
        address borrower; // the address who receives the loan
        uint8 nrOfPenalty;
        uint8 passedTenors; // the number of tenors which we can consider user passed - paid tenor
        Asset loanAsset;
        Asset collateralAsset;
        Status status; // the loan status
        LoanRules loanRules;
        address[] nftAddressArray; // the adderess of the ERC721
        uint256[] nftTokenIdArray; // the unique identifier of the NFT token that the borrower uses as collateral
        TribeOneHelper.TokenType[] nftTokenTypeArray; // the token types : ERC721 , ERC1155 , ...
    }

    mapping(uint256 => Loan) public loans; // loanId => Loan
    Counters.Counter public loanIds; // loanId is from No.1
    // uint public loanLength;
    uint256 public constant MAX_SLIPPAGE = 500; // 5%
    // uint256 public constant TENOR_UNIT = 4 weeks; // installment should be pay at least in every 4 weeks
    // uint256 public constant GRACE_PERIOD = 14 days; // 2 weeks

    /**
     * @dev It's for only testnet
     */
    uint256 public TENOR_UNIT = 7 minutes;
    uint256 public GRACE_PERIOD = 3 minutes;

    address public salesManager;
    address public assetManager;
    address public feeTo;
    address public immutable feeCurrency; // stable coin such as USDC, late fee $5
    uint256 public lateFee; // we will set it 5 USD for each tenor late
    uint256 public penaltyFee; // we will set it 5% in the future - 1000 = 100%

    event LoanCreated(uint256 indexed loanId, address indexed owner);
    event LoanApproved(uint256 indexed _loanId, address indexed _to, address _fundCurreny, uint256 _fundAmount);
    event LoanCanceled(uint256 indexed _loanId, address _sender);
    event NFTRelayed(uint256 indexed _loanId, address indexed _sender, bool _accepted);
    event InstallmentPaid(uint256 indexed _loanId, address _sender, address _currency, uint256 _amount);
    event NFTWithdrew(uint256 indexed _loanId, address _to);
    event LoanDefaulted(uint256 indexed _loandId);
    event LoanLiquidation(uint256 indexed _loanId, address _salesManager);
    event LoanPostLiquidation(uint256 indexed _loanId, uint256 _soldAmount, uint256 _finalDebt);
    event RestWithdrew(uint256 indexed _loanId, uint256 _amount);
    event SettingsUpdate(address _feeTo, uint256 _lateFee, uint256 _penaltyFee, address _salesManager, address _assetManager);
    event LoanRejected(uint256 _loanId, address _agent);

    constructor(
        address _salesManager,
        address _feeTo,
        address _feeCurrency,
        address _multiSigWallet,
        address _assetManager
    ) {
        require(
            _salesManager != address(0) &&
                _feeTo != address(0) &&
                _feeCurrency != address(0) &&
                _multiSigWallet != address(0) &&
                _assetManager != address(0),
            "TribeOne: ZERO address"
        );
        salesManager = _salesManager;
        assetManager = _assetManager;
        feeTo = _feeTo;
        feeCurrency = _feeCurrency;

        transferOwnership(_multiSigWallet);
    }

    function setPeriods(uint256 _tenorUint, uint256 _gracePeriod) external onlySuperOwner {
        TENOR_UNIT = _tenorUint;
        GRACE_PERIOD = _gracePeriod;
    }

    receive() external payable {}

    function getLoanAsset(uint256 _loanId) external view returns (address _token, uint256 _amount) {
        _token = loans[_loanId].loanAsset.currency;
        _amount = loans[_loanId].loanAsset.amount;
    }

    function getCollateralAsset(uint256 _loanId) external view returns (address _token, uint256 _amount) {
        _token = loans[_loanId].collateralAsset.currency;
        _amount = loans[_loanId].collateralAsset.amount;
    }

    function getLoanRules(uint256 _loanId)
        external
        view
        returns (
            uint16 tenor,
            uint16 LTV,
            uint16 interest
        )
    {
        tenor = loans[_loanId].loanRules.tenor;
        LTV = loans[_loanId].loanRules.LTV;
        interest = loans[_loanId].loanRules.interest;
    }

    function getLoanNFTCount(uint256 _loanId) external view returns (uint256) {
        return loans[_loanId].nftAddressArray.length;
    }

    function getLoanNFTItem(uint256 _loanId, uint256 _nftItemId) external view returns (address _nftAddress, uint256 _tokenId) {
        _nftAddress = loans[_loanId].nftAddressArray[_nftItemId];
        _tokenId = loans[_loanId].nftTokenIdArray[_nftItemId];
    }

    function setSettings(
        address _feeTo,
        uint256 _lateFee,
        uint256 _penaltyFee,
        address _salesManager,
        address _assetManager
    ) external onlySuperOwner {
        require(_feeTo != address(0) && _salesManager != address(0) && _assetManager != address(0), "TribeOne: ZERO address");
        require(_lateFee <= 5 && penaltyFee <= 50, "TribeOne: Exceeded fee limit");
        feeTo = _feeTo;
        lateFee = _lateFee;
        penaltyFee = _penaltyFee;
        salesManager = _salesManager;
        assetManager = _assetManager;
        emit SettingsUpdate(_feeTo, _lateFee, _penaltyFee, _salesManager, assetManager);
    }

    /**
     * @dev _fundAmount shoud be amount in loan currency, and _collateralAmount should be in collateral currency
     */
    function createLoan(
        uint16[] calldata _loanRules, // tenor, LTV, interest, 10000 - 100% to use array - avoid stack too deep
        address[] calldata _currencies, // _loanCurrency, _collateralCurrency, address(0) is native coin
        address[] calldata nftAddressArray,
        uint256[] calldata _amounts, // _fundAmount, _collateralAmount _fundAmount is the amount of _collateral in _loanAsset such as ETH
        uint256[] calldata nftTokenIdArray,
        TribeOneHelper.TokenType[] memory nftTokenTypeArray
    ) external payable {
        require(_loanRules.length == 3 && _amounts.length == 2 && _currencies.length == 2, "TribeOne: Invalid parameter");
        uint16 tenor = _loanRules[0];
        uint16 LTV = _loanRules[1];
        uint16 interest = _loanRules[2];
        require(_loanRules[1] > 0, "TribeOne: LTV should not be ZERO");
        require(_loanRules[0] > 0, "TribeOne: Loan must have at least 1 installment");
        require(nftAddressArray.length > 0, "TribeOne: Loan must have at least 1 NFT");
        address _collateralCurrency = _currencies[1];
        address _loanCurrency = _currencies[0];
        require(IAssetManager(assetManager).isAvailableLoanAsset(_loanCurrency), "TribeOne: Loan asset is not available");
        require(
            IAssetManager(assetManager).isAvailableCollateralAsset(_collateralCurrency),
            "TribeOne: Collateral asset is not available"
        );

        require(
            nftAddressArray.length == nftTokenIdArray.length && nftTokenIdArray.length == nftTokenTypeArray.length,
            "TribeOne: NFT provided informations are missing or incomplete"
        );

        loanIds.increment();
        uint256 loanID = loanIds.current();

        // Transfer Collateral from sender to contract
        uint256 _fundAmount = _amounts[0];
        uint256 _collateralAmount = _amounts[1];

        // Transfer collateral to TribeOne
        if (_collateralCurrency == address(0)) {
            require(msg.value >= _collateralAmount, "TribeOne: Insufficient collateral amount");
            if (msg.value > _collateralAmount) {
                TribeOneHelper.safeTransferETH(msg.sender, msg.value - _collateralAmount);
            }
        } else {
            require(msg.value == 0, "TribeOne: ERC20 collateral");
            TribeOneHelper.safeTransferFrom(_collateralCurrency, _msgSender(), address(this), _collateralAmount);
        }

        loans[loanID].nftAddressArray = nftAddressArray;
        loans[loanID].borrower = _msgSender();
        loans[loanID].loanAsset = Asset({currency: _loanCurrency, amount: 0});
        loans[loanID].collateralAsset = Asset({currency: _collateralCurrency, amount: _collateralAmount});
        loans[loanID].loanRules = LoanRules({tenor: tenor, LTV: LTV, interest: interest});
        loans[loanID].nftTokenIdArray = nftTokenIdArray;
        loans[loanID].fundAmount = _fundAmount;

        loans[loanID].status = Status.LISTED;
        loans[loanID].nftTokenTypeArray = nftTokenTypeArray;

        emit LoanCreated(loanID, msg.sender);
    }

    function approveLoan(
        uint256 _loanId,
        uint256 _amount,
        address _agent
    ) external override onlyOwner nonReentrant {
        Loan storage _loan = loans[_loanId];
        require(_loan.status == Status.LISTED, "TribeOne: Invalid request");
        require(_agent != address(0), "TribeOne: ZERO address");

        uint256 _fundAmount = _loan.fundAmount;
        uint256 _LTV = _loan.loanRules.LTV;

        uint256 expectedPrice = TribeOneHelper.getExpectedPrice(_fundAmount, _LTV, MAX_SLIPPAGE);
        require(_amount <= expectedPrice, "TribeOne: Invalid amount");
        // Loan should be rejected when requested loan amount is less than fund amount because of some issues such as big fluctuation in marketplace
        if (_amount <= _fundAmount) {
            _loan.status = Status.REJECTED;
            returnColleteral(_loanId);
            emit LoanRejected(_loanId, _agent);
        } else {
            if (!isAdmin(msg.sender)) {
                require(
                    IAssetManager(assetManager).isValidAutomaticLoan(_loan.loanAsset.currency, _amount),
                    "TribeOne: Exceeded loan limit"
                );
            }

            _loan.status = Status.APPROVED;
            address _token = _loan.loanAsset.currency;

            _loan.loanAsset.amount = _amount - _loan.fundAmount;

            if (_token == address(0)) {
                IAssetManager(assetManager).requestETH(_agent, _amount);
            } else {
                IAssetManager(assetManager).requestToken(_agent, _token, _amount);
            }

            emit LoanApproved(_loanId, _agent, _token, _amount);
        }
    }

    /**
     * @dev _loanId: loanId, _accepted: order to Partner is succeeded or not
     * loan will be back to TribeOne if accepted is false
     */
    function relayNFT(
        uint256 _loanId,
        address _agent,
        bool _accepted
    ) external payable override onlyOwner nonReentrant {
        Loan storage _loan = loans[_loanId];
        require(_loan.status == Status.APPROVED, "TribeOne: Not approved loan");
        require(_agent != address(0), "TribeOne: ZERO address");
        if (_accepted) {
            uint256 len = _loan.nftAddressArray.length;
            for (uint256 ii = 0; ii < len; ii++) {
                TribeOneHelper.safeTransferNFT(
                    _loan.nftAddressArray[ii],
                    _agent,
                    address(this),
                    _loan.nftTokenTypeArray[ii],
                    _loan.nftTokenIdArray[ii]
                );
            }

            _loan.status = Status.LOANACTIVED;
            _loan.loanStart = block.timestamp;
            // user can not get back collateral in this case, we transfer collateral to AssetManager
            address _currency = _loan.collateralAsset.currency;
            uint256 _amount = _loan.collateralAsset.amount;
            // TribeOneHelper.safeTransferAsset(_currency, assetManager, _amount);
            if (_currency == address(0)) {
                IAssetManager(assetManager).collectInstallment{value: _amount}(
                    _currency,
                    _amount,
                    _loan.loanRules.interest,
                    true
                );
            } else {
                IAssetManager(assetManager).collectInstallment(_currency, _amount, _loan.loanRules.interest, true);
            }
        } else {
            _loan.status = Status.FAILED;
            // refund loan
            // in the case when loan currency is ETH, loan amount should be fund back from agent to TribeOne AssetNanager
            address _token = _loan.loanAsset.currency;
            uint256 _amount = _loan.loanAsset.amount + _loan.fundAmount;
            if (_token == address(0)) {
                require(msg.value >= _amount, "TribeOne: Less than loan amount");
                if (msg.value > _amount) {
                    TribeOneHelper.safeTransferETH(_agent, msg.value - _amount);
                }
                IAssetManager(assetManager).collectInstallment{value: _amount}(_token, _amount, _loan.loanRules.interest, true);
            } else {
                TribeOneHelper.safeTransferFrom(_token, _agent, address(this), _amount);
                IAssetManager(assetManager).collectInstallment(_token, _amount, _loan.loanRules.interest, true);
            }

            returnColleteral(_loanId);
        }

        emit NFTRelayed(_loanId, _agent, _accepted);
    }

    function payInstallment(uint256 _loanId, uint256 _amount) external payable nonReentrant {
        Loan storage _loan = loans[_loanId];
        require(_loan.status == Status.LOANACTIVED || _loan.status == Status.DEFAULTED, "TribeOne: Invalid status");
        uint256 expectedNr = expectedNrOfPayments(_loanId);

        address _loanCurrency = _loan.loanAsset.currency;
        if (_loanCurrency == address(0)) {
            _amount = msg.value;
        }

        uint256 paidAmount = _loan.paidAmount;
        uint256 _totalDebt = totalDebt(_loanId); // loan + interest
        {
            uint256 expectedAmount = (_totalDebt * expectedNr) / _loan.loanRules.tenor;
            require(paidAmount + _amount >= expectedAmount, "TribeOne: Insufficient Amount");
            // out of rule, penalty
            _updatePenalty(_loanId);
        }

        // Transfer asset from msg.sender to AssetManager contract
        uint256 dust;
        if (paidAmount + _amount > _totalDebt) {
            dust = paidAmount + _amount - _totalDebt;
        }
        _amount -= dust;
        // NOTE - don't merge two conditions
        // All user payments will go to AssetManager contract
        if (_loanCurrency == address(0)) {
            if (dust > 0) {
                TribeOneHelper.safeTransferETH(_msgSender(), dust);
            }
            // TribeOneHelper.safeTransferETH(assetManager, _amount);
            IAssetManager(assetManager).collectInstallment{value: _amount}(
                _loanCurrency,
                _amount,
                _loan.loanRules.interest,
                false
            );
        } else {
            TribeOneHelper.safeTransferFrom(_loanCurrency, _msgSender(), address(this), _amount);
            IAssetManager(assetManager).collectInstallment(_loanCurrency, _amount, _loan.loanRules.interest, false);
        }

        _loan.paidAmount += _amount;
        uint256 passedTenors = (_loan.paidAmount * _loan.loanRules.tenor) / _totalDebt;

        if (passedTenors > _loan.passedTenors) {
            _loan.passedTenors = uint8(passedTenors);
        }

        if (_loan.status == Status.DEFAULTED) {
            _loan.status = Status.LOANACTIVED;
        }

        // If user is borrower and loan is paid whole amount and he has no lateFee, give back NFT here directly
        // else borrower should call withdraw manually himself
        // We should check conditions first to avoid transaction failed
        if (paidAmount + _amount == _totalDebt) {
            _loan.status = Status.LOANPAID;
            if (_loan.borrower == _msgSender() && (_loan.nrOfPenalty == 0 || lateFee == 0)) {
                _withdrawNFT(_loanId);
            }
        }

        emit InstallmentPaid(_loanId, msg.sender, _loanCurrency, _amount);
    }

    function withdrawNFT(uint256 _loanId) external nonReentrant {
        _withdrawNFT(_loanId);
    }

    function _withdrawNFT(uint256 _loanId) private {
        Loan storage _loan = loans[_loanId];
        require(_loan.status == Status.LOANPAID, "TribeOne: Invalid status - you have still debt to pay");
        address _sender = _msgSender();
        require(_sender == _loan.borrower, "TribeOne: Forbidden");
        _loan.status = Status.WITHDRAWN;

        if (_loan.nrOfPenalty > 0 && lateFee > 0) {
            uint256 _totalLateFee = _loan.nrOfPenalty * lateFee * (10**IERC20Metadata(feeCurrency).decimals());
            TribeOneHelper.safeTransferFrom(feeCurrency, _sender, address(feeTo), _totalLateFee);
        }

        uint256 len = _loan.nftAddressArray.length;
        for (uint256 ii = 0; ii < len; ii++) {
            address _nftAddress = _loan.nftAddressArray[ii];
            uint256 _tokenId = _loan.nftTokenIdArray[ii];
            TribeOneHelper.safeTransferNFT(_nftAddress, address(this), _sender, _loan.nftTokenTypeArray[ii], _tokenId);
        }

        emit NFTWithdrew(_loanId, _sender);
    }

    function _updatePenalty(uint256 _loanId) private {
        Loan storage _loan = loans[_loanId];
        require(_loan.status == Status.LOANACTIVED || _loan.status == Status.DEFAULTED, "TribeOne: Not actived loan");
        uint256 expectedNr = expectedNrOfPayments(_loanId);
        uint256 passedTenors = _loan.passedTenors;
        if (expectedNr > passedTenors) {
            _loan.nrOfPenalty += uint8(expectedNr - passedTenors);
        }
    }

    /**
     * @dev shows loan + interest
     */
    function totalDebt(uint256 _loanId) public view returns (uint256) {
        Loan storage _loan = loans[_loanId];
        return (_loan.loanAsset.amount * (10000 + _loan.loanRules.interest)) / 10000;
    }

    /**
     *@dev when user in Tenor 2 (from tenor 1 to tenor 2, we expect at least one time payment)
     */
    function expectedNrOfPayments(uint256 _loanId) private view returns (uint256) {
        uint256 loanStart = loans[_loanId].loanStart;
        uint256 _expected = (block.timestamp - loanStart) / TENOR_UNIT;
        uint256 _tenor = loans[_loanId].loanRules.tenor;
        return _expected > _tenor ? _tenor : _expected;
    }

    function expectedLastPaymentTime(uint256 _loanId) public view returns (uint256) {
        Loan storage _loan = loans[_loanId];
        return
            _loan.passedTenors >= _loan.loanRules.tenor
                ? _loan.loanStart + TENOR_UNIT * (_loan.loanRules.tenor)
                : _loan.loanStart + TENOR_UNIT * (_loan.passedTenors + 1);
    }

    function setLoanDefaulted(uint256 _loanId) external nonReentrant {
        Loan storage _loan = loans[_loanId];
        require(_loan.status == Status.LOANACTIVED, "TribeOne: Invalid status");
        require(expectedLastPaymentTime(_loanId) < block.timestamp, "TribeOne: Not overdued date yet");

        _loan.status = Status.DEFAULTED;

        emit LoanDefaulted(_loanId);
    }

    function setLoanLiquidation(uint256 _loanId) external nonReentrant {
        Loan storage _loan = loans[_loanId];
        require(_loan.status == Status.DEFAULTED, "TribeOne: Invalid status");
        require(expectedLastPaymentTime(_loanId) + GRACE_PERIOD < block.timestamp, "TribeOne: Not overdued date yet");
        _loan.status = Status.LIQUIDATION;
        uint256 len = _loan.nftAddressArray.length;

        // Transfering NFTs first
        for (uint256 ii = 0; ii < len; ii++) {
            address _nftAddress = _loan.nftAddressArray[ii];
            uint256 _tokenId = _loan.nftTokenIdArray[ii];
            TribeOneHelper.safeTransferNFT(_nftAddress, address(this), salesManager, _loan.nftTokenTypeArray[ii], _tokenId);
        }

        emit LoanLiquidation(_loanId, salesManager);
    }

    /**
     * @dev after sold NFT set in market place, and give that fund back to TribeOne
     * Only sales manager can do this
     */
    function postLiquidation(uint256 _loanId, uint256 _amount) external payable nonReentrant {
        require(_msgSender() == salesManager, "TribeOne: Forbidden");
        Loan storage _loan = loans[_loanId];
        require(_loan.status == Status.LIQUIDATION, "TribeOne: invalid status");

        // We collect debts to our asset manager address
        address _currency = _loan.loanAsset.currency;
        _amount = _currency == address(0) ? msg.value : _amount;
        uint256 _finalDebt = finalDebtAndPenalty(_loanId);
        _finalDebt = _amount > _finalDebt ? _finalDebt : _amount;
        if (_currency == address(0)) {
            // TribeOneHelper.safeTransferETH(assetManager, _finalDebt);
            IAssetManager(assetManager).collectInstallment{value: _finalDebt}(
                _currency,
                _finalDebt,
                _loan.loanRules.interest,
                false
            );
        } else {
            TribeOneHelper.safeTransferFrom(_currency, _msgSender(), address(this), _amount);
            IAssetManager(assetManager).collectInstallment(_currency, _finalDebt, _loan.loanRules.interest, false);
        }

        _loan.status = Status.POSTLIQUIDATION;
        if (_amount > _finalDebt) {
            _loan.restAmount = _amount - _finalDebt;
        }
        _loan.postTime = block.timestamp;
        emit LoanPostLiquidation(_loanId, _amount, _finalDebt);
    }

    function finalDebtAndPenalty(uint256 _loanId) public view returns (uint256) {
        Loan storage _loan = loans[_loanId];
        uint256 paidAmount = _loan.paidAmount;
        uint256 _totalDebt = totalDebt(_loanId);
        uint256 _penalty = ((_totalDebt - paidAmount) * penaltyFee) / 1000; // 5% penalty of loan amount
        return _totalDebt + _penalty - paidAmount;
    }

    /**
     * @dev User can get back the rest money through this function, but he should pay late fee.
     */
    function getBackFund(uint256 _loanId) external {
        Loan storage _loan = loans[_loanId];
        require(_msgSender() == _loan.borrower, "TribOne: Forbidden");
        require(_loan.status == Status.POSTLIQUIDATION, "TribeOne: Invalid status");
        require(_loan.postTime + GRACE_PERIOD > block.timestamp, "TribeOne: Time over");
        uint256 _restAmount = _loan.restAmount;
        require(_restAmount > 0, "TribeOne: No amount to give back");

        if (lateFee > 0) {
            uint256 _amount = lateFee * (10**IERC20Metadata(feeCurrency).decimals()) * _loan.nrOfPenalty; // tenor late fee
            TribeOneHelper.safeTransferFrom(feeCurrency, _msgSender(), address(feeTo), _amount);
        }

        _loan.status = Status.RESTWITHDRAWN;

        address _currency = _loan.loanAsset.currency;

        if (_currency == address(0)) {
            TribeOneHelper.safeTransferETH(_msgSender(), _restAmount);
        } else {
            TribeOneHelper.safeTransfer(_currency, _msgSender(), _restAmount);
        }

        emit RestWithdrew(_loanId, _restAmount);
    }

    /**
     * @dev if user does not want to get back rest of money due to some reasons, such as gas fee...
     * we will transfer rest money to our fee address (after 14 days notification).
     * For saving gas fee, we will transfer once for the one kind of token.
     */
    function lockRestAmount(uint256[] calldata _loanIds, address _currency) external nonReentrant {
        uint256 len = _loanIds.length;
        uint256 _amount = 0;
        for (uint256 ii = 0; ii < len; ii++) {
            uint256 _loanId = _loanIds[ii];
            Loan storage _loan = loans[_loanId];
            if (
                _loan.loanAsset.currency == _currency &&
                _loan.status == Status.POSTLIQUIDATION &&
                _loan.postTime + GRACE_PERIOD <= block.timestamp
            ) {
                _amount += _loan.restAmount;
                _loan.status = Status.RESTLOCKED;
            }
        }

        TribeOneHelper.safeTransferAsset(_currency, feeTo, _amount);
    }

    function cancelLoan(uint256 _loanId) external nonReentrant {
        Loan storage _loan = loans[_loanId];
        require(_loan.borrower == _msgSender() && _loan.status == Status.LISTED, "TribeOne: Forbidden");
        _loan.status = Status.CANCELLED;
        returnColleteral(_loanId);
        emit LoanCanceled(_loanId, _msgSender());
    }

    /**
     * @dev return back collateral to borrower due to some reasons
     */
    function returnColleteral(uint256 _loanId) private {
        Loan storage _loan = loans[_loanId];
        address _currency = _loan.collateralAsset.currency;
        uint256 _amount = _loan.collateralAsset.amount;
        address _to = _loan.borrower;
        TribeOneHelper.safeTransferAsset(_currency, _to, _amount);
    }

    function setAllowanceForAssetManager(address _token) external onlySuperOwner {
        TribeOneHelper.safeApprove(_token, assetManager, type(uint256).max);
    }

    function revokeAllowanceForAssetManager(address _token) external onlySuperOwner {
        TribeOneHelper.safeApprove(_token, assetManager, 0);
    }
}
