// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";

contract DepositAndWithdrawUpgradeEth is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    event FundsWithdrawnEth(
        address indexed withdrawAddresseth,
        uint256 amountWithdrawneth
    );
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");
    uint256 public ethBalance;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OWNER_ROLE, msg.sender);
        _grantRole(WITHDRAWER_ROLE, msg.sender);
    }

    function pause() public onlyRole(OWNER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(OWNER_ROLE) {
        _unpause();
    }

    receive() external payable {
        ethBalance += msg.value;
    }

    fallback() external payable {}

    function DepositEth() public payable {
        require(msg.value > 0, "the amount should be greater than zero");
        ethBalance += msg.value;
    }

    function withdrawEth(address _withdrawerAddress, uint256 _amount)
        public
        payable
        onlyRole(WITHDRAWER_ROLE)
        whenNotPaused
    {
        require(_amount > 0, "Withdraw an amount greater than 0");
        require(
            ethBalance >= _amount,
            "insufficient eth available in the contract"
        );
        payable(_withdrawerAddress).transfer(_amount);
        ethBalance -= _amount;
        emit FundsWithdrawnEth(_withdrawerAddress, _amount);
    }
}
