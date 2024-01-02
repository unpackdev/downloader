// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./ReentrancyGuardUpgradeable.sol";
import "./ERC1155BurnableUpgradeable.sol";
import "./IERC1155Receiver.sol";
import "./IERC20Metadata.sol";
import "./BaseUpgradeable.sol";
import "./Constants.sol";
import "./SafeTransfer.sol";

interface ITokenSale {
    function erc1155Collection() external view returns (address);

    function isExchangeable(uint256 id) external view returns (bool);
}

contract RewardExchangeUpgradeable is BaseUpgradeable, ReentrancyGuardUpgradeable {
    address public tokenSaleContract;
    address public rewardToken;
    uint256 public rate;

    error TreasuryUpgreadeable__NotAccept();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address roleManager_, address tokenSaleContract_, address rewardToken_, uint256 exchangePercentBps_) external initializer {
        __ReentrancyGuard_init();
        __BaseUpgradeable_init(roleManager_);
        _configExchange(rewardToken_, exchangePercentBps_);
        tokenSaleContract = tokenSaleContract_;
    }

    function configExchange(address rewardToken_, uint256 exchangePercentBps_) external onlyRole(OPERATOR_ROLE) {
        _configExchange(rewardToken_, exchangePercentBps_);
    }

    function getRewardAmounts(address collection, uint256 tokenId, uint256 quantity) external view returns (uint256) {
        if (!_isAccepted(collection, tokenId)) return 0;

        return (quantity * rate);
    }

    function onERC1155Received(address, address from, uint256 id, uint256 value, bytes calldata) public returns (bytes4) {
        address collection = _msgSender();

        if (!_isAccepted(collection, id)) revert TreasuryUpgreadeable__NotAccept();

        ERC1155BurnableUpgradeable(collection).burn(address(this), id, value);

        SafeTransferLib.safeTransfer(rewardToken, from, value * rate);

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) public returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function _getRate(address rewardToken_) internal view returns (uint256) {
        return 10 ** IERC20Metadata(rewardToken_).decimals();
    }

    function _isAccepted(address collection, uint256 tokenId) internal view returns (bool) {
        if (collection != ITokenSale(tokenSaleContract).erc1155Collection()) return false;

        if (!ITokenSale(tokenSaleContract).isExchangeable(tokenId)) return false;

        return true;
    }

    function _configExchange(address rewardToken_, uint256 receivePercentBps_) internal {
        rewardToken = rewardToken_;
        rate = (10 ** IERC20Metadata(rewardToken_).decimals() * receivePercentBps_) / HUNDER_PERCENT_IN_BPS;
    }
}
