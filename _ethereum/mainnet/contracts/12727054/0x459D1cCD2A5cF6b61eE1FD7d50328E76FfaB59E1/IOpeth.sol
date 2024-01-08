// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";

interface IOpeth {
    function mintFor(address _destination, address oToken, uint _amount) external;
    function getOpethDetails(address oToken, uint _oToken) external view returns(address, address, uint);
    function flashMint(address oToken, uint amount, bytes memory params) external;
}
