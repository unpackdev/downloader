// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./IObservability.sol";

/**
 * @title Observability
 * @author highlight.xyz
 * @notice Highlight Observability
 * @dev Singleton to coalesce select Highlight protocol events
 */
contract Observability is IObservability {
    /**
     * @notice See {IObservability-emitMinterRegistrationChanged}
     */
    function emitMinterRegistrationChanged(address minter, bool registered) external {
        emit MinterRegistrationChanged(msg.sender, minter, registered);
    }

    /**
     * @notice See {IObservability-emitGranularTokenManagersSet}
     */
    function emitGranularTokenManagersSet(uint256[] calldata _ids, address[] calldata _tokenManagers) external {
        emit GranularTokenManagersSet(msg.sender, _ids, _tokenManagers);
    }

    /**
     * @notice See {IObservability-emitGranularTokenManagersRemoved}
     */
    function emitGranularTokenManagersRemoved(uint256[] calldata _ids) external {
        emit GranularTokenManagersRemoved(msg.sender, _ids);
    }

    /**
     * @notice See {IObservability-emitDefaultTokenManagerChanged}
     */
    function emitDefaultTokenManagerChanged(address newDefaultTokenManager) external {
        emit DefaultTokenManagerChanged(msg.sender, newDefaultTokenManager);
    }

    /**
     * @notice See {IObservability-emitDefaultRoyaltySet}
     */
    function emitDefaultRoyaltySet(address recipientAddress, uint16 royaltyPercentageBPS) external {
        emit DefaultRoyaltySet(msg.sender, recipientAddress, royaltyPercentageBPS);
    }

    /**
     * @notice See {IObservability-emitGranularRoyaltiesSet}
     */
    function emitGranularRoyaltiesSet(uint256[] calldata ids, IRoyaltyManager.Royalty[] calldata _newRoyalties)
        external
    {
        emit GranularRoyaltiesSet(msg.sender, ids, _newRoyalties);
    }

    /**
     * @notice See {IObservability-emitRoyaltyManagerChanged}
     */
    function emitRoyaltyManagerChanged(address newRoyaltyManager) external {
        emit RoyaltyManagerChanged(msg.sender, newRoyaltyManager);
    }

    /**
     * @notice See {IObservability-emitMintsFrozen}
     */
    function emitMintsFrozen() external {
        emit MintsFrozen(msg.sender);
    }

    /**
     * @notice See {IObservability-emitContractMetadataSet}
     */
    function emitContractMetadataSet(
        string calldata name,
        string calldata symbol,
        string calldata contractURI
    ) external {
        emit ContractMetadataSet(msg.sender, name, symbol, contractURI);
    }

    /**
     * @notice See {IObservability-emitHashedMetadataConfigSet}
     */
    function emitHashedMetadataConfigSet(
        bytes calldata hashedURIData,
        bytes calldata hashedRotationData,
        uint256 _supply
    ) external {
        emit HashedMetadataConfigSet(msg.sender, hashedURIData, hashedRotationData, _supply);
    }

    /**
     * @notice See {IObservability-emitRevealed}
     */
    function emitRevealed(bytes calldata key, uint256 newRotationKey) external {
        emit Revealed(msg.sender, key, newRotationKey);
    }

    /**
     * @notice See {IObservability-emitTokenURIsSet}
     */
    function emitTokenURIsSet(uint256[] calldata ids, string[] calldata uris) external {
        emit TokenURIsSet(msg.sender, ids, uris);
    }

    /**
     * @notice See {IObservability-emitLimitSupplySet}
     */
    function emitLimitSupplySet(uint256 newLimitSupply) external {
        emit LimitSupplySet(msg.sender, newLimitSupply);
    }

    /**
     * @notice See {IObservability-emitBaseUriSet}
     */
    function emitBaseUriSet(string calldata newBaseUri) external {
        emit BaseUriSet(msg.sender, newBaseUri);
    }

    /**
     * @notice See {IObservability-emitGenerativeSeriesDeployed}
     */
    function emitGenerativeSeriesDeployed(address contractAddress) external {
        emit GenerativeSeriesDeployed(msg.sender, contractAddress);
    }

    /**
     * @notice See {IObservability-emitSeriesDeployed}
     */
    function emitSeriesDeployed(address contractAddress) external {
        emit SeriesDeployed(msg.sender, contractAddress);
    }

    /**
     * @notice See {IObservability-emitMultipleEditionsDeployed}
     */
    function emitMultipleEditionsDeployed(address contractAddress) external {
        emit MultipleEditionsDeployed(msg.sender, contractAddress);
    }

    /**
     * @notice See {IObservability-emitSingleEditionDeployed}
     */
    function emitSingleEditionDeployed(address contractAddress) external {
        emit SingleEditionDeployed(msg.sender, contractAddress);
    }

    /**
     * @notice See {IObservability-emitTransfer}
     */
    function emitTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external {
        emit Transfer(msg.sender, from, to, tokenId);
    }
}
