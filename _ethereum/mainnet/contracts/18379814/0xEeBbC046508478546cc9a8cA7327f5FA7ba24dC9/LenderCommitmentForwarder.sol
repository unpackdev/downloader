// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface LenderCommitmentForwarder {
    /**
     * @notice Accept the commitment to submitBid and acceptBid using the funds
     * @dev LoanDuration must be longer than the market payment cycle
     * @param _commitmentId The id of the commitment being accepted.
     * @param _principalAmount The amount of currency to borrow for the loan.
     * @param _collateralAmount The amount of collateral to use for the loan.
     * @param _collateralTokenId The tokenId of collateral to use for the loan if ERC721 or ERC1155.
     * @param _collateralTokenAddress The contract address to use for the loan collateral tokens.
     * @param _interestRate The interest rate APY to use for the loan in basis points.
     * @param _loanDuration The overall duration for the loan.  Must be longer than market payment cycle duration.
     * @return bidId The ID of the loan that was created on TellerV2
     */
    function acceptCommitment(
        uint256 _commitmentId,
        uint256 _principalAmount,
        uint256 _collateralAmount,
        uint256 _collateralTokenId,
        address _collateralTokenAddress,
        uint16 _interestRate,
        uint32 _loanDuration
    ) external returns (uint256 bidId);

    /**
     * @notice Accept the commitment to submitBid and acceptBid using the funds
     * @dev LoanDuration must be longer than the market payment cycle
     * @param _commitmentId The id of the commitment being accepted.
     * @param _principalAmount The amount of currency to borrow for the loan.
     * @param _collateralAmount The amount of collateral to use for the loan.
     * @param _collateralTokenId The tokenId of collateral to use for the loan if ERC721 or ERC1155.
     * @param _collateralTokenAddress The contract address to use for the loan collateral tokens.
     * @param _interestRate The interest rate APY to use for the loan in basis points.
     * @param _loanDuration The overall duration for the loan.  Must be longer than market payment cycle duration.
     * @param _merkleProof An array of bytes32 which are the roots down the merkle tree, the merkle proof.
     * @return bidId The ID of the loan that was created on TellerV2
     */
    function acceptCommitmentWithProof(
        uint256 _commitmentId,
        uint256 _principalAmount,
        uint256 _collateralAmount,
        uint256 _collateralTokenId,
        address _collateralTokenAddress,
        uint16 _interestRate,
        uint32 _loanDuration,
        bytes32[] calldata _merkleProof
    ) external returns (uint256 bidId);
}