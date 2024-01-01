// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "./Owned.sol";
import "./ERC721.sol";
import "./WETH.sol";
import "./SafeTransferLib.sol";

import "./IReservoir.sol";
import "./ILeverage.sol";
import "./ILoanCallback.sol";
import "./ICryptoPunksMarket.sol";
import "./IWrappedPunk.sol";
import "./MultiSourceLoan.sol";
import "./AddressManager.sol";
import "./InputChecker.sol";

contract Leverage is ILeverage, ILoanCallback, InputChecker, Owned, ERC721TokenReceiver {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for WETH;

    AddressManager private immutable _marketplaceContractsAddressManager;
    WETH private immutable _weth;

    address private _pendingMultiSourceLoanAddress;
    address private _pendingSeaportAddress;

    MultiSourceLoan private _multiSourceLoan;
    ICryptoPunksMarket private immutable _punkMarket;
    IWrappedPunk private immutable _wrappedPunk;
    address private immutable _punkProxy;
    address private _seaport;

    event BNPLLoansStarted(uint256[] _loanIds);
    event SellAndRepayExecuted(uint256[] _loanIds);
    event MultiSourceLoanPendingUpdate(address _newAddress);
    event MultiSourceLoanUpdated(address _newAddress);
    event SeaportPendingUpdate(address _newAddress);
    event SeaportUpdated(address _newAddress);

    error MarketplaceAddressNotWhitelisted();
    error OnlyWethSupportedError();
    error OnlyMultiSourceLoanError();
    error InvalidAddressUpdateError();
    error CouldNotReturnEthError();

    constructor(
        address _multiSourceLoanAddress,
        address _marketplaceContracts,
        address payable _wethAddress,
        address payable _punkMarketAddress,
        address payable _wrappedPunkAddress,
        address payable _seaportAddress
    ) Owned(tx.origin) {
        _checkAddressNotZero(_multiSourceLoanAddress);
        _checkAddressNotZero(_marketplaceContracts);
        _checkAddressNotZero(_wethAddress);
        _checkAddressNotZero(_punkMarketAddress);
        _checkAddressNotZero(_wrappedPunkAddress);
        _checkAddressNotZero(_seaportAddress);

        _multiSourceLoan = MultiSourceLoan(_multiSourceLoanAddress);
        _marketplaceContractsAddressManager = AddressManager(_marketplaceContracts);
        _weth = WETH(_wethAddress);
        _punkMarket = ICryptoPunksMarket(_punkMarketAddress);
        _wrappedPunk = IWrappedPunk(_wrappedPunkAddress);
        _seaport = _seaportAddress;

        _wrappedPunk.registerProxy();
        _punkProxy = _wrappedPunk.proxyInfo(address(this));
    }

    modifier onlyMultiSourceLoan() {
        if (msg.sender != address(_multiSourceLoan)) {
            revert OnlyMultiSourceLoanError();
        }
        _;
    }

    /// @inheritdoc ILeverage
    /// @dev Buy calls emit loan -> Before trying to transfer the NFT but after transfering the principal
    /// emitLoan will call the afterPrincipalTransfer Hook, which will execute the purchase.
    function buy(bytes[] calldata _executionData)
        external
        payable
        returns (uint256[] memory, IMultiSourceLoan.Loan[] memory)
    {
        bytes[] memory encodedOutput = _multiSourceLoan.multicall(_executionData);
        uint256[] memory loanIds = new uint256[](encodedOutput.length);
        IMultiSourceLoan.Loan[] memory loans = new IMultiSourceLoan.Loan[](encodedOutput.length);
        for (uint256 i; i < encodedOutput.length;) {
            (loanIds[i], loans[i]) = abi.decode(encodedOutput[i], (uint256, IMultiSourceLoan.Loan));
            unchecked {
                ++i;
            }
        }

        /// Return any remaining funds to sender.
        uint256 remainingBalance = address(this).balance;
        if (remainingBalance > 0) {
            (bool success,) = payable(msg.sender).call{value: remainingBalance}("");
            if (!success) {
                revert CouldNotReturnEthError();
            }
        }
        emit BNPLLoansStarted(loanIds);
        return (loanIds, loans);
    }

    /// @dev Similar to buy. Hook is called after the NFT transfer but before transfering WETH for repayment.
    /// @inheritdoc ILeverage
    function sell(bytes[] calldata _executionData) external {
        _multiSourceLoan.multicall(_executionData);
        uint256[] memory loanIds = new uint256[](_executionData.length);
        for (uint256 i = 0; i < _executionData.length;) {
            (IMultiSourceLoan.LoanRepaymentData memory _repaymentData) =
                abi.decode(_executionData[i][4:], (IMultiSourceLoan.LoanRepaymentData));
            loanIds[i] = _repaymentData.data.loanId;
            unchecked {
                ++i;
            }
        }
        emit SellAndRepayExecuted(loanIds);
    }

    /// @inheritdoc ILoanCallback
    function afterPrincipalTransfer(IMultiSourceLoan.Loan memory _loan, uint256 _fee, bytes calldata _executionData)
        external
        onlyMultiSourceLoan
        returns (bytes4)
    {
        IReservoir.ExecutionInfo memory executionInfo = abi.decode(_executionData, (IReservoir.ExecutionInfo));
        if (!_marketplaceContractsAddressManager.isWhitelisted(executionInfo.module)) {
            revert MarketplaceAddressNotWhitelisted();
        }
        if (_loan.principalAddress != address(_weth)) {
            revert OnlyWethSupportedError();
        }
        uint256 borrowed = _loan.principalAmount - _fee;
        /// @dev Get WETH from the borrower and unwrap it since listings expect native ETH.
        _weth.safeTransferFrom(_loan.borrower, address(this), borrowed);
        _weth.withdraw(borrowed);

        (bool success,) = executionInfo.module.call{value: executionInfo.value}(executionInfo.data);
        if (!success) {
            revert InvalidCallbackError();
        }
        /// @dev If it's seaport, we use the matchOrder method to avoid extra transfers. Note that calling fullfilment on seaport
        /// will fail on this contract.
        if (executionInfo.module == address(_punkMarket)) {
            /// @dev Wrap punk and transfer it to the borrower (loan is in Wrapped Punks).
            _punkMarket.transferPunk(address(_punkProxy), _loan.nftCollateralTokenId);
            _wrappedPunk.mint(_loan.nftCollateralTokenId);
            _wrappedPunk.transferFrom(address(this), _loan.borrower, _loan.nftCollateralTokenId);
        } else if (executionInfo.module != _seaport) {
            ERC721(_loan.nftCollateralAddress).transferFrom(address(this), _loan.borrower, _loan.nftCollateralTokenId);
        }
        return this.afterPrincipalTransfer.selector;
    }

    /// @inheritdoc ILoanCallback
    /// @dev See notes for `afterPrincipalTransfer`.
    function afterNFTTransfer(IMultiSourceLoan.Loan memory _loan, bytes calldata _executionData)
        external
        onlyMultiSourceLoan
        returns (bytes4)
    {
        IReservoir.ExecutionInfo memory executionInfo = abi.decode(_executionData, (IReservoir.ExecutionInfo));
        if (!_marketplaceContractsAddressManager.isWhitelisted(executionInfo.module)) {
            revert MarketplaceAddressNotWhitelisted();
        }
        bool success;
        /// @dev Similar to `afterPrincipalTransfer`, we use the matchOrder method to avoid extra transfers.
        /// Note that calling fullfilment on seaport will fail on this contract.
        if (executionInfo.module == address(_punkMarket)) {
            /// @dev Unwrap punk
            _wrappedPunk.transferFrom(_loan.borrower, address(this), _loan.nftCollateralTokenId);
            _wrappedPunk.burn(_loan.nftCollateralTokenId);

            /// @dev Execute sell, claim ETH from the contract and wrap it before sending it to the borrower.
            (success,) = executionInfo.module.call(executionInfo.data);
            _punkMarket.withdraw();
            uint256 balance = address(this).balance;
            _weth.deposit{value: balance}();
            /// @dev Not using executionInfo.value to avoid capital remaining here.
            /// This costs extra gas but was suggested by QS.
            _weth.safeTransfer(_loan.borrower, balance);
        } else if (executionInfo.module == _seaport) {
            (success,) = executionInfo.module.call(executionInfo.data);
        } else {
            ERC721 collection = ERC721(_loan.nftCollateralAddress);
            collection.transferFrom(_loan.borrower, address(this), _loan.nftCollateralTokenId);
            collection.approve(executionInfo.module, _loan.nftCollateralTokenId);
            (success,) = executionInfo.module.call(executionInfo.data);
            ERC20 asset = ERC20(_loan.principalAddress);
            uint256 balance = asset.balanceOf(address(this));
            /// @dev Not using executionInfo.value to avoid capital remaining here.
            /// This costs extra gas but was suggested by QS.
            asset.safeTransfer(_loan.borrower, balance);
        }

        if (!success) {
            revert InvalidCallbackError();
        }
        return this.afterNFTTransfer.selector;
    }

    /// @inheritdoc ILeverage
    function updateMultiSourceLoanAddressFirst(address _newAddress) external onlyOwner {
        _checkAddressNotZero(_newAddress);

        _pendingMultiSourceLoanAddress = _newAddress;

        emit MultiSourceLoanPendingUpdate(_newAddress);
    }

    /// @inheritdoc ILeverage
    function finalUpdateMultiSourceLoanAddress(address _newAddress) external onlyOwner {
        if (_pendingMultiSourceLoanAddress != _newAddress) {
            revert InvalidAddressUpdateError();
        }

        _multiSourceLoan = MultiSourceLoan(_pendingMultiSourceLoanAddress);
        _pendingMultiSourceLoanAddress = address(0);

        emit MultiSourceLoanUpdated(_pendingMultiSourceLoanAddress);
    }

    /// @inheritdoc ILeverage
    function getMultiSourceLoanAddress() external view override returns (address) {
        return address(_multiSourceLoan);
    }

    /// @inheritdoc ILeverage
    function updateSeaportAddressFirst(address _newAddress) external onlyOwner {
        _checkAddressNotZero(_newAddress);

        _pendingSeaportAddress = _newAddress;

        emit SeaportPendingUpdate(_newAddress);
    }

    /// @inheritdoc ILeverage
    function finalUpdateSeaportAddress(address _newAddress) external onlyOwner {
        if (_pendingSeaportAddress != _newAddress) {
            revert InvalidAddressUpdateError();
        }

        _seaport = _newAddress;
        _pendingSeaportAddress = address(0);

        emit SeaportUpdated(_newAddress);
    }

    /// @inheritdoc ILeverage
    function getSeaportAddress() external view override returns (address) {
        return _seaport;
    }

    fallback() external payable {}

    receive() external payable {}
}
