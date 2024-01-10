// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract ListingRewardForwarder is Ownable {
    using SafeERC20 for IERC20;

    event Burnt(uint256 amount);
    event Forwarded(uint256 amount);

    uint256 public totalBurnt;
    address public listingReward;
    IERC20 public token;

    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;

    constructor(IERC20 _token, address _listingReward) {
        token = _token;
        listingReward = _listingReward;
    }

    function burn(uint256 amount) external onlyOwner {
        require(amount > 0, 'Owner: amount > 0');
        token.safeTransfer(burnAddress, amount);
        totalBurnt += amount;
        emit Burnt(amount);
    }

    function release(uint256 amount) external onlyOwner {
        require(amount > 0, 'Owner: amount > 0');
        token.safeTransfer(listingReward, amount);
        emit Forwarded(amount);
    }
}
