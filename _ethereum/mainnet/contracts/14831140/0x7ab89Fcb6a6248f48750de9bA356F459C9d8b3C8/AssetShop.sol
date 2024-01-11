// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC1155.sol";
import "./OwnableWithAdmin.sol";
import "./IMercurianAssets.sol";

contract AssetShop is OwnableWithAdmin {

    IMercurianAssets public immutable mercurianAssets;
    address public centralTreasuryControl = 0x8Ac6794D1a42FA442449FB7465A3A0C1dBB0E848;

    constructor(address _mercurianAssetsAddress) {
        mercurianAssets = IMercurianAssets(_mercurianAssetsAddress);
    }

    function setCentralTreasuryAddress(address _newTreasuryAddress) external onlyOwnerOrAdmin {
        centralTreasuryControl = _newTreasuryAddress;
    }

    // SHOP

    function purchaseAsset(uint256 _tokenId, uint256 _amount, address _currency) external {
        IMercurianAssets _mercurianAssets = mercurianAssets;
        uint256 _price = _mercurianAssets.getPrice(_tokenId, _currency) * _amount;
        require(_price > 0, "No freebies, no exploits");
        require(_msgSender() == tx.origin, "EOA only");
        IERC20(_currency).transferFrom(_msgSender(), centralTreasuryControl, _price); // Make sure this contract is approved to spend _currency
        _mercurianAssets.mint(_msgSender(), _tokenId, _amount);
    }
    

}