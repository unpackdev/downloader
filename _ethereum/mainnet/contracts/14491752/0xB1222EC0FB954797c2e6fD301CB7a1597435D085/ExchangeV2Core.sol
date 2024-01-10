// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;
pragma abicoder v2;

import "./ReentrancyGuardUpgradeable.sol";
import "./LibFill.sol";
import "./LibOrder.sol";
import "./OrderValidator.sol";
import "./AssetMatcher.sol";
import "./LibFill.sol";
import "./LibFill.sol";
import "./TransferExecutor.sol";
import "./ITransferManager.sol";
import "./LibTransfer.sol";

abstract contract ExchangeV2Core is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    AssetMatcher,
    TransferExecutor,
    OrderValidator,
    ITransferManager
{
    using SafeMathUpgradeable for uint256;
    using LibTransfer for address;

    uint256 private constant UINT256_MAX = type(uint256).max;

    //state of the orders
    mapping(bytes32 => uint256) public fills;

    //events
    event Cancel(bytes32 hash);
    event Match(
        bytes32 leftHash,
        bytes32 rightHash,
        address indexed leftMaker,
        address indexed rightMaker,
        uint256 newLeftFill,
        uint256 newRightFill
    );

    function cancel(LibOrder.Order memory order) external nonReentrant {
        require(_msgSender() == order.maker, "not a maker");
        bytes32 orderKeyHash = LibOrder.hashKey(order);
        fills[orderKeyHash] = UINT256_MAX;
        emit Cancel(orderKeyHash);
    }

    function matchOrders(
        LibOrder.Order memory orderLeft,
        bytes memory signatureLeft,
        LibOrder.Order memory orderRight,
        bytes memory signatureRight
    ) external payable nonReentrant {
        validateFull(orderLeft, signatureLeft);
        validateFull(orderRight, signatureRight);
        if (orderLeft.taker != address(0)) {
            require(
                orderRight.maker == orderLeft.taker,
                "taker verification failed"
            );
        }
        if (orderRight.taker != address(0)) {
            require(
                orderRight.taker == orderLeft.maker,
                "taker verification failed"
            );
        }

        matchAndTransfer(orderLeft, orderRight);
    }

    function matchAndTransfer(
        LibOrder.Order memory orderLeft,
        LibOrder.Order memory orderRight
    ) internal {
        (
            LibAsset.AssetType memory makeMatch,
            LibAsset.AssetType memory takeMatch
        ) = matchAssets(orderLeft, orderRight);
        bytes32 leftOrderKeyHash = LibOrder.hashKey(orderLeft);
        bytes32 rightOrderKeyHash = LibOrder.hashKey(orderRight);
        uint256 leftOrderFill = fills[leftOrderKeyHash];
        uint256 rightOrderFill = fills[rightOrderKeyHash];
        LibFill.FillResult memory fill = LibFill.fillOrder(
            orderLeft,
            orderRight,
            leftOrderFill,
            rightOrderFill
        );
        require(fill.takeValue > 0, "nothing to fill");
        (uint256 totalMakeValue, uint256 totalTakeValue) = doTransfers(
            makeMatch,
            takeMatch,
            fill,
            orderLeft,
            orderRight
        );
        if (makeMatch.assetClass == LibAsset.ETH_ASSET_CLASS) {
            require(msg.value >= totalMakeValue, "not enough eth");
            if (msg.value > totalMakeValue) {
                address(msg.sender).transferEth(msg.value.sub(totalMakeValue));
            }
        } else if (takeMatch.assetClass == LibAsset.ETH_ASSET_CLASS) {
            //todo могут ли быть с обеих сторон ETH?
            require(msg.value >= totalTakeValue, "not enough eth");
            if (msg.value > totalTakeValue) {
                address(msg.sender).transferEth(msg.value.sub(totalTakeValue));
            }
        }

        address msgSender = _msgSender();
        if (msgSender != orderLeft.maker) {
            fills[leftOrderKeyHash] = leftOrderFill.add(fill.takeValue);
        }
        if (msgSender != orderRight.maker) {
            fills[rightOrderKeyHash] = rightOrderFill.add(fill.makeValue);
        }
        emit Match(
            leftOrderKeyHash,
            rightOrderKeyHash,
            orderLeft.maker,
            orderRight.maker,
            fill.takeValue,
            fill.makeValue
        );
    }

    function matchAssets(
        LibOrder.Order memory orderLeft,
        LibOrder.Order memory orderRight
    )
        internal
        view
        returns (
            LibAsset.AssetType memory makeMatch,
            LibAsset.AssetType memory takeMatch
        )
    {
        makeMatch = matchAssets(
            orderLeft.makeAsset.assetType,
            orderRight.takeAsset.assetType
        );
        require(makeMatch.assetClass != 0, "assets don't match");
        takeMatch = matchAssets(
            orderLeft.takeAsset.assetType,
            orderRight.makeAsset.assetType
        );
        require(takeMatch.assetClass != 0, "assets don't match");
    }

    function validateFull(LibOrder.Order memory order, bytes memory signature)
        internal
        view
    {
        LibOrder.validate(order);
        validate(order, signature);
    }

    uint256[49] private __gap;
}
