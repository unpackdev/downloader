// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./SignedSafeMathUpgradeable.sol";
import "./IBinarySearch.sol";

/// @custom:security-contact lee@rand.network,adr@rand.network
contract BinarySearch is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    IBinarySearch
{
    using SignedSafeMathUpgradeable for int256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());
    }

    function binarySearch(uint256[] memory _data, uint256 _target)
        public
        pure
        override
        returns (uint256)
    {
        int256 length = int256(_data.length);
        require(
            length > 0,
            "Binary Search: Array must not have zero elements."
        );
        int256 lo = -1;
        int256 hi = length.sub(1);
        int256 mi;

        while (hi.sub(lo) > 1) {
            mi = lo.add(hi).div(2);
            if (evaluate(_data[uint256(mi)], _target)) {
                hi = mi;
            } else {
                lo = mi;
            }
        }
        require(
            hi >= 0,
            "Binary Search: Result must be equal or greater than zero."
        );
        return uint256(hi);
    }

    function evaluate(uint256 _against, uint256 _target)
        internal
        pure
        returns (bool)
    {
        if (_against >= _target) return true;
        return false;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
}
