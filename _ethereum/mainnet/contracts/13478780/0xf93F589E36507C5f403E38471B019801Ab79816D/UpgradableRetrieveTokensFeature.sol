// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./SafeERC20.sol";

/**
 * Upgradable Contract that provides ETC and ERC20 token retrieval authorised by the owner
 */
contract UpgradableRetrieveTokensFeature is Initializable, ContextUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    /**
     * @dev Initialization of the contract
     */
    function __RetrieveToken_init() internal initializer {
        __Ownable_init();
    }

    /**
     * @dev Allows to transfer the whole amount of the given token to a receiver
     */
    function retrieveTokens(address to, address anotherToken) public virtual onlyOwner {
        IERC20 alienToken = IERC20(anotherToken);
        alienToken.safeTransfer(to, alienToken.balanceOf(address(this)));
    }

    /**
     * @dev Allows to transfer contract's ETH to a receiver
     */
    function retrieveETH(address payable to) public virtual onlyOwner {
        to.transfer(address(this).balance);
    }
}
