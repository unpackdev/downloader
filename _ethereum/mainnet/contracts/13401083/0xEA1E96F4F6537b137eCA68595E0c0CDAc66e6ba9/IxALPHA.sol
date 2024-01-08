// SPDX-License-Identifier: ISC

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

import "./IxTokenManager.sol";
import "./IALPHAStaking.sol";
import "./IWETH.sol";
import "./IOneInchLiquidityProtocol.sol";
import "./IStakingProxy.sol";

import "./StakingFactory.sol";

interface IxALPHA {
    enum SwapMode {
        SUSHISWAP,
        UNISWAP_V3
    }

    struct FeeDivisors {
        uint256 mintFee;
        uint256 burnFee;
        uint256 claimFee;
    }

    event Stake(uint256 proxyIndex, uint256 timestamp, uint256 amount);
    event Unbond(uint256 proxyIndex, uint256 timestamp, uint256 amount);
    event Claim(uint256 proxyIndex, uint256 amount);
    event FeeDivisorsSet(uint256 mintFee, uint256 burnFee, uint256 claimFee);
    event FeeWithdraw(uint256 fee);
    event UpdateSwapRouter(SwapMode version);
    event UpdateUniswapV3AlphaPoolFee(uint24 fee);
    event UpdateStakedBalance(uint256 totalStaked);

    function initialize(
        string calldata _symbol,
        IWETH _wethToken,
        IERC20 _alphaToken,
        address _alphaStaking,
        StakingFactory _stakingFactory,
        IxTokenManager _xTokenManager,
        address _uniswapRouter,
        address _sushiswapRouter,
        FeeDivisors calldata _feeDivisors
    ) external;

    function mint(uint256 minReturn) external payable;

    function mintWithToken(uint256 alphaAmount) external;

    function calculateMintAmount(uint256 incrementalAlpha, uint256 totalSupply)
        external
        view
        returns (uint256 mintAmount);

    function burn(
        uint256 tokenAmount,
        bool redeemForEth,
        uint256 minReturn
    ) external;

    function getNav() external view returns (uint256);

    function getBufferBalance() external view returns (uint256);

    function getFundBalances() external view returns (uint256, uint256);

    function getWithdrawableAmount(uint256 proxyIndex) external view returns (uint256);

    function stake(
        uint256 proxyIndex,
        uint256 amount,
        bool force
    ) external;

    function updateStakedBalance() external;

    function unbond(uint256 proxyIndex, bool force) external;

    function claimUnbonded(uint256 proxyIndex) external;

    function pauseContract() external;

    function unpauseContract() external;

    function emergencyUnbond() external;

    function emergencyClaim() external;

    function setFeeDivisors(
        uint256 mintFeeDivisor,
        uint256 burnFeeDivisor,
        uint256 claimFeeDivisor
    ) external;

    function updateSwapRouter(SwapMode version) external;

    function updateUniswapV3AlphaPoolFee(uint24 fee) external;

    function withdrawNativeToken() external;

    function withdrawTokenFromProxy(uint256 proxyIndex, address token) external;

    function withdrawFees() external;
}
