//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC20.sol";
import "./IERC721Receiver.sol";
import "./ERC721Holder.sol";
import "./GoldFeverNativeGold.sol";

contract GoldFeverRight is ReentrancyGuard, IERC721Receiver, ERC721Holder {
    bytes32 public constant CREATED = keccak256("CREATED");
    bytes32 public constant STAKED = keccak256("STAKED");
    bytes32 public constant BURNED = keccak256("BURNED");
    bytes32 public constant FINALIZED = keccak256("FINALIZED");

    using Counters for Counters.Counter;
    Counters.Counter private _rightOptionIds;
    Counters.Counter private _rightPurchaseIds;

    GoldFeverNativeGold ngl;

    constructor(address ngl_) public {
        ngl = GoldFeverNativeGold(ngl_);
    }

    struct RightOption {
        uint256 rightId;
        uint256 rightOptionId;
        uint256 rightType;
        uint256 price;
        uint256 duration;
    }
    struct RightPurchase {
        uint256 rightOptionId;
        uint256 rightPurchaseId;
        address buyer;
        bytes32 status;
        uint256 expiry;
        uint256 price;
        uint256 duration;
    }

    mapping(uint256 => RightOption) public idToRightOption;
    mapping(uint256 => mapping(uint256 => RightPurchase))
        public rightIdToRightPurchase;

    event RightOptionCreated(
        uint256 indexed rightId,
        uint256 indexed rightOptionId,
        uint256 rightType,
        uint256 price,
        uint256 duration
    );
    event RightOptionPurchased(
        uint256 indexed rightOptionId,
        uint256 indexed rightPurchaseId,
        address buyer,
        string status,
        uint256 expiry,
        uint256 price,
        uint256 duration
    );

    event RightOptionPurchaseFinished(uint256 indexed rightPurchaseId);

    function createRightOption(
        uint256 rightId,
        uint256 rightType,
        uint256 price,
        uint256 duration
    ) public nonReentrant {
        require(price > 0, "Price must be at least 1 wei");

        _rightOptionIds.increment();
        uint256 rightOptionId = _rightOptionIds.current();

        idToRightOption[rightOptionId] = RightOption(
            rightId,
            rightOptionId,
            rightType,
            price,
            duration
        );

        emit RightOptionCreated(
            rightId,
            rightOptionId,
            rightType,
            price,
            duration
        );
    }

    function purchaseRight(uint256 rightOptionId) public nonReentrant {
        uint256 price = idToRightOption[rightOptionId].price;
        uint256 duration = idToRightOption[rightOptionId].duration;
        uint256 rightType = idToRightOption[rightOptionId].rightType;
        uint256 expiry = block.timestamp + duration;

        _rightPurchaseIds.increment();
        uint256 rightPurchaseId = _rightPurchaseIds.current();

        if (rightType == 0) {
            ngl.transferFrom(msg.sender, address(this), price);

            rightIdToRightPurchase[rightOptionId][
                rightPurchaseId
            ] = RightPurchase(
                rightOptionId,
                rightPurchaseId,
                msg.sender,
                STAKED,
                expiry,
                price,
                duration
            );

            emit RightOptionPurchased(
                rightOptionId,
                rightPurchaseId,
                msg.sender,
                "STAKED",
                expiry,
                price,
                duration
            );
        } else if (rightType == 1) {
            ngl.burnFrom(msg.sender, price);

            rightIdToRightPurchase[rightOptionId][
                rightPurchaseId
            ] = RightPurchase(
                rightOptionId,
                rightPurchaseId,
                msg.sender,
                BURNED,
                expiry,
                price,
                duration
            );

            emit RightOptionPurchased(
                rightOptionId,
                rightPurchaseId,
                msg.sender,
                "BURNED",
                expiry,
                price,
                duration
            );
        }
    }

    function finalizeRightPurchase(
        uint256 rightOptionId,
        uint256 rightPurchaseId
    ) public nonReentrant {
        require(
            rightIdToRightPurchase[rightOptionId][rightPurchaseId].status ==
                STAKED,
            "Error"
        );
        require(
            rightIdToRightPurchase[rightOptionId][rightPurchaseId].expiry <=
                block.timestamp,
            "Not expired"
        );

        uint256 price = idToRightOption[rightOptionId].price;

        ngl.transfer(
            rightIdToRightPurchase[rightOptionId][rightPurchaseId].buyer,
            price
        );

        rightIdToRightPurchase[rightOptionId][rightPurchaseId]
            .status = FINALIZED;

        emit RightOptionPurchaseFinished(rightPurchaseId);
    }

    function getRightPurchase(uint256 rightOptionId, uint256 rightPurchaseId)
        public
        view
        returns (
            address buyer,
            string memory status,
            uint256 expiry
        )
    {
        RightPurchase memory rightPurchase = rightIdToRightPurchase[
            rightOptionId
        ][rightPurchaseId];
        if (rightPurchase.status == keccak256("STAKED")) {
            status = "STAKED";
        } else if (rightPurchase.status == keccak256("BURNED")) {
            status = "BURNED";
        } else if (rightPurchase.status == keccak256("FINALIZED")) {
            status = "FINALIZED";
        }

        buyer = rightPurchase.buyer;
        expiry = rightPurchase.expiry;
    }

    function getRightOption(uint256 rightOptionId)
        public
        view
        returns (
            uint256 rightId,
            uint256 rightType,
            uint256 price,
            uint256 duration
        )
    {
        RightOption memory rightOption = idToRightOption[rightOptionId];
        rightId = rightOption.rightId;
        rightType = rightOption.rightType;
        price = rightOption.price;
        duration = rightOption.duration;
    }
}
