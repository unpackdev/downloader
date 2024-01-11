// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./ERC721Holder.sol";
import "./ERC1155Holder.sol";
import "./EnumerableSet.sol";
import "./ITribeOne.sol";
import "./IAssetManager.sol";
import "./IBaseRentAdapter.sol";
import "./Ownable.sol";
import "./TribeOneHelper.sol";
import "./DataTypes.sol";

contract TribeOne is ERC721Holder, ERC1155Holder, ITribeOne, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(uint256 => DataTypes.Loan) private _loans; // loanId => Loan
    Counters.Counter public loanIds; // loanId is from No.1
    // uint public loanLength;
    uint256 public constant MAX_SLIPPAGE = 500; // 5%
    uint256 public constant TENOR_UNIT = 4 weeks; // installment should be pay at least in every 4 weeks
    uint256 public constant GRACE_PERIOD = 14 days; // 2 weeks

    mapping(uint256 => address) private _loanRents; // loanId => rentAdapter
    EnumerableSet.AddressSet rentAdaptersSet;

    /**
     * @dev It's for only testnet
     */
    // uint256 public TENOR_UNIT = 7 minutes;
    // uint256 public GRACE_PERIOD = 3 minutes;

    address public salesManager;
    address public assetManager;
    address public feeTo;
    address public immutable feeCurrency; // stable coin such as USDC, late fee $5
    uint256 public lateFee; // we will set it 5 USD for each tenor late
    uint256 public penaltyFee; // we will set it 5% in the future - 1000 = 100%

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
            "T1: ZERO address"
        );
        salesManager = _salesManager;
        assetManager = _assetManager;
        feeTo = _feeTo;
        feeCurrency = _feeCurrency;

        transferOwnership(_multiSigWallet);
    }

    receive() external payable {}

    function getLoans(uint256 _loanId) external view override returns (DataTypes.Loan memory) {
        return _loans[_loanId];
    }

    function getLoanNFTItem(uint256 _loanId) external view override returns (DataTypes.NFTItem memory) {
        return _loans[_loanId].nftItem;
    }

    function getLoanAsset(uint256 _loanId) external view override returns (uint256, address) {
        return (_loans[_loanId].loanAsset.amount, _loans[_loanId].loanAsset.currency);
    }

    function getCollateralAsset(uint256 _loanId) external view override returns (uint256, address) {
        return (_loans[_loanId].collateralAsset.amount, _loans[_loanId].collateralAsset.currency);
    }

    function getLoanRent(uint256 _loanId) external view override returns (address) {
        return _loanRents[_loanId];
    }

    function addRentAdapter(address _adapter) external onlySuperOwner {
        require(_adapter != address(0) && !rentAdaptersSet.contains(_adapter), "ZERO ADDRESS or already in adapter list");
        rentAdaptersSet.add(_adapter);
    }

    function removeRentAdapter(address _adapter) external onlySuperOwner {
        require(rentAdaptersSet.contains(_adapter), "Not avaialbe adapter");
        rentAdaptersSet.remove(_adapter);
    }

    function setSettings(
        address _feeTo,
        uint256 _lateFee,
        uint256 _penaltyFee,
        address _salesManager,
        address _assetManager
    ) external onlySuperOwner {
        require(_feeTo != address(0) && _salesManager != address(0) && _assetManager != address(0), "TribeOne: ZERO address");
        require(_lateFee <= 5 && penaltyFee <= 50, "T1: Exceeded fee limit");
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
        address nftAddress,
        bool isERC721,
        uint256[] calldata _amounts, // _fundAmount, _collateralAmount _fundAmount is the amount of _collateral in _loanAsset such as ETH
        uint256 nftTokenId
    ) external payable {
        require(_loanRules.length == 3 && _amounts.length == 2 && _currencies.length == 2, "T1: Invalid parameter");
        require(_loanRules[1] > 0 && _loanRules[1] < 10000, "T1: LTV should be greater than ZERO and less than 10000");
        require(_loanRules[0] > 0, "T1: Loan must have at least 1 installment");
        address _collateralCurrency = _currencies[1];
        address _loanCurrency = _currencies[0];
        require(IAssetManager(assetManager).isAvailableLoanAsset(_loanCurrency), "T1: Loan asset is not available");
        require(
            IAssetManager(assetManager).isAvailableCollateralAsset(_collateralCurrency),
            "T1: Collateral asset is not available"
        );

        loanIds.increment();
        uint256 loanID = loanIds.current();

        // Transfer Collateral from sender to contract
        // uint256 _fundAmount = _amounts[0];
        uint256 _collateralAmount = _amounts[1];

        // Transfer collateral to TribeOne
        if (_collateralCurrency == address(0)) {
            require(msg.value >= _collateralAmount, "T1: Insufficient collateral amount");
            if (msg.value > _collateralAmount) {
                TribeOneHelper.safeTransferETH(msg.sender, msg.value - _collateralAmount);
            }
        } else {
            require(msg.value == 0, "T1: ERC20 collateral");
            TribeOneHelper.safeTransferFrom(_collateralCurrency, _msgSender(), address(this), _collateralAmount);
        }

        _loans[loanID].borrower = _msgSender();
        _loans[loanID].loanAsset = DataTypes.Asset({currency: _loanCurrency, amount: 0});
        // _loans[loanID].loanAsset.currency = _loanCurrency;
        _loans[loanID].collateralAsset = DataTypes.Asset({currency: _collateralCurrency, amount: _collateralAmount});
        _loans[loanID].loanRules = DataTypes.LoanRules({tenor: _loanRules[0], LTV: _loanRules[1], interest: _loanRules[2]});
        _loans[loanID].fundAmount = _amounts[0];

        _loans[loanID].status = DataTypes.Status.LISTED;
        _loans[loanID].nftItem = DataTypes.NFTItem({nftAddress: nftAddress, isERC721: isERC721, nftId: nftTokenId});

        emit LoanCreated(loanID, msg.sender, nftAddress, nftTokenId, isERC721);
    }

    function approveLoan(
        uint256 _loanId,
        uint256 _amount,
        address _agent
    ) external override onlyOwner nonReentrant {
        DataTypes.Loan storage _loan = _loans[_loanId];
        require(_loan.status == DataTypes.Status.LISTED, "T1: Invalid request");
        require(_agent != address(0), "T1: ZERO address");

        uint256 _fundAmount = _loan.fundAmount;
        uint256 _LTV = _loan.loanRules.LTV;

        uint256 expectedPrice = TribeOneHelper.getExpectedPrice(_fundAmount, 10000 - _LTV, MAX_SLIPPAGE);
        require(_amount <= expectedPrice, "T1: Invalid amount");
        // Loan should be rejected when requested loan amount is less than fund amount because of some issues such as big fluctuation in marketplace
        if (_amount <= _fundAmount) {
            _loan.status = DataTypes.Status.REJECTED;
            returnColleteral(_loanId);
            emit LoanRejected(_loanId, _agent);
        } else {
            if (!isAdmin(msg.sender)) {
                require(
                    IAssetManager(assetManager).isValidAutomaticLoan(_loan.loanAsset.currency, _amount),
                    "T1: Exceeded loan limit"
                );
            }

            _loan.status = DataTypes.Status.APPROVED;
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
        DataTypes.Loan storage _loan = _loans[_loanId];
        require(_loan.status == DataTypes.Status.APPROVED, "T1: Not approved loan");
        require(_agent != address(0), "T1: ZERO address");
        if (_accepted) {
            TribeOneHelper.safeTransferNFT(
                _loan.nftItem.nftAddress,
                _agent,
                address(this),
                _loan.nftItem.isERC721,
                _loan.nftItem.nftId
            );

            _loan.status = DataTypes.Status.LOANACTIVED;
            _loan.loanStart = block.timestamp;
            // user can not get back collateral in this case, we transfer collateral to AssetManager
            address _currency = _loan.collateralAsset.currency;
            uint256 _amount = _loan.collateralAsset.amount;
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
            _loan.status = DataTypes.Status.FAILED;
            // refund loan
            // in the case when loan currency is ETH, loan amount should be fund back from agent to TribeOne AssetNanager
            address _token = _loan.loanAsset.currency;
            uint256 _amount = _loan.loanAsset.amount + _loan.fundAmount;
            if (_token == address(0)) {
                require(msg.value >= _amount, "T1: Less than loan amount");
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

    function payInstallment(uint256 _loanId, uint256 _amount) external payable override nonReentrant {
        DataTypes.Loan storage _loan = _loans[_loanId];
        require(_loan.status == DataTypes.Status.LOANACTIVED || _loan.status == DataTypes.Status.DEFAULTED, "T1: Invalid status");
        uint256 expectedNr = expectedNrOfPayments(_loanId);

        address _loanCurrency = _loan.loanAsset.currency;
        if (_loanCurrency == address(0)) {
            _amount = msg.value;
        }

        uint256 paidAmount = _loan.paidAmount;
        uint256 __totalDebt = _totalDebt(_loanId); // loan + interest
        {
            uint256 expectedAmount = (__totalDebt * expectedNr) / _loan.loanRules.tenor;
            // require(paidAmount + _amount >= expectedAmount, "T1: Insufficient Amount");
            // // out of rule, penalty
            if (paidAmount + _amount >= expectedAmount) {
                _updatePenalty(_loanId);
            }
        }

        // Transfer asset from msg.sender to AssetManager contract
        uint256 dust;
        if (paidAmount + _amount > __totalDebt) {
            dust = paidAmount + _amount - __totalDebt;
        }
        _amount -= dust;
        // NOTE - don't merge two conditions
        // All user payments will go to AssetManager contract
        if (_loanCurrency == address(0)) {
            if (dust > 0) {
                TribeOneHelper.safeTransferETH(_msgSender(), dust);
            }
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

        paidAmount += _amount;
        _loan.paidAmount = paidAmount;

        {
            uint256 passedTenors = (paidAmount * _loan.loanRules.tenor) / __totalDebt;
            if (passedTenors > _loan.passedTenors) {
                _loan.passedTenors = uint8(passedTenors);
            }
        }

        if (_loan.status == DataTypes.Status.DEFAULTED) {
            _loan.status = DataTypes.Status.LOANACTIVED;
        }

        // If user is borrower and loan is paid whole amount and he has no lateFee, give back NFT here directly
        // else borrower should call withdraw manually himself
        // We should check conditions first to avoid transaction failed
        if (paidAmount == __totalDebt) {
            _loan.status = DataTypes.Status.LOANPAID;
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
        DataTypes.Loan storage _loan = _loans[_loanId];
        require(_loan.status == DataTypes.Status.LOANPAID, "T1: Invalid status - you have still debt to pay");
        address _sender = _msgSender();
        require(_sender == _loan.borrower, "T1: Forbidden");
        _loan.status = DataTypes.Status.WITHDRAWN;

        if (_loan.nrOfPenalty > 0 && lateFee > 0) {
            uint256 _totalLateFee = _loan.nrOfPenalty * lateFee * (10**IERC20Metadata(feeCurrency).decimals());
            TribeOneHelper.safeTransferFrom(feeCurrency, _sender, address(feeTo), _totalLateFee);
        }

        TribeOneHelper.safeTransferNFT(
            _loan.nftItem.nftAddress,
            address(this),
            _sender,
            _loan.nftItem.isERC721,
            _loan.nftItem.nftId
        );

        emit NFTWithdrew(_loanId, _sender);
    }

    function _updatePenalty(uint256 _loanId) private {
        DataTypes.Loan storage _loan = _loans[_loanId];
        uint256 expectedNr = expectedNrOfPayments(_loanId);
        uint256 passedTenors = _loan.passedTenors;
        if (expectedNr > passedTenors) {
            _loan.nrOfPenalty += uint8(expectedNr - passedTenors);
        }
    }

    /**
     * @dev shows loan + interest
     */
    function totalDebt(uint256 _loanId) external view override returns (uint256) {
        return _totalDebt(_loanId);
    }

    function _totalDebt(uint256 _loanId) private view returns (uint256) {
        DataTypes.Loan storage _loan = _loans[_loanId];
        return (_loan.loanAsset.amount * (10000 + _loan.loanRules.interest)) / 10000;
    }

    /**
     *@dev when user in Tenor 2 (from tenor 1 to tenor 2, we expect at least one time payment)
     */
    function expectedNrOfPayments(uint256 _loanId) private view returns (uint256) {
        uint256 loanStart = _loans[_loanId].loanStart;
        uint256 _expected = (block.timestamp - loanStart) / TENOR_UNIT;
        uint256 _tenor = _loans[_loanId].loanRules.tenor;
        return _expected > _tenor ? _tenor : _expected;
    }

    function expectedLastPaymentTime(uint256 _loanId) public view returns (uint256) {
        DataTypes.Loan storage _loan = _loans[_loanId];
        return
            _loan.passedTenors >= _loan.loanRules.tenor
                ? _loan.loanStart + TENOR_UNIT * (_loan.loanRules.tenor)
                : _loan.loanStart + TENOR_UNIT * (_loan.passedTenors + 1);
    }

    function setLoanDefaulted(uint256 _loanId) external nonReentrant {
        DataTypes.Loan storage _loan = _loans[_loanId];
        require(_loan.status == DataTypes.Status.LOANACTIVED, "T1: Invalid status");
        require(expectedLastPaymentTime(_loanId) < block.timestamp, "T1: Not overdued date yet");

        _loan.status = DataTypes.Status.DEFAULTED;

        emit LoanDefaulted(_loanId);
    }

    function setLoanLiquidation(uint256 _loanId) external nonReentrant {
        DataTypes.Loan storage _loan = _loans[_loanId];
        require(_loan.status == DataTypes.Status.DEFAULTED, "T1: Invalid status");
        require(expectedLastPaymentTime(_loanId) + GRACE_PERIOD < block.timestamp, "T1: Not overdued date yet");
        _loan.status = DataTypes.Status.LIQUIDATION;

        TribeOneHelper.safeTransferNFT(
            _loan.nftItem.nftAddress,
            address(this),
            salesManager,
            _loan.nftItem.isERC721,
            _loan.nftItem.nftId
        );

        emit LoanLiquidation(_loanId, salesManager);
    }

    /**
     * @dev after sold NFT set in market place, and give that fund back to TribeOne
     * Only sales manager can do this
     */
    function postLiquidation(uint256 _loanId, uint256 _amount) external payable nonReentrant {
        require(_msgSender() == salesManager, "T1: Forbidden");
        DataTypes.Loan storage _loan = _loans[_loanId];
        require(_loan.status == DataTypes.Status.LIQUIDATION, "T1: invalid status");

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

        _loan.status = DataTypes.Status.POSTLIQUIDATION;
        if (_amount > _finalDebt) {
            _loan.restAmount = _amount - _finalDebt;
        }
        _loan.postTime = block.timestamp;
        emit LoanPostLiquidation(_loanId, _amount, _finalDebt);
    }

    function _currentDebt(uint256 _loanId) private view returns (uint256) {
        DataTypes.Loan storage _loan = _loans[_loanId];
        uint256 paidAmount = _loan.paidAmount;
        uint256 __totalDebt = _totalDebt(_loanId);
        return __totalDebt - paidAmount;
    }

    function currentDebt(uint256 _loanId) external view override returns (uint256) {
        return _currentDebt(_loanId);
    }

    function finalDebtAndPenalty(uint256 _loanId) public view returns (uint256) {
        DataTypes.Loan storage _loan = _loans[_loanId];
        uint256 paidAmount = _loan.paidAmount;
        uint256 __totalDebt = _totalDebt(_loanId);
        uint256 _penalty = ((__totalDebt - paidAmount) * penaltyFee) / 1000; // 5% penalty of loan amount
        return __totalDebt + _penalty - paidAmount;
    }

    /**
     * @dev User can get back the rest money through this function, but he should pay late fee.
     */
    function getBackFund(uint256 _loanId) external {
        DataTypes.Loan storage _loan = _loans[_loanId];
        require(_msgSender() == _loan.borrower, "T1: Forbidden");
        require(_loan.status == DataTypes.Status.POSTLIQUIDATION, "T1: Invalid status");
        require(_loan.postTime + GRACE_PERIOD > block.timestamp, "T1: Time over");
        uint256 _restAmount = _loan.restAmount;
        require(_restAmount > 0, "T1: No amount to give back");

        if (lateFee > 0) {
            uint256 _amount = lateFee * (10**IERC20Metadata(feeCurrency).decimals()) * _loan.nrOfPenalty; // tenor late fee
            TribeOneHelper.safeTransferFrom(feeCurrency, _msgSender(), address(feeTo), _amount);
        }

        _loan.status = DataTypes.Status.RESTWITHDRAWN;

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
            DataTypes.Loan storage _loan = _loans[_loanId];
            if (
                _loan.loanAsset.currency == _currency &&
                _loan.status == DataTypes.Status.POSTLIQUIDATION &&
                _loan.postTime + GRACE_PERIOD <= block.timestamp
            ) {
                _amount += _loan.restAmount;
                _loan.status = DataTypes.Status.RESTLOCKED;
            }
        }

        TribeOneHelper.safeTransferAsset(_currency, feeTo, _amount);
    }

    function cancelLoan(uint256 _loanId) external nonReentrant {
        DataTypes.Loan storage _loan = _loans[_loanId];
        require(_loan.borrower == _msgSender() && _loan.status == DataTypes.Status.LISTED, "T1: Forbidden");
        _loan.status = DataTypes.Status.CANCELLED;
        returnColleteral(_loanId);
        emit LoanCanceled(_loanId, _msgSender());
    }

    /**
     * @dev return back collateral to borrower due to some reasons
     */
    function returnColleteral(uint256 _loanId) private {
        DataTypes.Loan storage _loan = _loans[_loanId];
        address _currency = _loan.collateralAsset.currency;
        uint256 _amount = _loan.collateralAsset.amount;
        address _to = _loan.borrower;
        TribeOneHelper.safeTransferAsset(_currency, _to, _amount);
    }

    function listNFTForRent(uint256 loanId, address borrower) external override {
        require(rentAdaptersSet.contains(_msgSender()), "T1: Invalid caller");

        DataTypes.Loan storage loan = _loans[loanId];
        require(loan.borrower == borrower, "T1: Only borrower can list NFT for loan");
        require(_loanRents[loanId] == address(0), "T1: Already rented");
        require(loan.status == DataTypes.Status.LOANACTIVED, "T1: Invalid loan status");

        _loanRents[loanId] = _msgSender();
        TribeOneHelper.safeTransferNFT(
            loan.nftItem.nftAddress,
            address(this),
            msg.sender,
            loan.nftItem.isERC721,
            loan.nftItem.nftId
        );

        emit LoanRented(loanId, msg.sender);
    }

    function withdrawNFTFromRent(uint256 loanId) external override {
        require(_loanRents[loanId] == msg.sender, "T1: Invalid caller");

        delete _loanRents[loanId];

        TribeOneHelper.safeTransferNFT(
            _loans[loanId].nftItem.nftAddress,
            msg.sender,
            address(this),
            _loans[loanId].nftItem.isERC721,
            _loans[loanId].nftItem.nftId
        );
        emit LoanWithdrawFromRent(loanId, msg.sender);
    }

    /**
     * @dev We will use this function to withdraw NFT when we should liquidate loaned NFT
     */
    function forceWithdrawCall(uint256 loanId, bytes memory withdrawCallData) external {
        require(_loans[loanId].status == DataTypes.Status.DEFAULTED, "T1: Invalid status");
        require(expectedLastPaymentTime(loanId) + GRACE_PERIOD < block.timestamp, "T1: Not overdue yet");

        require(_loanRents[loanId] != address(0), "T1: Not rented loan");

        (bool success, ) = address(_loanRents[loanId]).call(withdrawCallData);
        require(success, "T1: Force withdraw was failed");
    }

    function isAvailableRentalAction(uint256 loanId, address user) external view override returns (bool) {
        if (_loans[loanId].borrower != user) {
            return false;
        }
        if (expectedLastPaymentTime(loanId) + GRACE_PERIOD < block.timestamp) {
            return false;
        }

        return true;
    }

    function grantAllowanceForAssetManager(address _token) external onlySuperOwner {
        TribeOneHelper.safeApprove(_token, assetManager, type(uint256).max);
    }

    function revokeAllowanceForAssetManager(address _token) external onlySuperOwner {
        TribeOneHelper.safeApprove(_token, assetManager, 0);
    }
}
