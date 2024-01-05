// SPDX-License-Identifier: MIT
pragma solidity 0.7.1;
import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";
import "./IUniswapV2Pair.sol";
import "./SafeMath.sol";

contract HodlerVault is Ownable {
    using SafeMath for uint;

    /** Emitted when purchaseLP() is called and LP tokens minted */
    event LPQueued(
        address hodler,
        uint amount,
        uint eth,
        uint ubaTokens,
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
        IERC20 ubaToken;
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

        uint ubaMaxAllowed;

        (uint reserve1, uint reserve2,) = config.tokenPair.getReserves();

        if (address(config.ubaToken) < address(config.weth)) {
            ubaMaxAllowed = config.uniswapRouter.quote(
                totalETH,
                reserve2,
                reserve1
            );
        } else {
            ubaMaxAllowed = config.uniswapRouter.quote(
                totalETH,
                reserve1,
                reserve2
            );
        }

        return ubaMaxAllowed;
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
        IERC20 ubaToken,
        address uniswapPair,
        address uniswapRouter,
        address payable feeReceiver,
        uint8 purchaseFee // UBA
    ) public onlyOwner {
        config.ubaToken = ubaToken;
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
            "HodlerVault: donation share % between 0 and 100"
        );
        require(
            purchaseFee <= 100,
            "HodlerVault: purchase fee share % between 0 and 100"
        );

        config.stakeDuration = duration * 1 days;
        config.donationShare = donationShare;
        config.purchaseFee = purchaseFee;
    }


    function setFeeReceiver(address payable feeReceiver) public onlyOwner {
        require(
            feeReceiver != address(0),
            "HodlerVault: fee receiver is zero address"
        );

        config.feeReceiver = feeReceiver;
    }

    function approveOnUni() public {
        config.ubaToken.approve(address(config.uniswapRouter), uint(-1));
    }


    function purchaseLP(uint amount) public lock {
        require(amount > 0, "HodlerVault: UBA required to mint LP");
        require(config.ubaToken.balanceOf(msg.sender) >= amount, "HodlerVault: Not enough UBA tokens");
        require(config.ubaToken.allowance(msg.sender, address(this)) >= amount, "HodlerVault: Not enough UBA tokens allowance");

        uint ubaFee = amount.mul(config.purchaseFee).div(100);
        uint netUba = amount.sub(ubaFee);

        (uint reserve1, uint reserve2, ) = config.tokenPair.getReserves();

        uint ethRequired;

        if (address(config.ubaToken) > address(config.weth)) {
            ethRequired = config.uniswapRouter.quote(
                netUba,
                reserve2,
                reserve1
            );
        } else {
            ethRequired = config.uniswapRouter.quote(
                netUba,
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
        config.ubaToken.transferFrom(
            msg.sender,
            tokenPairAddress,
            netUba
        );

        uint liquidityCreated = config.tokenPair.mint(address(this));

        if (ubaFee > 0 && config.feeReceiver != address(0)) {
            config.ubaToken.transferFrom(
                msg.sender,
                address(this),
                ubaFee
            );

            address[] memory path = new address[](2);
            path[0] = address(config.ubaToken);
            path[1] = address(config.weth);

            config.uniswapRouter.swapExactTokensForETH(
                ubaFee,
                0,
                path,
                config.feeReceiver,
                block.timestamp
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
            netUba,
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
