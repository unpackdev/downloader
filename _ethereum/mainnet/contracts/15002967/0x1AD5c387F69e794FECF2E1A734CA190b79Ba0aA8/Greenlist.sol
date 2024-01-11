// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.4;

import "./Address.sol";
import "./Ownable.sol";

import "./GreenlistManager.sol";

contract Greenlist is Ownable {
    using Address for address;
    bool greenlistStatus;

    GreenlistManager greenlistManager;

    event GreenlistStatus(bool _status);

    constructor(address _greenlistManagerAddress) {
        greenlistManager = GreenlistManager(_greenlistManagerAddress);
    }

    /// @notice switch on / off the greenlist
    /// @dev this function will allow only Aspen's asset proxy to transfer tokens
    function setGreenlistStatus(bool _status) external onlyOwner {
        greenlistStatus = _status;
        emit GreenlistStatus(_status);
    }

    /// @notice checks whether greenlist is activated
    /// @dev this function returns true / false for whether greenlist is on / off.
    function isGreenlistOn() public view returns (bool _status) {
        return greenlistStatus;
    }

    /// @dev this function checks whether the caller is a contract and if the operator is greenlisted
    function checkGreenlist(address _operator) internal view {
        if (Address.isContract(_operator) && isGreenlistOn()) {
            require(greenlistManager.isGreenlisted(_operator), "ERC721Cedar: operator is not greenlisted");
        }
    }
}
