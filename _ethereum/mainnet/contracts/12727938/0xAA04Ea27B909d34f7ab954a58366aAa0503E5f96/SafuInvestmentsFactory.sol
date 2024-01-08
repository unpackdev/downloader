// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafuInvestmentsPresale.sol";
import "./SafuInvestmentsInfo.sol";
import "./SafuInvestmentsLiquidityLock.sol";
import "./ITokenDecimals.sol";

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract SafuInvestmentsFactory {
    using SafeMath for uint256;

    event PresaleCreated(bytes32 title, uint256 safuId, address creator);

    IUniswapV2Router02 public immutable uniswapRouter;
    IUniswapV2Factory private immutable uniswapFactory;
    SafuInvestmentsInfo public immutable SAFU;
    bytes32 private immutable uniswapRouterPairForCodeHash;

    uint256 public minLiqAllocation = 25;

    constructor(
        address _safuInfo,
        address _uniswapRouter,
        bytes32 _uniswapRouterPairForCodeHash
    ) public {
        SAFU = SafuInvestmentsInfo(_safuInfo);
        IUniswapV2Router02 router = IUniswapV2Router02(_uniswapRouter);
        uniswapFactory = IUniswapV2Factory(router.factory());
        uniswapRouter = router;
        uniswapRouterPairForCodeHash = _uniswapRouterPairForCodeHash;
    }

    struct PresaleInfo {
        address tokenAddress;
        address unsoldTokensDumpAddress;
        address[] whitelistedAddresses;
        uint256 tokenPriceInWei;
        uint256 hardCapInWei;
        uint256 softCapInWei;
        uint256 maxInvestInWei;
        uint256 minInvestInWei;
        uint256 openTime;
        uint256 closeTime;
    }

    struct PresaleUniswapInfo {
        uint256 listingPriceInWei;
        uint256 liquidityAddingTime;
        uint256 lpTokensLockDurationInDays;
        uint256 liquidityPercentageAllocation;
    }

    struct PresaleStringInfo {
        bytes32 saleTitle;
        bytes32 linkTelegram;
        bytes32 linkDiscord;
        bytes32 linkTwitter;
        bytes32 linkWebsite;
    }

    // copied from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
    // calculates the CREATE2 address for a pair without making any external calls
    function uniV2LibPairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        uniswapRouterPairForCodeHash // init code hash
                    )
                )
            )
        );
    }

    function initializePresale(
        SafuInvestmentsPresale _presale,
        uint256 _totalTokens,
        uint256 _finalTokenPriceInWei,
        PresaleInfo calldata _info,
        PresaleUniswapInfo calldata _uniInfo,
        PresaleStringInfo calldata _stringInfo
    ) internal {
        _presale.setAddressInfo(msg.sender, _info.tokenAddress, _info.unsoldTokensDumpAddress);
        _presale.setGeneralInfo(
            _totalTokens,
            _finalTokenPriceInWei,
            _info.hardCapInWei,
            _info.softCapInWei,
            _info.maxInvestInWei,
            _info.minInvestInWei,
            _info.openTime,
            _info.closeTime
        );
        _presale.setUniswapInfo(
            _uniInfo.listingPriceInWei,
            _uniInfo.liquidityAddingTime,
            _uniInfo.lpTokensLockDurationInDays,
            _uniInfo.liquidityPercentageAllocation
        );
        _presale.setStringInfo(
            _stringInfo.saleTitle,
            _stringInfo.linkTelegram,
            _stringInfo.linkDiscord,
            _stringInfo.linkTwitter,
            _stringInfo.linkWebsite
        );

        _presale.addwhitelistedAddresses(_info.whitelistedAddresses);
    }

    function setMinLiqAllocation(uint256 _minLiqAllocation) external {
        require(msg.sender == SAFU.owner());
        minLiqAllocation = _minLiqAllocation;
    }

    function createPresale(
        PresaleInfo calldata _info,
        PresaleUniswapInfo calldata _uniInfo,
        PresaleStringInfo calldata _stringInfo
    ) external {
        require(
            _uniInfo.liquidityPercentageAllocation >= minLiqAllocation,
            "Liq. percentage allocation is less than the required minimum"
        );

        IERC20 token = IERC20(_info.tokenAddress);

        SafuInvestmentsPresale presale = new SafuInvestmentsPresale(
            address(this),
            SAFU.owner(),
            address(uniswapRouter)
        );

        // lp pair should not have liquidity
        address existingPairAddress = uniswapFactory.getPair(address(token), uniswapRouter.WETH());
        require(
            existingPairAddress == address(0) || token.balanceOf(existingPairAddress) == 0,
            "Token pair's liquidity had already been added"
        );

        uint256 maxEthPoolTokenAmount = _info.hardCapInWei.mul(_uniInfo.liquidityPercentageAllocation).div(100);
        uint256 tokenDecimals = 10**uint256(ITokenDecimals(address(token)).decimals());
        uint256 maxLiqPoolTokenAmount = maxEthPoolTokenAmount.mul(_uniInfo.listingPriceInWei).div(tokenDecimals);

        uint256 maxTokensToBeSold = _info.hardCapInWei.mul(_info.tokenPriceInWei).div(tokenDecimals);
        uint256 requiredTokenAmount = maxLiqPoolTokenAmount.add(maxTokensToBeSold);
        token.transferFrom(msg.sender, address(presale), requiredTokenAmount);

        initializePresale(presale, maxTokensToBeSold, _info.tokenPriceInWei, _info, _uniInfo, _stringInfo);

        address pairAddress = uniV2LibPairFor(address(uniswapFactory), address(token), uniswapRouter.WETH());

        SafuInvestmentsLiquidityLock liquidityLock = new SafuInvestmentsLiquidityLock(
            IERC20(pairAddress),
            msg.sender,
            _uniInfo.liquidityAddingTime + (_uniInfo.lpTokensLockDurationInDays * 1 days),
            address(SAFU)
        );

        uint256 safuId = SAFU.addPresaleAddress(address(presale));
        presale.setSafuInfo(address(liquidityLock), SAFU.getDevFeePercentage(), SAFU.getMinDevFeeInWei(), safuId);

        emit PresaleCreated(_stringInfo.saleTitle, safuId, msg.sender);
    }
}
