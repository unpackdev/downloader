// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";


abstract contract Permissions {
    using SafeERC20 for IERC20;

    mapping(address => bool) internal distributors;
    address public admin;
    address public pendingAdmin;
    address[] internal distributorsGroup;
    uint256 private constant MAX_GROUP_SIZE = 50;

    event EtherWithdraw(uint256 amount, address sendTo);
    event TokenWithdraw(IERC20 token, uint256 amount, address sendTo);
    event AdminClaimed(address newAdmin, address previousAdmin);
    event TransferAdminPending(address pendingAdmin);
    event DistributorAdded(address newDistributor, bool isAdd);

    constructor(address _admin) {
        require(_admin != address(0), "admin 0");
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier onlyDistributor() {
        require(distributors[msg.sender], "only distributor");
        _;
    }

    function withdrawEther(uint256 amount, address payable sendTo) external onlyAdmin {
        (bool success, ) = sendTo.call{value: amount}("");
        require(success, "withdraw failed");
        emit EtherWithdraw(amount, sendTo);
    }

    function withdrawToken(
        IERC20 token,
        uint256 amount,
        address sendTo
    ) external onlyAdmin {
        token.safeTransfer(sendTo, amount);
        emit TokenWithdraw(token, amount, sendTo);
    }

    function claimAdmin() public {
        require(pendingAdmin == msg.sender, "not pending");
        emit AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "new admin 0");
        emit TransferAdminPending(newAdmin);
        pendingAdmin = newAdmin;
    }

    function addDistributor(address newDistributor) public onlyAdmin {
        require(!distributors[newDistributor], "distributor exists"); // prevent duplicates.
        require(distributorsGroup.length < MAX_GROUP_SIZE, "max distributors");

        emit DistributorAdded(newDistributor, true);
        distributors[newDistributor] = true;
        distributorsGroup.push(newDistributor);
    }

    function removeDistributor(address distributor) public onlyAdmin {
        require(distributors[distributor], "not distributor");
        distributors[distributor] = false;

        for (uint256 i = 0; i < distributorsGroup.length; ++i) {
            if (distributorsGroup[i] == distributor) {
                distributorsGroup[i] = distributorsGroup[distributorsGroup.length - 1];
                distributorsGroup.pop();
                emit DistributorAdded(distributor, false);
                break;
            }
        }
    }

    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "admin 0");
        emit TransferAdminPending(newAdmin);
        emit AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    function getDistributors() external view returns (address[] memory) {
        return distributorsGroup;
    }
}