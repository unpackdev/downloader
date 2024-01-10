// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IERC20Mintable.sol";
import "./IKIKIVault.sol";
import "./SafeOwnable.sol";

contract MarketLocker {
    using SafeMath for uint256;

    event NewReceiver(address receiver, uint totalReleaseAmount, uint lastReleaseAt);
    event ReleaseToken(address receiver, uint releaseAmount, uint nextReleaseAmount, uint nextReleaseBlockNum);

    uint constant MARKET_REEASE_RATIO = 9;
    uint constant VAULT_RELEASE_RATIO = 60;

    ///@notice the token to lock
    IERC20 public immutable token;
    IKIKIVault immutable public vault;
    address immutable public market;
    uint public userReleased;

    constructor(
        IERC20 _token, IKIKIVault _vault, address _market
    ) {
        require(address(_token) != address(0), "token address is zero");
        token = _token;
        require(address(_vault) != address(0), "vault address is zero");
        vault = _vault;
        require(_market != address(0), "deployer address is zero");
        market = _market;
    }

    function claim() external {
        uint vaultReleaseAmount = vault.totalReleaseAmount();
        uint shouldReleaseAmount = vaultReleaseAmount.mul(MARKET_REEASE_RATIO).div(VAULT_RELEASE_RATIO);
        shouldReleaseAmount = shouldReleaseAmount.sub(userReleased);
        userReleased = userReleased.add(shouldReleaseAmount); 
        uint balance = token.balanceOf(address(this));
        if (balance < shouldReleaseAmount) {
            IERC20Mintable(address(token)).mint(address(this), shouldReleaseAmount.sub(balance));
            balance = token.balanceOf(address(this));
        }
        require(balance >= shouldReleaseAmount, "contract balance not enough");
        if (shouldReleaseAmount > 0) {
            SafeERC20.safeTransfer(token, market, shouldReleaseAmount);
        }
    }

}
