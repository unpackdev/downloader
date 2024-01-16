// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./ECDSA.sol";

import "./IRoyaltyEngine.sol";
import "./ISeaport.sol";

contract SimpleWallet is Ownable {
    // Structs

    struct Execution {
        address to;
        bytes data;
        uint256 value;
    }

    // Errors

    error InvalidListing();
    error UnsuccessfulExecution();

    // Constants

    ISeaport public constant SEAPORT =
        ISeaport(0x00000000006c3852cbEf3e08E8dF289169EdE581);
    IRoyaltyEngine public constant ROYALTY_ENGINE =
        IRoyaltyEngine(0x0385603ab55642cb4Dd5De3aE9e306809991804f);

    bytes32 public immutable SEAPORT_DOMAIN_SEPARATOR;

    // Constructor

    constructor() {
        (, SEAPORT_DOMAIN_SEPARATOR, ) = SEAPORT.information();
    }

    // Receive fallback

    receive() external payable {}

    // Generic execute

    function execute(Execution[] calldata executions) public payable onlyOwner {
        uint256 length = executions.length;
        for (uint256 i = 0; i < length; ) {
            (bool success, ) = payable(executions[i].to).call{
                value: executions[i].value
            }(executions[i].data);
            if (!success) {
                revert UnsuccessfulExecution();
            }

            unchecked {
                ++i;
            }
        }
    }

    // ERC1271

    function isValidSignature(bytes32 digest, bytes memory signature)
        external
        view
        returns (bytes4)
    {
        (
            address collection,
            uint256 tokenId,
            ,
            ,
            ,
            ,
            ISeaport.ConsiderationItem[] memory consideration,
            bytes memory orderSignature
        ) = abi.decode(
                signature,
                (
                    address,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    bytes32,
                    ISeaport.ConsiderationItem[],
                    bytes
                )
            );

        ISeaport.OfferItem[] memory offer = new ISeaport.OfferItem[](1);
        offer[0] = ISeaport.OfferItem(
            ISeaport.ItemType.ERC721,
            collection,
            tokenId,
            1,
            1
        );

        uint256 price;
        uint256 considerationLength = consideration.length;
        for (uint256 i = 0; i < considerationLength; ) {
            if (
                consideration[i].itemType != ISeaport.ItemType.NATIVE ||
                consideration[i].startAmount != consideration[i].endAmount
            ) {
                revert InvalidListing();
            }

            price += consideration[i].endAmount;

            unchecked {
                ++i;
            }
        }

        // Avoid "Stack too deep" errors
        {
            (
                address[] memory recipients,
                uint256[] memory amounts
            ) = ROYALTY_ENGINE.getRoyaltyView(collection, tokenId, price);

            uint256 diff = considerationLength - amounts.length;
            for (uint256 i = diff; i < considerationLength; ) {
                if (
                    consideration[i].recipient != recipients[i - diff] ||
                    consideration[i].endAmount != amounts[i - diff]
                ) {
                    revert InvalidListing();
                }

                unchecked {
                    ++i;
                }
            }
        }

        // Avoid "Stack too deep" errors
        bytes32 orderHash;
        {
            (
                ,
                ,
                uint256 startTime,
                uint256 endTime,
                uint256 salt,
                bytes32 conduitKey
            ) = abi.decode(
                    signature,
                    (address, uint256, uint256, uint256, uint256, bytes32)
                );

            ISeaport.OrderComponents memory order;
            order.offerer = address(this);
            // order.zone = address(0);
            order.offer = offer;
            order.consideration = consideration;
            // order.orderType = ISeaport.OrderType.FULL_OPEN;
            order.startTime = startTime;
            order.endTime = endTime;
            // order.zoneHash = bytes32(0);
            order.salt = salt;
            order.conduitKey = conduitKey;
            order.counter = SEAPORT.getCounter(address(this));

            orderHash = SEAPORT.getOrderHash(order);
        }

        if (
            digest !=
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    SEAPORT_DOMAIN_SEPARATOR,
                    orderHash
                )
            )
        ) {
            revert InvalidListing();
        }

        address signer = ECDSA.recover(digest, orderSignature);
        if (signer != owner()) {
            revert InvalidListing();
        }

        return this.isValidSignature.selector;
    }

    // ERC721 receive hook

    function onERC721Received(
        address, // operator
        address, // from
        uint256, // tokenId
        bytes calldata // data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // ERC1155 receive hooks

    function onERC1155Received(
        address, // operator
        address, // from
        uint256, // id
        uint256, // value
        bytes calldata // data
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, // operator
        address, // from
        uint256[] calldata, // ids
        uint256[] calldata, // values
        bytes calldata // data
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
