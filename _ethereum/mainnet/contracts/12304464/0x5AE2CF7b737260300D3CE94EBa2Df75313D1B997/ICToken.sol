pragma solidity ^0.7.0;

interface CTokenInterface {
    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral
    ) external returns (uint256);

    function liquidateBorrow(address borrower, address cTokenCollateral)
        external
        payable;

    function exchangeRateCurrent() external returns (uint256);

    function getCash() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function balanceOfUnderlying(address account) external returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalReserves() external view returns (uint256);
    
    function totalBorrows() external view returns (uint256);

    function reserveFactorMantissa() external view returns (uint256);

    function getAccountSnapshot(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function allowance(address, address) external view returns (uint256);

    function approve(address, uint256) external;

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function underlying() external returns (address);

    function mint(uint mintAmount) external returns (uint);
}
