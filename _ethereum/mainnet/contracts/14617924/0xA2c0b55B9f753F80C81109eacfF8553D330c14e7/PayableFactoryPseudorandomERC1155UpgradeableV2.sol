// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CountersUpgradeable.sol";
import "./BasePayableFactoryERC1155Upgradeable.sol";
import "./AvailableIdsMixinUpgradeable.sol";

contract PayableFactoryPseudorandomERC1155UpgradeableV2 is
    BasePayableFactoryERC1155Upgradeable,
    AvailableIdsMixinUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _nftAddress,
        uint256 _fixedPrice,
        address _payeeAddress
    ) public initializer {
        __BasePayableFactoryERC1155Upgradeable_init(
            _nftAddress,
            _fixedPrice,
            _payeeAddress
        );
        __AvailableIdsMixinUpgradeable_init();
    }

    function addIds(uint256[] memory _ids) public onlyOwner {
        _addIds(_ids);
    }

    function balanceOf(address _fromAddress)
        public
        view
        override
        returns (uint256)
    {
        return availableSupply();
    }

    // TODO(security): verify msgSender is not a contract (so it can't reverse-engineer block attributes by making a method call from same block)
    function getSeed() internal view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );
        return seed;
    }

    function _nextId() internal override returns (uint256) {
        require(
            availableIds.length > 0,
            "PseudorandomFactoryERC1155Upgradeable#_nextId: must have at least 1 available id"
        );

        uint256 seed = getSeed();
        uint256 seletectedIndex = seed % availableIds.length;

        uint256 selectedTokenId = availableIds[seletectedIndex];

        availableIds[seletectedIndex] = availableIds[availableIds.length - 1];
        availableIds.pop();

        return selectedTokenId;
    }

    function _nextIds(uint256 _amount)
        internal
        override
        returns (uint256[] memory)
    {
        require(
            availableIds.length > (_amount - 1),
            "PseudorandomFactoryERC1155Upgradeable#_nextIds: must have at least (amount) available id"
        );
        uint256[] memory _ids = new uint256[](_amount);
        uint256 seed = getSeed();
        for (uint256 i = 0; i < _amount; i++) {
            require(
                seed > availableIds.length,
                "PseudorandomFactoryERC1155Upgradeable#_nextIds: amount too high"
            );

            uint256 seletectedIndex = seed % availableIds.length;
            seed /= availableIds.length;

            _ids[i] = availableIds[seletectedIndex];

            availableIds[seletectedIndex] = availableIds[
                availableIds.length - 1
            ];
            availableIds.pop();
        }
        return _ids;
    }

    uint256[50] private __gap;
}
