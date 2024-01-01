// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC721.sol";

import "./IWETH.sol";
import "./INFTLending.sol";
import "./LenderCommitmentForwarder.sol";
import "./CollateralManager.sol";
import "./ITellerV2.sol";
import "./IMarketRegistry.sol";

contract TellerLending is INFTLending {

    IWETH public immutable weth;
    ITellerV2 public immutable loansCore;

    constructor(IWETH _weth, ITellerV2 _loansCore) {
        weth = _weth;
        loansCore = _loansCore;
    }

    /// @inheritdoc INFTLending
    function getLoanDetails(
        uint256 _loanId
    ) external view returns (LoanDetails memory loanDetails) {
        CollateralManager.Collateral memory collateral = CollateralManager(loansCore.collateralManager()).getCollateralInfo(_loanId)[0];
        uint32 expiry = loansCore.calculateNextDueDate(_loanId);
        ITellerV2.Payment memory payment = loansCore.calculateAmountOwed(_loanId, expiry);

        loanDetails = LoanDetails(
            payment.principal,
            payment.principal + payment.interest,
            expiry,
            collateral._collateralAddress,
            collateral._tokenId
        );
    }

    /// @inheritdoc INFTLending
    function borrow(
        bytes calldata _inputData
    ) external payable returns (uint256 loanId) {
        address lenderCommitmentForwarder = loansCore.lenderCommitmentForwarder();
        address collateralManager = loansCore.collateralManager();

        // 1. Decode
        (
            uint256 _commitmentId,
            uint256 _principalAmount,
            uint256 _collateralAmount,
            uint256 _collateralTokenId,
            address _collateralTokenAddress,
            uint16 _interestRate,
            uint32 _loanDuration,
            uint256 _marketplaceId,
            bytes32[] memory _merkleProof
        ) = abi.decode(
            _inputData,
            (uint256, uint256, uint256, uint256, address, uint16, uint32, uint256, bytes32[]));

        // 2. Approve NFT Transfer
        IERC721 nft = IERC721(_collateralTokenAddress);
        if (!nft.isApprovedForAll(address(this), collateralManager)) {
            nft.setApprovalForAll(collateralManager, true);
        }

        // 3. Approve market forwarder
        if (!loansCore.hasApprovedMarketForwarder(_marketplaceId, lenderCommitmentForwarder, address(this))) {
            loansCore.approveMarketForwarder(_marketplaceId, lenderCommitmentForwarder);
        }

        // 4. Take out loan
        if (_merkleProof.length > 0) {
            loanId = LenderCommitmentForwarder(lenderCommitmentForwarder).acceptCommitmentWithProof(
                _commitmentId,
                _principalAmount,
                _collateralAmount,
                _collateralTokenId,
                _collateralTokenAddress,
                _interestRate,
                _loanDuration, 
                _merkleProof
            );
        } else {
            loanId = LenderCommitmentForwarder(lenderCommitmentForwarder).acceptCommitment(
                _commitmentId,
                _principalAmount,
                _collateralAmount,
                _collateralTokenId,
                _collateralTokenAddress,
                _interestRate,
                _loanDuration
            );
        }

        // 5. Unwrap WETH into ETH
        uint256 amountToBorrower = calculateAmountToBorrower(_principalAmount, _marketplaceId);
        weth.withdraw(amountToBorrower);
    }

    /// @inheritdoc INFTLending
    function repay(uint256 _loanId, address _receiver) external payable {
        address collateralManager = loansCore.collateralManager();
        // 1. Calculate amount
        ITellerV2.Payment memory payment = loansCore.calculateAmountOwed(_loanId, block.timestamp);
        uint256 repayAmount = payment.interest + payment.principal;
        CollateralManager.Collateral memory collateral = CollateralManager(collateralManager).getCollateralInfo(_loanId)[0];

        // 2. Deposit and approve WETH
        weth.deposit{value: repayAmount}();
        weth.approve(collateralManager, repayAmount);

        // 3. Repay loan
        loansCore.repayLoanFull(_loanId);

        // 4. Transfer collateral NFT to the user
        if (_receiver != address(this)) {
            IERC721(collateral._collateralAddress).safeTransferFrom(
                address(this),
                _receiver,
                collateral._tokenId
            );
        }
    }

    /// @notice Calculates the fee paid to the protocol upfront
    /// @param _principal the loan principal
    /// @param _marketId the market id
    function calculateTellerFees(uint256 _principal, uint256 _marketId) view public returns(uint256 totalFees) {
        uint256 amountToProtocol = percent(_principal, loansCore.protocolFee());
        uint256 amountToMarketplace = percent(_principal, IMarketRegistry(loansCore.marketRegistry()).getMarketplaceFee(_marketId));
        totalFees = amountToProtocol + amountToMarketplace;
    }

    /// @notice Calculates the amount received by a protocol
    /// @param _principal the loan principal
    /// @param _marketId the market id
    function calculateAmountToBorrower(uint256 _principal, uint256 _marketId) view public returns(uint256 amountToBorrower) {
        amountToBorrower = _principal - calculateTellerFees(_principal, _marketId);
    }

    function percent(uint256 value, uint16 percentage) pure internal returns (uint256) {
        return value * percentage / 10_000;
    }

    receive() external payable {}
}