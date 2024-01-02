// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

interface ILenderCommitmentForwarder {
    enum CommitmentCollateralType {
        NONE, // no collateral required
        ERC20,
        ERC721,
        ERC1155,
        ERC721_ANY_ID,
        ERC1155_ANY_ID,
        ERC721_MERKLE_PROOF,
        ERC1155_MERKLE_PROOF
    }

    struct Commitment {
        uint256 maxPrincipal;
        uint32 expiration;
        uint32 maxDuration;
        uint16 minInterestRate;
        address collateralTokenAddress;
        uint256 collateralTokenId; //we use this for the MerkleRootHash  for type ERC721_MERKLE_PROOF
        uint256 maxPrincipalPerCollateralAmount;
        CommitmentCollateralType collateralTokenType;
        address lender;
        uint256 marketId;
        address principalTokenAddress;
    }

    function commitments(
        uint256 _commitmentId
    ) external view returns (Commitment memory);

    function acceptCommitmentWithRecipient(
        uint256 _commitmentId,
        uint256 _principalAmount,
        uint256 _collateralAmount,
        uint256 _collateralTokenId,
        address _collateralTokenAddress,
        address _recipient,
        uint16 _interestRate,
        uint32 _loanDuration
    ) external returns (uint256 bidId_);

    function createCommitment(
        Commitment calldata _commitment,
        address[] calldata _borrowerAddressList
    ) external returns (uint256 commitmentId_);

    function addExtension(address extension) external;

    function getCommitmentMarketId(
        uint256 _commitmentId
    ) external view returns (uint256);
}
