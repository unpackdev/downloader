// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20.sol";
import "./AccessControl.sol";

import "./console.sol";

contract Payment is AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    address payable public admin;
    address payable public payee;

    IERC20 public HAREM;

    event ETHPayment(uint256 ETHAmt, address sender, uint256 timestamp);
    event HAREMPayment(uint256 HAREMAmt, address sender, uint256 timestamp);

    constructor(address payable _admin, address _HAREM) public {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(MANAGER_ROLE, _admin);
        admin = _admin;
        payee = _admin;
        HAREM = IERC20(_HAREM);
    }

    function ETHPurchase() external payable {
        emit ETHPayment(msg.value, msg.sender, now);
    }

    function HAREMPurchase(uint256 HAREMAmt) external {
        HAREM.transferFrom(msg.sender, address(this), HAREMAmt);
        emit HAREMPayment(HAREMAmt, msg.sender, now);
    }

    function withdrawETH(uint256 amt) external {
        require(hasRole(MANAGER_ROLE, msg.sender), "Caller is not a manager");
        payee.transfer(amt);
    }

    function withdrawHAREM(uint256 amt) external {
        require(hasRole(MANAGER_ROLE, msg.sender), "Caller is not a manager");
        HAREM.transfer(payee, amt);
    }

    function changePayee(address payable _payee) public {
        require(hasRole(MANAGER_ROLE, msg.sender), "Caller is not a manager");
        payee = _payee;
    }

    function addManager(address manager) public {
        require(hasRole(MANAGER_ROLE, msg.sender), "Caller is not a manager");
        _setupRole(MANAGER_ROLE, manager);
    }

    function removeManager(address manager) public {
        require(hasRole(MANAGER_ROLE, msg.sender), "Caller is not a manager");
        revokeRole(MANAGER_ROLE, manager);
    }

    function hasManagerRole(address user) public view returns (bool hasManagerRole) {
        return hasRole(MANAGER_ROLE, user);
    }
}
