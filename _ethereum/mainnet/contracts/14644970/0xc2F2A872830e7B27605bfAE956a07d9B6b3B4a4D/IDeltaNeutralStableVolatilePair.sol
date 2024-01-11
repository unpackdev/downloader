pragma solidity 0.8.6;


interface IDeltaNeutralStableVolatilePair {

    struct Amounts {
        uint stable;
        uint vol;
    }

    struct UniArgs {
        uint amountStableMin;
        uint amountVolMin;
        uint deadline;
        address[] swapPath;
        uint swapAmountOutMin;
    }

    function deposit(
        uint amountStableDesired,
        uint amountVolDesired,
        UniArgs calldata uniArgs,
        address to
    ) external payable;

    function withdraw(
        uint liquidity,
        UniArgs calldata uniArgs
    ) external;

    // TODO return token addresses
    function getReserves(uint amountStable, uint amountVol, uint amountUniLp) external returns (uint, uint, uint);

    function rebalanceAuto(
        address user,
        uint feeAmount,
        uint maxGasPrice
    ) external;

    function getDebtBps() external returns (uint ownedAmountVol, uint debtAmountVol, uint debtBps);

    function setMinBps(uint newMinBps) external;

    function setMaxBps(uint newMaxBps) external;

    function newPath(address src, address dest) external pure returns (address[] memory);
}
