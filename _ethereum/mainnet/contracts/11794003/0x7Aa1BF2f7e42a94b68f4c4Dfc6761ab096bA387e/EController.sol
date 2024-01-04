// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "./AccessControl.sol";
import "./IEPriceOracle.sol";
import "./EPriceOracleEth.sol";
import "./IAssetToken.sol";

interface IEController {
    function getPrice(uint payment) external view returns (uint);
    function isAdmin(address account) external view returns (bool);
}

/**
 * @title Elysia's Asset Control layer
 * @notice Controll admin
 * @author Elysia
 */
contract EController is IEController, AccessControl {
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
            emit NewAssetToken(address(assetTokens[i]));
        }
    }

    function setAdmin(address account)
        external
        onlyAdmin
    {
        _setupRole(DEFAULT_ADMIN_ROLE, account);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
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

    /// @dev Restricted to members of the admin role.
    modifier onlyAdmin() {
        require(_isAdmin(msg.sender), "Restricted to admin.");
        _;
    }

    /// @dev Return `true` if the account belongs to the admin role.
    function isAdmin(address account)
        external
        view
        override
        returns (bool) {
        return _isAdmin(account);
    }

    function _isAdmin(address account) internal view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }
}
