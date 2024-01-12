// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.11;

import "./IBentoBoxMinimal.sol";
import "./IStargateRouter.sol";
import "./IStargateWidget.sol";

interface IImmutableState {
    function bentoBox() external view returns (IBentoBoxMinimal);

    function stargateRouter() external view returns (IStargateRouter);

    function stargateWidget() external view returns (IStargateWidget);

    function factory() external view returns (address);

    function pairCodeHash() external view returns (bytes32);
}