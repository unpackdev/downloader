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

contract WasabiBNPL is IWasabiBNPL, Ownable, IERC721Receiver, ReentrancyGuard {
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

    /// @dev Returns the option data for the given option id
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

    /// @notice Executes BNPL flow
    /// @dev BNLP flow
    ///      1. take flashloan
    ///      2. buy nft from marketplace
    ///      3. get loan from nft lending protocol
    /// @param _nftLending NFTLending contract address
    /// @param _borrowData Borrow data
    /// @param _flashLoanAmount Call value
    /// @param _marketplaceCallData List of marketplace calldata
    /// @param _signatures Signatures
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
        bool marketSuccess = executeFunctions(_marketplaceCallData);
        if (!marketSuccess) {
            revert FunctionCallFailed();
        }

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
            revert LoanNotPaid();
        }
        uint256 payout = address(this).balance - flashLoanRepayAmount;

        (bool sent, ) = payable(address(flashloan)).call{
            value: flashLoanRepayAmount
        }("");
        if (!sent) {
            revert EthTransferFailed();
        }
        if (payout > 0) {
            (sent, ) = payable(_msgSender()).call{value: payout}("");
            if (!sent) {
                revert EthTransferFailed();
            }
        }

        return optionId;
    }

    /// @notice Executes a given list of functions
    /// @param _marketplaceCallData List of marketplace calldata
    function executeFunctions(
        FunctionCallData[] memory _marketplaceCallData
    ) internal returns (bool) {
        uint256 length = _marketplaceCallData.length;
        for (uint256 i; i != length; ++i) {
            FunctionCallData memory functionCallData = _marketplaceCallData[i];
            (bool success, ) = functionCallData.to.call{
                value: functionCallData.value
            }(functionCallData.data);
            if (success == false) {
                return false;
            }
        }
        return true;
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

    /// @dev Withdraws any stuck ETH in this contract
    function withdrawETH(uint256 _amount) external payable onlyOwner {
        if (_amount > address(this).balance) {
            _amount = address(this).balance;
        }
        (bool sent, ) = payable(owner()).call{value: _amount}("");
        if (!sent) {
            revert EthTransferFailed();
        }
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

    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 /* tokenId */,
        bytes memory /* data */
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive() external payable {}

    /**
     * @dev Executes the given option id
     * @param _optionId The option id
     */
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

    /**
     * @dev Executes the given option id and sells the NFT to the market
     * @param _optionId The option id
     * @param _marketplaceCallData List of marketplace calldata
     * @param _signatures List of signatures of the marketplace call data
     */
    function executeOptionWithArbitrage(
        uint256 _optionId,
        FunctionCallData[] calldata _marketplaceCallData,
        bytes[] calldata _signatures
    ) external payable nonReentrant {
        validate(_marketplaceCallData, _signatures);
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

        uint256 initialBalance = address(this).balance;

        // 1. Get flash loan
        uint256 flashLoanRepayAmount = flashloan.borrow(
            loanDetails.repayAmount
        );

        // 2. Repay loan
        loanInfo.nftLending.functionDelegateCall(
            abi.encodeWithSelector(
                INFTLending.repay.selector,
                loanInfo.loanId,
                address(this)
            )
        );
        wasabiOption.burn(_optionId);

        // 3. Sell NFT
        bool marketSuccess = executeFunctions(_marketplaceCallData);
        if (!marketSuccess) {
            revert FunctionCallFailed();
        }

        // Withdraw any WETH received
        IWETH weth = IWETH(wethAddress);
        uint256 wethBalance = weth.balanceOf(address(this));
        if (wethBalance > 0) {
            weth.withdraw(wethBalance);
        }

        uint256 balanceChange = address(this).balance - initialBalance;

        // 4. Repay flashloan
        if (balanceChange < flashLoanRepayAmount) {
            revert LoanNotPaid();
        }
        (bool sent, ) = payable(address(flashloan)).call{
            value: flashLoanRepayAmount
        }("");
        if (!sent) {
            revert EthTransferFailed();
        }

        // 5. Give payout
        uint256 payout = balanceChange - flashLoanRepayAmount;
        if (payout > 0) {
            (sent, ) = payable(_msgSender()).call{value: payout}("");
            if (!sent) {
                revert EthTransferFailed();
            }
        }

        emit OptionExecutedWithArbitrage(_optionId, payout);
    }
}
