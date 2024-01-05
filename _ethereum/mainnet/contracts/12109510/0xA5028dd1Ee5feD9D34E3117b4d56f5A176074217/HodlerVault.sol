// SPDX-License-Identifier: MIT
pragma solidity 0.7.1;
import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";
import "./IUniswapV2Pair.sol";

contract HodlerVault is Ownable {

    /** Emitted when purchaseLP() is called and LP tokens minted */
    event LPQueued(
        address hodler,
        uint amount,
        uint eth,
        uint osmTokens,
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
        IERC20 osmToken;
        IUniswapV2Router02 uniswapRouter;
        IUniswapV2Pair tokenPair;
        address weth;
        uint32 stakeDuration;
        uint8 donationShare; //0-100
    }

    bool private locked;
    bool public forceUnlock;

    modifier lock {
        require(!locked, "HodlerVault: reentrancy violation");
        locked = true;
        _;
        locked = false;
    }

    HodlerVaultConfig public config;
    //Front end can loop through this and inspect if enough time has passed
    mapping(address => LPbatch[]) public lockedLP;
    mapping(address => uint) public queueCounter;

    receive() external payable {}

    function maxTokensToInvest() public view returns (uint) {
        uint totalETH = address(this).balance;
        if (totalETH == 0) {
            return 0;
        }

        uint osmMaxAllowed;

        (uint reserve1, uint reserve2,) = config.tokenPair.getReserves();

        if (address(config.osmToken) < address(config.weth)) {
            osmMaxAllowed = config.uniswapRouter.quote(
                totalETH,
                reserve2,
                reserve1
            );
        } else {
            osmMaxAllowed = config.uniswapRouter.quote(
                totalETH,
                reserve1,
                reserve2
            );
        }

        return osmMaxAllowed;
    }


    function getLockedLP(address hodler, uint position)
        public
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

    function lockedLPLength(address hodler) public view returns (uint) {
        return lockedLP[hodler].length;
    }

    function getStakeDuration() public view returns (uint) {
        return forceUnlock ? 0 : config.stakeDuration;
    }

    function seed(
        uint32 duration,
        IERC20 osmToken,
        address uniswapPair,
        address uniswapRouter
    ) public onlyOwner {
        config.osmToken = osmToken;
        config.uniswapRouter = IUniswapV2Router02(uniswapRouter);
        config.tokenPair = IUniswapV2Pair(uniswapPair);
        config.weth = config.uniswapRouter.WETH();
        setParameters(duration, 0);
    }

    function setParameters(uint32 duration, uint8 donationShare)
        public
        onlyOwner
    {
        require(
            donationShare <= 100,
            "HodlerVault: donation share % between 0 and 100"
        );

        config.stakeDuration = duration * 1 days;
        config.donationShare = donationShare;
    }


    function purchaseLP(uint amount) public lock {
        require(amount > 0, "HodlerVault: OSM required to mint LP");
        require(config.osmToken.balanceOf(msg.sender) >= amount, "HodlerVault: Not enough OSM tokens");
        require(config.osmToken.allowance(msg.sender, address(this)) >= amount, "HodlerVault: Not enough OSM tokens allowance");

        (uint reserve1, uint reserve2, ) = config.tokenPair.getReserves();

        uint ethRequired;

        if (address(config.osmToken) > address(config.weth)) {
            ethRequired = config.uniswapRouter.quote(
                amount,
                reserve2,
                reserve1
            );
        } else {
            ethRequired = config.uniswapRouter.quote(
                amount,
                reserve1,
                reserve2
            );
        }

        require(
            address(this).balance >= ethRequired,
            "HodlerVault: insufficient ETH on HodlerVault"
        );

        IWETH(config.weth).deposit{ value: ethRequired }();
        address tokenPairAddress = address(config.tokenPair);
        IWETH(config.weth).transfer(tokenPairAddress, ethRequired);
        config.osmToken.transferFrom(
            msg.sender,
            tokenPairAddress,
            amount
        );

        uint liquidityCreated = config.tokenPair.mint(address(this));

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
            amount,
            block.timestamp
        );

    }

    //pops latest LP if older than period
    function claimLP() public {
        uint next = queueCounter[msg.sender];
        require(
            next < lockedLP[msg.sender].length,
            "HodlerVault: nothing to claim."
        );
        LPbatch storage batch = lockedLP[msg.sender][next];
        require(
            block.timestamp - batch.timestamp > getStakeDuration(),
            "HodlerVault: LP still locked."
        );
        next++;
        queueCounter[msg.sender] = next;
        uint donation = (config.donationShare * batch.amount) / 100;
        batch.claimed = true;
        emit LPClaimed(msg.sender, batch.amount, block.timestamp, donation);
        require(
            config.tokenPair.transfer(address(0), donation),
            "HodlerVault: donation transfer failed in LP claim."
        );
        require(
            config.tokenPair.transfer(msg.sender, batch.amount - donation),
            "HodlerVault: transfer failed in LP claim."
        );
    }

    // Could not be canceled if activated
    function enableLPForceUnlock() public onlyOwner {
        forceUnlock = true;
    }
}
