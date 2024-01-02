// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "./IWETH.sol";
import "./IAave.sol";
import "./IStETH.sol";
import "./ICurve.sol";
import "./IWstETH.sol";
import "./IAaveHub.sol";
import "./IWiseLending.sol";
import "./IWiseSecurity.sol";
import "./IPositionNFTs.sol";
import "./IWiseOracleHub.sol";
import "./IBalancerFlashloan.sol";

import "./TransferHelper.sol";
import "./ApprovalHelper.sol";

error Deactivated();
error InvalidParam();
error InvalidOwner();
error AccessDenied();
error AmountTooSmall();
error LeverageTooHigh();
error DebtRatioTooLow();
error NotBalancerVault();
error DebtRatioTooHigh();
error ResultsInBadDebt();

contract wstETHFarmDeclarations is
    TransferHelper,
    ApprovalHelper
{
    // Mapping of {KeyNFT} to type of pool
    mapping(uint256 => bool) public isAave;

    // Bool indicating that a power farm is deactivated
    bool public isShutdown;

    // Bool gating for callback (flashloan balancer)
    bool public allowEnter;

    // Bool indicating ETH transfer in progress
    bool public sendingProgress;

    // Corresponding Aave borrow token used by farm
    address public immutable aaveTokenAddresses;

    // Borrow token used by farm
    address public immutable borrowTokenAddresses;

    // Referral address used for lido
    address public referralAddress;

    // Collateral factor used for sDAI collateral
    uint256 public collateralFactor;

    IWETH public immutable WETH;
    IAave public immutable AAVE;
    ICurve public immutable CURVE;
    IStETH public immutable ST_ETH;
    IWstETH public immutable WST_ETH;
    IAaveHub public immutable AAVE_HUB;
    IWiseLending public immutable WISE_LENDING;
    IWiseOracleHub public immutable ORACLE_HUB;
    IWiseSecurity public immutable WISE_SECURITY;
    IBalancerVault public immutable BALANCER_VAULT;
    IPositionNFTs public immutable POSITION_NFT;

    // @TODO: need to fetch from AAVE_HUB
    address internal constant AAVE_ADDRESS = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;

    // @TODO: need to fetch from WISE_LENDING
    address internal constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // @TODO: can we fetch this from somewhere dynamically? if not pass in constructor
    address internal constant ST_ETH_ADDRESS = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    // @TODO: can we fetch this from somewhere dynamically? if not pass in constructor
    address internal constant WST_ETH_ADDRESS = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    // @TODO: can we fetch this from somewhere dynamically? if not pass in constructor
    address internal constant BALANCER_ADDRESS = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    // @TODO: need to fetch from WISE_LENDING
    address internal constant AAVE_HUB_ADDRESS = 0xCd87EDBb1eCF759162f4F0462CfdD2A913A96C7d;

    // @TODO: need to fetch from AAVE_HUB
    address internal constant AAVE_WETH_ADDRESS = 0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8;

    // @TODO: can we fetch this from somewhere dynamically? if not pass in constructor
    address internal constant CURVE_POOL_ADDRESS = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;

    // Math constant for computations
    uint256 internal constant PRECISION_FACTOR_E18 = 1E18;

    // Maximal allowed leverage factor
    uint256 internal constant MAX_LEVERAGE = 15 * PRECISION_FACTOR_E18;

    // Minimal required deposit amount for leveraged postion in ETH
    uint256 public minDepositEthAmount = 3 * PRECISION_FACTOR_E18;

    // Max possible amount for uint256
    uint256 internal constant MAX_AMOUNT = type(uint256).max;

    event FarmEntry(
        uint256 indexed keyId,
        uint256 indexed wiseLendingNFT,
        uint256 indexed leverage,
        uint256 amount,
        uint256 timestamp
    );

    event FarmExit(
        uint256 indexed keyId,
        uint256 indexed wiseLendingNFT,
        uint256 amount,
        uint256 timestamp
    );

    event FarmStatus(
        bool indexed state,
        uint256 timestamp
    );

    event ReferralUpdate(
        address indexed referralAddress,
        uint256 timestamp
    );

    event ManualPaybackShares(
        uint256 indexed keyId,
        uint256 indexed wiseLendingNFT,
        uint256 amount,
        uint256 timestamp
    );

    event ManualWithdrawShares(
        uint256 indexed keyId,
        uint256 indexed wiseLendingNFT,
        uint256 amount,
        uint256 timestamp
    );

    event BaseUrlChange(
        string baseUrl,
        uint256 timestamp
    );

    event BaseExtensionChange(
        string baseExtension,
        uint256 timestamp
    );

    event MinDepositChange(
        uint256 minDepositEthAmount,
        uint256 timestamp
    );

    event ETHReceived(
        uint256 amount,
        address from
    );

    event RegistrationFarm(
        uint256 nftId,
        uint256 timestamp
    );

    constructor(
        address _wiseLendingAddress,
        uint256 _collateralFactor
    ) {
        WISE_LENDING = IWiseLending(
            _wiseLendingAddress
        );

        ORACLE_HUB = IWiseOracleHub(
            WISE_LENDING.WISE_ORACLE()
        );

        BALANCER_VAULT = IBalancerVault(
            BALANCER_ADDRESS
        );

        WISE_SECURITY = IWiseSecurity(
            WISE_LENDING.WISE_SECURITY()
        );

        AAVE = IAave(
            AAVE_ADDRESS
        );

        WETH = IWETH(
            WETH_ADDRESS
        );

        ST_ETH = IStETH(
            ST_ETH_ADDRESS
        );

        WST_ETH = IWstETH(
            WST_ETH_ADDRESS
        );

        AAVE_HUB = IAaveHub(
            AAVE_HUB_ADDRESS
        );

        CURVE = ICurve(
            CURVE_POOL_ADDRESS
        );

        POSITION_NFT = IPositionNFTs(
            WISE_LENDING.POSITION_NFT()
        );

        collateralFactor = _collateralFactor;

        borrowTokenAddresses = WETH_ADDRESS;
        aaveTokenAddresses = AAVE_WETH_ADDRESS;

        _doApprovals(
            _wiseLendingAddress
        );
    }

    function doApprovals()
        external
    {
        _doApprovals(
            address(WISE_LENDING)
        );
    }

    function _doApprovals(
        address _wiseLendingAddress
    )
        internal
    {
        _safeApprove(
            WETH_ADDRESS,
            _wiseLendingAddress,
            MAX_AMOUNT
        );

        _safeApprove(
            ST_ETH_ADDRESS,
            WST_ETH_ADDRESS,
            MAX_AMOUNT
        );

        _safeApprove(
            WST_ETH_ADDRESS,
            address(WISE_LENDING),
            MAX_AMOUNT
        );

        _safeApprove(
            ST_ETH_ADDRESS,
            CURVE_POOL_ADDRESS,
            MAX_AMOUNT
        );
    }

    modifier isActive() {
        if (isShutdown == true) {
            revert Deactivated();
        }
        _;
    }
}
