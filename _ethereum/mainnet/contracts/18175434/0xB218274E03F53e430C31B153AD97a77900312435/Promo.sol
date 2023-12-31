// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        //amount of tokens we are sending in
        uint256 amountIn,
        //the minimum amount of tokens we want out of the trade
        uint256 amountOutMin,
        //list of token addresses we are going to trade in.  this is necessary to calculate amounts
        address[] calldata path,
        //this is the address we are going to send the output tokens to
        address to,
        //the last time that the trade is valid for
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract TokenUtility {
    mapping(address => bool) public whitelist;

    address private UNISWAP_V2_ROUTER = 0x327Df1E6de05895d2ab08513aaDD9313Fe505d86;

    address private WETH = 0x4200000000000000000000000000000000000006;

    uint256 private MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    constructor() {
        whitelist[msg.sender] = true;
    }

    function addToWhitelist(address[] calldata toAddAddresses) external {
        require(whitelist[msg.sender], "NOT_IN_WHITELIST");
        for (uint256 i = 0; i < toAddAddresses.length; i++) {
            whitelist[toAddAddresses[i]] = true;
        }
    }

    function removeFromWhitelist(address[] calldata toRemoveAddresses)
        external
    {
        require(whitelist[msg.sender], "NOT_IN_WHITELIST");
        for (uint256 i = 0; i < toRemoveAddresses.length; i++) {
            delete whitelist[toRemoveAddresses[i]];
        }
    }

    function swapsVoume(address token, uint256 count) external {
        require(whitelist[msg.sender], "NOT_IN_WHITELIST");

        uint256 amountWETH = IERC20(WETH).balanceOf(msg.sender);

        IERC20(WETH).transferFrom(msg.sender, address(this), amountWETH);
        IERC20(WETH).approve(UNISWAP_V2_ROUTER, MAX_INT);
        IERC20(token).approve(UNISWAP_V2_ROUTER, MAX_INT);

        address[] memory pathBuy = new address[](2);
        pathBuy[0] = WETH;
        pathBuy[1] = token;

        address[] memory pathSell = new address[](2);
        pathSell[0] = token;
        pathSell[1] = WETH;

        for (uint256 i = 0; i < count; i++) {
            uint256 amountBuy = IERC20(WETH).balanceOf(address(this));
            uint256[] memory amounts = IUniswapV2Router(UNISWAP_V2_ROUTER)
                .swapExactTokensForTokens(
                    amountBuy,
                    0,
                    pathBuy,
                    address(this),
                    block.timestamp
                );

            IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
                amounts[amounts.length - 1],
                0,
                pathSell,
                address(this),
                block.timestamp
            );
        }

        IERC20(WETH).transfer(
            msg.sender,
            IERC20(WETH).balanceOf(address(this))
        );
    }

    function withdraw() external payable {
        require(whitelist[msg.sender], "NOT_IN_WHITELIST");
        IERC20(WETH).transfer(
            msg.sender,
            IERC20(WETH).balanceOf(address(this))
        );
    }
}
