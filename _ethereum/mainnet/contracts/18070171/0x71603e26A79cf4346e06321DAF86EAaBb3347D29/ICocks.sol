// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./IOFT.sol";

/**
 * @dev Interface of the OFT standard
 */
interface ICocks is IOFT {
    function setOnce() external view returns (bool);

    function cockadoods() external view returns (address);

    function mintTokens(address _to, uint256 _amount) external;

    function mintTokensTest(address _to, uint256 _amount) external;

    function setCockadoods(address _cocksnft) external;
}
