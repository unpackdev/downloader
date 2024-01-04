// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "./AccessControl.sol";
import "./IEPriceOracle.sol";
import "./EPriceOracleEth.sol";
import "./IAssetToken.sol";

interface IEController {
    function getPrice(uint payment) external view returns (uint);
    function addAddressToWhitelist(address account) external;
    function addAddressesToWhitelist(address[] memory accounts) external;
    function removeAddressFromWhitelist(address account) external;
    function removeAddressesFromWhitelist(address[] memory accounts) external;
    function changeWhitelistedAccount(address account) external;
    function isWhitelisted(address account) external view returns (bool);
    function isAdmin(address account) external view returns (bool);
}

/**
 * @title Elysia's Asset Control layer
 * @notice Control admin and whitelisted account
 * @author Elysia
 */
contract EController is IEController, AccessControl {
    bytes32 public constant WHITELISTED = keccak256("WHITELISTED");

    // 0: el, 1: eth, 2: wBTC ...
    mapping(address => uint256) assetPayment;

    // AssetToken list
    IAssetTokenBase[] public assetTokenList;

    // 0: el, 1: eth, 2: wBTC ...
    mapping(uint256 => IEPriceOracle) public ePriceOracle;

    /// @notice Emitted when new priceOracle is set
    event NewPriceOracle(address ePriceOracle);

    /// @notice Emitted when new assetToken is set
    event NewAssetToken(address assetToken);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, address(this));
        _setRoleAdmin(WHITELISTED, DEFAULT_ADMIN_ROLE);
    }

    /*** Oracle View functions ***/

    function getPrice(uint payment) external view override returns (uint256) {
        IEPriceOracle oracle = ePriceOracle[payment];
        return oracle.getPrice();
    }

    /*** Admin Functions on Setup ***/

    /**
     * @notice Set EPriceoracle in each payment
     * @param ePriceOracle_ The address of the ePriceOracle to be enabled
     * @param payment The payment of price feed
     */
    function setEPriceOracle(IEPriceOracle ePriceOracle_, uint256 payment)
        external
        onlyAdmin
    {
        ePriceOracle[payment] = ePriceOracle_;
        emit NewPriceOracle(address(ePriceOracle_));
    }

    /**
     * @notice Add assets to be included in eController
     * @param assetTokens The list of addresses of the assetTokens to be enabled
     */
    function setAssetTokens(IAssetTokenBase[] memory assetTokens)
        external
        onlyAdmin
    {
        uint256 len = assetTokens.length;

        for (uint256 i = 0; i < len; i++) {
            assetTokenList.push(assetTokens[i]);
            assetPayment[address(assetTokens[i])] = assetTokens[i].getPayment();
            emit NewAssetToken(address(assetTokens[i]));
        }
    }

    /*** Functions on Whitelist ***/

    /**
     * @notice Whitelisted user can change whitelisted address
     * @param account The address of account to change
     */
    function changeWhitelistedAccount(address account)
        external
        override
        onlyWhitelisted()
    {
        _setupRole(WHITELISTED, account);
        renounceRole(WHITELISTED, msg.sender);
    }

    /*** Admin Functions on Whitelist ***/

    /**
     * @notice Add an 'account' to the whitelist
     * @param account The address of account to add
     */
    function addAddressToWhitelist(address account)
        external
        override
        onlyAdmin
    {
        grantRole(WHITELISTED, account);
    }

    function addAddressesToWhitelist(address[] memory accounts)
        external
        override
        onlyAdmin
    {
        uint256 len = accounts.length;

        for (uint256 i = 0; i < len; i++) {
            grantRole(WHITELISTED, accounts[i]);
        }
    }

    /**
     * @notice remove an 'account' from the whitelist
     * @param account The address of account to remove
     */
    function removeAddressFromWhitelist(address account)
        external
        override
        onlyAdmin
    {
        revokeRole(WHITELISTED, account);
    }

    function removeAddressesFromWhitelist(address[] memory accounts)
        external
        override
        onlyAdmin
    {
        uint256 len = accounts.length;

        for (uint256 i = 0; i < len; i++) {
            revokeRole(WHITELISTED, accounts[i]);
        }
    }

    function pauseAssetTokens(IAssetTokenBase[] memory assetTokens)
        public
        onlyAdmin
    {
        uint256 len = assetTokens.length;

        for (uint256 i = 0; i < len; i++) {
            assetTokens[i].pause();
        }
    }

    function unpauseAssetTokens(IAssetTokenBase[] memory assetTokens)
        public
        onlyAdmin
    {
        uint256 len = assetTokens.length;

        for (uint256 i = 0; i < len; i++) {
            assetTokens[i].unpause();
        }
    }

    /*** Access Controllers ***/

    /// @dev Restricted to members of the whitelisted user.
    modifier onlyWhitelisted() {
        require(_isWhitelisted(msg.sender), "Restricted to whitelisted.");
        _;
    }

    /// @dev Restricted to members of the admin role.
    modifier onlyAdmin() {
        require(_isAdmin(msg.sender), "Restricted to admin.");
        _;
    }

    /// @dev Return `true` if the account belongs to whitelist.
    function isWhitelisted(address account)
        external
        view
        override
        returns (bool)
    {
        return _isWhitelisted(account);
    }

    /// @dev Return `true` if the account belongs to the admin role.
    function isAdmin(address account)
        external
        view
        override
        returns (bool) {
        return _isAdmin(account);
    }

    function _isWhitelisted(address account) internal view returns (bool) {
        return hasRole(WHITELISTED, account);
    }

    function _isAdmin(address account) internal view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }
}
