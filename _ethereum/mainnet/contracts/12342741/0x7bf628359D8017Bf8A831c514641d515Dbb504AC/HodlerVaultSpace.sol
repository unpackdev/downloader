// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";
import "./IUniswapV2Pair.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract HodlerVaultSpace is Ownable {
    using SafeMath for uint;

    /** Emitted when purchaseLP() is called to track INFINITY amounts */
    event InfinityTransferred(
        address from,
        uint amount,
        uint percentageAmount
    );

    /** Emitted when purchaseLP() is called and LP tokens minted */
    event LPQueued(
        address hodler,
        uint amount,
        uint eth,
        uint infinityTokens,
        uint timeStamp
    );

    /** Emitted when claimLP() is called */
    event LPClaimed(
        address hodler,
        uint amount,
        uint timestamp,
        uint donation
    );

    struct LPbatch {
        uint amount;
        uint timestamp;
        bool claimed;
    }

    struct HodlerVaultConfig {
        IERC20 infinityToken;
        IUniswapV2Router02 uniswapRouter;
        IUniswapV2Pair tokenPair;
        address weth;
        address payable feeReceiver;
        uint32 stakeDuration;
        uint8 donationShare; //0-100
        uint8 purchaseFee; //0-100
    }

    bool private locked;
    bool public forceUnlock;

    modifier lock {
        require(!locked, "HodlerVaultSpace: reentrancy violation");
        locked = true;
        _;
        locked = false;
    }

    HodlerVaultConfig public config;
    //Front end can loop through this and inspect if enough time has passed
    mapping(address => LPbatch[]) public lockedLP;
    mapping(address => uint) public queueCounter;

    receive() external payable {}

    function maxTokensToInvest() external view returns (uint) {
        uint totalETH = address(this).balance;
        if (totalETH == 0) {
            return 0;
        }

        uint infinityMaxAllowed;

        (uint reserve1, uint reserve2,) = config.tokenPair.getReserves();

        if (address(config.infinityToken) < address(config.weth)) {
            infinityMaxAllowed = config.uniswapRouter.quote(
                totalETH,
                reserve2,
                reserve1
            );
        } else {
            infinityMaxAllowed = config.uniswapRouter.quote(
                totalETH,
                reserve1,
                reserve2
            );
        }

        return infinityMaxAllowed;
    }


    function getLockedLP(address hodler, uint position)
        external
        view
        returns (
            address,
            uint,
            uint,
            bool
        )
    {
        LPbatch memory batch = lockedLP[hodler][position];
        return (hodler, batch.amount, batch.timestamp, batch.claimed);
    }

    function lockedLPLength(address hodler) external view returns (uint) {
        return lockedLP[hodler].length;
    }

    function getStakeDuration() public view returns (uint) {
        return forceUnlock ? 0 : config.stakeDuration;
    }

    function seed(
        uint32 duration,
        IERC20 infinityToken,
        address uniswapPair,
        address uniswapRouter,
        address payable feeReceiver,
        uint8 purchaseFee // INFINITY
    ) external onlyOwner {
        config.infinityToken = infinityToken;
        config.uniswapRouter = IUniswapV2Router02(uniswapRouter);
        config.tokenPair = IUniswapV2Pair(uniswapPair);
        config.weth = config.uniswapRouter.WETH();
        setParameters(duration, 0, purchaseFee);
        setFeeReceiver(feeReceiver);
    }

    function setParameters(uint32 duration, uint8 donationShare, uint8 purchaseFee)
        public
        onlyOwner
    {
        require(
            donationShare <= 100,
            "HodlerVaultSpace: donation share % between 0 and 100"
        );
        require(
            purchaseFee <= 100,
            "HodlerVaultSpace: purchase fee share % between 0 and 100"
        );

        config.stakeDuration = duration * 1 days;
        config.donationShare = donationShare;
        config.purchaseFee = purchaseFee;
    }


    function setFeeReceiver(address payable feeReceiver) public onlyOwner {
        require(
            feeReceiver != address(0),
            "HodlerVaultSpace: fee receiver is zero address"
        );

        config.feeReceiver = feeReceiver;
    }

    function purchaseLP(uint amount) external lock {
        require(amount > 0, "HodlerVaultSpace: INFINITY required to mint LP");
        require(config.infinityToken.balanceOf(msg.sender) >= amount, "HodlerVaultSpace: Not enough INFINITY tokens");
        require(config.infinityToken.allowance(msg.sender, address(this)) >= amount, "HodlerVaultSpace: Not enough INFINITY tokens allowance");

        uint infinityFee = amount.mul(config.purchaseFee).div(100);
        uint netInfinity = amount.sub(infinityFee);

        (uint reserve1, uint reserve2, ) = config.tokenPair.getReserves();

        uint ethRequired;

        if (address(config.infinityToken) > address(config.weth)) {
            ethRequired = config.uniswapRouter.quote(
                netInfinity,
                reserve2,
                reserve1
            );
        } else {
            ethRequired = config.uniswapRouter.quote(
                netInfinity,
                reserve1,
                reserve2
            );
        }

        require(
            address(this).balance >= ethRequired,
            "HodlerVaultSpace: insufficient ETH on HodlerVaultSpace"
        );

        IWETH(config.weth).deposit{ value: ethRequired }();
        address tokenPairAddress = address(config.tokenPair);
        IWETH(config.weth).transfer(tokenPairAddress, ethRequired);
        config.infinityToken.transferFrom(
            msg.sender,
            tokenPairAddress,
            netInfinity
        );

        uint liquidityCreated = config.tokenPair.mint(address(this));

        if (infinityFee > 0 && config.feeReceiver != address(0)) {
            config.infinityToken.transferFrom(
                msg.sender,
                config.feeReceiver,
                infinityFee
            );
        }

        lockedLP[msg.sender].push(
            LPbatch({
                amount: liquidityCreated,
                timestamp: block.timestamp,
                claimed: false
            })
        );

        emit LPQueued(
            msg.sender,
            liquidityCreated,
            ethRequired,
            netInfinity,
            block.timestamp
        );

        emit InfinityTransferred(msg.sender, netInfinity, infinityFee);
    }

    //pops latest LP if older than period
    function claimLP() external {
        uint next = queueCounter[msg.sender];
        require(
            next < lockedLP[msg.sender].length,
            "HodlerVaultSpace: nothing to claim."
        );
        LPbatch storage batch = lockedLP[msg.sender][next];
        require(
            block.timestamp - batch.timestamp > getStakeDuration(),
            "HodlerVaultSpace: LP still locked."
        );
        next++;
        queueCounter[msg.sender] = next;
        uint donation = (config.donationShare * batch.amount) / 100;
        batch.claimed = true;
        emit LPClaimed(msg.sender, batch.amount, block.timestamp, donation);
        require(
            config.tokenPair.transfer(address(0), donation),
            "HodlerVaultSpace: donation transfer failed in LP claim."
        );
        require(
            config.tokenPair.transfer(msg.sender, batch.amount - donation),
            "HodlerVaultSpace: transfer failed in LP claim."
        );
    }

    // Could not be canceled if activated
    function enableLPForceUnlock() public onlyOwner {
        forceUnlock = true;
    }
}
