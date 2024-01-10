// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IDecentralandFacet.sol";

contract DecentralandAdminOperatorUpdater {
    function updateAssetsAdministrativeState(
        address _landWorks,
        uint256[] memory _assets
    ) public {
        IDecentralandFacet landWorks = IDecentralandFacet(_landWorks);
        for (uint256 i = 0; i < _assets.length; i++) {
            landWorks.updateAdministrativeState(_assets[i]);
        }
    }
}
