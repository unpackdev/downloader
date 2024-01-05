// SPDX-License-Identifier: MIT
pragma solidity 0.7.1;
import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";
import "./IUniswapV2Pair.sol";
import "./PriceOracle.sol";

contract AcceleratorVault is Ownable {
    /** Emitted when purchaseLP() is called to track ETH amounts */
    event EthereumDeposited(
        address from,
        address to,
        uint amount,
        uint percentageAmount
    );

    /** Emitted when purchaseLP() is called and LP tokens minted */
    event LPQueued(
        address holder,
        uint amount,
        uint eth,
        uint osmToken,
        uint timestamp
    );

    /** Emitted when claimLP() is called */
    event LPClaimed(
        address holder,
        uint amount,
        uint timestamp,
        uint exitFee,
        bool claimed
    );

    struct LPbatch {
        address holder;
        uint amount;
        uint timestamp;
        bool claimed;
    }

    struct AcceleratorVaultConfig {
        address osmToken;
        IUniswapV2Router02 uniswapRouter;
        IUniswapV2Pair tokenPair;
        PriceOracle uniswapOracle;
        address weth;
        address payable ethHodler;
        uint32 stakeDuration;
        uint8 donationShare; //0-100
        uint8 purchaseFee; //0-100
    }

    bool public forceUnlock;
    bool private locked;

    modifier lock {
        require(!locked, "AcceleratorVault: reentrancy violation");
        locked = true;
        _;
        locked = false;
    }

    AcceleratorVaultConfig public config;

    mapping(address => LPbatch[]) public lockedLP;
    mapping(address => uint) public queueCounter;

    function seed(
        uint32 duration,
        address osmToken,
        address uniswapPair,
        address uniswapRouter,
        address payable ethHodler,
        uint8 donationShare, // LP Token
        uint8 purchaseFee, // ETH
        PriceOracle uniswapOracle
    ) public onlyOwner {
        config.osmToken = osmToken;
        config.uniswapRouter = IUniswapV2Router02(uniswapRouter);
        config.tokenPair = IUniswapV2Pair(uniswapPair);
        config.weth = config.uniswapRouter.WETH();
        config.uniswapOracle = uniswapOracle;
        setEthHodlerAddress(ethHodler);
        setParameters(duration, donationShare, purchaseFee);
    }

    function setOracleAddress(PriceOracle _uniswapOracle) external onlyOwner {
        require(address(_uniswapOracle) != address(0), "Zero address not allowed");
        config.uniswapOracle = _uniswapOracle;
    }

    function getStakeDuration() public view returns (uint) {
        return forceUnlock ? 0 : config.stakeDuration;
    }

    // Could not be canceled if activated
    function enableLPForceUnlock() public onlyOwner {
        forceUnlock = true;
    }

    function setEthHodlerAddress(address payable ethHodler) public onlyOwner {
        require(
            ethHodler != address(0),
            "AcceleratorVault: eth receiver is zero address"
        );

        config.ethHodler = ethHodler;
    }

    function setParameters(uint32 duration, uint8 donationShare, uint8 purchaseFee)
        public
        onlyOwner
    {
        require(
            donationShare <= 100,
            "AcceleratorVault: donation share % between 0 and 100"
        );
        require(
            purchaseFee <= 100,
            "AcceleratorVault: purchase fee share % between 0 and 100"
        );

        config.stakeDuration = duration * 1 days;
        config.donationShare = donationShare;
        config.purchaseFee = purchaseFee;
    }

    function purchaseLPFor(address beneficiary) public payable lock {
        require(msg.value > 0, "AcceleratorVault: ETH required to mint OSM LP");

        uint feeValue = (config.purchaseFee * msg.value) / 100;
        uint exchangeValue = msg.value - feeValue;

        (uint reserve1, uint reserve2, ) = config.tokenPair.getReserves();

        uint osmRequired;

        if (address(config.osmToken) < address(config.weth)) {
            osmRequired = config.uniswapRouter.quote(
                exchangeValue,
                reserve2,
                reserve1
            );
        } else {
            osmRequired = config.uniswapRouter.quote(
                exchangeValue,
                reserve1,
                reserve2
            );
        }

        uint balance = IERC20(config.osmToken).balanceOf(address(this));
        require(
            balance >= osmRequired,
            "AcceleratorVault: insufficient OSM tokens in AcceleratorVault"
        );

        IWETH(config.weth).deposit{ value: exchangeValue }();
        address tokenPairAddress = address(config.tokenPair);
        IWETH(config.weth).transfer(tokenPairAddress, exchangeValue);
        IERC20(config.osmToken).transfer(
            tokenPairAddress,
            osmRequired
        );
        //ETH receiver is hodler vault here
        config.ethHodler.transfer(feeValue);
        config.uniswapOracle.update();

        uint liquidityCreated = config.tokenPair.mint(address(this));

        lockedLP[beneficiary].push(
            LPbatch({
                holder: beneficiary,
                amount: liquidityCreated,
                timestamp: block.timestamp,
                claimed: false
            })
        );

        emit LPQueued(
            beneficiary,
            liquidityCreated,
            exchangeValue,
            osmRequired,
            block.timestamp
        );

        emit EthereumDeposited(msg.sender, config.ethHodler, exchangeValue, feeValue);
    }

    //send eth to match with OSM tokens in AcceleratorVault
    function purchaseLP() public payable {
        purchaseLPFor(msg.sender);
    }

    function claimLP() public {
        uint next = queueCounter[msg.sender];
        require(
            next < lockedLP[msg.sender].length,
            "AcceleratorVault: nothing to claim."
        );
        LPbatch storage batch = lockedLP[msg.sender][next];
        require(
            block.timestamp - batch.timestamp > getStakeDuration(),
            "AcceleratorVault: LP still locked."
        );
        next++;
        queueCounter[msg.sender] = next;
        uint donation = (config.donationShare * batch.amount) / 100;
        batch.claimed = true;
        emit LPClaimed(msg.sender, batch.amount, block.timestamp, donation, batch.claimed);
        require(
            config.tokenPair.transfer(address(0), donation),
            "AcceleratorVault: donation transfer failed in LP claim."
        );
        require(
            config.tokenPair.transfer(batch.holder, batch.amount - donation),
            "AcceleratorVault: transfer failed in LP claim."
        );
    }

    function lockedLPLength(address holder) public view returns (uint) {
        return lockedLP[holder].length;
    }

    function getLockedLP(address holder, uint position)
        public
        view
        returns (
            address,
            uint,
            uint,
            bool
        )
    {
        LPbatch memory batch = lockedLP[holder][position];
        return (batch.holder, batch.amount, batch.timestamp, batch.claimed);
    }
}
