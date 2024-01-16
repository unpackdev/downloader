// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./OwnableUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./ERC721ProjectUpgradeable.sol";

abstract contract WithTreasuryUpgradeable is Initializable, ContextUpgradeable, OwnableUpgradeable {
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev the wallet address that receives NFT sale funds
    address payable internal treasury;

    event TreasurySet(address treasury);
    event ETHSentToTreasury(address indexed reciver, uint256 amount);

    /**
     * @dev Initializes
     */
    function __WithTreasury_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __WithTreasury_init_unchained();
    }

    function __WithTreasury_init_unchained() internal initializer {}

    function setTreasury(address payable treasuryAddress) public onlyOwner {
        require(treasuryAddress != payable(address(0)), "bad treasury address");
        treasury = treasuryAddress;
        emit TreasurySet(treasuryAddress);
    }

    function getTreasury() public view returns (address) {
        return treasury;
    }

    function _sendETHToTreasury(uint256 amount) internal {
        treasury.sendValue(amount);
        emit ETHSentToTreasury(treasury, amount);
    }

    // withdraw token or ETH
    function withdrawTokens(
        address _tokenAddr,
        address payable _to,
        uint256 _amount
    ) external onlyOwner {
        if (_tokenAddr == address(0)) {
            AddressUpgradeable.sendValue(_to, _amount);
        } else {
            IERC20Upgradeable(_tokenAddr).safeTransfer(_to, _amount);
        }
    }

    uint256[49] private __gap;
}
