pragma solidity 0.6.10;
import "./IJasperVault.sol";
import "./IERC20.sol";

interface ILeverageModule {
    function initialize(
        IJasperVault _jasperVault
    ) external;

    function borrow(           
           IJasperVault _jasperVault,
           IERC20 _borrowAsset,
           uint256 _borrowQuantityUnits) external;

    function  repay(
        IJasperVault _jasperVault,
        IERC20 _repayAsset,
        uint256 _redeemQuantityUnits,
        bool  _isAllRepay
    ) external;      

    function lever(
        IJasperVault _jasperVault,
        IERC20 _borrowAsset,
        IERC20 _collateralAsset,
        uint256 _borrowQuantityUnits,
        uint256 _minReceiveQuantityUnits,
        string memory _tradeAdapterName,
        bytes memory _tradeData
    ) external;

    function delever(
        IJasperVault _jasperVault,
        IERC20 _collateralAsset,
        IERC20 _repayAsset,
        uint256 _redeemQuantityUnits,
        uint256 _minRepayQuantityUnits,
        string memory _tradeAdapterName,
        bytes memory _tradeData
    ) external;

    function deleverToZeroBorrowBalance(
        IJasperVault _jasperVault,
        IERC20 _collateralAsset,
        IERC20 _repayAsset,
        uint256 _redeemQuantityUnits,
        string memory _tradeAdapterName,
        bytes memory _tradeData
    ) external;
}
