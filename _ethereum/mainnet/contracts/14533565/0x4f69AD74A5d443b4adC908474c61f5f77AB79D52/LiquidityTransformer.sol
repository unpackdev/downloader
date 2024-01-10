// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface ILendFlareToken is IERC20 {
    function setLiquidityFinish() external;
}

contract LiquidityTransformer is ReentrancyGuard {
    using Address for address payable;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    ILendFlareToken public lendflareToken;
    address public uniswapPair;

    IUniswapV2Router02 public constant uniswapRouter =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address payable teamAddress;

    uint256 public constant FEE_DENOMINATOR = 10;
    uint256 public constant liquifyTokens = 909090909 * 1e18;
    uint256 public investmentTime;
    uint256 public minInvest;
    uint256 public launchTime;

    struct Globals {
        uint256 totalUsers;
        uint256 totalBuys;
        uint256 transferredUsers;
        uint256 totalWeiContributed;
        bool liquidity;
        uint256 endTimeAt;
    }

    Globals public globals;

    mapping(address => uint256) public investorBalances;
    mapping(address => uint256[2]) investorHistory;

    event UniSwapResult(
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity,
        uint256 endTimeAt
    );

    modifier afterUniswapTransfer() {
        require(globals.liquidity == true, "Forward liquidity first");
        _;
    }

    constructor(
        address _lendflareToken,
        address payable _teamAddress,
        uint256 _launchTime
    ) public {
        require(_launchTime > block.timestamp, "!_launchTime");
        launchTime = _launchTime;
        lendflareToken = ILendFlareToken(_lendflareToken);
        teamAddress = _teamAddress;

        minInvest = 0.1 ether;
        investmentTime = 7 days;

        
    }

    function createPair() external {
        require(address(uniswapPair) == address(0), "!uniswapPair");

        uniswapPair = address(
            IUniswapV2Factory(factory()).createPair(
                WETH(),
                address(lendflareToken)
            )
        );
    }

    receive() external payable {
        require(
            msg.sender == address(uniswapRouter) || msg.sender == teamAddress,
            "Direct deposits disabled"
        );
    }

    function reserve() external payable {
        _reserve(msg.sender, msg.value);
    }

    function reserveWithToken(address _tokenAddress, uint256 _tokenAmount)
        external
    {
        IERC20 token = IERC20(_tokenAddress);

        token.safeTransferFrom(msg.sender, address(this), _tokenAmount);

        token.approve(address(uniswapRouter), _tokenAmount);

        address[] memory _path = preparePath(_tokenAddress);

        uint256[] memory amounts = uniswapRouter.swapExactTokensForETH(
            _tokenAmount,
            minInvest,
            _path,
            address(this),
            block.timestamp
        );

        _reserve(msg.sender, amounts[1]);
    }

    function _reserve(address _senderAddress, uint256 _senderValue) internal {
        require(block.timestamp >= launchTime, "Not started");
        require(
            block.timestamp <= launchTime.add(investmentTime),
            "IDO has ended"
        );
        require(globals.liquidity == false, "!globals.liquidity");
        require(_senderValue >= minInvest, "Investment below minimum");

        if (investorBalances[_senderAddress] == 0) {
            globals.totalUsers++;
        }

        investorBalances[_senderAddress] = investorBalances[_senderAddress].add(
            _senderValue
        );

        globals.totalWeiContributed = globals.totalWeiContributed.add(
            _senderValue
        );
        globals.totalBuys++;
    }

    function forwardLiquidity() external nonReentrant {
        require(msg.sender == tx.origin, "!EOA");
        require(globals.liquidity == false, "!globals.liquidity");
        require(
            block.timestamp > launchTime.add(investmentTime),
            "Not over yet"
        );

        uint256 _etherFee = globals.totalWeiContributed.div(FEE_DENOMINATOR);
        uint256 _balance = globals.totalWeiContributed.sub(_etherFee);

        teamAddress.sendValue(_etherFee);

        uint256 half = liquifyTokens.div(2);
        uint256 _lendflareTokenFee = half.div(FEE_DENOMINATOR);

        IERC20(lendflareToken).safeTransfer(teamAddress, _lendflareTokenFee);

        lendflareToken.approve(
            address(uniswapRouter),
            half.sub(_lendflareTokenFee)
        );

        (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        ) = uniswapRouter.addLiquidityETH{value: _balance}(
                address(lendflareToken),
                half.sub(_lendflareTokenFee),
                0,
                0,
                address(0x0),
                block.timestamp
            );

        globals.liquidity = true;
        globals.endTimeAt = block.timestamp;

        lendflareToken.setLiquidityFinish();

        emit UniSwapResult(
            amountToken,
            amountETH,
            liquidity,
            globals.endTimeAt
        );
    }

    function getMyTokens() external afterUniswapTransfer nonReentrant {
        require(globals.liquidity, "!globals.liquidity");
        require(investorBalances[msg.sender] > 0, "!balance");

        uint256 myTokens = checkMyTokens(msg.sender);

        investorHistory[msg.sender][0] = investorBalances[msg.sender];
        investorHistory[msg.sender][1] = myTokens;
        investorBalances[msg.sender] = 0;

        IERC20(lendflareToken).safeTransfer(msg.sender, myTokens);

        globals.transferredUsers++;

        if (globals.transferredUsers == globals.totalUsers) {
            uint256 surplusBalance = IERC20(lendflareToken).balanceOf(
                address(this)
            );

            if (surplusBalance > 0) {
                IERC20(lendflareToken).safeTransfer(
                    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
                    surplusBalance
                );
            }
        }
    }

    /* view functions */
    function WETH() public pure returns (address) {
        return IUniswapV2Router02(uniswapRouter).WETH();
    }

    function checkMyTokens(address _sender) public view returns (uint256) {
        if (
            globals.totalWeiContributed == 0 || investorBalances[_sender] == 0
        ) {
            return 0;
        }

        uint256 half = liquifyTokens.div(2);
        uint256 otherHalf = liquifyTokens.sub(half);
        uint256 percent = investorBalances[_sender].mul(100e18).div(
            globals.totalWeiContributed
        );
        uint256 myTokens = otherHalf.mul(percent).div(100e18);

        return myTokens;
    }

    function factory() public pure returns (address) {
        return IUniswapV2Router02(uniswapRouter).factory();
    }

    function getInvestorHistory(address _sender)
        public
        view
        returns (uint256[2] memory)
    {
        return investorHistory[_sender];
    }

    function preparePath(address _tokenAddress)
        internal
        pure
        returns (address[] memory _path)
    {
        _path = new address[](2);
        _path[0] = _tokenAddress;
        _path[1] = WETH();
    }
}
