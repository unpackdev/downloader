// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./ILotteryFactory.sol";
import "./IAskoStaking.sol";
import "./console.sol";

contract AskoLotteryToken is ERC20, AccessControl {
    IUniswapV2Factory public uniswapV2Factory;
    IUniswapV2Router02 public uniswapV2Router02;

    IAskoStaking public askoStaking;
    ILotteryFactory public lotteryFactory;

    address payable public admin;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    uint256 public tokenPrice;

    uint256 public tokenMaxSupply;
    uint256 public ETHMaxSupply;
    uint256 public uniswapTokenSupplyPercentNumerator;
    uint256 public stakersETHRewardsPercentNumerator;
    uint256 public adminFeesETHPercentNumerator;

    uint256 public lotteryTokenHardCap;
    uint256 public ETHHardCap;

    uint256 public lotteryRound;

    uint256 public presaleStartTime;
    uint256 public presaleEndTime;

    uint256 public stakersETHRewards;

    mapping(address => uint256) public unclaimedETHRewards;

    event TokensBought(address buyerAddress, uint256 tokenAmt);
    event StakerETHRewardsClaimed(address claimerAddress, uint256 ETHAmount);
    event LiquidityAdded(
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    constructor(
        // address list:
        // address _uniswapV2Factory,
        // address _uniswapV2Router02,
        // address _askoStaking,
        // address _lotteryFactory,
        address[4] memory addressData,
        address payable _admin,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _tokenPrice,
        uint256 _tokenMaxSupply,
        uint256 _ETHMaxSupply,
        uint256 _uniswapTokenSupplyPercentNumerator,
        uint256 _stakersETHRewardsPercentNumerator,
        uint256 _adminFeesETHPercentNumerator,
        uint256 _lotteryRound
    ) public ERC20(_tokenName, _tokenSymbol) {
        uniswapV2Factory = IUniswapV2Factory(addressData[0]);
        uniswapV2Router02 = IUniswapV2Router02(addressData[1]);
        askoStaking = IAskoStaking(addressData[2]);
        lotteryFactory = ILotteryFactory(addressData[3]);
        admin = _admin;
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MANAGER_ROLE, admin);

        tokenPrice = _tokenPrice;
        tokenMaxSupply = _tokenMaxSupply;
        ETHMaxSupply = _ETHMaxSupply;
        uniswapTokenSupplyPercentNumerator = _uniswapTokenSupplyPercentNumerator;
        stakersETHRewardsPercentNumerator = _stakersETHRewardsPercentNumerator;
        adminFeesETHPercentNumerator = _adminFeesETHPercentNumerator;
        lotteryRound = _lotteryRound;
        presaleStartTime = now;

        lotteryTokenHardCap =
            (_tokenMaxSupply * (100 - _uniswapTokenSupplyPercentNumerator)) /
            100;
        ETHHardCap =
            (_ETHMaxSupply * (100 - _stakersETHRewardsPercentNumerator)) /
            100;
    }

    function buy(uint256 tokenAmt) public payable {
        require(presaleEndTime == 0, "Presale has ended");

        require(
            msg.value >= (tokenAmt  * (tokenPrice / 10**18)),
            "Not enough Ether"
        );
        require(
            totalSupply() < lotteryTokenHardCap,
            "All tokens have been sold"
        );
        require(
            address(this).balance <= ETHHardCap,
            "Sufficient ETH has been collected"
        );

        _mint(msg.sender, tokenAmt);

        emit TokensBought(msg.sender, tokenAmt);
    }

    function endPresale() public {
        require(hasRole(MANAGER_ROLE, msg.sender), "Caller is not a manager");

        presaleEndTime = now;
        uint256 contractETHBalance = address(this).balance;

        // send tokens to uniswap
        //token supply
        uint256 uniswapTokenSupply = (totalSupply() *
            uniswapTokenSupplyPercentNumerator) / 100;
        _mint(address(this), uniswapTokenSupply);

        _approve(address(this), address(uniswapV2Router02), uniswapTokenSupply);

        // 1% slippage tolerance
        uint256 minTokensOut = (uniswapTokenSupply *
            (100 - (uniswapTokenSupplyPercentNumerator + 1))) / 100;

        // ETH supply
        uint256 uniswapETHSupply = (contractETHBalance *
            (100 -
                (stakersETHRewardsPercentNumerator +
                    adminFeesETHPercentNumerator))) / 100;

        // 1% slippage tolerance
        uint256 minETHOut = (contractETHBalance *
            (100 -
                (stakersETHRewardsPercentNumerator +
                    adminFeesETHPercentNumerator +
                    1))) / 100;

        uint256 amountToken;
        uint256 amountETH;
        uint256 liquidity;
        (amountToken, amountETH, liquidity) = uniswapV2Router02.addLiquidityETH{
            value: uniswapETHSupply
        }(
            address(this),
            uniswapTokenSupply,
            minTokensOut,
            minETHOut,
            admin,
            now + 60 * 5
        );
        emit LiquidityAdded(amountToken, amountETH, liquidity);

        // make ETH rewards claimable to registered stakers
        stakersETHRewards =
            (contractETHBalance * stakersETHRewardsPercentNumerator) /
            100;

        uint256 totalRegisteredStakedTokens = 0;
        uint256 registeredStakersLength = lotteryFactory
            .getRegisteredStakersLength();

        for (uint256 i = 0; i < registeredStakersLength; i++) {
            totalRegisteredStakedTokens += askoStaking.stakeValue(
                lotteryFactory.registeredStakers(i)
            );
        }

        require(totalRegisteredStakedTokens > 0, "Registered stakers have a total of 0 tokens staked");

        for (uint256 j = 0; j < registeredStakersLength; j++) {
            address currRegisteredStakerAddress = lotteryFactory
                .registeredStakers(j);

            // share ETH rewards amongst ASKO stakers registered in lottery
            uint256 currRegisteredStakerETHRewardPercentNumerator = (askoStaking
                .stakeValue(lotteryFactory.registeredStakers(j)) * 100) /
                totalRegisteredStakedTokens;

            unclaimedETHRewards[currRegisteredStakerAddress] =
                (stakersETHRewards *
                    currRegisteredStakerETHRewardPercentNumerator) /
                100;
        }

        // send admin fees ETH
        admin.transfer(
            (contractETHBalance * adminFeesETHPercentNumerator) / 100
        );
    }

    function claimStakerETHRewards() public {
        require(presaleEndTime != 0, "Lottery has not started");

        uint256 unclaimedETHReward = unclaimedETHRewards[msg.sender];
        require(unclaimedETHReward > 0, "Asko staker has no ETH rewards");

        unclaimedETHRewards[msg.sender] = 0;

        msg.sender.transfer(unclaimedETHReward);

        emit StakerETHRewardsClaimed(msg.sender, unclaimedETHReward);
    }
}
