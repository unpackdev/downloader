// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.17;

import "./ERC1155.sol";
import "./ICreatorPassIssuer.sol";
import "./IPropHouse.sol";
import "./IManager.sol";
import "./Uint256.sol";

contract CreatorPassIssuer is ICreatorPassIssuer, ERC1155 {
    using { Uint256.toUint256 } for address;

    /// @notice The entrypoint for all house and round creation
    IPropHouse public immutable propHouse;

    /// @notice The Prop House manager contract
    IManager public immutable manager;

    /// @notice Require that the caller is a valid house
    modifier onlyHouse() {
        if (!propHouse.isHouse(msg.sender)) {
            revert ONLY_HOUSE();
        }
        _;
    }

    /// @param _propHouse The address of the Prop House entrypoint contract
    /// @param _manager The address of the Prop House manager contract
    constructor(address _propHouse, address _manager) {
        propHouse = IPropHouse(_propHouse);
        manager = IManager(_manager);
    }

    /// @notice Returns the deposit token URI for the provided token ID
    /// @param tokenId The creator pass token ID
    function uri(uint256 tokenId) external view override returns (string memory) {
        return manager.getMetadataRenderer(address(this)).tokenURI(tokenId);
    }

    /// @notice Determine if the provided `creator` holds a pass with the id `id`
    /// @param creator The creator address
    /// @param id The house ID
    function holdsPass(address creator, uint256 id) public view returns (bool) {
        return balanceOf[creator][id] != 0;
    }

    /// @notice Revert if the passed `creator` does not hold a pass with the id `id`
    /// @param creator The creator address
    /// @param id The house ID
    function requirePass(address creator, uint256 id) external view {
        if (!holdsPass(creator, id)) {
            revert CREATOR_HOLDS_NO_PASS();
        }
    }

    /// @notice Issue one or more round creator passes to the provided `creator`
    /// @param creator The address who will receive the round creator token(s)
    /// @param amount The amount of creator passes to issue
    /// @dev This function is only callable by valid houses
    function issueCreatorPassesTo(address creator, uint256 amount) external onlyHouse {
        _mint(creator, _callingHouseId(), amount, new bytes(0));
    }

    /// @notice Revoke one or more round creator passes from the provided `creator`
    /// @param creator The address to revoke the creator pass(es) from
    /// @param amount The amount of creator passes to revoke
    /// @dev This function is only callable by valid houses
    function revokeCreatorPassesFrom(address creator, uint256 amount) external onlyHouse {
        _burn(creator, _callingHouseId(), amount);
    }

    /// @notice Issue one or more round creator passes to many `creators`
    /// @param creators The addresses who will receive the round creator token(s)
    /// @param amounts The amount of creator passes to issue to each creator
    /// @dev This function is only callable by valid houses
    function issueCreatorPassesToMany(address[] calldata creators, uint256[] calldata amounts) external onlyHouse {
        uint256 creatorCount = creators.length;
        if (creatorCount != amounts.length) {
            revert LENGTH_MISMATCH();
        }

        uint256 id = _callingHouseId();
        for (uint256 i = 0; i < creatorCount; ) {
            _mint(creators[i], id, amounts[i], new bytes(0));

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Revoke one or more round creator passes from many `creators`
    /// @param creators The addresses to revoke the creator pass(es) from
    /// @param amounts The amount of creator passes to revoke from each creator
    /// @dev This function is only callable by valid houses
    function revokeCreatorPassesFromMany(address[] calldata creators, uint256[] calldata amounts) external onlyHouse {
        uint256 creatorCount = creators.length;
        if (creatorCount != amounts.length) {
            revert LENGTH_MISMATCH();
        }

        uint256 id = _callingHouseId();
        for (uint256 i = 0; i < creatorCount; ) {
            _burn(creators[i], id, amounts[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Return the ID of the calling house
    function _callingHouseId() internal view returns (uint256) {
        return msg.sender.toUint256();
    }
}
