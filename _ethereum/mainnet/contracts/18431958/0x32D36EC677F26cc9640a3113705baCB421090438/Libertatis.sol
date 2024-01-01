// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./MathUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IUniswapV3MintCallback.sol";
import "./IUniswapV3Factory.sol";
import "./IUniswapV3Pool.sol";
import "./IWETH9.sol";


/*
Error codes:
EOP - End of phase
EOPS - End of phase supply
OAL - Only after launch
PO  - Pool only - can only be called by Uniswap pool
TBD - To be deployed
RPP - Rug pull protection
FP - Already in final phase
SNF - Stake not found
OOS - Out of supply; That's all folks ¯\_(ツ)_/¯
NVA - Not a valid ambassador - Ambassadors must own Libertatis

Assumung that we want to have 1 000 000 000 tokens (abbr.: T) in total.
Furthermore, each of the rhree phases shall have 250 000 000T.
The remaining 250 000 000T shall be reserved.
During the initial phase, we want to mint 6000 ETH.
Therefore, the conversion rate is 6000 ETH / 250mT = 0,000024 ETH/T = 24 000 Gwei / T

Uniswap calculations:
Since starting price of a token is 24 000 Gwei / T, we have to select the Uniswap ticks accordingly.
By setting the lower tick target to 12 000 Gwei / T and the upper to 36 000 Gwei / T, we garantuee an initial median for trading at 24 000 Gwei / T.
Since the tick limits are calculated as floor(log(price, 1.0001)), the tick limits would be -99446 and -110435.
To fix this, we swap the pool from ETH <-> T to T <-> ETH, resulting in floor(log(1/price, 1.0001)), hence 99447 and 110434.
*/
contract Libertatis is Initializable, ERC20Upgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, IUniswapV3MintCallback {

    enum Phase { TokenDeployed, TokenMinting, TokenPreSale,  TokenLaunch }
    Phase public currentPhase;

    uint88 public phaseSupply;
    uint48 public mintingPrice;
    uint256 public phaseEndDate;
    IUniswapV3Pool internal liquidityPool;
    address internal weth9Address;

    struct PoolData {
        int24 tickLower;
        int24 tickUpper;
        uint160 sqrtPriceX96;
        uint128 liquidity;
    }
    PoolData public poolData;
    bytes32 public constant LIBERTATIS_AI_ROLE = keccak256("LIBERTATIS_AI");
    bytes32 public constant LIBERTATIS_MODERATOR_ROLE = keccak256("LIBERTATIS_MODERATOR");

    struct StakingData {
        uint256 amountBought;
        uint lastTimeClaimed;
        uint16 apy;
    }
    mapping (address => StakingData) public stakes;
    mapping (address => uint256) public incentives;

    event NewRole(address indexed receiver, bytes32 role);
    event ModeratorTransfer(address indexed receiver, uint256 amount);
    event UniswapPoolInteraction(string message);
    event PhaseEvent(string message);
    event LibertatisIssued(address indexed receiver, uint256 amount);
    event StakeIssued(address indexed receiver, uint256 amount);

    function initialize(address _weth9Address, address uniswapV3FactoryAddress) initializer public nonReentrant(){
        __ERC20_init("Libertatis", "LTC");
        __AccessControl_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        currentPhase = Phase.TokenDeployed;

        phaseEndDate = block.timestamp + 30 days;
        phaseSupply = 250_000_000 ether;

        mintingPrice = 24_000 gwei;

        _mint(address(this), 250_000_000 ether);

        PoolData memory pd = PoolData({
            tickLower: 99447,
            tickUpper: 110434,
            sqrtPriceX96: 16172380951520764240549778554880,
            liquidity: 41815740030778910762336256
        });

        weth9Address = _weth9Address;

        IUniswapV3Factory factory = IUniswapV3Factory(uniswapV3FactoryAddress);
        uint24 poolFee = 3_000;
        address liquidityPoolAddress = factory.getPool(address(this), _weth9Address, poolFee);
        IUniswapV3Pool lp;
        if (liquidityPoolAddress == address(0)) {
            factory.createPool(address(this), _weth9Address, poolFee);
            liquidityPoolAddress = factory.getPool(address(this), _weth9Address, poolFee);
            lp = IUniswapV3Pool(liquidityPoolAddress);
            lp.initialize(pd.sqrtPriceX96);
            emit UniswapPoolInteraction("Pool created!");
        } else {
            lp = IUniswapV3Pool(liquidityPoolAddress);
            emit UniswapPoolInteraction("Connected to pool");
        }
        poolData = pd;
        liquidityPool = lp;
    }

    function addAiAccount(address aiAccount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(LIBERTATIS_AI_ROLE, aiAccount);
        emit NewRole(aiAccount, LIBERTATIS_AI_ROLE);
    }

    function addModeratorAccount(address moderatorAccount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(LIBERTATIS_MODERATOR_ROLE, moderatorAccount);
        emit NewRole(moderatorAccount, LIBERTATIS_MODERATOR_ROLE);
    }

    function transferLibertatis(address receiver, uint256 amount) external onlyRole(LIBERTATIS_MODERATOR_ROLE) {
        _transfer(address(this), receiver, amount);
        emit ModeratorTransfer(receiver, amount);
    }

    function uniswapV3MintCallback(uint256 libertatisOwed, uint256 wethOwed, bytes calldata) external override nonReentrant() {
        require(currentPhase == Phase.TokenLaunch, "OAL");
        address poolAddress = address(liquidityPool);
        require(msg.sender == poolAddress, "PO");
        address weth9 = weth9Address;
        if (wethOwed != 0) {
            IWETH9(weth9).deposit{value: wethOwed}();
            IWETH9(weth9).transfer(poolAddress, wethOwed);
        }
        if (libertatisOwed != 0) {
            _mint(poolAddress, libertatisOwed);
        }
        emit UniswapPoolInteraction("Sent liquidity to Uniswap");
    }

    function adjustPoolParameter(int24 tickLower, int24 tickUpper, uint160 sqrtPriceX96, uint128 liquidity) external onlyRole(LIBERTATIS_AI_ROLE) {
        poolData = PoolData({
            tickLower: tickLower,
            tickUpper: tickUpper,
            sqrtPriceX96: sqrtPriceX96,
            liquidity: liquidity
        });
        emit UniswapPoolInteraction("Adjusted pool parameter for launch");
    }

    function moveToNextPhase() external onlyRole(DEFAULT_ADMIN_ROLE) {
        Phase current = currentPhase;
        require(current != Phase.TokenLaunch, "FP");
        current = Phase(uint(current) + 1);
        currentPhase = current;

        uint88 ps = phaseSupply;
        if (current == Phase.TokenMinting) {
            emit PhaseEvent("Minting has started!");
        } else if (current == Phase.TokenPreSale) {
            _mint(address(this), ps);
            ps = 250_000_000 ether;
            phaseEndDate = block.timestamp + 30 days;
            emit PhaseEvent("Presale has started!");
        } else if (current == Phase.TokenLaunch) {
            ps = 250_000_000 ether;
            _mint(address(this), 250_000_000 ether);
            PoolData memory pd = poolData;
            liquidityPool.mint(address(this), pd.tickLower, pd.tickUpper, pd.liquidity, abi.encodePacked());
            emit PhaseEvent("Libertatis has been started!");
        }
        phaseSupply = ps;
    }

    function ethWeiToLibertatisWei(uint256 amountPayedInWei) public view returns (uint256) {
        uint48 mp = mintingPrice;
        uint48 price = (currentPhase == Phase.TokenMinting) ? mp : mp * 3;
        return (amountPayedInWei * 1 ether) / price;
    }

    function buyLibertatis() external payable {
        buyLibertatisWithReferral(address(0));
    }

    function buyLibertatisWithReferral(address ambassadorAddress) public payable {
        Phase current = currentPhase;
        uint88 ps = phaseSupply;
        require(current != Phase.TokenDeployed, "TBD");
        uint256 libertatisTokensToBuy = ethWeiToLibertatisWei(msg.value);
        require(libertatisTokensToBuy < ps, "EOPS");

        if (current == Phase.TokenMinting) {
            require((balanceOf(msg.sender) + libertatisTokensToBuy) <= ethWeiToLibertatisWei(15 ether), "RPP");
        }
        if (current == Phase.TokenMinting || current == Phase.TokenPreSale) {
            require(block.timestamp < phaseEndDate, "EOP");
        }

        if (ambassadorAddress != address(0)) {
            require(balanceOf(ambassadorAddress) != 0, "NVA");
            uint256 commission = libertatisTokensToBuy / 4;
            _mint(ambassadorAddress, commission);
            incentives[ambassadorAddress] = commission;
            emit LibertatisIssued(ambassadorAddress, commission);
        }

        registerNewStake(libertatisTokensToBuy);
        phaseSupply = ps - uint88(libertatisTokensToBuy);

        if (current == Phase.TokenLaunch) {
            _transfer(address(this), msg.sender, libertatisTokensToBuy);
        } else {
            _mint(msg.sender, libertatisTokensToBuy);
        }
        emit LibertatisIssued(msg.sender, libertatisTokensToBuy);
    }

    function registerNewStake(uint256 value) internal {
        StakingData memory sd = stakes[msg.sender];
        uint16 apy = 0;
        Phase current = currentPhase;
        if (current == Phase.TokenMinting){
            apy = 1000;
        } else if (current == Phase.TokenPreSale) {
            apy = 500;
        } else if (current == Phase.TokenLaunch) {
            apy = 250;
        }
        if (sd.amountBought != 0) {
            claimStakes();
        }

        sd.amountBought += value;
        sd.lastTimeClaimed = block.timestamp;
        sd.apy = apy;
        stakes[msg.sender] = sd;
    }

    function claimStakes() public nonReentrant() {
        StakingData memory sd = stakes[msg.sender];
        require(sd.amountBought != 0, "SNF");

        uint rewardableSecods = (block.timestamp - sd.lastTimeClaimed);
        sd.lastTimeClaimed = block.timestamp;
        uint256 claimAmount = MathUpgradeable.min(balanceOf(address(this)), calcStakeReward(sd.amountBought, sd.apy, rewardableSecods));

        require(claimAmount != 0, "OOS");
        stakes[msg.sender] = sd;

        _transfer(address(this), msg.sender, claimAmount);
        emit StakeIssued(msg.sender, claimAmount);
    }

    function calcStakeReward(uint256 amountBought, uint16 apy, uint secondsElapsed) private pure returns (uint256) {
        //return ((amountBought * apy / 31536000) * secondsElapsed) / 100;
        return (amountBought * apy * secondsElapsed) / (31536000 * 100);
    }

    function getClaimableStakes() view external returns (uint256) {
        StakingData memory sd = stakes[msg.sender];
        require(sd.amountBought != 0, "SNF");

        uint rewardableSecods = (block.timestamp - sd.lastTimeClaimed);
        uint256 calcedStakes = calcStakeReward(sd.amountBought, sd.apy, rewardableSecods);
        return MathUpgradeable.min(balanceOf(address(this)), calcedStakes);
    }

    function _burn(address account, uint256 amount) internal override(ERC20Upgradeable) {
        ERC20Upgradeable._burn(account, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20Upgradeable) {
        ERC20Upgradeable._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20Upgradeable) {
        ERC20Upgradeable._mint(to, amount);
    }
}
