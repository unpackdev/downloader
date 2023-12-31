// SPDX-License-Identifier: BSL-1.1

pragma solidity ^0.8.14;

import "./IDarwinSwapPair.sol";
import "./IDarwinSwapFactory.sol";
import "./IDarwinSwapLister.sol";
import "./IDarwinSwapRouter.sol";
import "./ILiquidityInjector.sol";
import "./IERC20.sol";

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

contract LiquidityInjector is ILiquidityInjector {
    IDarwinSwapFactory public immutable factory;
    IDarwinSwapPair public pair;
    IDarwinSwapRouter public router;
    IDarwinSwapLister public lister;
    address public dev;
    IERC20 public token0;
    IERC20 public token1;

    modifier onlyTeamOrDev() {
        require(
            msg.sender == dev ||
                msg.sender == lister.tokenInfo(address(token0)).owner ||
                msg.sender == lister.tokenInfo(address(token1)).owner,
            "LiquidityInjector: CALLER_NOT_TOKEN_TEAM_OR_DEV"
        );
        _;
    }

    constructor() {
        factory = IDarwinSwapFactory(msg.sender);
    }

    function initialize(
        address _pair,
        address _token0,
        address _token1
    ) external {
        require(
            msg.sender == address(factory),
            "LiquidityInjector: CALLER_NOT_FACTORY"
        );
        pair = IDarwinSwapPair(_pair);
        router = IDarwinSwapRouter(factory.router());
        lister = IDarwinSwapLister(factory.lister());
        dev = factory.dev();
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        token0.approve(address(router), type(uint).max);
        token1.approve(address(router), type(uint).max);
        token0.approve(address(pair), type(uint).max);
        token1.approve(address(pair), type(uint).max);
    }

    function buyBackAndPair(IERC20 _sellToken) public onlyTeamOrDev {
        uint256 contractEthBalance = address(this).balance;

        if (contractEthBalance > 0) {
            // Wrap it into WETH
            address WETH = router.WETH();
            IWETH(WETH).deposit{value: contractEthBalance}();
        }

        IERC20 _buyToken = address(_sellToken) == address(token1)
            ? token0
            : token1;

        // Return if there is no buyToken balance in the liqInj
        if (_buyToken.balanceOf(address(this)) == 0) {
            if (_sellToken.balanceOf(address(this)) > 0) {
                buyBackAndPair(_buyToken);
            }
            return;
        }

        IDarwinSwapLister.TokenInfo memory tokenInfo = lister.tokenInfo(
            address(_sellToken)
        );

        // SWAP
        pair.swapWithoutToks(
            address(_buyToken),
            _buyToken.balanceOf(address(this)) / 2
        );
        uint balanceSellToken = _sellToken.balanceOf(address(this));
        uint balanceBuyToken = _buyToken.balanceOf(address(this));

        // PAIR
        router.addLiquidityWithoutReceipt(
            address(_sellToken),
            address(_buyToken),
            balanceSellToken,
            balanceBuyToken,
            block.timestamp + 600
        );

        emit BuyBackAndPair(
            _buyToken,
            _sellToken,
            balanceBuyToken,
            balanceSellToken
        );
    }

    receive() external payable {}
}
