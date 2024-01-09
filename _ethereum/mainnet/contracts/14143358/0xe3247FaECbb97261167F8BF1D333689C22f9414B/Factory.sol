pragma solidity =0.8.7;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Clones.sol";
import "./ReentrancyGuard.sol";
import "./IAuction.sol";
import "./IBasket.sol";
import "./IFactory.sol";

contract Factory is IFactory, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 private constant BASE = 1e18;
    uint256 public constant TIMELOCK_DURATION = 5 days;


    constructor (IAuction _auctionImpl, IBasket _basketImpl) {
        auctionImpl = _auctionImpl;
        basketImpl = _basketImpl;
    }

    Proposal[] private _proposals;

    IAuction public override auctionImpl;
    IBasket public override basketImpl;

    uint256 public override minLicenseFee = 1e15; // 1e15 0.1%
    uint256 public override auctionDecrement = 10000;
    uint256 public override auctionMultiplier = 2;
    uint256 public override bondPercentDiv = 400;
    
    PendingChange public pendingMinLicenseFee;
    PendingChange public pendingAuctionDecrement;
    PendingChange public pendingAuctionMultiplier;
    PendingChange public pendingBondPercentDiv;

    uint256 public override ownerSplit;
    PendingChange public pendingOwnerSplit;

    function proposal(uint256 proposalId) external override view returns (Proposal memory) {
        return _proposals[proposalId];
    }

    function proposals(uint256[] memory _ids) external override view returns (Proposal[] memory) {
        uint256 numIds = _ids.length;
        Proposal[] memory returnProps = new Proposal[](numIds);

        for (uint256 i = 0; i < numIds; i++) {
            returnProps[i] = _proposals[_ids[i]];
        }

        return returnProps;
    }

    function proposalsLength() external override view returns(uint256) {
        return _proposals.length;
    }

    function setMinLicenseFee(uint256 newMinLicenseFee) public override onlyOwner {
        if (pendingMinLicenseFee.change != 0 && pendingMinLicenseFee.change == newMinLicenseFee) {
            require(block.timestamp >= pendingMinLicenseFee.timestamp + TIMELOCK_DURATION);
            minLicenseFee = newMinLicenseFee;

            pendingMinLicenseFee.change = 0;

            emit ChangedMinLicenseFee(newMinLicenseFee);
        } else {
            pendingMinLicenseFee.change = newMinLicenseFee;
            pendingMinLicenseFee.timestamp = block.timestamp;

            emit NewMinLicenseFeeSubmitted(newMinLicenseFee);
        }
    }

    function setAuctionDecrement(uint256 newAuctionDecrement) public override onlyOwner {
        if (pendingAuctionDecrement.change != 0 && pendingAuctionDecrement.change == newAuctionDecrement) {
            require(block.timestamp >= pendingAuctionDecrement.timestamp + TIMELOCK_DURATION);
            auctionDecrement = newAuctionDecrement;

            pendingAuctionDecrement.change = 0;

            emit ChangedAuctionDecrement(newAuctionDecrement);
        } else {
            pendingAuctionDecrement.change = newAuctionDecrement;
            pendingAuctionDecrement.timestamp = block.timestamp;

            emit NewAuctionDecrementSubmitted(newAuctionDecrement);
        }
    }

    function setAuctionMultiplier(uint256 newAuctionMultiplier) public override onlyOwner {
        if (pendingAuctionMultiplier.change != 0 && pendingAuctionMultiplier.change == newAuctionMultiplier) {
            require(block.timestamp >= pendingAuctionMultiplier.timestamp + TIMELOCK_DURATION);
            auctionMultiplier = newAuctionMultiplier;

            pendingAuctionMultiplier.change = 0;

            emit ChangedAuctionMultipler(newAuctionMultiplier);
        } else {
            pendingAuctionMultiplier.change = newAuctionMultiplier;
            pendingAuctionMultiplier.timestamp = block.timestamp;

            emit NewAuctionMultiplierSubmitted(newAuctionMultiplier);
        }
    }

    function setBondPercentDiv(uint256 newBondPercentDiv) public override onlyOwner {
        if (pendingBondPercentDiv.change != 0 && pendingBondPercentDiv.change == newBondPercentDiv) {
            require(block.timestamp >= pendingBondPercentDiv.timestamp + TIMELOCK_DURATION);
            bondPercentDiv = newBondPercentDiv;

            pendingBondPercentDiv.change = 0;

            emit ChangedBondPercentDiv(newBondPercentDiv);
        } else {
            pendingBondPercentDiv.change = newBondPercentDiv;
            pendingBondPercentDiv.timestamp = block.timestamp;

            emit NewBondPercentDivSubmitted(newBondPercentDiv);
        }
    }

    function setOwnerSplit(uint256 newOwnerSplit) public override onlyOwner {
        require(newOwnerSplit <= 2e17);
        if (pendingOwnerSplit.change != 0 && pendingOwnerSplit.change == newOwnerSplit) {
            require(block.timestamp >= pendingOwnerSplit.timestamp + TIMELOCK_DURATION);
            ownerSplit = newOwnerSplit;

            pendingOwnerSplit.change = 0;

            emit ChangedOwnerSplit(newOwnerSplit);
        } else {
            pendingOwnerSplit.change = newOwnerSplit;
            pendingOwnerSplit.timestamp = block.timestamp;

            emit NewOwnerSplitSubmitted(newOwnerSplit);
        }
    }

    function getProposalWeights(uint256 id) external override view returns (address[] memory, uint256[] memory) {
        return (_proposals[id].tokens, _proposals[id].weights);
    }

    function proposeBasketLicense(
        uint256 licenseFee, 
        string memory tokenName, 
        string memory tokenSymbol, 
        address[] memory tokens,
        uint256[] memory weights,
        uint256 maxSupply
    ) public override returns (uint256 id) {
        basketImpl.validateWeights(tokens, weights);

        require(licenseFee >= minLicenseFee);

        // create proposal object
        Proposal memory newProposal = Proposal({
            licenseFee: licenseFee,
            tokenName: tokenName,
            tokenSymbol: tokenSymbol,
            proposer: address(msg.sender),
            tokens: tokens,
            weights: weights,
            basket: address(0),
            maxSupply: maxSupply
        });

        _proposals.push(newProposal);
        emit BasketLicenseProposed(msg.sender, tokenName, _proposals.length - 1);

        return _proposals.length - 1;
    }

    function createBasket(uint256 idNumber) external override nonReentrant returns (IBasket) {
        Proposal memory bProposal = _proposals[idNumber];
        require(bProposal.basket == address(0));

        IAuction newAuction = IAuction(Clones.clone(address(auctionImpl)));
        IBasket newBasket = IBasket(Clones.clone(address(basketImpl)));

        _proposals[idNumber].basket = address(newBasket);

        newAuction.initialize(address(newBasket), address(this));
        newBasket.initialize(bProposal, newAuction);

        for (uint256 i = 0; i < bProposal.weights.length; i++) {
            IERC20 token = IERC20(bProposal.tokens[i]);
            token.safeTransferFrom(msg.sender, address(this), bProposal.weights[i]);
            token.safeApprove(address(newBasket), 0);
            token.safeApprove(address(newBasket), bProposal.weights[i]);
        }

        newBasket.mintTo(BASE, msg.sender);

        emit BasketCreated(address(newBasket), idNumber);

        return newBasket;
    }
}
