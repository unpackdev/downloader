// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract TokenTransfer is AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 public constant MAX_PERMILLE = 10000;

    event AdminChanged(address indexed newAdmin, address indexed admin);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event ERC20Transfer(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount
    );

    event NativeTransfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    address public swap;
    address public admin;
    address public owner;
    uint256 adminFeePermille;

    constructor(
        address _swap,
        address _admin,
        address _owner,
        uint256 _adminFee
    ) {
        require(_swap != address(0), "Invalid swap address");
        require(_admin != address(0), "Invalid admin address");
        require(_owner != address(0), "Invalid owner address");

        swap = _swap;
        admin = _admin;
        owner = _owner;
        adminFeePermille = _adminFee;

        _setupRole(ADMIN_ROLE, admin);
        _setupRole(OWNER_ROLE, owner);
    }

    function getContractTokenBalance(
        IERC20 token
    ) external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getContractNativeBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function adminServiceFee() external view returns (uint256) {
        return adminFeePermille;
    }

    function depositTokens(
        address tokenAddress,
        uint256 _amount
    ) external payable {
        require(_amount > 0, "Amount must be greater than zero");
        require(tokenAddress != address(this), "Invalid token address");

        uint256 adminFee = _amount.mul(adminFeePermille).div(MAX_PERMILLE);
        uint256 swapAmount = _amount.sub(adminFee);

        if (tokenAddress == address(0)) {
            require(msg.value >= _amount, "Insufficient Ether sent");

            (bool adminTransferSuccess, ) = payable(admin).call{
                value: adminFee
            }("");
            require(adminTransferSuccess, "Admin transfer failed");

            (bool swapTransferSuccess, ) = payable(swap).call{
                value: swapAmount
            }("");
            require(swapTransferSuccess, "Swap transfer failed");

            emit NativeTransfer(msg.sender, admin, msg.value);
        } else {
            require(
                IERC20(tokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    _amount
                ),
                "Transfer failed"
            );
            IERC20(tokenAddress).transfer(admin, adminFee);
            IERC20(tokenAddress).transfer(swap, swapAmount);
            emit ERC20Transfer(tokenAddress, msg.sender, admin, _amount);
        }
    }

    function setAdminServiceFee(
        uint256 _adminFee
    ) external onlyRole(ADMIN_ROLE) {
        adminFeePermille = _adminFee;
    }

    function setSwap(address newSwap) external onlyRole(OWNER_ROLE) {
        require(newSwap != address(0), "New swap address is the zero address");
        swap = newSwap;
    }

    function withdrawToken(
        IERC20 token,
        uint256 _amount
    ) external onlyRole(OWNER_ROLE) nonReentrant {
        uint256 contractBalance = token.balanceOf(address(this));
        require(_amount <= contractBalance, "Exceeds contract balance");
        token.transfer(msg.sender, _amount);
    }

    function withdrawNativeToken() public onlyRole(OWNER_ROLE) nonReentrant {
        require(address(this).balance > 0, "Contract balance is zero");
        address to = msg.sender;
        (bool success, ) = to.call{value: getContractNativeBalance()}("");
        require(success, "Transfer failed");
    }

    function transferOwnership(
        address newOwner
    ) external onlyRole(OWNER_ROLE) returns (bool) {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _revokeRole(OWNER_ROLE, owner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        _setupRole(OWNER_ROLE, newOwner);
        return true;
    }

    function changeAdmin(address _newAdmin) external onlyRole(OWNER_ROLE) {
        require(_newAdmin != address(0), "New admin is the zero address");
        _revokeRole(ADMIN_ROLE, admin);
        emit AdminChanged(_newAdmin, admin);
        admin = _newAdmin;
        _setupRole(ADMIN_ROLE, admin);
    }
}
