// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

interface ISushiswapRouter {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface ISquidStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function unstake(uint256 _amount, bool _trigger) external;
}

interface ISquidBond {
    function deposit(
        uint256 _amount,
        uint256 _maxPrice,
        address _depositor
    ) external returns (uint256);

    function payoutFor(uint256 _value) external view returns (uint256);

    function maxPayout() external view returns (uint256);

    function bondPrice() external view returns (uint256 price_);

    function pendingPayoutFor(address _depositor)
        external
        view
        returns (uint256 pendingPayout_);

    function bondInfo(address user)
        external
        view
        returns (
            uint256 payout,
            uint256 vesting,
            uint256 lastBlock,
            uint256 pricePaid
        );
}

interface ITreasury {
    function valueOf(address _token, uint256 _amount)
        external
        view
        returns (uint256 value_);
}

interface SquidDistributor {}

contract SquidDiscountGrabber is Ownable, ReentrancyGuard {
    address public sushiswapRouterAddress =
        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address public squidStakingAddress =
        0x5895B13Da9BEB11e36136817cdcf3c4fcb16aaeA;
    address public sSquidAddress = 0x9d49BfC921F36448234b0eFa67B5f91b3C691515;
    address public squidAddress = 0x21ad647b8F4Fe333212e735bfC1F36B4941E6Ad2;
    address public wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public squidDistributorAddress =
        0x2d99d0B76168E315f2dC699BFf8D47Be30B3F9D7;
    address public squidEthBondAddress =
        0x8f9b609eA2179262A7A672553D6F78ec83215EE9;
    address public treasuryAddress = 0x61d8a57b3919e9F4777C80b6CF1138962855d2Ca;
    mapping(address=>bool) subscribed;

    ISushiswapRouter sushiswapRouter;
    ISquidStaking squidStaking;

    constructor() {
        sushiswapRouter = ISushiswapRouter(sushiswapRouterAddress);
        squidStaking = ISquidStaking(squidStakingAddress);
    }
    function subscribe() external payable nonReentrant{
        require(msg.value == 0.05 ether, "payment amount has to be 0.05 eth");
        require(!subscribed[msg.sender], "already subscribed");
        subscribed[msg.sender] = true;
    }

    function unstakeAndBond(uint256 requiredDiscountInPercentage)
        external
        nonReentrant
    {
        uint256 sSquidAmount = IERC20(sSquidAddress).balanceOf(msg.sender);
        (uint256 initialVestingAmount, , , ) = ISquidBond(squidEthBondAddress)
            .bondInfo(msg.sender);
        address[] memory paths = new address[](2);
        paths[0] = squidAddress;
        paths[1] = wethAddress;
        uint256[] memory amountsOut = sushiswapRouter.getAmountsOut(
            sSquidAmount,
            paths
        );
        uint256 wethAmount = amountsOut[1];
        if (msg.sender != owner() && !subscribed[msg.sender]) {
            wethAmount = (wethAmount * 99) / 100;
        }
        uint256 depositValue = ITreasury(treasuryAddress).valueOf(
            wethAddress,
            wethAmount
        );
        uint256 squidReceivableFromBonding = ISquidBond(squidEthBondAddress)
            .payoutFor(depositValue);

        require(
            squidReceivableFromBonding >=
                (sSquidAmount * (100 + requiredDiscountInPercentage)) / 100,
            "required discount not met"
        );
        require(squidReceivableFromBonding >= 100000, "Bond too small");
        require(
            squidReceivableFromBonding <=
                ISquidBond(squidEthBondAddress).maxPayout(),
            "Bond too large, you ain't no shrimp."
        );

        // get sSquid from sender
        IERC20(sSquidAddress).transferFrom(
            msg.sender,
            address(this),
            sSquidAmount
        );
        // unstake and get squid
        IERC20(sSquidAddress).approve(squidStakingAddress, sSquidAmount);
        ISquidStaking(squidStakingAddress).unstake(sSquidAmount, false);
        // swap squid for weth
        IERC20(squidAddress).approve(sushiswapRouterAddress, sSquidAmount);
        uint256[] memory actualAmountsOut = sushiswapRouter
            .swapExactTokensForTokens(
                sSquidAmount,
                0,
                paths,
                address(this),
                block.timestamp + 10
            );
        // take 1% as fees
        uint256 depositAmount = actualAmountsOut[1];
        if (msg.sender != owner() && !subscribed[msg.sender]) {
            depositAmount = (depositAmount * 99) / 100;
        }
        IERC20(wethAddress).approve(squidEthBondAddress, depositAmount);
        ISquidBond(squidEthBondAddress).deposit(
            depositAmount,
            ISquidBond(squidEthBondAddress).bondPrice(),
            msg.sender
        );
        (uint256 postVestingAmount, , , ) = ISquidBond(squidEthBondAddress)
            .bondInfo(msg.sender);
        require(
            postVestingAmount > initialVestingAmount,
            "vesting amount does not increase after this tx"
        );
    }

    function withdraw() external onlyOwner {
        uint256 wethBalance = IERC20(wethAddress).balanceOf(address(this));
        if (wethBalance > 0) {
            IERC20(wethAddress).transfer(owner(), wethBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            payable(owner()).transfer(ethBalance);
        }
    }
}
