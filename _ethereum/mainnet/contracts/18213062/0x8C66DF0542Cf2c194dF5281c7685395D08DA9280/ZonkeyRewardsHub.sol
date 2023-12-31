/**
    Website: https://zonkey.io
    Twitter: https://twitter.com/zonkeyio
    Telegram: https://t.me/zonkeyofficial
**/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Extended {
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function burnFrom(address account, uint256 amount) external;

    function circulatingSupply() external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IUniswapV2Router02 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract ZonkeyRewardsHub {
    address private constant _POOL_WALLET =
        0x94e0fbC2390b38754927Fd8AD034Df3b7569FEfb;
    address private constant _UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public immutable owner;

    mapping(address => address) public tokens;

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function burnAndClaim(address rewardToken, uint256 burnAmount) external {
        require(
            tokens[rewardToken] != address(0),
            "reward token not registered"
        );
        require(burnAmount > 0, "invalid burn amount");

        IERC20Extended rewTkn = IERC20Extended(rewardToken);
        IERC20Extended utilTkn = IERC20Extended(tokens[rewardToken]);

        uint256 utilityClaimAmount = _getClaimAmount(
            burnAmount,
            rewTkn.circulatingSupply(),
            utilTkn.balanceOf(_POOL_WALLET)
        );
        require(utilityClaimAmount > 0, "claimable utility tokens == 0");

        rewTkn.burnFrom(msg.sender, burnAmount);
        utilTkn.transferFrom(_POOL_WALLET, msg.sender, utilityClaimAmount);
    }

    function configureToken(
        address rewardToken,
        address utilityToken
    ) external onlyOwner {
        require(utilityToken != address(0), "cannot unregister token");
        tokens[rewardToken] = utilityToken;
    }

    function convertPool(address rewardToken) external onlyOwner {
        IERC20Extended rewTkn = IERC20Extended(rewardToken);

        uint256 poolBalance = rewTkn.balanceOf(_POOL_WALLET);
        require(poolBalance > 0, "pool reward token balance == 0");

        uint256 allowance = rewTkn.allowance(address(this), _UNISWAP_V2_ROUTER);
        if (allowance < poolBalance)
            rewTkn.approve(_UNISWAP_V2_ROUTER, type(uint256).max);

        rewTkn.transferFrom(_POOL_WALLET, address(this), poolBalance);

        address[] memory path = new address[](3);
        path[0] = rewardToken;
        path[1] = _WETH;
        path[2] = tokens[rewardToken];

        IUniswapV2Router02(_UNISWAP_V2_ROUTER)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                poolBalance,
                0,
                path,
                _POOL_WALLET,
                block.timestamp
            );
    }

    function getClaimAmount(
        address rewardToken,
        uint256 burnAmount
    ) external view returns (uint256) {
        return
            _getClaimAmount(
                burnAmount,
                IERC20Extended(rewardToken).circulatingSupply(),
                IERC20Extended(tokens[rewardToken]).balanceOf(_POOL_WALLET)
            );
    }

    function withdrawERC20(address token, uint256 amount) external onlyOwner {
        IERC20Extended(token).transfer(owner, amount);
    }

    function withdrawETH(uint256 amount) external onlyOwner {
        (bool success, ) = owner.call{value: amount}("");
        require(success);
    }

    function _getClaimAmount(
        uint256 rewardBurnAmount,
        uint256 rewardCirculatingSupply,
        uint256 utilityTokensInPool
    ) internal pure returns (uint256) {
        if (
            rewardBurnAmount == 0 ||
            rewardCirculatingSupply == 0 ||
            utilityTokensInPool == 0
        ) return 0;

        uint256 supplyPercentage = (rewardBurnAmount * 100_000) /
            rewardCirculatingSupply;
        return (supplyPercentage * utilityTokensInPool) / 100_000;
    }
}