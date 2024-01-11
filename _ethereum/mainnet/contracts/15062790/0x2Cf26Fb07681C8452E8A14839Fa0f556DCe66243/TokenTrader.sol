// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./LibAsset.sol";
import "./IERC721Mintable.sol";
import "./IERC1155Mintable.sol";

contract TokenTrader is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    struct TradeInfo {
        bool enabled;
        uint256 price;
        uint256 amount;
    }

    mapping(address => TradeInfo) public tradeInfoERC721;

    mapping(address => mapping(uint256 => TradeInfo)) public tradeInfoERC1155;

    // EVENTS

    event TokenBought(LibAsset.Asset asset);

    // CONSTRUCTOR

    function __TokenTrader_init() public onlyInitializing {
        __Ownable_init();
    }

    // PUBLIC FUNCTIONS

    function buy(LibAsset.Asset memory asset) external payable nonReentrant {
        if (asset.assetType == LibAsset.AssetType.ERC721) {
            _checkAndUpdateInfo(tradeInfoERC721[asset.token], asset);
            IERC721Mintable(asset.token).mint(msg.sender, asset.amount);
        } else if (asset.assetType == LibAsset.AssetType.ERC1155) {
            _checkAndUpdateInfo(tradeInfoERC1155[asset.token][asset.id], asset);
            IERC1155Mintable(asset.token).mint(msg.sender, asset.id, asset.amount);
        } else {
            revert("TokenTrader: unsupported asset type");
        }
        emit TokenBought(asset);
    }

    // RESTRICTED FUNCTIONS

    function setTradeInfoERC721(
        address token,
        bool enabled,
        uint256 price,
        uint256 amount
    ) external onlyOwner {
        tradeInfoERC721[token] = TradeInfo({enabled: enabled, price: price, amount: amount});
    }

    function setTradeInfoERC1155(
        address token,
        uint256[] memory ids,
        bool[] memory enabled,
        uint256[] memory prices,
        uint256[] memory amounts
    ) external onlyOwner {
        require(
            ids.length == enabled.length &&
                enabled.length == prices.length &&
                prices.length == amounts.length,
            "TokenTrader: length mismatch"
        );
        for (uint256 i = 0; i < ids.length; i++) {
            tradeInfoERC1155[token][ids[i]] = TradeInfo({
                enabled: enabled[i],
                price: prices[i],
                amount: amounts[i]
            });
        }
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

    // INTERNAL FUNCTIONS

    function _checkAndUpdateInfo(TradeInfo storage info, LibAsset.Asset memory asset) private {
        require(info.enabled, "TokenTrader: token sale not enabled");
        require(msg.value == info.price * asset.amount, "TokenTrader: message value too low");
        require(info.amount >= asset.amount, "TokenTrader: remaining amount too low");

        unchecked {
            info.amount -= asset.amount;
        }
    }
}
