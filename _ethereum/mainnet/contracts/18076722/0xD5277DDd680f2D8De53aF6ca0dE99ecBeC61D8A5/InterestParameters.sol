// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "./Initializable.sol";
import "./IInterestParameters.sol";
import "./AccessManagedUpgradeable.sol";
import "./Roles.sol";

/**
 * @title InterestParameters
 * @dev Contains functions related to interests and maturities for the bonds
 * @author Ethichub
 */
abstract contract InterestParameters is Initializable, IInterestParameters, AccessManagedUpgradeable {
    uint256[] public interests;
    uint256[] public maturities;
    uint256 public maxParametersLength;

    error InterestMustBeGreaterThanZero();
    error InterestParametersIsGreaterThanMaxParameters();
    error InterestLengthDistinctMaturityLength();
    error UnorderedMaturities();
    error InterestLengthLesserOrEqualZero();
    error MaturityInputMustBeGreaterThanFirstMaturity();

    function __InterestParameters_init(
        uint256[] calldata _interests,
        uint256[] calldata _maturities
    )
    internal initializer {
        maxParametersLength = 3;
        _setInterestParameters(_interests, _maturities);
    }

    function setInterestParameters(
        uint256[] calldata _interests,
        uint256[] calldata _maturities
    )
    external override onlyRole(INTEREST_PARAMETERS_SETTER) {
        _setInterestParameters(_interests, _maturities);
    }

    /**
     * @dev Sets the maximum length of interests and maturities parameters
     * @param value uint256
     *
     * Requirement:
     *
     * - The length value can not be 0
     */
    function setMaxInterestParams(uint256 value) external override onlyRole(INTEREST_PARAMETERS_SETTER) {
        if (value <= 0) revert InterestLengthLesserOrEqualZero();
        maxParametersLength = value;
        emit MaxInterestParametersSet(value);
    }

    /**
     * @dev Checks the interest correspondant to the maturity.
     * Needs at least 1 maturity / interest pair.
     * Returns interest per second
     * @param maturity duration of the bond in seconds
     */
    function getInterestForMaturity(uint256 maturity) public view override returns (uint256) {
        if (maturity < maturities[0]) revert MaturityInputMustBeGreaterThanFirstMaturity();
        for (uint256 i = interests.length - 1; i >= 0; --i) {
            if (maturity >= maturities[i]) {
                return interests[i];
            }
        }
        return interests[0];
    }

    /**
     * @dev Sets the parameters of interests and maturities
     * @param _interests set of interests per second in wei
     * @param _maturities set of maturities in second
     *
     * Requirements:
     *
     * - The length of the array of interests can not be 0
     * - The length of the array of interests can not be greater than maxParametersLength
     * - The length of the array of interests and maturities must be the same
     * - The value of maturities must be in ascending order
     * - The values of interest and maturities can not be 0
     */
    function _setInterestParameters(
        uint256[] calldata _interests,
        uint256[] calldata _maturities
    )
    internal {
        if (_interests.length <= 0) revert InterestMustBeGreaterThanZero();
        if (_interests.length > maxParametersLength) revert InterestParametersIsGreaterThanMaxParameters();
        if (_interests.length != _maturities.length) revert InterestLengthDistinctMaturityLength();
        for (uint256 i = 0; i < _interests.length; ++i) {
            if (i != 0) {
                if (_maturities[i-1] >= _maturities[i]) revert UnorderedMaturities();
            }
        }
        interests = _interests;
        maturities = _maturities;
        emit InterestParametersSet(interests, maturities);
    }

    /**
     * ////// [v1.0, v1.1, v1.2] //////
     * 1 interests
     * 1 maturities
     * 1 maxParametersLength
     * 49 __gap
     * 52 (mistakenly deployed with 52 store gaps)
     */
    uint256[49] private __gap; // deployed with 52 store gaps
}