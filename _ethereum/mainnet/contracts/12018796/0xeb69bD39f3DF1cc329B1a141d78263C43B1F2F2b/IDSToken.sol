// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./IERC20.sol";

import "./IConverterAnchor.sol";
import "./IOwned.sol";

/*
    DSToken interface
*/
interface IDSToken is IConverterAnchor, IERC20 {
    function issue(address _to, uint256 _amount) external;

    function destroy(address _from, uint256 _amount) external;
}
