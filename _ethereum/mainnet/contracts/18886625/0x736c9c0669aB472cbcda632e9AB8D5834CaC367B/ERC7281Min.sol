// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4 <0.9.0;

import "./IERC7281Min.sol";

/// @notice A minimal implementation in the spirit of ERC-7281, generalized to any minter/burner
/// @author Dinari (https://github.com/dinaricrypto/usdplus-contracts/blob/main/src/ERC7281/ERC7281Min.sol)
/// @author Modified from defi-wonderland (https://github.com/defi-wonderland/xERC20/blob/main/solidity/contracts/XERC20.sol)
abstract contract ERC7281Min is IERC7281Min {
    struct LimitParameters {
        uint64 mintLimitTimestamp;
        uint64 burnLimitTimestamp;
        uint256 mintRatePerSecond;
        uint256 burnRatePerSecond;
        uint256 mintMaxLimit;
        uint256 burnMaxLimit;
        uint256 mintCurrentLimit;
        uint256 burnCurrentLimit;
    }

    /**
     * @notice The duration it takes for the limits to fully replenish
     */
    uint64 private constant _DURATION = 1 days;

    /// ------------------ Storage ------------------

    struct ERC7281MinStorage {
        mapping(address => LimitParameters) _issuerLimits;
    }

    // keccak256(abi.encode(uint256(keccak256("dinaricrypto.storage.ERC7281Min")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC7281MIN_STORAGE_LOCATION =
        0x4f7337d0ed9263ce19d7b42b3e4f1fab493f50854a84b6d021b0bdd3f1d6ea00;

    function _getERC7281MinStorage() private pure returns (ERC7281MinStorage storage $) {
        assembly {
            $.slot := ERC7281MIN_STORAGE_LOCATION
        }
    }

    /// ------------------ ERC-7281 ------------------

    function _setIssuerLimits(address issuer, uint256 mintingLimit, uint256 burningLimit) internal {
        _changeMintingLimit(issuer, mintingLimit);
        _changeBurningLimit(issuer, burningLimit);
        emit IssuerLimitsSet(issuer, mintingLimit, burningLimit);
    }

    function mintingMaxLimitOf(address issuer) external view returns (uint256) {
        ERC7281MinStorage storage $ = _getERC7281MinStorage();
        return $._issuerLimits[issuer].mintMaxLimit;
    }

    function burningMaxLimitOf(address issuer) external view returns (uint256) {
        ERC7281MinStorage storage $ = _getERC7281MinStorage();
        return $._issuerLimits[issuer].burnMaxLimit;
    }

    function mintingCurrentLimitOf(address issuer) external view returns (uint256) {
        ERC7281MinStorage storage $ = _getERC7281MinStorage();
        LimitParameters storage issuerLimits = $._issuerLimits[issuer];
        uint256 maxLimit = issuerLimits.mintMaxLimit;
        if (maxLimit == type(uint256).max) return type(uint256).max;
        return _getCurrentLimit(
            issuerLimits.mintLimitTimestamp, issuerLimits.mintRatePerSecond, maxLimit, issuerLimits.mintCurrentLimit
        );
    }

    function burningCurrentLimitOf(address issuer) external view returns (uint256) {
        ERC7281MinStorage storage $ = _getERC7281MinStorage();
        LimitParameters storage issuerLimits = $._issuerLimits[issuer];
        uint256 maxLimit = issuerLimits.burnMaxLimit;
        if (maxLimit == type(uint256).max) return type(uint256).max;
        return _getCurrentLimit(
            issuerLimits.burnLimitTimestamp, issuerLimits.burnRatePerSecond, maxLimit, issuerLimits.burnCurrentLimit
        );
    }

    /**
     * @notice Checks and uses the minting limit of an issuer
     * @param issuer The address of the issuer
     * @param value The change in the limit
     */
    function _useMintingLimits(address issuer, uint256 value) internal {
        ERC7281MinStorage storage $ = _getERC7281MinStorage();
        LimitParameters storage issuerLimits = $._issuerLimits[issuer];
        uint256 maxLimit = issuerLimits.mintMaxLimit;
        if (maxLimit == type(uint256).max) return;

        uint256 currentLimit = _getCurrentLimit(
            issuerLimits.mintLimitTimestamp, issuerLimits.mintRatePerSecond, maxLimit, issuerLimits.mintCurrentLimit
        );
        if (currentLimit < value) revert ERC7281_LimitExceeded();
        issuerLimits.mintLimitTimestamp = uint64(block.timestamp);
        issuerLimits.mintCurrentLimit = currentLimit - value;
    }

    /**
     * @notice Checks and uses the burning limit of an issuer
     * @param issuer The address of the issuer
     * @param value The change in the limit
     */
    function _useBurningLimits(address issuer, uint256 value) internal {
        ERC7281MinStorage storage $ = _getERC7281MinStorage();
        LimitParameters storage issuerLimits = $._issuerLimits[issuer];
        uint256 maxLimit = issuerLimits.burnMaxLimit;
        if (maxLimit == type(uint256).max) return;

        uint256 currentLimit = _getCurrentLimit(
            issuerLimits.burnLimitTimestamp, issuerLimits.burnRatePerSecond, maxLimit, issuerLimits.burnCurrentLimit
        );
        if (currentLimit < value) revert ERC7281_LimitExceeded();
        issuerLimits.burnLimitTimestamp = uint64(block.timestamp);
        issuerLimits.burnCurrentLimit = currentLimit - value;
    }

    /**
     * @notice Updates the minting limit of an issuer
     * @dev Can only be called by the owner
     * @param issuer The address of the issuer on which we are setting the limit
     * @param newMaxLimit The updated limit we are setting on the issuer
     */
    function _changeMintingLimit(address issuer, uint256 newMaxLimit) internal {
        ERC7281MinStorage storage $ = _getERC7281MinStorage();
        LimitParameters storage issuerLimits = $._issuerLimits[issuer];

        if (newMaxLimit == type(uint256).max) {
            delete issuerLimits.mintLimitTimestamp;
            delete issuerLimits.mintRatePerSecond;
            issuerLimits.mintMaxLimit = type(uint256).max;
            delete issuerLimits.mintCurrentLimit;
            return;
        }

        uint256 oldMaxLimit = issuerLimits.mintMaxLimit;
        uint256 currentLimit = _getCurrentLimit(
            issuerLimits.mintLimitTimestamp,
            issuerLimits.mintRatePerSecond,
            issuerLimits.mintMaxLimit,
            issuerLimits.mintCurrentLimit
        );
        issuerLimits.mintCurrentLimit = _calculateNewCurrentLimit(newMaxLimit, oldMaxLimit, currentLimit);

        issuerLimits.mintMaxLimit = newMaxLimit;
        issuerLimits.mintRatePerSecond = newMaxLimit / _DURATION;
        issuerLimits.mintLimitTimestamp = uint64(block.timestamp);
    }

    /**
     * @notice Updates the burning limit of an issuer
     * @dev Can only be called by the owner
     * @param issuer The address of the issuer on which we are setting the limit
     * @param newMaxLimit The updated limit we are setting on the issuer
     */
    function _changeBurningLimit(address issuer, uint256 newMaxLimit) internal {
        ERC7281MinStorage storage $ = _getERC7281MinStorage();
        LimitParameters storage issuerLimits = $._issuerLimits[issuer];

        if (newMaxLimit == type(uint256).max) {
            delete issuerLimits.burnLimitTimestamp;
            delete issuerLimits.burnRatePerSecond;
            issuerLimits.burnMaxLimit = type(uint256).max;
            delete issuerLimits.burnCurrentLimit;
            return;
        }

        uint256 oldMaxLimit = issuerLimits.burnMaxLimit;
        uint256 currentLimit = _getCurrentLimit(
            issuerLimits.burnLimitTimestamp,
            issuerLimits.burnRatePerSecond,
            issuerLimits.burnMaxLimit,
            issuerLimits.burnCurrentLimit
        );
        issuerLimits.burnCurrentLimit = _calculateNewCurrentLimit(newMaxLimit, oldMaxLimit, currentLimit);

        issuerLimits.burnMaxLimit = newMaxLimit;
        issuerLimits.burnRatePerSecond = newMaxLimit / _DURATION;
        issuerLimits.burnLimitTimestamp = uint64(block.timestamp);
    }

    /**
     * @notice Updates the current limit
     *
     * @param newMaxLimit The new limit
     * @param oldMaxLimit The old limit
     * @param currentLimit The current limit
     */
    function _calculateNewCurrentLimit(uint256 newMaxLimit, uint256 oldMaxLimit, uint256 currentLimit)
        internal
        pure
        returns (uint256)
    {
        if (newMaxLimit > oldMaxLimit) {
            return currentLimit + (newMaxLimit - oldMaxLimit);
        }
        uint256 difference = oldMaxLimit - newMaxLimit;
        return currentLimit > difference ? currentLimit - difference : 0;
    }

    /**
     * @notice Gets the current limit
     */
    function _getCurrentLimit(uint64 timestamp, uint256 ratePerSecond, uint256 maxLimit, uint256 currentLimit)
        internal
        view
        returns (uint256)
    {
        if (currentLimit == maxLimit || timestamp + _DURATION <= block.timestamp) {
            return maxLimit;
        }

        uint256 timePassed = block.timestamp - timestamp;
        uint256 calculatedLimit = currentLimit + (timePassed * ratePerSecond);
        if (calculatedLimit > maxLimit) {
            return maxLimit;
        }
        return calculatedLimit;
    }
}
