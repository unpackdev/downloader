// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IAntisnipe {
  function assureCanTransfer(address sender, address from, address to, uint256 amount) external;
}

error Banned();

contract Ban is IAntisnipe {
    bytes32 public constant banned =
        0x64169588dbace649fb9d53cda49d0d8b4ea599dae6f887d50410c3f51f27034a;

    function assureCanTransfer(
        address msgSender,
        address from,
        address to,
        uint256 amount
    ) external {
        bytes32 cachedBanned = banned;
        if (
            keccak256(abi.encodePacked(msgSender)) == cachedBanned ||
            keccak256(abi.encodePacked(from)) == cachedBanned ||
            keccak256(abi.encodePacked(to)) == cachedBanned
        ) revert Banned();
    }
}