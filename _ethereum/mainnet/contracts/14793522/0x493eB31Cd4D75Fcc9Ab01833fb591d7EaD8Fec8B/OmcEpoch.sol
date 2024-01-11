//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./OmcDistributor.sol";
import "./Omc.sol";
import "./IOmcEpoch.sol";
import "./OMCLib.sol";

contract OmcEpoch is IOmcEpoch {
    address private _owner;
    address public receiver;
    address public omcDistributor;
    address public miner;
    uint256 public epochNum;
    address public omc;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public distributeInterval = 2880;
    address public constant uniswapRouterV2 =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant uniswapFactoryV2 =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    uint256 public lastDistributeBlockHeight;

    modifier onlyMiner() {
        require(msg.sender == miner, "ONLY MINER");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "ONLY OWNER");
        _;
    }

    constructor(address _miner, address _omc) {
        _owner = msg.sender;
        miner = _miner;
        omc = _omc;
    }

    function setOmc(address _newOmc) external override onlyOwner {
        omc = _newOmc;
    }

    function setOmcDistributor(address _newOmcDistributor)
        external
        override
        onlyOwner
    {
        omcDistributor = _newOmcDistributor;
    }

    function setReceiver(address _newReceiver) external override onlyOwner {
        receiver = _newReceiver;
        emit ReceipientModification(_newReceiver);
    }

    function setMiner(address _newMiner) external override onlyOwner {
        miner = _newMiner;
    }

    function setDistributeInterval(uint256 _newDistributeInterval)
        external
        override
        onlyOwner
    {
        distributeInterval = _newDistributeInterval;
    }

    function distribute() external override onlyMiner {
        require(receiver != address(0), "RECEIVER NOT SET");
        require(
            lastDistributeBlockHeight + distributeInterval <= block.number,
            "TOO FREQUENT DISTRIBUTE"
        );

        uint256 balance = IERC20(WETH).balanceOf(address(this));
        require(balance > 0, "NOTHING TO DISTRIBUTE");

        uint256 totalSupply = Omc(omc).getTotalSupply();
        require(totalSupply > 0, "ZERO TOTAL SUPPLY");

        lastDistributeBlockHeight = block.number;

        uint256 epochReward = balance / 2;

        OmcDistributor(omcDistributor).compound(
            epochNum,
            epochReward,
            totalSupply
        );

        epochNum += 1;

        OMCLib._safeTransfer(WETH, receiver, epochReward);
        OMCLib._safeTransfer(WETH, omcDistributor, epochReward);

        emit RoyaltyDistribution(omcDistributor, epochReward);
    }

    function swapTokenForWETH(address _token) external override onlyMiner {
        uint256 amountIn = IERC20(_token).balanceOf(address(this));
        require(amountIn > 0, "ZERO BALANCE");

        address pool = IUniswapV2Factory(uniswapFactoryV2).getPair(
            _token,
            WETH
        );
        require(pool != address(0), "PAIR DOES NOT EXIST");

        address[] memory tokenList = new address[](2);
        tokenList[0] = _token;
        tokenList[1] = WETH;
        IERC20(_token).approve(uniswapRouterV2, amountIn);
        IUniswapV2Router02(uniswapRouterV2).swapExactTokensForTokens(
            amountIn,
            0,
            tokenList,
            address(this),
            block.timestamp + 10
        );
        emit SwapForWETH(_token, amountIn);
    }

    function swapETHForWETH() external override onlyMiner {
        uint256 balance = address(this).balance;
        require(balance > 0, "ZERO BALANCE");
        IWETH(WETH).deposit{value: balance}();
        emit SwapETHForWETH(balance);
    }

    fallback() external payable {}

    receive() external payable {}
}
