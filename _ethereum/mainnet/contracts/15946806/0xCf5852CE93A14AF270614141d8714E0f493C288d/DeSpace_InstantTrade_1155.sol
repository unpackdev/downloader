// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./DeSpace_Container_1155.sol";

abstract contract DeSpace_InstantTrade_1155 is DeSpace_Container_1155 {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public instantIds;
    mapping(uint256 => InstantTrade) private _instants;
    event CancelledInstant(uint256 indexed id);
    event InstantCreated(address indexed seller, uint256 indexed instId);
    event NewBuy(address indexed buyer, uint256 indexed instId, uint256 amount);

    modifier buyIf(uint256 _instId) {
        InstantTrade memory instant;
        instant = _instants[_instId];
        if (instant.seller == address(0))
            revert DeSpace_Marketplace_NonExistent();
        if (instant.seller == msg.sender) revert DeSpace_Marketplace_BuyOwn();
        if (instant.closed) revert DeSpace_Marketplace_AlreadyEnded();
        _;
    }

    function listInstant(
        address _from,
        address _token,
        uint256 _tokenId,
        uint256 _numberOfTokens,
        uint256 _price,
        MoneyType money
    ) external returns (uint256 instId) {
        _checkBeforeCollect(_from, _token, _tokenId, _numberOfTokens);

        instantIds++;
        instId = instantIds;

        _instants[instId] = InstantTrade(
            payable(msg.sender),
            payable(address(0)),
            _token,
            _tokenId,
            _numberOfTokens,
            _price,
            0,
            money,
            false
        );

        emit InstantCreated(msg.sender, instId);
    }

    function buyInstant(uint256 _instId, uint256 amount)
        external
        payable
        buyIf(_instId)
        nonReentrant
    {
        InstantTrade memory instant = _instants[_instId];
        uint256 amt = amountForBuy(_instId);
        uint256 fee;
        uint256 cost;
        if (instant.money == MoneyType.DES) {
            if (msg.value != 0) revert DeSpace_Marketplace_WrongAsset();
            if (amount < amt) revert DeSpace_Marketplace_PriceCheck();

            IERC20Upgradeable des_ = IERC20Upgradeable(des);
            fee = (desFee * amount) / DIV;
            des_.safeTransferFrom(msg.sender, wallet, fee);
            des_.safeTransferFrom(msg.sender, instant.seller, amount - fee);
            cost = amount;
            emit NewBuy(msg.sender, _instId, amount);
        } else {
            if (msg.value < amt) revert DeSpace_Marketplace_PriceCheck();
            fee = (nativeFee * msg.value) / DIV;
            wallet.transfer(fee);
            instant.seller.transfer(msg.value - fee);
            cost = msg.value;
            emit NewBuy(msg.sender, _instId, msg.value);
        }

        InstantTrade storage inst = _instants[_instId];
        inst.buyer = payable(msg.sender);
        inst.closed = true;
        inst.buyPrice = cost;

        IERC1155Upgradeable nft = IERC1155Upgradeable(instant.token);
        nft.safeTransferFrom(
            address(this),
            msg.sender,
            instant.tokenId,
            instant.numberOfTokens,
            "0x0"
        );
    }

    function closeAndCancelInstant(uint256 _instId) external {
        InstantTrade memory instant = _instants[_instId];

        if (msg.sender != instant.seller)
            revert DeSpace_Marketplace_UnauthorizedCaller();
        if (instant.closed) revert DeSpace_Marketplace_AlreadyEnded();

        IERC1155Upgradeable nft = IERC1155Upgradeable(instant.token);
        _instants[_instId].closed = true;

        nft.safeTransferFrom(
            address(this),
            msg.sender,
            instant.tokenId,
            instant.numberOfTokens,
            "0x0"
        );
        emit CancelledInstant(_instId);
    }

    function idToInstant(uint256 id)
        external
        view
        returns (InstantTrade memory trade)
    {
        trade = _instants[id];
    }

    function amountForBuy(uint256 _instId)
        public
        view
        returns (uint256 amount)
    {
        InstantTrade memory instant;
        instant = _instants[_instId];

        if (instant.seller == address(0))
            revert DeSpace_Marketplace_NonExistent();
        if (!instant.closed) return instant.floorPrice;
        else return 0;
    }
}
