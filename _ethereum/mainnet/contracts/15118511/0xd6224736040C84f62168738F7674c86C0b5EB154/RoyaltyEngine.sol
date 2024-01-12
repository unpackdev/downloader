// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./IRoyaltyEngine.sol";
import "./RoyaltyEngineStorage.sol";
import "./IManifoldRoyaltyEngineV1.sol";
import "./IOwnable.sol";

contract RoyaltyEngine is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    IRoyaltyEngine,
    RoyaltyEngineStorage
{
    function initialize(address admin, address _manifoldRoyaltyEngine)
        public
        initializer
    {
        manifoldRoyaltyEngine = _manifoldRoyaltyEngine;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(UPGRADE_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
    }

    // For UUPSUpgradeable
    function _authorizeUpgrade(address) internal view override {
        require(
            hasRole(UPGRADE_ROLE, _msgSender()),
            "RE: caller not in UPGRADE_ROLE"
        );
    }

    function updatetRoyaltyConfigByOwner(
        address collection,
        address setter,
        address payable[] calldata receivers,
        uint256[] calldata fees
    ) external override {
        require(
            _msgSender() == IOwnable(collection).owner(),
            "RE: caller not owner"
        );
        royaltyConfigs[collection] = RoyaltyConfig({
            setter: setter,
            receivers: receivers,
            fees: fees
        });
        emit RoyaltyCfgUpdated(collection, setter, receivers, fees);
    }

    function updatetRoyaltyConfigBySetter(
        address collection,
        address setter,
        address payable[] calldata receivers,
        uint256[] calldata fees
    ) external override {
        require(
            _msgSender() == royaltyConfigs[collection].setter,
            "RE: caller not setter"
        );
        royaltyConfigs[collection] = RoyaltyConfig({
            setter: setter,
            receivers: receivers,
            fees: fees
        });
        emit RoyaltyCfgUpdated(collection, setter, receivers, fees);
    }

    function overrideRoyaltyConfig(
        address collection,
        address setter,
        address payable[] calldata receivers,
        uint256[] calldata fees
    ) external override {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "RE: caller not in MANAGER_ROLE"
        );
        royaltyConfigs[collection] = RoyaltyConfig({
            setter: setter,
            receivers: receivers,
            fees: fees
        });
        emit RoyaltyCfgUpdated(collection, setter, receivers, fees);
    }

    function getRoyalty(
        address collection,
        uint256 tokenId,
        uint256 value
    )
        external
        view
        override
        returns (address payable[] memory recipients, uint256[] memory amounts)
    {
        RoyaltyConfig memory cfg = royaltyConfigs[collection];
        if (cfg.fees.length > 0) {
            return (cfg.receivers, _computeAmounts(value, cfg.fees));
        }
        return
            IManifoldRoyaltyEngineV1(manifoldRoyaltyEngine).getRoyaltyView(
                collection,
                tokenId,
                value
            );
    }

    function _computeAmounts(uint256 value, uint256[] memory fees)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory amounts = new uint256[](fees.length);
        uint256 totalAmount;
        for (uint256 i = 0; i < fees.length; i++) {
            amounts[i] = (value * fees[i]) / 10000;
            totalAmount = totalAmount + amounts[i];
        }
        require(totalAmount < value, "RE: invalid fee amount");
        return amounts;
    }
}
