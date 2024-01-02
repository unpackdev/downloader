// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IComplianceRegistry.sol";
import "./IGnosisSafe.sol";
import "./IBridgeToken.sol";
import "./IRealtMediator.sol";

// Allows anyone to claim a token if they exist in a merkle root.
interface IPropertyVaultUUPS {
    event ComplianceRegistryUpdated(
        IComplianceRegistry indexed oldComplianceRegistry,
        IComplianceRegistry indexed newComplianceRegistry
    );
    event TrustedIntermediaryUpdated(address newTrustedIntermediary);

    event DistributorUpdated(
        IGnosisSafe indexed oldDistributor,
        IGnosisSafe indexed newDistributor
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

    // This event is triggered whenever a call to #claimAndBridge succeeds.
    event ClaimedBridge(
        address indexed account,
        address[] tokens,
        uint256[] amounts
    );

     // This event is triggered whenever a call to #claimAndBridge succeeds.
    event MediatorUpdated(
        IRealtMediator oldMediator,
        IRealtMediator newMediator
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

    function setTrustedIntermediary(address trusted) external;

    function trustedIntermediary() external view returns (address);

    function contractSignature() external view returns (bytes memory);

    function realtMediator() external view returns (IRealtMediator);

    function setRealtMediator(IRealtMediator bridge_) external;

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

    // Claim amounts (array) of tokens (array) to the given address on the other blockchain using omni bridge. Reverts if the inputs are invalid.
    function claimAndBridge(
        address account,
        address[] calldata tokens,
        uint256[] calldata cumulativeAmounts,
        bytes32 expectedMerkleRoot,
        bytes32[] calldata merkleProof
    ) external;
}
