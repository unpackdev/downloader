//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMonkey {
    function getMonkeySupply() external view returns (uint256);
    function getMonkeyIdsByOwner(address _owner) external view returns (uint256[] memory);
    function setMonkeyMintIsOpen(bool _isOpen) external;
    function setMonkeyBatchSize(uint16 _batchSize) external;
    function setMonkeyMintSecondsBetweenBatches(uint32 _secondsBetweenBatches) external;
    function setMonkeyMaxPerWallet(uint8 _maxPerWallet) external;
    function setMonkeyMintPriceInBanans(uint128 _priceInBanans) external;
    function setMonkeyMintBananFeePercentageToBurn(uint16 _monkeyMintBananFeePercentageToBurn) external;
    function setMonkeyMintBananFeePercentageToStolenPool(uint16 _monkeyMintBananFeePercentageToStolenPool) external;
    function setMonkeyMintTier1Threshold(uint16 _tier1Threshold) external;
    function setMonkeyMintTier2Threshold(uint16 _tier2Threshold) external;
    function setMonkeyHP(uint8 _HP) external;
    function setMonkeyHitRate(uint16 _hitRate) external;
    function setMonkeyAttackIsOpen(bool _isOpen) external;
    function setAttackCooldownSeconds(uint32 _attackCooldownSeconds) external;
    function setAttackHPDeductionAmount(uint8 _attackHPDeductionAmount) external;
    function setAttackHPDeductionThreshold(uint16 _attackHPDeductionThreshold) external;
}