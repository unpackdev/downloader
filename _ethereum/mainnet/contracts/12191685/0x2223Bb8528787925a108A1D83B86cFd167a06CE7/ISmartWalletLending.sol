pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "./IERC20Ext.sol";
import "./IAaveLendingPoolV2.sol";
import "./IAaveLendingPoolV1.sol";
import "./IWeth.sol";
import "./ICompErc20.sol";


interface ISmartWalletLending {

    event ClaimedComp(
        address[] holders,
        ICompErc20[] cTokens,
        bool borrowers,
        bool suppliers
    );

    enum LendingPlatform { AAVE_V1, AAVE_V2, COMPOUND }

    struct UserReserveData {
        uint256 currentATokenBalance;
        uint256 liquidityRate;
        uint256 poolShareInPrecision;
        bool usageAsCollateralEnabled;
        // Aave v1 data
        uint256 currentBorrowBalance;
        uint256 principalBorrowBalance;
        uint256 borrowRateMode;
        uint256 borrowRate;
        uint256 originationFee;
        // Aave v2 data
        uint256 currentStableDebt;
        uint256 currentVariableDebt;
        uint256 principalStableDebt;
        uint256 scaledVariableDebt;
        uint256 stableBorrowRate;
    }

    function updateAaveLendingPoolData(
        IAaveLendingPoolV2 poolV2,
        IProtocolDataProvider provider,
        IAaveLendingPoolV1 poolV1,
        address lendingPoolCoreV1,
        uint16 referalCode,
        IWeth weth,
        IERC20Ext[] calldata tokens
    ) external;

    function updateCompoundData(
        address _comptroller,
        address _cEth,
        address[] calldata _cTokens
    ) external;

    function depositTo(
        LendingPlatform platform,
        address payable onBehalfOf,
        IERC20Ext token,
        uint256 amount
    ) external;

    function borrowFrom(
        LendingPlatform platform,
        address payable onBehalfOf,
        IERC20Ext token,
        uint256 borrowAmount,
        uint256 interestRateMode
    ) external;

    function withdrawFrom(
        LendingPlatform platform,
        address payable onBehalfOf,
        IERC20Ext token,
        uint256 amount,
        uint256 minReturn
    ) external returns (uint256 returnedAmount);

    function repayBorrowTo(
        LendingPlatform platform,
        address payable onBehalfOf,
        IERC20Ext token,
        uint256 amount,
        uint256 payAmount,
        uint256 rateMode // only for aave v2
    ) external;
    
    function claimComp(
        address[] calldata holders,
        ICompErc20[] calldata cTokens,
        bool borrowers,
        bool suppliers
    ) external;

    function storeAndRetrieveUserDebtCurrent(
        LendingPlatform platform,
        address _reserve,
        address _user
    ) external returns (uint256 debt);

    function getLendingToken(LendingPlatform platform, IERC20Ext token) external view returns(address);

    function getUserDebtStored(LendingPlatform platform, address reserve, address user)
        external
        view
        returns (uint256 debt);
}
