//SPDX-License-Identifier: CC-BY-NC-ND-2.5
pragma solidity 0.8.16;

import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

import "./JubiERC20BasicImpl.sol";
import "./Types.sol";

/**
 * @title Contract factory to manage ventures
 * @notice You can use this Contract to create new Ventures and Allocators
 */
contract BasicTokenCreator is OwnableUpgradeable, UUPSUpgradeable {

    function initialize(
    ) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /**
     * @notice This event is emitted when an implementation is cloned of type `implType` with `config`
     * @param newToken The clone that was created.
     * @param implType The type of implementation that was created.
     * @param config The config that was used to create the Allocator.
     */
    event NewTokenCreated(
        address indexed newToken,
        Types.ImplementationType implType,
        Types.TokenConfig config
    );

    function createToken(Types.TokenConfig memory _config) public {
        require(_config.owner != address(0), "Owner cannot be 0 address");
        JubiERC20BasicImpl newToken = new JubiERC20BasicImpl(
            _config.name,
            _config.symbol
        );
        uint256 length = _config.minterburners.length;
        if (length != 0 ) {
            for (uint256 i; i < length; ++i) {
                newToken.setMinter(
                    _config.minterburners[i],
                    true
                );
            }
        }
        newToken.transferOwnership(_config.owner);
        emit NewTokenCreated(
            address(newToken),
            Types.ImplementationType.ERC20_BASIC_TOKEN,
            _config
        );
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
