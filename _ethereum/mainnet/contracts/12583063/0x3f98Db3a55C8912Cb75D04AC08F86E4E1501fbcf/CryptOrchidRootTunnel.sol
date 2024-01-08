// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <0.9.0;

import "./FxBaseRootTunnel.sol";

interface CryptOrchidParent {
    enum Stage {Unsold, Seed, Flower, Dead}

    function getTokenMetadata(uint256 tokenId)
        external
        view
        returns (
            string memory,
            uint256,
            uint256,
            Stage
        );

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);
}

/**
 * @title CryptOrchidRootTunnel
 */
contract CryptOrchidRootTunnel is FxBaseRootTunnel {
    bytes public latestData;
    address public CryptOrchidERC721;

    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _CryptOrchidERC721
    ) public FxBaseRootTunnel(_checkpointManager, _fxRoot) {
        CryptOrchidERC721 = _CryptOrchidERC721;
    }

    // Effectively a no-op, FXBaseRootTunnel requires that we implement this
    function _processMessageFromChild(bytes memory data) internal override {
        latestData = data;
    }

    function sendMessageToChild(uint256 tokenId) public {
        try CryptOrchidParent(CryptOrchidERC721).ownerOf(tokenId) returns (address owner) {
            if (owner == msg.sender) {
                (string memory species, uint256 plantedAt, uint256 waterLevel, ) = CryptOrchidParent(CryptOrchidERC721)
                    .getTokenMetadata(tokenId);

                bytes memory message = abi.encode(species, plantedAt, waterLevel, tokenId);

                _sendMessageToChild(message);
            }
        } catch {} // solhint-disable-line no-empty-blocks
    }
}
