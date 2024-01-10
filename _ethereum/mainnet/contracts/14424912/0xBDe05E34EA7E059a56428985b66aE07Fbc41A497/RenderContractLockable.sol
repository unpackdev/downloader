// SPDX-License-Identifier: UNLICENSED
/// @title RenderContractLockable
/// @notice RenderContractLockable
/// @author CyberPnk <cyberpnk@cyberpnk.win>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____
//  __________________/\/\/\/\________________________________________________________________________________
// __________________________________________________________________________________________________________

pragma solidity ^0.8.2;

import "./Ownable.sol";

abstract contract RenderContractLockable is Ownable {
    address public renderContract;
    bool public isChangeRenderContractDisabled = false;

    // Irreversible.
    function disableChangeRenderContract() external onlyOwner {
        isChangeRenderContractDisabled = true;
    }

    // In case there's a bug, but eventually disabled
    function setRenderContract(address _renderContract) external onlyOwner {
        require(!isChangeRenderContractDisabled, "Disabled");
        renderContract = _renderContract;
    }
}
