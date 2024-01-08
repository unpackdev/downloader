// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;
import "./SafeERC20.sol";
import "./UpgradableRetrieveTokensFeature.sol";

/**
 * Upgradable Vault to hold a specific ERC20 Token
 */
contract UpgradableTokenVault is UpgradableRetrieveTokensFeature {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 internal _token;

    /**
     * Initalize the vault
     */
    function initialize() public initializer {
        __RetrieveToken_init();
    }

    /**
     * @dev set the token to hold
     */
    function setToken(IERC20 token_) public onlyOwner {
        require(address(_token) == address(0), 'token already added');
        _token = token_;
    }

    /**
     * @return the token being held.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @dev retrieve wrongly assigned tokens
     */
    function retrieveTokens(address to, address anotherToken) public override onlyOwner {
        require(address(_token) != address(0), 'Token must be set');
        require(address(_token) != anotherToken, 'You should only use this method to withdraw extraneous tokens.');
        super.retrieveTokens(to, anotherToken);
    }
}
