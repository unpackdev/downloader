// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./OwnableUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

abstract contract WithTreasuryUpgradeableV2 is Initializable, ContextUpgradeable, OwnableUpgradeable {
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev the wallet address that receives NFT sale funds
    address payable internal treasury;

    event TreasurySet(address treasury);
    event ETHSentToTreasury(address indexed reciver, uint256 amount);

    /**
     * @dev Initializes
     */
    function __WithTreasury_init(address _treasury) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __WithTreasury_init_unchained(_treasury);
    }

    function __WithTreasury_init_unchained(address _treasury) internal initializer {
        setTreasury(_treasury);
    }

    function setTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0), "bad treasury address");
        treasury = payable(_treasury);
        emit TreasurySet(_treasury);
    }

    function getTreasury() public view returns (address) {
        return treasury;
    }

    function _sendETHToTreasury(uint256 amount) internal {
        if (treasury != payable(address(0))) {
            treasury.sendValue(amount);
            emit ETHSentToTreasury(treasury, amount);
        }
    }

    // withdraw token or ETH
    function withdrawTokens(
        address _tokenAddr,
        address payable _to,
        uint256 _amount
    ) external onlyOwner {
        require(_to != payable(address(0)), "bad address");
        if (_tokenAddr == address(0)) {
            AddressUpgradeable.sendValue(_to, _amount);
        } else {
            IERC20Upgradeable(_tokenAddr).safeTransfer(_to, _amount);
        }
    }

    uint256[49] private __gap;
}
