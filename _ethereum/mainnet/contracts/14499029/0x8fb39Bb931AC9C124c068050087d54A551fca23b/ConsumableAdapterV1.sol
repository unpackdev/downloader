// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC165.sol";
import "./IERC721.sol";

import "./IERC721Consumable.sol";

/// @title Version 1 adapter for metaverse integrations
/// @author Daniel K Ivanov
/// @notice Adapter for metaverses that lack the necessary consumer role required to be integrated into LandWorks
/// For reference see https://eips.ethereum.org/EIPS/eip-4400
contract ConsumableAdapterV1 is IERC165, IERC721Consumable {
    /// @notice LandWorks address
    address public immutable landworks;
    /// @notice NFT Token address
    IERC721 public immutable token;

    /// @notice mapping of authorised consumer addresses
    mapping(uint256 => address) private consumers;

    constructor(address _landworks, address _token) {
        landworks = _landworks;
        token = IERC721(_token);
    }

    /// @dev See {IERC721Consumable-consumerOf}
    function consumerOf(uint256 tokenId) public view returns (address) {
        return consumers[tokenId];
    }

    /// @dev See {IERC721Consumable-changeConsumer}
    function changeConsumer(address consumer, uint256 tokenId) public {
        require(
            msg.sender == landworks,
            "ConsumableAdapter: sender is not LandWorks"
        );
        require(
            msg.sender == token.ownerOf(tokenId),
            "ConsumableAdapter: sender is not owner of tokenId"
        );

        consumers[tokenId] = consumer;
        emit ConsumerChanged(msg.sender, consumer, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return interfaceId == type(IERC721Consumable).interfaceId;
    }
}
