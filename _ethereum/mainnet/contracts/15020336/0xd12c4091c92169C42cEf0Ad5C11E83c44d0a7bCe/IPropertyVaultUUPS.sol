// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IComplianceRegistry.sol";
import "./IGnosisSafe.sol";
import "./IBridgeToken.sol";

// Allows anyone to claim a token if they exist in a merkle root.
interface IPropertyVaultUUPS {
    event ComplianceRegistryUpdated(
        IComplianceRegistry indexed oldComplianceRegistry,
        IComplianceRegistry indexed newComplianceRegistry
    );
    event TrustedIntermediaryUpdated(
        IGnosisSafe indexed oldTrustedIntermediary,
        IGnosisSafe indexed newTrustedIntermediary
    );
    event DistributorUpdated(
        IGnosisSafe indexed oldDistributor,
        IGnosisSafe indexed newDistributor
    );
    event ConctractSignatureUpdated(
        bytes indexed oldContractSignature,
        bytes indexed newContractSignature
    );
    // This event is triggered whenever a call to #setMerkleRoot succeeds.
    event MerkelRootUpdated(
        bytes32 indexed oldMerkleRoot,
        bytes32 indexed newMerkleRoot
    );
    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(
        address indexed account,
        address[] tokens,
        uint256[] amounts
    );

    // Returns the total amount that the address already claimed.
    function totalClaimedAmount(address token, address account)
        external
        view
        returns (uint256);

    function setComplianceRegistry(IComplianceRegistry complianceRegistry_)
        external;

    function complianceRegistry()
        external
        view
        returns (IComplianceRegistry);

    function totalClaimedAmounts(address[] calldata tokens_, address account_) external view returns (uint256[] memory amounts);

    function setTrustedIntermediary(IGnosisSafe trustedIntermediary_) external;

    function setDistributor(IGnosisSafe distributor_) external;

    function distributor() external view returns (IGnosisSafe);

    function trustedIntermediary() external view returns (IGnosisSafe);

    function contractSignature() external view returns (bytes memory);

    // Returns the address of the token distributed by this contract.
    // function tokens() external view returns (address []);
    // Returns the merkle root of the merkle tree containing cumulative account balances available to claim.
    function merkleRoot() external view returns (bytes32);

    // Sets the merkle root of the merkle tree containing cumulative account balances available to claim.
    function setMerkleRoot(bytes32 merkleRoot_) external;

    // Claim amounts (array) of tokens (array) to the given address. Reverts if the inputs are invalid.
    function claim(
        address account,
        address[] calldata tokens,
        uint256[] calldata cumulativeAmounts,
        bytes32 expectedMerkleRoot,
        bytes32[] calldata merkleProof
    ) external;
}
