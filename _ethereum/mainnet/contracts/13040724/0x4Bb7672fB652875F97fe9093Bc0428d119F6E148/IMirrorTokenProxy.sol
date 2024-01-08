// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IMirrorTokenProxy {
    event Update(address oldLogic, address newLogic);

    function logic() external returns (address logic);

    function update(address logic_) external;
}
