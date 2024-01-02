// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

library Utils {
    uint24 public constant BASE = 100_000;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant STAKE_STAR_ROLE = keccak256("StakeStar");
    bytes32 public constant MANAGER_ROLE = keccak256("Manager");
    bytes32 public constant TREASURY_ROLE = keccak256("Treasury");

    uint32 public constant EPOCH_DURATION = 384;

    string public constant ZERO_ADDR_ERROR_MSG = "zero address";

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }

    function addressToWithdrawalCredentials(
        address _address
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                bytes32((uint256(1) << 248) | uint256(uint160(_address)))
            );
    }

    function compareBytes(
        bytes memory a,
        bytes memory b
    ) internal pure returns (bool) {
        return (keccak256(a) == keccak256(b));
    }
}
