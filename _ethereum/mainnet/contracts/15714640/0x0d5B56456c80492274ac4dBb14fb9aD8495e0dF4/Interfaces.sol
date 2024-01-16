// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

interface IPrajna is IERC20 {
    function updateReward(address _address) external;
    function burn(address _from, uint256 amount) external;
}

interface IRiseOfPunakawan is IERC721 {

}

interface ISemar is IERC721 {

}
