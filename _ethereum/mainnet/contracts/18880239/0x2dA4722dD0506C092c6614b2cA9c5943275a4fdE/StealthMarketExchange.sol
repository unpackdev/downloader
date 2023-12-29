// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./IERC20.sol";

enum Status {
    UNREQUESTED,
    REQUESTED,
    COMPLETED,
    CANCELED
}

struct Swap {
    address creator;
    address sellToken;
    address buyToken;
    uint256 sellAmount;
    uint256 buyAmount;
    Status status;
}

contract StealthMarketExchange {
    uint256 private swapCount;

    mapping(uint256 => Swap) public swaps;

    event SwapCreated(
        address indexed creator,
        address indexed sellToken,
        address indexed buyToken,
        uint256 sellAmount,
        uint256 buyAmount,
        uint256 swapId
    );

    event SwapCancelled(
        address indexed cancelor,
        address indexed sellToken,
        address indexed buyToken,
        uint256 sellAmount,
        uint256 buyAmount,
        uint256 swapId
    );

    event SwapCompleted(
        address indexed seller,
        address indexed buyer,
        address sellToken,
        address buyToken,
        uint256 sellAmount,
        uint256 buyAmount,
        uint256 swapId
    );

    constructor() {}

    receive() external payable {}

    function createSwap(
        address sellToken,
        address buyToken,
        uint256 sellAmount,
        uint256 buyAmount
    ) external payable {
        if (sellToken == address(0)) {
            require(
                msg.value == sellAmount,
                "Exchange: sell ETH value mismatch"
            );
        } else {
            IERC20(sellToken).transferFrom(
                msg.sender,
                address(this),
                sellAmount
            );
        }

        swaps[swapCount] = Swap({
            creator: msg.sender,
            sellToken: sellToken,
            buyToken: buyToken,
            sellAmount: sellAmount,
            buyAmount: buyAmount,
            status: Status.REQUESTED
        });

        emit SwapCreated(
            msg.sender,
            sellToken,
            buyToken,
            sellAmount,
            buyAmount,
            swapCount
        );

        unchecked {
            swapCount += 1;
        }
    }

    function cancelSwap(uint256 swapNumber) external {
        Swap storage swap = swaps[swapNumber];

        require(swap.creator == msg.sender, "Exchange: not creator");
        require(
            swap.status == Status.REQUESTED,
            "Exchange: should be requested"
        );

        swap.status = Status.CANCELED;

        if (swap.sellToken == address(0)) {
            (bool success, ) = payable(msg.sender).call{value: swap.sellAmount}(
                ""
            );
            require(success, "Exchange: failed to revert sell ETH");
        } else {
            require(
                IERC20(swap.sellToken).transfer(msg.sender, swap.sellAmount),
                "Exchange: failed to revert sell token"
            );
        }

        emit SwapCancelled(
            msg.sender,
            swap.sellToken,
            swap.buyToken,
            swap.sellAmount,
            swap.buyAmount,
            swapNumber
        );
    }

    function completeSwap(uint256 swapNumber) external payable {
        Swap storage swap = swaps[swapNumber];

        require(swap.creator != msg.sender, "Exchange: you are creator");
        require(
            swap.status == Status.REQUESTED,
            "Exchange: should be requested"
        );

        swap.status = Status.COMPLETED;

        if (swap.sellToken == address(0)) {
            (bool success, ) = payable(msg.sender).call{value: swap.sellAmount}(
                ""
            );
            require(success, "Exchange: failed to transfer sell ETH");
        } else {
            require(
                IERC20(swap.sellToken).transfer(msg.sender, swap.sellAmount),
                "Exchange: failed to transfer sell token"
            );
        }

        if (swap.buyToken == address(0)) {
            require(
                msg.value == swap.buyAmount,
                "Exchange: buy ETH value mismatch"
            );
            (bool success, ) = payable(swap.creator).call{
                value: swap.buyAmount
            }("");
            require(success, "Exchange: failed to transfer buy ETH");
        } else {
            require(
                IERC20(swap.buyToken).transferFrom(
                    msg.sender,
                    swap.creator,
                    swap.buyAmount
                ),
                "Exchange: failed to transfer buy token"
            );
        }

        emit SwapCompleted(
            swap.creator,
            msg.sender,
            swap.sellToken,
            swap.buyToken,
            swap.sellAmount,
            swap.buyAmount,
            swapNumber
        );
    }
}
