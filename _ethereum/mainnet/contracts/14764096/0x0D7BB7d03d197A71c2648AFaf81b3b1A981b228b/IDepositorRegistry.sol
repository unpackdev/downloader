// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;
pragma abicoder v2;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./IZapDepositor.sol";
import "./IAMM.sol";
import "./IAMMRegistry.sol";

interface IDepositorRegistry {
    event ZapDepositorSet(address _amm, IZapDepositor _zapDepositor);

    function ZapDepositorsPerAMM(address _address)
        external
        view
        returns (IZapDepositor);

    function registry() external view returns (IAMMRegistry);

    function setZapDepositor(address _amm, IZapDepositor _zapDepositor)
        external;

    function isRegisteredZap(address _zapAddress) external view returns (bool);

    function addZap(address _zapAddress) external returns (bool);

    function removeZap(address _zapAddress) external returns (bool);

    function zapLength() external view returns (uint256);

    function zapAt(uint256 _index) external view returns (address);
}
