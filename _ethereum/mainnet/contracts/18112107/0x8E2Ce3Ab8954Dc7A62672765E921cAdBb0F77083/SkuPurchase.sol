// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import "./AccessControlUpgradeable.sol";
import "./IERC20Upgradeable.sol";

contract SkuPurchase is AccessControlUpgradeable {

    struct PackageInfo {
        uint256 price;
        uint256 amount;
    }

    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    event Received(address indexed sender, uint256 value);

    function initialize(address withdrawer) public initializer {
        __AccessControl_init_unchained();
        __SkuPurchase_init_unchained(withdrawer);
    }

    function __SkuPurchase_init_unchained(address withdrawer)
        internal
        onlyInitializing
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(WITHDRAW_ROLE, withdrawer);
    }

    function withdraw(address tokenAddress, address valutAddress) external onlyRole(WITHDRAW_ROLE) {
        uint256 balance = IERC20Upgradeable(tokenAddress).balanceOf(address(this));
        IERC20Upgradeable(tokenAddress).transfer(valutAddress, balance);
    }

    function transfer(address tokenAddress, uint256 amount, address valutAddress) external onlyRole(WITHDRAW_ROLE) {
        IERC20Upgradeable(tokenAddress).transfer(valutAddress, amount);
    }

    function claimNativeToekns(address payable valutAddress) external onlyRole(WITHDRAW_ROLE) payable {
        uint256 balance = address(this).balance;
        (bool sent, ) = valutAddress.call{value: balance}("");
        require(sent, "Failed to send Ether");
    }

    // Function to receive Ether and log the sender's address and value
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}