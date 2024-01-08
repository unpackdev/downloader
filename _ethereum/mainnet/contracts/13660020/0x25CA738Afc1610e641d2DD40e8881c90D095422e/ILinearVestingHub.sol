// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./SVesting.sol";
import "./IERC20.sol";

interface ILinearVestingHub {
    // solhint-disable-next-line func-name-mixedcase
    function TOKEN() external view returns (IERC20);

    function nextVestingIdByReceiver(address receiver_)
        external
        view
        returns (uint256);

    function vestingsByReceiver(address receiver_, uint256 id_)
        external
        view
        returns (Vesting memory);

    function totalWithdrawn() external view returns (uint256);

    function isReceiver(address receiver_) external view returns (bool);

    function receiverAt(uint256 index_) external view returns (address);

    function receivers() external view returns (address[] memory);
}
