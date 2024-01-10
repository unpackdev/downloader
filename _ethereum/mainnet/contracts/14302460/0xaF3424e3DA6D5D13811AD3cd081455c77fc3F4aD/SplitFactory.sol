pragma solidity 0.8.10;

import "./Clones.sol";

interface ISplitter {
    function initialize(address wethAddress_, bytes32 merkleRoot_)
        external
        returns (address);
}

interface ISplitFactoryEvents {
    /// @notice New Split clone deployed
    /// @param sender The address sending the deploy transaction
    /// @param clone Deployed clone address
    event SplitDeployed(address sender, address clone);
}

/// @title SplitFactory
/// @notice The `SplitFactory` contract deploys split clones. After deployment, the
/// factory calls `initialize` to set up the split metadata
/// @author MirrorXYZ
contract SplitFactory is ISplitFactoryEvents {
    /// @notice Address that holds the clone implementation
    address public immutable implementation;

    /// @notice Creates SplitFactory
    /// @param implementation_ Split implementation address
    constructor(address implementation_) {
        implementation = implementation_;
    }

    /// @notice Deploys a new split
    /// @param wethAddress_ Wrapped ether address
    /// @param merkleRoot_ Merkle root containign split allocations
    function createSplit(address wethAddress_, bytes32 merkleRoot_)
        external
        returns (address clone)
    {
        clone = Clones.cloneDeterministic(
            implementation,
            keccak256(abi.encode(merkleRoot_, msg.sender))
        );

        ISplitter(clone).initialize(wethAddress_, merkleRoot_);

        emit SplitDeployed(msg.sender, clone);
    }

    /// @notice Predicts deterministic address
    /// @param implementation_ Implementation contract address
    /// @param salt Salt generated during deployment
    function predictDeterministicAddress(address implementation_, bytes32 salt)
        external
        view
        returns (address)
    {
        return
            Clones.predictDeterministicAddress(
                implementation_,
                salt,
                address(this)
            );
    }
}
