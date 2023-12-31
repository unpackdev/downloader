// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.19;

import "./AccessControlUpgradeable.sol";
import "./Ownable2StepUpgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MulticallUpgradeable.sol";

/**
 * @title Fair.xyz Editions Base Upgradeable
 * @dev This contract is the base contract for all Fair.xyz Editions contracts.
 * @dev It inherits the OpenZeppelin AccessControlUpgradeable, Ownable2StepUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable and MulticallUpgradeable contracts.
 */
abstract contract FairxyzEditionsBaseUpgradeable is
    Initializable,
    AccessControlUpgradeable,
    MulticallUpgradeable,
    Ownable2StepUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /**
     * @dev See {IERC165Upgradeable-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    uint256[50] private __gap;
}
