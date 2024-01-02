// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./IRaribleExchangeV2.sol";
import "./LibOrderDataV1.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract RaribleExchangeV2Wrapper is ReentrancyGuard {
    /**
     * @dev Public immutable state
     */

    IRaribleExchangeV2 public immutable RARIBLE_EXCHANGE_V2;
    address public immutable RARIBLE_ERC20_PROXY;

    /**
     * @dev Constructor
     */

    constructor(address raribleExchangeV2_, address raribleERC20Proxy_) {
        RARIBLE_EXCHANGE_V2 = IRaribleExchangeV2(raribleExchangeV2_);
        RARIBLE_ERC20_PROXY = raribleERC20Proxy_;
    }

    /**
     * @dev Errors
     */

    error ERC20TransferFromFailed(
        address erc20,
        address from,
        address to,
        uint256 value
    );
    error ERC20ApproveFailed(address erc20, address spender, uint256 value);

    error RaribleExchangeV2AssetNotCompatible(bytes4 assetClass);

    /**
     * @dev Structs
     */

    struct Item {
        LibOrder.Order orderLeft;
        uint256 orderLeftQuantity;
        bytes signatureLeft;
        uint256 fillQuantity;
    }

    /**
     * @dev Public functions
     */

    function checkout(Item[] calldata items_) external payable nonReentrant {
        for (uint i = 0; i < items_.length; i++) {
            Item calldata _item = items_[i];
            LibOrder.Order
                memory _orderRight = raribleExchangeV2ConstructOrderRight(
                    _item
                );
            raribleExchangeV2MatchOrders(
                _item.orderLeft,
                _item.signatureLeft,
                _orderRight,
                '' // signatureRight
            );
        }

        // send back remaining ETH balance
        uint _ethBalance = address(this).balance;
        if (_ethBalance > 0) {
            payable(msg.sender).transfer(_ethBalance);
        }
    }

    /**
     * @dev Private functions
     */

    function raribleExchangeV2ConstructOrderRight(
        Item calldata item_
    ) private view returns (LibOrder.Order memory) {
        LibPart.Part[] memory _payouts = new LibPart.Part[](1);
        _payouts[0] = LibPart.Part(payable(msg.sender), 10_000);
        LibPart.Part[] memory _originsFees;
        return
            LibOrder.Order(
                address(this), // maker
                LibAsset.Asset( // makeAsset
                    item_.orderLeft.takeAsset.assetType,
                    (item_.orderLeft.takeAsset.value /
                        item_.orderLeftQuantity) * item_.fillQuantity
                ),
                address(0), // taker
                LibAsset.Asset( // takeAsset
                    item_.orderLeft.makeAsset.assetType,
                    (item_.orderLeft.makeAsset.value /
                        item_.orderLeftQuantity) * item_.fillQuantity
                ),
                0, // salt
                0, // start
                0, // end
                LibOrderDataV1.V1, // dataType
                abi.encode(LibOrderDataV1.DataV1(_payouts, _originsFees)) // data
            );
    }

    function raribleExchangeV2MatchOrders(
        LibOrder.Order memory orderLeft_,
        bytes memory signatureLeft_,
        LibOrder.Order memory orderRight_,
        bytes memory signatureRight_
    ) private {
        uint256 _ethValue = 0;
        if (
            orderRight_.makeAsset.assetType.assetClass ==
            LibAsset.ERC20_ASSET_CLASS
        ) {
            // decode asset
            address _tokenAddress = abi.decode(
                orderRight_.makeAsset.assetType.data,
                (address)
            );
            uint256 value = orderRight_.makeAsset.value;

            // transfer ERC20 to this contract
            if (
                IERC20(_tokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    value
                ) == false
            )
                revert ERC20TransferFromFailed(
                    _tokenAddress,
                    msg.sender,
                    address(this),
                    value
                );

            // setup allowance to ERC20 proxy
            if (
                IERC20(_tokenAddress).approve(
                    RARIBLE_ERC20_PROXY,
                    type(uint256).max
                ) == false
            )
                revert ERC20ApproveFailed(
                    _tokenAddress,
                    RARIBLE_ERC20_PROXY,
                    type(uint256).max
                );
        } else if (
            orderRight_.makeAsset.assetType.assetClass ==
            LibAsset.ETH_ASSET_CLASS
        ) {
            // set eth value to be sent to exchange
            _ethValue = orderRight_.makeAsset.value;
        } else {
            revert RaribleExchangeV2AssetNotCompatible(
                orderRight_.makeAsset.assetType.assetClass
            );
        }

        // execute match orders on Rarible Exchange V2
        RARIBLE_EXCHANGE_V2.matchOrders{value: _ethValue}(
            orderLeft_,
            signatureLeft_,
            orderRight_,
            signatureRight_
        );
    }
}
