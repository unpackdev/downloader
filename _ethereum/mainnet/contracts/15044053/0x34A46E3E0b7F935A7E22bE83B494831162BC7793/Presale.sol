// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";

contract PresaleERC20 is AccessControl, ReentrancyGuard {
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    IERC20 superX;

    event TransferBatch(address[] addresses, uint256[] amounts);

    constructor(
        address _superXAddress,
        address _transfererAddress,
        address _owner
    ) {
        superX = IERC20(_superXAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(TRANSFER_ROLE, _owner);
        _grantRole(TRANSFER_ROLE, _transfererAddress);
    }

    function transferBatch(
        address[] calldata addresses,
        uint256[] calldata amounts
    ) external onlyRole(TRANSFER_ROLE) nonReentrant {
        require(addresses.length == amounts.length, "invalid array length");
        uint256 sum = sumArray(amounts);
        require(
            superX.balanceOf(address(this)) >= sum,
            "balance is not enough"
        );
        uint256 len = addresses.length;
        for (uint256 i = 0; i < len; i++) {
            superX.transfer(addresses[i], amounts[i]);
        }
        emit TransferBatch(addresses, amounts);
    }

    function fetchSuperXBalanceBatch(address[] calldata _users)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](_users.length);
        for (uint256 i = 0; i < _users.length; i++) {
            uint256 bl = superX.balanceOf(_users[i]);
            balances[i] = bl;
        }
        return balances;
    }

    function sumArray(uint256[] memory amounts) private pure returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }
        return total;
    }
}
