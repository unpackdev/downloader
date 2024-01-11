pragma solidity ^0.8.0;

import "./SafeERC20Upgradeable.sol";

import "./Owned.sol";

contract SafeBoxRetriever is Owned {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    constructor(address _owner) Owned(_owner) {}

    function retrieveTokens(address token, uint amount) external onlyOwner {
        IERC20Upgradeable(token).transfer(msg.sender, amount);
    }
}
