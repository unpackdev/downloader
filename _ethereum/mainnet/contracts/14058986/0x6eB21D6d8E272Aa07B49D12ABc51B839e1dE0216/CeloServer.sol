// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./BaseServer.sol";

interface ICeloBridge {
    function send(
        address _token,
        uint256 _amount,
        uint32 _destination,
        bytes32 _recipient
    ) external;
}

contract CeloServer is BaseServer {
    address public constant bridgeAddr =
        0x4fc16De11deAc71E8b2Db539d82d93BE4b486892;

    event BridgedSushi(address indexed minichef, uint256 indexed amount);

    constructor(uint256 _pid, address _minichef) BaseServer(_pid, _minichef) {}

    function _bridge() internal override {
        uint256 sushiBalance = sushi.balanceOf(address(this));

        sushi.approve(bridgeAddr, sushiBalance);
        ICeloBridge(bridgeAddr).send(
            address(sushi),
            sushiBalance,
            1667591279,
            bytes32(uint256(uint160(minichef)))
        );
        emit BridgedSushi(minichef, sushiBalance);
    }
}
