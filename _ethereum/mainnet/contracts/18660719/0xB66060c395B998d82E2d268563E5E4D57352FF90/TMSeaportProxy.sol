// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./SeaportInterface.sol";

contract TMSeaportProxy is Ownable, Pausable {
    SeaportInterface seaport;
    address kyberRouter;
    address constant NativeAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    error InsufficientBalance(
        address token,
        uint256 available,
        uint256 required
    );
    error SwapFailed();

    error WrongInput();

    constructor(SeaportInterface _seaport, address _kyberRouter) {
        seaport = _seaport;
        kyberRouter = _kyberRouter;
    }

    function changeSeaport(
        SeaportInterface _seaport
    ) external onlyOwner whenPaused {
        seaport = _seaport;
    }

    function changeRouter(address _kyberRouter) external onlyOwner whenPaused {
        kyberRouter = _kyberRouter;
    }

    receive() external payable {}

    function unpause() external onlyOwner {
        _unpause();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function approveToken(
        address token,
        address spender,
        uint amount
    ) external onlyOwner {
        IERC20(token).approve(spender, amount);
    }

    function rescueFunds(IERC20 token, uint256 amount) external onlyOwner {
        if (address(token) == NativeAddress) {
            payable(msg.sender).transfer(amount);
        } else {
            token.transfer(msg.sender, amount);
        }
    }

    function swapToFulfill(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient,
        bytes calldata swapData,
        address tokenIn,
        uint256 amountIn
    ) external payable whenNotPaused {
        // check consideration items
        address token;
        uint256 fulfillAmount = 0;
        uint256 returnAmount = 0;
        {
            if (tokenIn != NativeAddress) {
                IERC20(tokenIn).transferFrom(
                    msg.sender,
                    address(this),
                    amountIn
                );
                IERC20(tokenIn).approve(kyberRouter, amountIn);
            }
            //
            ConsiderationItem[] memory considerations = advancedOrder
                .parameters
                .consideration;

            token = address(considerations[0].token);
            for (uint i = 0; i < considerations.length; i++) {
                if (
                    considerations[i].token != token ||
                    considerations[i].startAmount != considerations[i].endAmount
                ) {
                    revert WrongInput();
                }
                fulfillAmount += considerations[i].endAmount;
            }
            fulfillAmount =
                (fulfillAmount * advancedOrder.numerator) /
                advancedOrder.denominator;

            //swap to consideration token
            (bool success, bytes memory data) = kyberRouter.call{
                value: msg.value
            }(swapData);

            if (!success) {
                revert SwapFailed();
            }
            (returnAmount, ) = abi.decode(data, (uint256, uint256));

            if (returnAmount < fulfillAmount) {
                revert InsufficientBalance(
                    address(considerations[0].token),
                    returnAmount,
                    fulfillAmount
                );
            }
        }
        // fulfill order!
        seaport.fulfillAdvancedOrder(
            advancedOrder,
            criteriaResolvers,
            fulfillerConduitKey,
            recipient
        );
        if (returnAmount > fulfillAmount)
            IERC20(token).transfer(msg.sender, returnAmount - fulfillAmount);
    }
}
