// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./IERC20Upgradeable.sol";
import "./draft-IERC20PermitUpgradeable.sol";

interface IUSDEToken is IERC20Upgradeable, IERC20PermitUpgradeable {
    // --- Events ---

    // event TroveManagerAddressChanged(address _troveManagerAddress);
    // event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    // event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);

    event USDETokenBalanceUpdated(address _user, uint256 _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function mintToTreasury(uint256 _amount, uint256 _factor) external;

    function sendToPool(
        address _sender,
        address poolAddress,
        uint256 _amount
    ) external;

    function returnFromPool(
        address poolAddress,
        address user,
        uint256 _amount
    ) external;
}
