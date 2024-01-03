//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import "./IPriceOracle.sol";

interface IRemiliasRegistrarController {
    function available(string memory) external returns (bool);

    function register(
        string calldata,
        address,
        address,
        uint256,
        address,
        bytes[] calldata
    ) external;

    function resetOwner(address, uint256) external;
}
