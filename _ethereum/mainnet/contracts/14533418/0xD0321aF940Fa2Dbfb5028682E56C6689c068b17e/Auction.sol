pragma solidity =0.8.7;

import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./IFactory.sol";
import "./IBasket.sol";
import "./IAuction.sol";

contract Auction is IAuction, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 private constant BASE = 1e18;
    uint256 private constant ONE_DAY = 1 days;
    
    bool public override auctionOngoing;
    uint256 public override auctionStart;
    bool public override hasBonded;
    uint256 public override bondAmount;
    uint256 public override bondTimestamp;
    uint256 public override bondBlock;

    IBasket public override basket;
    IFactory public override factory;
    address public override auctionBonder;

    Bounty[] private _bounties;

    bool public override initialized;

    modifier onlyBasket() {
        require(msg.sender == address(basket));
        _;
    }

    function startAuction() onlyBasket public override {
        require(auctionOngoing == false);

        auctionOngoing = true;
        auctionStart = block.number;

        emit AuctionStarted();
    }

    function killAuction() onlyBasket public override {
        auctionOngoing = false;
    }

    function endAuction() public override {
        require(msg.sender == basket.publisher());
        require(auctionOngoing);
        require(!hasBonded);

        auctionOngoing = false;
    }

    function initialize(address basket_, address factory_) public override {
        require(address(factory) == address(0));
        require(!initialized);

        basket = IBasket(basket_);
        factory = IFactory(factory_);
        initialized = true;
    }

    function bondForRebalance() public override {
        require(auctionOngoing);
        require(!hasBonded);

        bondTimestamp = block.timestamp;
        bondBlock = block.number;

        uint256 newRatio = calcIbRatio(bondBlock);
        (,, uint256 minIbRatio) = basket.getPendingWeights();
        require(newRatio >= minIbRatio);

        IERC20 basketToken = IERC20(address(basket));
        bondAmount = basketToken.totalSupply() / factory.bondPercentDiv();
        basketToken.safeTransferFrom(msg.sender, address(this), bondAmount);
        hasBonded = true;
        auctionBonder = msg.sender;

        emit Bonded(msg.sender, bondAmount);
    }

    function calcIbRatio(uint256 blockNum) public view override returns (uint256) {
        uint256 a = factory.auctionMultiplier() * basket.ibRatio();
        uint256 b = (blockNum - auctionStart) * BASE / factory.auctionDecrement();
        uint256 newRatio = a - b;
        return newRatio;
    }

    function getCurrentNewIbRatio() public view override returns(uint256) {
        return calcIbRatio(block.number);
    }

    function settleAuctionWithBond(
        uint256[] memory bountyIDs,
        address[] memory inputTokens,
        uint256[] memory inputAmounts,
        address[] memory outputTokens,
        uint256[] memory outputAmounts
    ) public nonReentrant override {
        require(auctionOngoing);
        require(hasBonded);
        require(bondTimestamp + ONE_DAY > block.timestamp);
        require(msg.sender == auctionBonder);
        require(inputTokens.length == inputAmounts.length);
        require(outputTokens.length == outputAmounts.length);

       uint256 newIbRatio = calcIbRatio(bondBlock);

       _settleAuction(bountyIDs, inputTokens, inputAmounts, outputTokens, outputAmounts, newIbRatio);

        IERC20 basketAsERC20 = IERC20(address(basket));
        basketAsERC20.safeTransfer(msg.sender, bondAmount);
    }
    
    function settleAuctionWithoutBond(
        uint256[] memory bountyIDs,
        address[] memory inputTokens,
        uint256[] memory inputAmounts,
        address[] memory outputTokens,
        uint256[] memory outputAmounts
    ) public nonReentrant override {
        require(auctionOngoing);
        require(!hasBonded);
        require(inputTokens.length == inputAmounts.length);
        require(outputTokens.length == outputAmounts.length);

       uint256 newIbRatio = getCurrentNewIbRatio();

       _settleAuction(bountyIDs, inputTokens, inputAmounts, outputTokens, outputAmounts, newIbRatio);
    }
      function _settleAuction(
        uint256[] memory bountyIDs,
        address[] memory inputTokens,
        uint256[] memory inputAmounts,
        address[] memory outputTokens,
        uint256[] memory outputAmounts,
        uint256 newIbRatio
    ) internal {
        for (uint256 i = 0; i < inputTokens.length; i++) {
            IERC20(inputTokens[i]).safeTransferFrom(msg.sender, address(basket), inputAmounts[i]);
        }

        for (uint256 i = 0; i < outputTokens.length; i++) {
            IERC20(outputTokens[i]).safeTransferFrom(address(basket), msg.sender, outputAmounts[i]);
        }

        (address[] memory pendingTokens, uint256[] memory pendingWeights, uint256 minIbRatio) = basket.getPendingWeights();
        require(newIbRatio >= minIbRatio);
        IERC20 basketAsERC20 = IERC20(address(basket));

        for (uint256 i = 0; i < pendingWeights.length; i++) {
            uint256 tokensNeeded = basketAsERC20.totalSupply() * pendingWeights[i] * newIbRatio / BASE / BASE;
            require(IERC20(pendingTokens[i]).balanceOf(address(basket)) >= tokensNeeded);
        }

        basket.setNewWeights();
        basket.updateIBRatio(newIbRatio);
        auctionOngoing = false;
        hasBonded = false;

        withdrawBounty(bountyIDs);

        emit AuctionSettled(msg.sender);
    }

    function bondBurn() external override {
        require(auctionOngoing);
        require(hasBonded);
        require(bondTimestamp + ONE_DAY <= block.timestamp);

        basket.auctionBurn(bondAmount);
        hasBonded = false;
        auctionOngoing = false;
        basket.deleteNewIndex();

        emit BondBurned(msg.sender, auctionBonder, bondAmount);

        auctionBonder = address(0);
    }

    function addBounty(IERC20 token, uint256 amount) public nonReentrant override returns (uint256) {
        // add bounty to basket
        _bounties.push(Bounty({
            token: address(token),
            amount: amount,
            active: true
        }));
        token.safeTransferFrom(msg.sender, address(this), amount);

        uint256 id = _bounties.length - 1;
        emit BountyAdded(token, amount, id);
        return id;
    }

    function withdrawBounty(uint256[] memory bountyIds) internal {
        // withdraw bounties
        for (uint256 i = 0; i < bountyIds.length; i++) {
            Bounty storage bounty = _bounties[bountyIds[i]];
            require(bounty.active);
            bounty.active = false;

            IERC20(bounty.token).safeTransfer(msg.sender, bounty.amount);

            emit BountyClaimed(msg.sender, bounty.token, bounty.amount, bountyIds[i]);
        }
    }
 }