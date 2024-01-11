// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "./draft-IERC20PermitUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./LibDerivative.sol";

interface IOpiumPositionToken is IERC20PermitUpgradeable, IERC20Upgradeable {
    struct OpiumPositionTokenParams {
        LibDerivative.Derivative derivative;
        LibDerivative.PositionType positionType;
        bytes32 derivativeHash;
    }

    function initialize(
        bytes32 _derivativeHash,
        LibDerivative.PositionType _positionType,
        LibDerivative.Derivative calldata _derivative
    ) external;

    function mint(address _positionOwner, uint256 _amount) external;

    function burn(address _positionOwner, uint256 _amount) external;

    function getFactoryAddress() external view returns (address);

    function getPositionTokenData() external view returns (OpiumPositionTokenParams memory opiumPositionTokenParams);

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) external;

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) external;
}
