// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "./IBaseLoan.sol";

interface IMultiSourceLoan {
    /// @param executionData Execution data.
    /// @param lender Lender address.
    /// @param borrower Address that owns the NFT and will take over the loan.
    /// @param lenderOfferSignature Signature of the offer (signed by lender).
    /// @param borrowerOfferSignature Signature of the offer (signed by borrower).
    /// @param callbackData Whether to call the afterPrincipalTransfer callback
    struct LoanExecutionData {
        IBaseLoan.ExecutionData executionData;
        address lender;
        address borrower;
        bytes lenderOfferSignature;
        bytes borrowerOfferSignature;
    }

    /// @param loanId Loan ID.
    /// @param callbackData Whether to call the afterNFTTransfer callback
    /// @param shouldDelegate Whether to delegate ownership of the NFT (avoid seaport flags).
    struct SignableRepaymentData {
        uint256 loanId;
        bytes callbackData;
        bool shouldDelegate;
    }

    /// @param loan Loan.
    /// @param borrowerLoanSignature Signature of the loan (signed by borrower).
    struct LoanRepaymentData {
        SignableRepaymentData data;
        Loan loan;
        bytes borrowerSignature;
    }

    /// @notice When a loan is initiated, there's one source, the original lender. After each refinance,
    /// a new source is created to represent the new lender, and potentially others dissapear (if a tranche
    /// is fully refinanced)
    /// @dev No need to have principal address here since it's the same across all, so it can live in the Loan.
    /// @param loanId Loan ID.
    /// @param lender Lender for this given source.
    /// @param principalAmount Principal Amount.
    /// @param accruedInterest Accrued Interest.
    /// @param startTime Start Time. Either the time at which the loan initiated / was refinanced.
    /// @param aprBps APR in basis points.
    struct Source {
        uint256 loanId;
        address lender;
        uint256 principalAmount;
        uint256 accruedInterest;
        uint256 startTime;
        uint256 aprBps;
    }

    /// @dev Principal Amount is equal to the sum of all sources principalAmount.
    /// We keep it for caching purposes. Since we are not saving this on chain but the hash,
    /// it does not have a huge impact on gas.
    /// @param borrower Borrower.
    /// @param nftCollateralTokenId NFT Collateral Token ID.
    /// @param nftCollateralAddress NFT Collateral Address.
    /// @param principalAddress Principal Address.
    /// @param principalAmount Principal Amount.
    /// @param startTime Start Time.
    /// @param duration Duration.
    /// @param source Sources
    struct Loan {
        address borrower;
        uint256 nftCollateralTokenId;
        address nftCollateralAddress;
        address principalAddress;
        uint256 principalAmount;
        uint256 startTime;
        uint256 duration;
        Source[] source;
    }

    struct RenegotiationOffer {
        uint256 renegotiationId;
        uint256 loanId;
        address lender;
        uint256 fee;
        uint256[] targetPrincipal;
        uint256 principalAmount;
        uint256 aprBps;
        uint256 expirationTime;
        uint256 duration;
    }

    /// @notice Call by the borrower when emiting a new loan.
    /// @param _executionData Loan execution data.
    /// @return loanId Loan ID.
    /// @return loan Loan.
    function emitLoan(LoanExecutionData calldata _executionData) external returns (uint256, Loan memory);

    /// @notice Refinance whole loan (leaving just one source).
    /// @param _renegotiationOffer Offer to refinance a loan.
    /// @param _loan Current loan.
    /// @param _renegotiationOfferSignature Signature of the offer.
    /// @return loanId New Loan Id, New Loan.
    function refinanceFull(
        RenegotiationOffer calldata _renegotiationOffer,
        Loan memory _loan,
        bytes calldata _renegotiationOfferSignature
    ) external returns (uint256, Loan memory);

    /// @notice Refinance a loan partially. It can only be called by the new lender
    /// (they are always a strict improvement on apr).
    /// @param _renegotiationOffer Offer to refinance a loan partially.
    /// @param _loan Current loan.
    /// @return loanId New Loan Id, New Loan.
    function refinancePartial(RenegotiationOffer calldata _renegotiationOffer, Loan memory _loan)
        external
        returns (uint256, Loan memory);

    /// @notice Repay loan. Interest is calculated pro-rata based on time. Lender is defined by nft ownership.
    /// @param _repaymentData Repayment data.
    function repayLoan(LoanRepaymentData calldata _repaymentData) external;

    /// @notice Call when a loan is past its due date.
    /// @param _loanId Loan ID.
    /// @param _loan Loan.
    /// @return Liquidation Struct of the liquidation.
    function liquidateLoan(uint256 _loanId, Loan calldata _loan) external returns (bytes memory);

    /// @return maxSources Max sources per loan.
    function getMaxSources() external view returns (uint256);

    /// @notice Update the maximum number of sources per loan.
    /// @param maxSources Maximum number of sources.
    function setMaxSources(uint256 maxSources) external;

    /// @notice Set min lock period (in BPS).
    /// @param _minLockPeriod Min lock period.
    function setMinLockPeriod(uint256 _minLockPeriod) external;

    /// @notice Get min lock period (in BPS).
    /// @return minLockPeriod Min lock period.
    function getMinLockPeriod() external view returns (uint256);

    /// @notice Get delegation registry.
    /// @return delegateRegistry Delegate registry.
    function getDelegateRegistry() external view returns (address);

    /// @notice Update delegation registry.
    /// @param _newDelegationRegistry Delegation registry.
    function setDelegateRegistry(address _newDelegationRegistry) external;

    /// @notice Delegate ownership.
    /// @param _loanId Loan ID.
    /// @param _loan Loan.
    /// @param _rights Delegation Rights. Empty for all.
    /// @param _delegate Delegate address.
    /// @param _value True if delegate, false if undelegate.
    function delegate(uint256 _loanId, Loan calldata _loan, address _delegate, bytes32 _rights, bool _value) external;

    /// @notice Anyone can reveke a delegation on an NFT that's no longer in escrow.
    /// @param _delegate Delegate address.
    /// @param _collection Collection address.
    /// @param _tokenId Token ID.
    function revokeDelegate(address _delegate, address _collection, uint256 _tokenId) external;

    /// @notice Get Flash Action Contract.
    /// @return flashActionContract Flash Action Contract.
    function getFlashActionContract() external view returns (address);

    /// @notice Update Flash Action Contract.
    /// @param _newFlashActionContract Flash Action Contract.
    function setFlashActionContract(address _newFlashActionContract) external;

    /// @notice Get Loan Hash.
    /// @param _loanId Loan ID.
    /// @return loanHash Loan Hash.
    function getLoanHash(uint256 _loanId) external view returns (bytes32);

    /// @notice Transfer NFT to the flash action contract (expected use cases here are for airdrops and similar scenarios).
    /// The flash action contract would implement specific interactions with given contracts.
    /// Only the the borrower can call this function for a given loan. By the end of the transaction, the NFT must have
    /// been returned to escrow.
    /// @param _loanId Loan ID.
    /// @param _loan Loan.
    /// @param _target Target address for the flash action contract to interact with.
    /// @param _data Data to be passed to be passed to the ultimate contract.
    function executeFlashAction(uint256 _loanId, Loan calldata _loan, address _target, bytes calldata _data) external;

    /// @notice Called by the liquidator for accounting purposes.
    /// @param _loanId The id of the loan.
    /// @param _loan The loan object.
    function loanLiquidated(uint256 _loanId, Loan calldata _loan) external;
}
