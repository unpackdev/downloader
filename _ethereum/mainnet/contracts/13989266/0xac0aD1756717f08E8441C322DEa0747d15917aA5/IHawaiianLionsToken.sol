// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title HawaiianLions Token Interface
/// @author @MilkyTasteEth MilkyTaste:8662 https://milkytaste.xyz
/// https://www.hawaiianlions.world/

import "./IERC721.sol";

interface IHawaiianLionsToken is IERC721 {

    /**
     * Mint by utility contract.
     * @dev This function is reserved for future utility.
     */
    function mintUtility(uint256 numTokens, address mintTo) external;

    function totalSupply() external view returns (uint256);

}
