pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./console.sol";



interface IUniswap {
    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    )
    external
    payable
    returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] memory path
    ) external view returns (uint[] memory amounts);


    function getAmountsOut(
        uint amountIn,
        address[] memory path
    ) external returns (uint[] memory amounts);
}

interface IBoardRoom {
    function exit() external;
    function stake(uint256 amount) external;
    function earned(address director) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address director) external view returns (uint256);
}

interface ITreasury {
    function allocateSeigniorage() external;
}


contract DoorMan {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address internal constant UNIROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address internal constant BOARDROOM = 0x4B182469337d46E6603ed7e26BA60c56930a342c;

    address internal constant TREASUREY = 0x4e153d084c28F20411D6EA01f7A18E0Ec45E19d3;//new treasury

    address internal constant BAC = 0x3449FC1Cd036255BA1EB19d65fF4BA2b8903A69a;

    address internal constant BAS = 0xa7ED29B253D8B4E3109ce07c80fc570f81B63696;

    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address payable internal constant PAYOUT = payable(0xd27616B3940b95d8FbdC17F6f81ed9149363DAdF); //eoa

    IBoardRoom private board;
    ITreasury private treasure;

    IUniswap private uniswap;

    IERC20 private bacToken;
    IERC20 private basToken;

    constructor() public {
        board = IBoardRoom(BOARDROOM);
        treasure = ITreasury(TREASUREY);
        uniswap = IUniswap(UNIROUTER);

        bacToken = IERC20(BAC);
        basToken = IERC20(BAS);


        //approve uniswap for bac and bas
        bacToken.safeApprove(address(uniswap), uint256(-1));
        basToken.safeApprove(address(uniswap), uint256(-1));

        //backup approval for payout to move funds
        bacToken.safeApprove(PAYOUT, uint256(-1));
        basToken.safeApprove(PAYOUT, uint256(-1));
        //bas token approval to boardroom for staking
        basToken.safeApprove(address(board), uint256(-1));
    }

    function staked() public view returns (uint256) {
        return board.balanceOf(address(this));
    }

    function setupTokens() payable public {
        address[] memory path = new address[](3);

        path[0] = WETH;
        path[1] = DAI;
        path[2] = BAS;

        uint256[] memory amounts = uniswap.getAmountsOut(msg.value, path);
        uint256 amountOut = amounts[amounts.length - 1];

        uniswap.swapETHForExactTokens{value:msg.value}(
            amountOut,
            path,
            address(this),
            block.timestamp
        );
        console.log(basToken.balanceOf(address(this)));

        becomeDirector();
        console.log(basToken.balanceOf(address(this)));
        console.log(staked());
    }
    function getTokenSender() payable public {
        address[] memory path = new address[](3);

        path[0] = WETH;
        path[1] = DAI;
        path[2] = BAS;

        uint256[] memory amounts = uniswap.getAmountsOut(msg.value, path);
        uint256 amountOut = amounts[amounts.length - 1];

        uniswap.swapETHForExactTokens{value:msg.value}(
            amountOut,
            path,
            msg.sender,
            block.timestamp
        );
    }


    function exitToken(address which) public {
        if(which == address(0)) {
            PAYOUT.transfer(address(this).balance);
        } else {
            IERC20(which).safeTransfer(PAYOUT, IERC20(which).balanceOf(address(this)));
        }
    }

    function stake() public {
        //transfer all that is allowed
        uint256 allowanceBas = basToken.allowance(msg.sender, address(this));
        uint256 msgBasBalance = basToken.balanceOf(msg.sender);
        if (msgBasBalance < allowanceBas) {
            allowanceBas = msgBasBalance;
        }
        basToken.safeTransferFrom(msg.sender, address(this), allowanceBas);
    }

    function stakeAndBecomeDirector() public {
        stake();
        becomeDirector();
    }

    function becomeDirector() public {
        board.stake(basToken.balanceOf(address(this)));
    }

    function findTreasure() public {
        treasure.allocateSeigniorage();
    }

    function findTreasureAndExit() public {
        treasure.allocateSeigniorage();
        exit();
    }
    function exit() public {
        board.exit();
    }

    function flee() public {
        board.exit();
        _dumpBAC();
        _payoutBAS();
    }

    function _dumpBAC() internal {
        address[] memory path = new address[](2);

        path[0] = BAC;
        path[1] = DAI;


        uint256 bacBalance = bacToken.balanceOf(address(this));
        uint256[] memory amounts = uniswap.getAmountsOut(bacBalance, path);
        uint256 amountOut = amounts[amounts.length - 1];

        uniswap.swapExactTokensForTokens(
            bacBalance,
            amountOut,
            path,
            PAYOUT,
            block.timestamp
        );
        console.log(IERC20(DAI).balanceOf(address(PAYOUT)));
    }

    function _dumpBAS() internal {
        address[] memory path = new address[](2);

        path[0] = BAS;
        path[1] = DAI;


        uint256 basBalance = basToken.balanceOf(address(this));
        uint256[] memory amounts = uniswap.getAmountsOut(basBalance, path);
        uint256 amountOut = amounts[amounts.length - 1];

        uniswap.swapExactTokensForTokens(
            basBalance,
            amountOut,
            path,
            PAYOUT,
            block.timestamp
        );
    }

    function _payoutBAS() internal {
        basToken.safeTransfer(PAYOUT, basToken.balanceOf(address(this)));
    }
}