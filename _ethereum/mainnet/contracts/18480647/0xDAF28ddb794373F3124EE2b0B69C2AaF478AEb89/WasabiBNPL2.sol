// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";

import "./Signing.sol";
import "./IWETH.sol";
import "./IWasabiBNPL.sol";
import "./IWasabiOption.sol";
import "./IFlashloan.sol";
import "./ILendingAddressProvider.sol";
import "./INFTLending.sol";

contract WasabiBNPL2 is IWasabiBNPL, Ownable, IERC721Receiver, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;

    /// @notice Wasabi Option
    IWasabiOption public wasabiOption;

    /// @notice Wasabi Flashloan
    IFlashloan public flashloan;

    /// @notice Wasabi Address Provider
    ILendingAddressProvider public addressProvider;

    /// @notice Wasabi Pool Factory
    address public factory;

    /// @notice Option ID to LoanInfo mapping
    mapping(uint256 => LoanInfo) public optionToLoan;

    /// @notice
    address public wethAddress;

    /// @notice WasabiBNPL Constructor
    /// @param _wasabiOption Wasabi Option address
    /// @param _flashloan Wasabi Flashloan address
    /// @param _addressProvider Wasabi Address Provider address
    /// @param _wethAddress Wrapped ETH address
    /// @param _factory Wasabi Pool Factory address
    constructor(
        IWasabiOption _wasabiOption,
        IFlashloan _flashloan,
        ILendingAddressProvider _addressProvider,
        address _wethAddress,
        address _factory
    ) {
        wasabiOption = _wasabiOption;
        flashloan = _flashloan;
        addressProvider = _addressProvider;
        wethAddress = _wethAddress;
        factory = _factory;
    }

    /// @inheritdoc IWasabiBNPL
    function getOptionData(
        uint256 _optionId
    ) external view returns (WasabiStructs.OptionData memory optionData) {
        LoanInfo memory loanInfo = optionToLoan[_optionId];
        INFTLending.LoanDetails memory loanDetails = INFTLending(
            loanInfo.nftLending
        ).getLoanDetails(loanInfo.loanId);
        bool active = wasabiOption.ownerOf(_optionId) != address(0) &&
            loanDetails.loanExpiration > block.timestamp;

        optionData = WasabiStructs.OptionData(
            active,
            WasabiStructs.OptionType.CALL,
            loanDetails.repayAmount,
            loanDetails.loanExpiration,
            loanDetails.tokenId
        );
    }

    /// @inheritdoc IWasabiBNPL
    function bnpl(
        address _nftLending,
        bytes calldata _borrowData,
        uint256 _flashLoanAmount,
        FunctionCallData[] calldata _marketplaceCallData,
        bytes[] calldata _signatures
    ) external payable nonReentrant returns (uint256) {
        validate(_marketplaceCallData, _signatures);

        if (!addressProvider.isLending(_nftLending)) {
            revert InvalidParam();
        }

        // 1. Get flash loan
        uint256 flashLoanRepayAmount = flashloan.borrow(_flashLoanAmount);

        // 2. Buy NFT
        executeFunctions(_marketplaceCallData);

        // 3. Get loan
        bytes memory result = _nftLending.functionDelegateCall(
            abi.encodeWithSelector(INFTLending.borrow.selector, _borrowData)
        );

        uint256 loanId = abi.decode(result, (uint256));
        uint256 optionId = wasabiOption.mint(_msgSender(), factory);
        optionToLoan[optionId] = LoanInfo({
            nftLending: _nftLending,
            loanId: loanId
        });

        // 4. Repay flashloan
        if (address(this).balance < flashLoanRepayAmount) {
            revert FlashLoanNotPaid();
        }
        uint256 payout = address(this).balance - flashLoanRepayAmount;
        payETH(address(flashloan), flashLoanRepayAmount);
        if (payout > 0) {
            payETH(_msgSender(), payout);
        }

        emit OptionIssued(optionId);
        return optionId;
    }

    /// @inheritdoc IWasabiBNPL
    function executeOption(uint256 _optionId) external payable nonReentrant {
        require(
            wasabiOption.ownerOf(_optionId) == _msgSender(),
            "Only owner can exercise option"
        );

        LoanInfo storage loanInfo = optionToLoan[_optionId];
        require(loanInfo.nftLending != address(0), "Invalid Option");

        INFTLending.LoanDetails memory loanDetails = INFTLending(
            loanInfo.nftLending
        ).getLoanDetails(loanInfo.loanId);
        require(
            loanDetails.loanExpiration > block.timestamp,
            "Loan has expired"
        );
        require(
            msg.value >= loanDetails.repayAmount,
            "Insufficient repay amount supplied"
        );

        loanInfo.nftLending.functionDelegateCall(
            abi.encodeWithSelector(
                INFTLending.repay.selector,
                loanInfo.loanId,
                _msgSender()
            )
        );

        wasabiOption.burn(_optionId);
        emit OptionExecuted(_optionId);
    }

    /// @inheritdoc IWasabiBNPL
    function executeOptionWithArbitrage(
        uint256 _optionId,
        FunctionCallData[] calldata _marketplaceCallData,
        bytes[] calldata _signatures
    ) external payable nonReentrant {
        validate(_marketplaceCallData, _signatures);
        require(wasabiOption.ownerOf(_optionId) == _msgSender(), "Only owner can exercise option");

        LoanInfo storage loanInfo = optionToLoan[_optionId];
        require(loanInfo.nftLending != address(0), "Invalid Option");

        INFTLending.LoanDetails memory loanDetails = INFTLending(
            loanInfo.nftLending
        ).getLoanDetails(loanInfo.loanId);
        require(
            loanDetails.loanExpiration > block.timestamp,
            "Loan has expired"
        );

        uint256 initialBalance = address(this).balance;

        // 1. Get flash loan
        uint256 flashLoanRepayAmount = flashloan.borrow(loanDetails.repayAmount);

        // 2. Repay loan
        loanInfo.nftLending.functionDelegateCall(abi.encodeWithSelector(INFTLending.repay.selector, loanInfo.loanId, address(this)));
        wasabiOption.burn(_optionId);

        // 3. Sell NFT
        executeFunctions(_marketplaceCallData);

        // Withdraw any WETH received
        IWETH weth = IWETH(wethAddress);
        uint256 wethBalance = weth.balanceOf(address(this));
        if (wethBalance > 0) {
            weth.withdraw(wethBalance);
        }

        uint256 balanceChange = address(this).balance - initialBalance;

        // 4. Repay flashloan
        if (balanceChange < flashLoanRepayAmount) {
            revert FlashLoanNotPaid();
        }
        payETH(address(flashloan), flashLoanRepayAmount);

        // 5. Give payout
        uint256 payout = balanceChange - flashLoanRepayAmount;
        if (payout > 0) {
            payETH(_msgSender(), payout);
        }

        emit OptionExecutedWithArbitrage(_optionId, payout);
    }

    /// @inheritdoc IWasabiBNPL
    function rolloverOption(uint256 _optionId, address _nftLending, bytes calldata _borrowData) external payable nonReentrant {
        if (!addressProvider.isLending(_nftLending)) {
            revert InvalidParam();
        }
        require(wasabiOption.ownerOf(_optionId) == _msgSender(), "Only owner can rollover option");

        LoanInfo storage loanInfo = optionToLoan[_optionId];
        require(loanInfo.nftLending != address(0), "Invalid Option");

        INFTLending.LoanDetails memory loanDetails = INFTLending(loanInfo.nftLending).getLoanDetails(loanInfo.loanId);
        require(loanDetails.loanExpiration > block.timestamp,"Loan has expired");

        uint256 initialBalance = address(this).balance - msg.value;

        // 1. Get flash loan
        uint256 flashLoanRepayAmount = flashloan.borrow(loanDetails.repayAmount);

        // 2. Repay loan
        loanInfo.nftLending.functionDelegateCall(
            abi.encodeWithSelector(
                INFTLending.repay.selector, loanInfo.loanId, address(this)));
        wasabiOption.burn(_optionId);
        emit OptionExecuted(_optionId);

        // 3. Get loan
        bytes memory result = _nftLending.functionDelegateCall(
            abi.encodeWithSelector(
                INFTLending.borrow.selector, _borrowData));
        uint256 loanId = abi.decode(result, (uint256));
        uint256 newOptionId = wasabiOption.mint(_msgSender(), factory);
        optionToLoan[newOptionId] = LoanInfo({
            nftLending: _nftLending,
            loanId: loanId
        });
        
        uint256 balanceChange = address(this).balance - initialBalance;

        // 4. Repay flashloan
        if (balanceChange < flashLoanRepayAmount) {
            revert FlashLoanNotPaid();
        }
        payETH(address(flashloan), flashLoanRepayAmount);

        // 5. Give payout
        uint256 payout = balanceChange - flashLoanRepayAmount;
        if (payout > 0) {
            payETH(_msgSender(), payout);
        }

        emit OptionRolledOver(newOptionId, _optionId, payout);
    }

    // Helper Functions 

    /// @dev Withdraws any stuck ETH in this contract
    function withdrawETH(uint256 _amount) external payable onlyOwner {
        if (_amount > address(this).balance) {
            _amount = address(this).balance;
        }
        payETH(owner(), _amount);
    }

    /// @dev Withdraws any stuck ERC20 in this contract
    function withdrawERC20(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.safeTransfer(_msgSender(), _amount);
    }

    /// @dev Withdraws any stuck ERC721 in this contract
    function withdrawERC721(
        IERC721 _token,
        uint256 _tokenId
    ) external onlyOwner {
        _token.safeTransferFrom(address(this), owner(), _tokenId);
    }


    /// @notice Executes a given list of functions
    /// @param _marketplaceCallData List of marketplace calldata
    function executeFunctions(FunctionCallData[] memory _marketplaceCallData) internal {
        uint256 length = _marketplaceCallData.length;
        for (uint256 i; i != length; ++i) {
            _marketplaceCallData[i].to.functionCallWithValue(_marketplaceCallData[i].data, _marketplaceCallData[i].value);
        }
    }

    /// @notice Validates if the FunctionCallData list has been approved
    /// @param _marketplaceCallData List of marketplace calldata
    /// @param _signatures Signatures
    function validate(
        FunctionCallData[] calldata _marketplaceCallData,
        bytes[] calldata _signatures
    ) internal view {
        uint256 calldataLength = _marketplaceCallData.length;
        require(calldataLength > 0, "Need marketplace calls");
        require(calldataLength == _signatures.length, "Length is invalid");
        for (uint256 i; i != calldataLength; ++i) {
            bytes32 ethSignedMessageHash = Signing.getEthSignedMessageHash(
                getMessageHash(_marketplaceCallData[i])
            );
            require(
                Signing.recoverSigner(ethSignedMessageHash, _signatures[i]) ==
                    owner(),
                "Owner is not signer"
            );
        }
    }

    /// @notice Returns the message hash for the given _data
    function getMessageHash(
        FunctionCallData calldata _data
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_data.to, _data.value, _data.data));
    }

    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 /* tokenId */,
        bytes memory /* data */
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// Pays ETH to the target
    /// @param _target the target address
    /// @param _amount the amount to pay
    function payETH(address _target, uint256 _amount) private {
        (bool sent, ) = payable(_target).call{value: _amount}("");
        if (!sent) {
            revert EthTransferFailed();
        }
    }

    /// Receive function
    receive() external payable {}
}
