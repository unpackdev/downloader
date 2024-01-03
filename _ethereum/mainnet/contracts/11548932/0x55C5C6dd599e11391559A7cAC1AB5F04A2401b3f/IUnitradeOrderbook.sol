// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
enum OrderState {Placed, Cancelled, Executed}

interface UnitradeInterface {
    function cancelOrder(uint256 orderId) external returns (bool);

    function executeOrder(uint256 orderId)
        external
        returns (uint256[] memory amounts);

    function feeDiv() external view returns (uint16);

    function feeMul() external view returns (uint16);

    function getActiveOrderId(uint256 index) external view returns (uint256);

    function getActiveOrdersLength() external view returns (uint256);

    function getOrder(uint256 orderId)
        external
        view
        returns (
            uint8 orderType,
            address maker,
            address tokenIn,
            address tokenOut,
            uint256 amountInOffered,
            uint256 amountOutExpected,
            uint256 executorFee,
            uint256 totalEthDeposited,
            OrderState orderState,
            bool deflationary
        );

    function getOrderIdForAddress(address _address, uint256 index)
        external
        view
        returns (uint256);

    function getOrdersForAddressLength(address _address)
        external
        view
        returns (uint256);

    function incinerator() external view returns (address);

    function owner() external view returns (address);

    function placeOrder(
        uint8 orderType,
        address tokenIn,
        address tokenOut,
        uint256 amountInOffered,
        uint256 amountOutExpected,
        uint256 executorFee
    ) external returns (uint256);

    function renounceOwnership() external;

    function splitDiv() external view returns (uint16);

    function splitMul() external view returns (uint16);

    function staker() external view returns (address);

    function transferOwnership(address newOwner) external;

    function uniswapV2Factory() external view returns (address);

    function uniswapV2Router() external view returns (address);

    function updateFee(uint16 _feeMul, uint16 _feeDiv) external;

    function updateOrder(
        uint256 orderId,
        uint256 amountInOffered,
        uint256 amountOutExpected,
        uint256 executorFee
    ) external returns (bool);

    function updateSplit(uint16 _splitMul, uint16 _splitDiv) external;

    function updateStaker(address newStaker) external;
}
