// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./Ownable.sol";
import "./HardCoreLike.sol";
import "./FeeDistributorLike.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";
import "./IUniswapV2Pair.sol";
import "./PriceOracle.sol";

contract LiquidVault is Ownable {

    event EthereumDeposited(
        address from,
        address to,
        uint256 amount,
        uint256 percentageAmount
    );

    /*
    * A user can hold multiple locked LP batches.
    * Each batch takes 30 days to incubate
    */
    event LPQueued(
        address holder,
        uint256 amount,
        uint256 eth,
        uint256 hardCore,
        uint256 timeStamp
    );

    event LPClaimed(
        address holder,
        uint256 amount,
        uint256 timestamp,
        uint256 exitfee
    );

    struct LPbatch {
        address holder;
        uint256 amount;
        uint256 timestamp;
    }

    struct liquidVaultConfig {
        address hardCore;
        IUniswapV2Router02 uniswapRouter;
        IUniswapV2Pair tokenPair;
        FeeDistributorLike feeDistributor;
        PriceOracle uniswapOracle;
        address weth;
        address payable ethReceiver;
        uint32 stakeDuration;
        uint8 donationShare; //0-100
        uint8 purchaseFee; //0-100
    }

    bool private locked;
    modifier lock {
        require(!locked, "HARDCORE: reentrancy violation");
        locked = true;
        _;
        locked = false;
    }

    liquidVaultConfig public config;
    //Front end can loop through this and inspect if enough time has passed
    mapping(address => LPbatch[]) public LockedLP;
    mapping(address => uint256) public queueCounter;

    function seed(
        uint32 duration,
        address hcore,
        address feeDistributor,
        address payable ethReceiver,
        uint8 donationShare, // LP Token
        uint8 purchaseFee, // ETH
        PriceOracle uniswapOracle
    ) public onlyOwner {
        config.hardCore = hcore;
        config.uniswapRouter = IUniswapV2Router02(
            HardCoreLike(hcore).uniswapRouter()
        );
        config.tokenPair = IUniswapV2Pair(
            HardCoreLike(hcore).tokenUniswapPair()
        );
        config.feeDistributor = FeeDistributorLike(feeDistributor);
        config.weth = config.uniswapRouter.WETH();
        config.uniswapOracle = uniswapOracle;
        setEthFeeAddress(ethReceiver);
        setParameters(duration, donationShare, purchaseFee);
    }

    function setOracleAddress(PriceOracle _uniswapOracle) external onlyOwner {
        require(address(_uniswapOracle) != address(0), 'Zero address not allowed');
        config.uniswapOracle = _uniswapOracle;
    }

    function setEthFeeAddress(address payable ethReceiver)
        public
        onlyOwner
    {
        require(
            ethReceiver != address(0),
            "LiquidVault: eth receiver is zero address"
        );

        config.ethReceiver = ethReceiver;
    }

    function setParameters(uint32 duration, uint8 donationShare, uint8 purchaseFee)
        public
        onlyOwner
    {
        require(
            donationShare <= 100,
            "HardCore: donation share % between 0 and 100"
        );
        require(
            purchaseFee <= 100,
            "HardCore: purchase fee share % between 0 and 100"
        );

        config.stakeDuration = duration * 1 days;
        config.donationShare = donationShare;
        config.purchaseFee = purchaseFee;
    }

    function purchaseLPFor(address beneficiary) public payable lock {
        config.feeDistributor.distributeFees();
        require(msg.value > 0, "HARDCORE: eth required to mint Hardcore LP");

        uint256 feeValue = config.purchaseFee * msg.value / 100;
        uint256 exchangeValue = msg.value - feeValue;

        (uint256 reserve1, uint256 reserve2, ) = config.tokenPair.getReserves();

        uint256 hardCoreRequired;

        if (address(config.hardCore) < address(config.weth)) {
            hardCoreRequired = config.uniswapRouter.quote(
                exchangeValue,
                reserve2,
                reserve1
            );
        } else {
            hardCoreRequired = config.uniswapRouter.quote(
                exchangeValue,
                reserve1,
                reserve2
            );
        }

        uint256 balance = HardCoreLike(config.hardCore).balanceOf(address(this));
        require(
            balance >= hardCoreRequired,
            "HARDCORE: insufficient HardCore in LiquidVault"
        );

        IWETH(config.weth).deposit{ value: exchangeValue }();
        address tokenPairAddress = address(config.tokenPair);
        IWETH(config.weth).transfer(tokenPairAddress, exchangeValue);
        HardCoreLike(config.hardCore).transfer(
            tokenPairAddress,
            hardCoreRequired
        );
        config.ethReceiver.transfer(feeValue);
        config.uniswapOracle.update();

        uint256 liquidityCreated = config.tokenPair.mint(address(this));

        LockedLP[beneficiary].push(
            LPbatch({
                holder: beneficiary,
                amount: liquidityCreated,
                timestamp: block.timestamp
            })
        );

        emit LPQueued(
            beneficiary,
            liquidityCreated,
            exchangeValue,
            hardCoreRequired,
            block.timestamp
        );

        emit EthereumDeposited(msg.sender, config.ethReceiver, exchangeValue, feeValue);
    }

    //send eth to match with HCORE tokens in LiquidVault
    function purchaseLP() public payable {
        purchaseLPFor(msg.sender);
    }

    //pops latest LP if older than period
    function claimLP() public {
        uint256 length = LockedLP[msg.sender].length;
        require(length > 0, "HARDCORE: No locked LP.");
        uint256 oldest = queueCounter[msg.sender];
        LPbatch memory batch = LockedLP[msg.sender][oldest];
        require(
            block.timestamp - batch.timestamp > config.stakeDuration,
            "HARDCORE: LP still locked."
        );
        oldest = LockedLP[msg.sender].length - 1 == oldest
            ? oldest
            : oldest + 1;
        queueCounter[msg.sender] = oldest;
        uint256 donation = (config.donationShare * batch.amount) / 100;
        emit LPClaimed(msg.sender, batch.amount, block.timestamp, donation);
        require(
            config.tokenPair.transfer(address(0), donation),
            "HardCore: donation transfer failed in LP claim."
        );
        require(
            config.tokenPair.transfer(batch.holder, batch.amount - donation),
            "HardCore: transfer failed in LP claim."
        );
    }

    function lockedLPLength(address holder) public view returns (uint256) {
        return LockedLP[holder].length;
    }

    function getLockedLP(address holder, uint256 position)
        public
        view
        returns (
            address,
            uint256,
            uint256
        )
    {
        LPbatch memory batch = LockedLP[holder][position];
        return (batch.holder, batch.amount, batch.timestamp);
    }
}
