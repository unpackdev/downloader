// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Calculations.sol";
import "./ERC20.sol";
import "./ReentrancyGuard.sol";

contract PresalePublic is ReentrancyGuard {
    uint256 public id;

    address payable public factoryAddress;
    address public platformOwner;
    LessLibrary public lessLib;

    address[][5] public whitelist; //for backend
    uint8[4] public poolPercentages;
    uint256[5] public stakingTiers;

    TicketsInfo[] public tickets;
    PresaleInfo public generalInfo;
    PresaleUniswapInfo public uniswapInfo;
    PresaleStringInfo public stringInfo;
    IntermediateVariables public intermediate;

    mapping(address => uint256) public voters;
    mapping(address => bool) public claimed; // if 1, it means investor already claimed the tokens or got a refund
    mapping(address => Investment) public investments; // total wei invested per address
    mapping(address => bool) public whitelistTier;

    bool private initiate;
    bool private withdrawedFunds;
    address private lpAddress;
    uint256 private lpAmount;
    address private devAddress;
    uint256 private tokenMagnitude;
    address private WETHAddress;

    uint256[4] private tiersTimes = [6900, 6300, 5400, 3600]; // 1h55m-> 1h45m -> 1h30m -> 1h
    uint256 private lpDaySeconds = 1 days; // one day

    struct TicketsInfo {
        address user;
        uint256 ticketAmount;
    }

    struct PresaleInfo {
        address creator;
        address token;
        uint256 tokenPriceInWei;
        uint256 hardCapInWei;
        uint256 softCapInWei;
        uint256 tokensForSaleLeft;
        uint256 tokensForLiquidityLeft;
        uint256 openTimeVoting;
        uint256 closeTimeVoting;
        uint256 openTimePresale;
        uint256 closeTimePresale;
        uint256 collectedFee;
    }

    struct IntermediateVariables {
        bool cancelled;
        bool liquidityAdded;
        uint256 beginingAmount;
        uint256 raisedAmount;
        uint256 raisedAmountBeforeLiquidity;
        uint256 participants;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 lastTotalStakedAmount;
    }

    struct PresaleUniswapInfo {
        uint256 listingPriceInWei;
        uint256 lpTokensLockDurationInDays;
        uint8 liquidityPercentageAllocation;
        uint256 liquidityAllocationTime;
        uint256 unlockTime;
    }

    struct PresaleStringInfo {
        bytes32 saleTitle;
        bytes32 linkTelegram;
        bytes32 linkGithub;
        bytes32 linkTwitter;
        bytes32 linkWebsite;
        string linkLogo;
        string description;
        string whitepaper;
    }

    struct Investment {
        uint256 amountEth;
        uint256 amountTokens;
    }

    modifier onlyFabric() {
        require(factoryAddress == msg.sender);
        _;
    }

    modifier onlyPresaleCreator() {
        require(msg.sender == generalInfo.creator);
        _;
    }

    modifier notCreator() {
        require(msg.sender != generalInfo.creator, "No permition");
        _;
    }

    modifier liquidityAdded() {
        require(intermediate.liquidityAdded, "Add liquidity");
        _;
    }

    modifier onlyWhenOpenVoting() {
        require(
            block.timestamp >= generalInfo.openTimeVoting &&
                block.timestamp <= generalInfo.closeTimeVoting,
            "Voting closed"
        );
        _;
    }

    modifier onlyWhenOpenPresale() {
        uint256 nowTime = block.timestamp;
        require(
            nowTime >= generalInfo.openTimePresale &&
                nowTime <= generalInfo.closeTimePresale,
            "No presales"
        );
        _;
    }

    modifier presaleIsNotCancelled() {
        require(!intermediate.cancelled);
        _;
    }

    modifier votesPassed(uint256 totalStakedAmount) {
        require(
            intermediate.yesVotes >= intermediate.noVotes,
            "Not enough yes votes"
        );
        require(
            intermediate.yesVotes >=
                lessLib.getMinYesVotesThreshold(totalStakedAmount),
            "Votes less min.treshold"
        );
        require(
            block.timestamp >= generalInfo.closeTimeVoting,
            "Voting is open"
        );
        _;
    }

    modifier openRegister() {
        require(
            block.timestamp >=
                generalInfo.openTimePresale - lessLib.getRegistrationTime() &&
                block.timestamp < generalInfo.openTimePresale,
            "Not registration time"
        );
        _;
    }

    receive() external payable {}

    constructor(
        address payable _factory,
        address _library,
        address _devAddress
    ) {
        require(
            _factory != address(0) &&
                _library != address(0) &&
                _devAddress != address(0)
        );
        lessLib = LessLibrary(_library);
        factoryAddress = _factory;
        platformOwner = lessLib.owner();
        devAddress = _devAddress;
    }

    function init(
        address[2] memory _creatorToken,
        uint256[9] memory _priceTokensForSaleLiquiditySoftHardOpenCloseFee
    ) external onlyFabric {
        require(
            _creatorToken[0] != address(0) && _creatorToken[1] != address(0),
            "0 addr"
        );
        require(!initiate, "already inited");

        require(
            _priceTokensForSaleLiquiditySoftHardOpenCloseFee[5] >=
                block.timestamp,
            "not voting"
        );

        initiate = true;
        generalInfo = PresaleInfo(
            _creatorToken[0],
            _creatorToken[1],
            _priceTokensForSaleLiquiditySoftHardOpenCloseFee[0],
            _priceTokensForSaleLiquiditySoftHardOpenCloseFee[4],
            _priceTokensForSaleLiquiditySoftHardOpenCloseFee[3],
            _priceTokensForSaleLiquiditySoftHardOpenCloseFee[1],
            _priceTokensForSaleLiquiditySoftHardOpenCloseFee[2],
            _priceTokensForSaleLiquiditySoftHardOpenCloseFee[5],
            _priceTokensForSaleLiquiditySoftHardOpenCloseFee[5] +
                lessLib.getVotingTime(),
            _priceTokensForSaleLiquiditySoftHardOpenCloseFee[6],
            _priceTokensForSaleLiquiditySoftHardOpenCloseFee[7],
            _priceTokensForSaleLiquiditySoftHardOpenCloseFee[8]
        );

        uint8 tokenDecimals = ERC20(_creatorToken[1]).decimals();
        tokenMagnitude = uint256(10)**uint256(tokenDecimals);
        intermediate
            .beginingAmount = _priceTokensForSaleLiquiditySoftHardOpenCloseFee[
            1
        ];
    }

    function setUniswapInfo(
        uint256 price,
        uint256 duration,
        uint8 percent,
        uint256 allocationTime
    ) external onlyFabric {
        uniswapInfo = PresaleUniswapInfo(
            price,
            duration,
            percent,
            allocationTime,
            0
        );
    }

    function setStringInfo(
        bytes32 _saleTitle,
        bytes32 _linkTelegram,
        bytes32 _linkGithub,
        bytes32 _linkTwitter,
        bytes32 _linkWebsite,
        string calldata _linkLogo,
        string calldata _description,
        string calldata _whitepaper
    ) external onlyFabric {
        stringInfo = PresaleStringInfo(
            _saleTitle,
            _linkTelegram,
            _linkGithub,
            _linkTwitter,
            _linkWebsite,
            _linkLogo,
            _description,
            _whitepaper
        );
    }

    function setArrays(
        uint8[4] memory _poolPercentages,
        uint256[5] memory _stakingTiers
    ) external onlyFabric {
        poolPercentages = _poolPercentages;
        stakingTiers = _stakingTiers;
    }

    function getWhitelist(uint256 _tier)
        external
        view
        returns (address[] memory)
    {
        return whitelist[5 - _tier];
    }

    function isWhitelisting() external view returns (bool) {
        return
            block.timestamp <= generalInfo.openTimePresale &&
            block.timestamp >=
            generalInfo.openTimePresale - lessLib.getRegistrationTime();
    }

    function register(
        uint256 _tokenAmount,
        uint256 _tier,
        uint256 _timestamp,
        bytes memory _signature
    )
        external
        openRegister
        notCreator
        votesPassed(intermediate.lastTotalStakedAmount)
        presaleIsNotCancelled
    {
        require(_tier > 0 && _tier < 6, "wr tier");
        require(!lessLib.getSignUsed(_signature), "used sign");
        require(
            lessLib._verifySigner(
                keccak256(
                    abi.encodePacked(
                        _tokenAmount,
                        msg.sender,
                        address(this),
                        _timestamp
                    )
                ),
                _signature,
                0
            ),
            "w sign"
        );
        require(!whitelistTier[msg.sender], "whitelisted");

        lessLib.setSingUsed(_signature, address(this));

        if (_tier < 3)
            tickets.push(
                TicketsInfo(msg.sender, _tokenAmount / (500 * tokenMagnitude))
            );
        whitelistTier[msg.sender] = true;
        whitelist[5 - _tier].push(msg.sender);
    }

    function vote(
        bool _yes,
        uint256 _stakingAmount,
        uint256 _timestamp,
        bytes memory _signature,
        uint256 _totalStakedAmount
    ) external onlyWhenOpenVoting presaleIsNotCancelled notCreator {
        require(!lessLib.getSignUsed(_signature), "used sign");
        require(
            lessLib._verifySigner(
                keccak256(
                    abi.encodePacked(
                        _stakingAmount,
                        msg.sender,
                        address(this),
                        _timestamp
                    )
                ),
                _signature,
                0
            )
        );
        require(_stakingAmount >= lessLib.getMinVoterBalance(), "scant bal");
        require(voters[msg.sender] == 0, "a.voted");

        lessLib.setSingUsed(_signature, address(this));

        voters[msg.sender] = _stakingAmount;
        if (_yes) {
            intermediate.yesVotes = intermediate.yesVotes + _stakingAmount;
        } else {
            intermediate.noVotes = intermediate.noVotes + _stakingAmount;
        }
        intermediate.lastTotalStakedAmount = _totalStakedAmount;
    }

    // _tokenAmount only for non bnb tokens
    // poolPercentages starts from 5th to 2nd teirs
    // Staking tiers also starts from 5th to 2nd tiers
    function invest(
        bytes memory _signature,
        uint256 _stakedAmount,
        uint256 _timestamp
    )
        public
        payable
        presaleIsNotCancelled
        onlyWhenOpenPresale
        votesPassed(intermediate.lastTotalStakedAmount)
        nonReentrant
        notCreator
    {
        require(whitelistTier[msg.sender], "not whitelisted");
        require(!lessLib.getSignUsed(_signature), "used sign");
        require(
            lessLib._verifySigner(
                keccak256(
                    abi.encodePacked(
                        _stakedAmount,
                        msg.sender,
                        address(this),
                        _timestamp
                    )
                ), 
                _signature, 
                0
            ),
            "wrong sign"
        );

        uint256 tokensLeft;
        uint256 tokensSold = intermediate.beginingAmount -
            generalInfo.tokensForSaleLeft;
        uint256 nowTime = block.timestamp;

        uint256[5] memory poolAmounts;
        uint256 prevPoolsTotalAmount;
        for (uint256 i = 0; i < 4; i++) {
            poolAmounts[i] =
                (intermediate.beginingAmount * poolPercentages[i]) /
                100;
        }

        if (nowTime < generalInfo.openTimePresale + tiersTimes[3]) {
            require(_stakedAmount >= stakingTiers[0], "TIER 5");
            tokensLeft = poolAmounts[0] - tokensSold;
        } else if (nowTime < generalInfo.openTimePresale + tiersTimes[2]) {
            require(_stakedAmount >= stakingTiers[1], "TIER 4");
            prevPoolsTotalAmount = poolAmounts[0];
            tokensLeft = poolAmounts[1] + prevPoolsTotalAmount - tokensSold;
        } else if (nowTime < generalInfo.openTimePresale + tiersTimes[1]) {
            require(_stakedAmount >= stakingTiers[2], "TIER 3");
            prevPoolsTotalAmount = poolAmounts[0] + poolAmounts[1];
            tokensLeft = poolAmounts[2] + prevPoolsTotalAmount - tokensSold;
        } else if (nowTime < generalInfo.openTimePresale + tiersTimes[0]) {
            require(_stakedAmount >= stakingTiers[3], "TIER 2");
            prevPoolsTotalAmount =
                poolAmounts[0] +
                poolAmounts[1] +
                poolAmounts[2];
            tokensLeft = poolAmounts[3] + prevPoolsTotalAmount - tokensSold;
        } else {
            require(_stakedAmount >= stakingTiers[4], "TIER 1");
            tokensLeft = generalInfo.tokensForSaleLeft;
        }
        uint256 reservedTokens = getTokenAmount(msg.value);
        require(intermediate.raisedAmount < generalInfo.hardCapInWei, "H cap");
        require(tokensLeft >= reservedTokens, "Not enough tokens in pool");
        require(msg.value > 0, "<0");
        uint256 totalInvestmentInWei = investments[msg.sender].amountEth +
            msg.value;

        if (investments[msg.sender].amountEth == 0) {
            intermediate.participants += 1;
        }

        intermediate.raisedAmount += msg.value;
        investments[msg.sender].amountEth = totalInvestmentInWei;
        investments[msg.sender].amountTokens += reservedTokens;
        generalInfo.tokensForSaleLeft -= reservedTokens;
        lessLib.setSingUsed(_signature, address(this));
    }

    function withdrawInvestment(address payable to, uint256 amount)
        external
        nonReentrant
    {
        require(block.timestamp >= generalInfo.openTimePresale, "early");
        require(investments[msg.sender].amountEth >= amount, "not enough amt");
        require(amount > 0, "zero");
        if (!intermediate.cancelled) {
            require(
                !intermediate.liquidityAdded &&
                    intermediate.raisedAmount < generalInfo.softCapInWei,
                "afterCap withdraw"
            );
        }
        require(to != address(0), "0 addr");
        if (investments[msg.sender].amountEth - amount == 0) {
            intermediate.participants -= 1;
        }
        uint256 reservedTokens = getTokenAmount(amount);
        intermediate.raisedAmount -= amount;
        investments[msg.sender].amountEth -= amount;
        investments[msg.sender].amountTokens -= reservedTokens;
        generalInfo.tokensForSaleLeft += reservedTokens;
        to.transfer(amount);
    }

    function claimTokens() external presaleIsNotCancelled nonReentrant liquidityAdded {
        require(
            block.timestamp >= generalInfo.closeTimePresale &&
                !claimed[msg.sender] &&
                investments[msg.sender].amountEth > 0,
            "Cant claim tkns"
        );
        claimed[msg.sender] = true; // make sure this goes first before transfer to prevent reentrancy
        IERC20(generalInfo.token).transfer(
            msg.sender,
            investments[msg.sender].amountTokens
        );
    }

    function addLiquidity() external presaleIsNotCancelled nonReentrant {
        require(msg.sender == devAddress, "only dev");
        require(
            uniswapInfo.liquidityAllocationTime <= block.timestamp &&
            block.timestamp >= generalInfo.closeTimePresale,
            "early"
        );
        require(!intermediate.liquidityAdded, "already added");
        require(
            intermediate.raisedAmount >= generalInfo.softCapInWei,
            "sCap n riched"
        );
        uint256 raisedAmount = intermediate.raisedAmount;
        if (raisedAmount == 0) {
            intermediate.liquidityAdded = true;
            return;
        }

        uint256 liqPoolEthAmount = (raisedAmount *
            uniswapInfo.liquidityPercentageAllocation) / 100;
        uint256 liqPoolTokenAmount = (liqPoolEthAmount * tokenMagnitude) /
            uniswapInfo.listingPriceInWei;

        require(
            generalInfo.tokensForLiquidityLeft >= liqPoolTokenAmount,
            "no liquidity"
        );

        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(
            address(lessLib.getUniswapRouter())
        );

        IERC20 token = IERC20(generalInfo.token);

        token.approve(address(uniswapRouter), liqPoolTokenAmount);

        uint256 amountEth;
        uint256 amountToken;

        (amountToken, amountEth, lpAmount) = uniswapRouter.addLiquidityETH{
            value: liqPoolEthAmount
        }(
            address(token),
            liqPoolTokenAmount,
            0,
            0,
            address(this),
            block.timestamp + 15 minutes
        );

        intermediate.raisedAmountBeforeLiquidity = intermediate.raisedAmount;
        intermediate.raisedAmount -= amountEth;

        IUniswapV2Factory02 uniswapFactory = IUniswapV2Factory02(
            uniswapRouter.factory()
        );
        lpAddress = uniswapFactory.getPair(
            uniswapRouter.WETH(),
            address(token)
        );

        generalInfo.tokensForLiquidityLeft -= amountToken;
        intermediate.liquidityAdded = true;
        uniswapInfo.unlockTime =
            block.timestamp +
            (uniswapInfo.lpTokensLockDurationInDays * lpDaySeconds);
    }

    function collectFundsRaised()
        external
        presaleIsNotCancelled
        nonReentrant
        onlyPresaleCreator
        liquidityAdded
    {
        require(
            intermediate.raisedAmountBeforeLiquidity >=
                generalInfo.softCapInWei,
            "sCap n riched"
        );
        require(!withdrawedFunds, "only once");
        withdrawedFunds = true;

        uint256 fee = lessLib.calculateFee(
            intermediate.raisedAmountBeforeLiquidity
        );
        lessLib.getVaultAddress().transfer(fee);
        payable(generalInfo.creator).transfer(intermediate.raisedAmount - fee);

        uint256 unsoldTokensAmount = generalInfo.tokensForSaleLeft +
            generalInfo.tokensForLiquidityLeft;
        if (unsoldTokensAmount > 0) {
            require(
                IERC20(generalInfo.token).transfer(
                    generalInfo.creator,
                    unsoldTokensAmount
                ),
                "can't send tokens"
            );
        }
    }

    function refundLpTokens()
        external
        presaleIsNotCancelled
        nonReentrant
        onlyPresaleCreator
        liquidityAdded
    {
        require(lpAmount != 0 && block.timestamp >= uniswapInfo.unlockTime);
        require(
            IERC20(lpAddress).transfer(generalInfo.creator, lpAmount),
            "transf.fail"
        );
        lpAmount = 0;
    }

    function collectFee() external nonReentrant {
        require(generalInfo.collectedFee > 0, "already withdrawn");
        require(
            block.timestamp >= generalInfo.closeTimeVoting,
            "only after voting"
        );
        uint256 collectedFee = generalInfo.collectedFee;
        generalInfo.collectedFee = 0;
        if (
            intermediate.yesVotes >= intermediate.noVotes &&
            intermediate.yesVotes > 0 &&
            intermediate.yesVotes >=
            lessLib.getMinYesVotesThreshold(intermediate.lastTotalStakedAmount)
        ) {
            require(msg.sender == platformOwner);
            payable(platformOwner).transfer(collectedFee);
        } else {
            require(msg.sender == generalInfo.creator);
            if (!intermediate.cancelled) {
                _cancelPresale();
            }
            payable(generalInfo.creator).transfer(collectedFee);
        }
    }

    function changeCloseTimeVoting(uint256 _newCloseTime)
        external
        presaleIsNotCancelled
        onlyPresaleCreator
    {
        require(
            block.timestamp < _newCloseTime &&
                _newCloseTime + lessLib.getRegistrationTime() <= generalInfo.openTimePresale
        );
        generalInfo.closeTimeVoting = _newCloseTime;
    }

    function changePresaleTime(uint256 _newOpenTime, uint256 _newCloseTime)
        external
        presaleIsNotCancelled
        onlyPresaleCreator
    {
        require(block.timestamp < generalInfo.openTimePresale, "started");
        require(
            _newCloseTime > _newOpenTime &&
                generalInfo.closeTimeVoting + lessLib.getRegistrationTime() <
                _newOpenTime &&
                _newCloseTime - _newOpenTime > tiersTimes[0] &&
                _newCloseTime < uniswapInfo.liquidityAllocationTime
        );
        generalInfo.openTimePresale = _newOpenTime;
        generalInfo.closeTimePresale = _newCloseTime;
    }

    function cancelPresale() external presaleIsNotCancelled {
        uint256 raisedAmount = (intermediate.liquidityAdded) ? intermediate.raisedAmountBeforeLiquidity : intermediate.raisedAmount;
        if (
            raisedAmount <
            generalInfo.softCapInWei &&
            block.timestamp >= generalInfo.closeTimePresale
        ) {
            require(
                msg.sender == generalInfo.creator ||
                    msg.sender == platformOwner,
                "owners"
            );
        } else {
            require(msg.sender == platformOwner, "owner");
        }
        _cancelPresale();
    }

    function getPresaleId() external view returns (uint256) {
        return id;
    }

    function setPresaleId(uint256 _id) external onlyFabric {
        if (id != 0) {
            require(id != _id);
        }
        id = _id;
    }

    function getMyVote() external view returns (uint256) {
        return voters[msg.sender];
    }

    function getGenInfo()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            generalInfo.tokensForSaleLeft,
            generalInfo.tokensForLiquidityLeft,
            generalInfo.collectedFee
        );
    }

    function getTokenAmount(uint256 _weiAmount)
        internal
        view
        returns (uint256)
    {
        return (_weiAmount * tokenMagnitude) / generalInfo.tokenPriceInWei;
    }

    function _cancelPresale() private presaleIsNotCancelled {
        intermediate.cancelled = true;
        uint256 bal = IERC20(generalInfo.token).balanceOf(address(this));
        if (bal > 0) {
            require(
                IERC20(generalInfo.token).transfer(generalInfo.creator, bal),
                "TRANSFER"
            );
        }
    }
}
