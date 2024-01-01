pragma solidity 0.8.21;

import "ITokenLocker.sol";

contract PrismaSnapshotMockToken {
    string public constant name = "Prisma Snapshot Vote";

    string public constant symbol = "PRISMA-SNAP";

    uint256 public constant decimals = 18;

    ITokenLocker public constant locker = ITokenLocker(0x3f78544364c3eCcDCe4d9C89a630AEa26122829d);

    function balanceOf(address account) external view returns (uint256) {
        return locker.getAccountWeight(account) * 1e18;
    }

    function totalSupply() external view returns (uint256) {
        return locker.getTotalWeight() * 1e18;
    }
}
