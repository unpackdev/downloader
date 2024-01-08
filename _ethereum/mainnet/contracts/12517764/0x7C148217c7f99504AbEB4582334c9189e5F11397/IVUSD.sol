// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./draft-IERC20Permit.sol";
import "./IERC20.sol";

interface IVUSD is IERC20, IERC20Permit {
    function burnFrom(address _user, uint256 _amount) external;

    function mint(address _to, uint256 _amount) external;

    function multiTransfer(address[] memory _recipients, uint256[] memory _amounts) external returns (bool);

    function updateMinter(address _newMinter) external;

    function updateTreasury(address _newTreasury) external;

    function governor() external view returns (address _governor);

    function minter() external view returns (address _minter);

    function treasury() external view returns (address _treasury);
}
