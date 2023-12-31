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

    function burn(address account, uint256 amount) external;

    function circulatingSupply() external view returns (uint256);

    function transfer(
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
    uint256 private constant _MAX_INT = type(uint256).max;
    address private constant _UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public immutable owner;

    mapping(address => bool) public activeRewardTokens;
    mapping(address => address) _rewardUtilityMap;

    struct RescueCall {
        address to;
        bytes data;
        uint256 value;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setTokenConfiguration(
        bool active,
        address rewardTokenAddr,
        address utilityToken
    ) external onlyOwner {
        activeRewardTokens[rewardTokenAddr] = active;
        _rewardUtilityMap[rewardTokenAddr] = utilityToken;
    }

    function swapRewardBalanceForUtilityTokens(
        address rewardToken
    ) external onlyOwner {
        require(activeRewardTokens[rewardToken], "reward token not active");

        IERC20Extended token = IERC20Extended(rewardToken);

        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "reward token balance == 0");

        uint256 allowance = token.allowance(address(this), _UNISWAP_V2_ROUTER);
        if (allowance < balance)
            require(
                _approveToken(rewardToken, _UNISWAP_V2_ROUTER, _MAX_INT),
                "not approved for uniswap"
            );

        address[] memory path = new address[](3);
        path[0] = rewardToken;
        path[1] = _WETH;
        path[2] = _rewardUtilityMap[rewardToken];

        IUniswapV2Router02(_UNISWAP_V2_ROUTER)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                balance,
                0,
                path,
                address(this),
                block.timestamp
            );
    }

    function burnAndClaim(
        address rewardTokenAddress,
        uint256 rewardBurnAmount
    ) external {
        require(
            activeRewardTokens[rewardTokenAddress],
            "reward token not active"
        );
        require(rewardBurnAmount > 0, "burn amount <= 0");

        IERC20Extended rewardToken = IERC20Extended(rewardTokenAddress);
        IERC20Extended utilityToken = IERC20Extended(
            _rewardUtilityMap[rewardTokenAddress]
        );

        uint256 utilityClaimAmount = _getClaimAmount(
            rewardBurnAmount,
            rewardToken.circulatingSupply(),
            utilityToken.balanceOf(address(this))
        );
        require(utilityClaimAmount > 0, "claimable utility tokens == 0");

        rewardToken.burn(msg.sender, rewardBurnAmount);
        utilityToken.transfer(msg.sender, utilityClaimAmount);
    }

    function getClaimAmount(
        address rewardTokenAddress,
        uint256 rewardBurnAmount
    ) external view returns (uint256) {
        return
            _getClaimAmount(
                rewardBurnAmount,
                IERC20Extended(rewardTokenAddress).circulatingSupply(),
                IERC20Extended(_rewardUtilityMap[rewardTokenAddress]).balanceOf(
                    address(this)
                )
            );
    }

    function _approveToken(
        address token,
        address spender,
        uint256 amount
    ) internal returns (bool) {
        return IERC20Extended(token).approve(spender, amount);
    }

    function _getClaimAmount(
        uint256 rewardBurnAmount,
        uint256 rewardCirculatingSupply,
        uint256 contractUtilityBalance
    ) internal pure returns (uint256) {
        if (rewardBurnAmount == 0) return 0;
        if (rewardCirculatingSupply == 0) return 0;
        if (contractUtilityBalance == 0) return 0;

        uint256 supplyPercentage = ((rewardBurnAmount * 100_000) /
            rewardCirculatingSupply);
        return (supplyPercentage * contractUtilityBalance) / 100_000;
    }

    function rescueTokens(
        RescueCall[] calldata calls
    ) external payable onlyOwner {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, ) = payable(calls[i].to).call{value: calls[i].value}(
                calls[i].data
            );
            require(success);
        }
    }
}