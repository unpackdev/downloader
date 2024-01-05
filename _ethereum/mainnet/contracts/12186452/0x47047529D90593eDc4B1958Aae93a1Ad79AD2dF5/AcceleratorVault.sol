// SPDX-License-Identifier: MIT
pragma solidity 0.7.1;
import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";
import "./IUniswapV2Pair.sol";

contract AcceleratorVault is Ownable {
    /** Emitted when purchaseLP() is called to track ETH amounts */
    event EthTransferred(
        address from,
        uint amount,
        uint percentageAmount,
        bool ethFeeTransferEnabled
    );

    /** Emitted when purchaseLP() is called and LP tokens minted */
    event LPQueued(
        address holder,
        uint amount,
        uint eth,
        uint ubaToken,
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
        address ubaToken;
        IUniswapV2Router02 uniswapRouter;
        IUniswapV2Pair tokenPair;
        address weth;
        address payable ethHodler;
        uint32 stakeDuration;
        uint8 donationShare; //0-100
        uint8 purchaseFee; //0-100
    }

    bool public ethFeeTransferEnabled;
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
        address ubaToken,
        address uniswapPair,
        address uniswapRouter,
        address payable ethHodler,
        uint8 donationShare, // LP Token
        uint8 purchaseFee // ETH
    ) public onlyOwner {
        config.ubaToken = ubaToken;
        config.uniswapRouter = IUniswapV2Router02(uniswapRouter);
        config.tokenPair = IUniswapV2Pair(uniswapPair);
        config.weth = config.uniswapRouter.WETH();
        setEthHodlerAddress(ethHodler);
        setParameters(duration, donationShare, purchaseFee);
    }

    function getStakeDuration() public view returns (uint) {
        return forceUnlock ? 0 : config.stakeDuration;
    }

    // Could not be canceled if activated
    function enableLPForceUnlock() public onlyOwner {
        forceUnlock = true;
    }

    function setEthFeeToHodler() public onlyOwner {
        ethFeeTransferEnabled = true;
    }

    function setBuyPressure() public onlyOwner {
        ethFeeTransferEnabled = false;
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
        require(msg.value > 0, "AcceleratorVault: ETH required to mint UBA LP");

        uint feeValue = (config.purchaseFee * msg.value) / 100;
        uint exchangeValue = msg.value - feeValue;

        (uint reserve1, uint reserve2, ) = config.tokenPair.getReserves();

        uint ubaRequired;

        if (address(config.ubaToken) < address(config.weth)) {
            ubaRequired = config.uniswapRouter.quote(
                exchangeValue,
                reserve2,
                reserve1
            );
        } else {
            ubaRequired = config.uniswapRouter.quote(
                exchangeValue,
                reserve1,
                reserve2
            );
        }

        uint balance = IERC20(config.ubaToken).balanceOf(address(this));
        require(
            balance >= ubaRequired,
            "AcceleratorVault: insufficient UBA tokens in AcceleratorVault"
        );

        IWETH(config.weth).deposit{ value: exchangeValue }();
        address tokenPairAddress = address(config.tokenPair);
        IWETH(config.weth).transfer(tokenPairAddress, exchangeValue);
        IERC20(config.ubaToken).transfer(
            tokenPairAddress,
            ubaRequired
        );

        uint liquidityCreated = config.tokenPair.mint(address(this));

        if (!ethFeeTransferEnabled) {
            address[] memory path = new address[](2);
            path[0] = address(config.weth);
            path[1] = address(config.ubaToken);

            config.uniswapRouter.swapExactETHForTokens{ value: feeValue }(
                0,
                path,
                address(this),
                block.timestamp
            );
        } else {
            //ETH receiver is hodler vault here
            config.ethHodler.transfer(feeValue);
        }

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
            ubaRequired,
            block.timestamp
        );

        emit EthTransferred(msg.sender, exchangeValue, feeValue, ethFeeTransferEnabled);
    }

    //send eth to match with UBA tokens in AcceleratorVault
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
