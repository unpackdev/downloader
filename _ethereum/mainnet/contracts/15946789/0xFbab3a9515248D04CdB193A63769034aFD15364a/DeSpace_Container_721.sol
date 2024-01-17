// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./IERC721Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";

error DeSpace_Marketplace_AlreadyInitialized();
error DeSpace_Marketplace_BidOwn();
error DeSpace_Marketplace_BuyOwn();
error DeSpace_Marketplace_UnauthorizedCaller();
error DeSpace_Marketplace_NonExistent();
error DeSpace_Marketplace_NotStarted();
error DeSpace_Marketplace_AlreadyEnded();
error DeSpace_Marketplace_PriceCheck();
error DeSpace_Marketplace_WrongCallPeriod();
error DeSpace_Marketplace_LowPrice();
error DeSpace_Marketplace_WrongAsset();
error DeSpace_Marketplace_WrongAddressInput();

enum MoneyType {
    DES,
    NATIVE
}

struct Auction {
    address payable seller;
    address payable topBidder;
    address token;
    uint256 tokenId;
    uint256 floorPrice;
    uint256 topBid;
    uint256 startPeriod;
    uint256 endPeriod;
    uint256 bidCount;
    MoneyType money;
    bool closed;
    bool fixedTime;
}

struct InstantTrade {
    address payable seller;
    address payable buyer;
    address token;
    uint256 tokenId;
    uint256 floorPrice;
    uint256 buyPrice;
    MoneyType money;
    bool closed;
}

contract DeSpace_Container_721 is
    OwnableUpgradeable,
    ERC721HolderUpgradeable,
    ReentrancyGuardUpgradeable
{
    uint256 public desFee; // 1% = 1000
    uint256 public nativeFee; // 1% = 1000
    uint256 internal constant DIV = 10e5;
    address payable public wallet;
    address public des;

    event FeeSet(address indexed admin, uint256 desFee, uint256 nativeFee);
    event WalletSet(address indexed admin, address indexed wallet);

    function setFee(uint256 _desFee, uint256 _nativeFee) external onlyOwner {
        _setFee(_desFee, _nativeFee);
        emit FeeSet(msg.sender, _desFee, _nativeFee);
    }

    function setWallet(address _wallet) external onlyOwner {
        _setWallet(_wallet);
        emit WalletSet(msg.sender, _wallet);
    }

    function _setFee(uint256 _desFee, uint256 _nativeFee) internal {
        desFee = _desFee;
        nativeFee = _nativeFee;
    }

    function _setWallet(address _wallet) internal {
        require(
            _wallet != wallet && _wallet != address(0),
            "Error: Wrong or duplicated"
        );
        wallet = payable(_wallet);
    }

    function _checkBeforeCollect(address _token, uint256 _tokenId) internal {
        IERC721Upgradeable nft = IERC721Upgradeable(_token);
        address currentHodler = nft.ownerOf(_tokenId);

        if (currentHodler != msg.sender) {
            bool canMake = nft.isApprovedForAll(currentHodler, msg.sender);
            address approved = nft.getApproved(_tokenId);

            if (!canMake && approved != msg.sender) {
                revert DeSpace_Marketplace_UnauthorizedCaller();
            }
        }
        // collect NFT
        nft.safeTransferFrom(currentHodler, address(this), _tokenId);
    }
}
