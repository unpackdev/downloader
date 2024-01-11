// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
// import "./console.sol";

contract AuthCenter is Ownable, AccessControlEnumerable {
    bytes32 public constant ACCOUNT_FULL_ACCESS = bytes32("ACCOUNT_FULL_ACCESS"); //0x4143434f554e545f46554c4c5f41434345535300000000000000000000000000
    bytes32 public constant FUNDS_PROVIDER_PULL_ACCESS = bytes32("FUNDS_PROVIDER_PULL_ACCESS"); // 0x46554e44535f50524f56494445525f50554c4c5f414343455353000000000000
    bytes32 public constant FUNDS_PROVIDER_REBALANCE_ACCESS = bytes32("FUNDS_PROVIDER_REBALANCE_ACCESS"); // 0x46554e44535f50524f56494445525f524542414c414e43455f41434345535300
    bytes32 public constant OPERATOR_FULL_ACCESS = bytes32("OPERATOR_FULL_ACCESS"); // 0x4f50455241544f525f46554c4c5f414343455353000000000000000000000000
    bytes32 public constant OPERATOR_PULL_ACCESS = bytes32("OPERATOR_PULL_ACCESS"); //
    bytes32 public constant ACCOUNT_MGR_FULL_ACCESS = bytes32("ACCOUNT_MGR_FULL_ACCESS"); // 0x4143434f554e545f4d47525f46554c4c5f414343455353000000000000000000

    bool flag;

    function init() external {
        require(!flag, "BYDEFI: already initialized!");
        super.initialize();
        // 0x0000000000000000000000000000000000000000000000000000000000000000
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        flag = true;
    }

    function grantRoleInBulk(bytes32 _role, address[] memory array) external onlyRole(getRoleAdmin(_role)) {
        for (uint256 i = 0; i < array.length; ) {
            _grantRole(_role, array[i]);
            unchecked {
                ++i;
            }
        }
    }

    function revokeRoleInBulk(bytes32 _role, address[] memory array) external onlyRole(getRoleAdmin(_role)) {
        for (uint256 i = 0; i < array.length; ) {
            _revokeRole(_role, array[i]);
            unchecked {
                ++i;
            }
        }
    }

    function resetAdminRole(address addr, bool status) external onlyOwner {
        if (status) {
            _grantRole(DEFAULT_ADMIN_ROLE, addr);
        } else {
            _revokeRole(DEFAULT_ADMIN_ROLE, addr);
        }
    }

    function ensureAccountAccess(address _caller) external view {
        _checkRole(ACCOUNT_FULL_ACCESS, _caller);
    }

    function ensureOperatorPullAccess(address _caller) external view {
        _checkRole(OPERATOR_PULL_ACCESS, _caller);
    }

    function ensureFundsProviderPullAccess(address _caller) external view {
        _checkRole(FUNDS_PROVIDER_PULL_ACCESS, _caller);
    }

    function ensureFundsProviderRebalanceAccess(address _caller) external view {
        _checkRole(FUNDS_PROVIDER_REBALANCE_ACCESS, _caller);
    }

    function ensureOperatorAccess(address _caller) external view {
        _checkRole(OPERATOR_FULL_ACCESS, _caller);
    }

    function ensureAccountManagerAccess(address _caller) external view {
        _checkRole(ACCOUNT_MGR_FULL_ACCESS, _caller);
    }

    function useless() public pure returns (uint256 a, string memory s) {
        a = 100;
        s = "hello world!";
    }
}
