//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./FxBaseRootTunnel.sol";
import "./NftOwnership.sol";
import "./Royalties.sol";

/// @dev This contract lives on the L1 and allows NFT owners to register NFTs that live on the L1.
/// Once ownership is verified, it will send a message up to the contracts on the L2 specifying that
/// the NFT has been registered or unregistered.
/// This is not an upgradeable contract and should not be used with a proxy.
contract RootRegistrar is FxBaseRootTunnel {
    bytes32 public constant REGISTER = keccak256("REGISTER");
    bytes32 public constant DE_REGISTER = keccak256("DE_REGISTER");

    /// @dev the address that deployed this contract is the only one that can update the fxRootTunnel
    address public deployer;

    /// @dev the address where the registry royalty is deployed
    address royaltyRegistry;

    /// @param _checkpointManager This is a well known contract deployed by matic that is used to verify messages coming from the L2 down to L1.
    /// @param _fxRoot This is a well known contract deployed by matic that will emit the events going from L1 to L2.
    /// @dev You must call setFxChildTunnel() with the ChildRegistrar address on the L2 after deployment
    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _royaltyRegistry
    ) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
        deployer = msg.sender;
        royaltyRegistry = _royaltyRegistry;
    }

    /// @dev Set fxChildTunnel if not set already
    /// Only the deploying account can update this
    /// Overrides the function in the base contract
    function setFxChildTunnel(address _fxChildTunnel) public override {
        require(deployer == msg.sender, "Only deployer");
        require(fxChildTunnel == address(0x0), "Already set");
        fxChildTunnel = _fxChildTunnel;
    }

    /// @dev Allows a NFT owner to register the NFT in the protocol on L1
    /// Once the ownership is verified a message will be sent to the Child contract
    /// on the L2 chain that will trigger a registration there.
    function registerNft(
        address nftContractAddress,
        uint256 nftId,
        address creatorAddress,
        uint256 creatorSaleBasisPoints,
        uint256 optionBits,
        string memory ipfsMetadataHash
    ) external {
        // Verify ownership
        require(
            NftOwnership._verifyOwnership(
                nftContractAddress,
                nftId,
                msg.sender
            ),
            "NFT not owned"
        );

        // Get the royalties for the creator addresses - use fallback if none set on chain
        (
            address[] memory addressesArray,
            uint256[] memory creatorBasisPointsArray
        ) = Royalties._getRoyaltyOverride(
                royaltyRegistry,
                nftContractAddress,
                nftId,
                creatorAddress,
                creatorSaleBasisPoints
            );

        // REGISTER, encode(owner, chainId, nftContractAddress, nftId, creatorAddress, optionBits, ipfsMetadataHash)
        bytes memory message = abi.encode(
            REGISTER,
            abi.encode(
                msg.sender,
                block.chainid,
                nftContractAddress,
                nftId,
                addressesArray,
                creatorBasisPointsArray,
                optionBits,
                ipfsMetadataHash
            )
        );
        _sendMessageToChild(message);
    }

    /// @dev Allows a NFT owner to de-register the NFT in the protocol on L1
    /// Once the ownership is verified a message will be sent to the Child contract
    /// on the L2 chain that will trigger a desgregistration there.
    function deRegisterNft(address nftContractAddress, uint256 nftId) external {
        // Verify ownership
        require(
            NftOwnership._verifyOwnership(
                nftContractAddress,
                nftId,
                msg.sender
            ),
            "NFT not owned"
        );

        // DERegister, encode(address owner, uint256 chainId, address nftContractAddress, uint256 nftId)
        bytes memory message = abi.encode(
            DE_REGISTER,
            abi.encode(msg.sender, block.chainid, nftContractAddress, nftId)
        );
        _sendMessageToChild(message);
    }

    /// @dev NOOP - No messages come from L2 down to L1
    function _processMessageFromChild(bytes memory data) internal override {}
}
