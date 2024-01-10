// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";
import "./Math.sol";
import "./TransferHelper.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./console.sol";

// TODO: check against https://swcregistry.io/
// TODO: Use automatic ETH <-> WETH conversion from uniswap-v2-periphery
// TODO: Optimize contract storage by removing filled offers, withdrawn offers, withdrawn positions? (- indexes might change)
contract Coliquidity is Ownable {
    // NOTE: Contract functions use Uniswap-style error codes (shorthands like "WEXP", "RAMP"). The error codes should be converted to human-readable error messages in UI.
    // NOTE: Contract functions protect against reentrancy by setting protection status before calling external contracts

    struct Offer {
        address maker;
        address makerToken;
        uint makerAmount;
        address taker; // address of a taker that could create a position from this offer (if zero address - anybody can create)
        address[] takerTokens; // addresses of tokens at the other side of the pool (allows to offer coliquidity for multiple token pairs)
        uint makerDenominator;
        uint takerDenominator;
        bool reinvest;
        uint pausedUntil; // UNIX timestamp
        uint lockedUntil; // UNIX timestamp
    }

    struct Contribution {
        uint offerIndex;
        address taker;
        address takerToken;
        uint takerAmount;
    }

    struct Position {
        uint offerIndex;
        address maker;
        address taker;
        address makerToken; // SHLD, BULL, LINK, ...
        address takerToken; // USDT, WETH, WBTC, ...
        uint makerAmount; // needed to calculate the fee
        uint takerAmount; // needed to calculate the fee
        uint liquidityAmount;
        uint lockedUntil; // UNIX timestamp
    }

    Offer[] public offers;
    Contribution[] public contributions;
    Position[] public positions;

    mapping(uint => uint[]) contributionIndexesByOfferIndex;

    struct IndexedOffer {
        uint index;
        Offer offer;
    }

    struct IndexedContribution {
        uint index;
        Contribution contribution;
    }

    struct IndexedPosition {
        uint index;
        Position position;
    }

    // Needed to avoid "Stack too deep" error (https://medium.com/1milliondevs/compilererror-stack-too-deep-try-removing-local-variables-solved-a6bcecc16231)
    struct ContributionVars {
        uint takerAmountSum;
        uint takerAmountMax;
        uint takerAmountDesired;
        uint makerAmountMax;
        uint makerAmountDesired;
    }

    uint public feeNumerator = 1;
    uint public feeDenominator = 100;

    // Store the factory address to save gas on external call to the router
    address public immutable router;
    address public immutable factory;
    address public immutable WETH;

    event OfferCreated(address indexed sender, uint indexed offerIndex);
    event PositionCreated(address indexed sender, uint indexed offerIndex, uint indexed positionIndex);
    event ContributionCreated(address indexed sender, uint indexed offerIndex, uint indexed contributionIndex);
    event OfferWithdrawn(address indexed sender, uint indexed offerIndex);
    event ContributionWithdrawn(address indexed sender, uint indexed offerIndex, uint indexed contributionIndex);
    event PositionWithdrawn(address indexed sender, uint indexed offerIndex, uint indexed positionIndex);

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Coliquidity: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(address _router, address _factory, address _WETH) {
        router = _router;
        factory = _factory;
        WETH = _WETH;
    }

    // only accept ETH via fallback from the WETH contract
    receive() external payable {
        assert(msg.sender == WETH);
    }

    function setFee(uint _feeNumerator, uint _feeDenominator) public onlyOwner {
        require(_feeNumerator > 0, "Coliquidity: SFNZ");
        require(_feeDenominator > 0, "Coliquidity: SFDZ");
        feeNumerator = _feeNumerator;
        feeDenominator = _feeDenominator;
    }

    function createOffer(address makerToken, uint makerAmount, address taker, address[] calldata takerTokens, uint makerDenominator, uint takerDenominator, bool reinvest, uint pausedUntil, uint lockedUntil) lock public {
        require(makerToken != address(0), "Coliquidity: COTNZ");
        require(makerAmount > 0, "Coliquidity: COAGZ");
        require(takerTokens.length > 0, "Coliquidity: COPLG");
        require(lockedUntil == 0 || lockedUntil > block.timestamp, "Coliquidity: COLBT");
        if (makerDenominator != 0) makerAmount = roundBy(makerAmount, makerDenominator);
        // allow taker address to be zero (anybody can take the offer)
        TransferHelper.safeTransferFrom(makerToken, msg.sender, address(this), makerAmount);
        offers.push(
            Offer({maker : msg.sender, makerToken : makerToken, makerAmount : makerAmount, taker : taker, takerTokens : takerTokens, makerDenominator : makerDenominator, takerDenominator : takerDenominator, reinvest : reinvest, pausedUntil : pausedUntil, lockedUntil : lockedUntil})
        );
        emit OfferCreated(msg.sender, offers.length - 1);
    }

    function createContribution(uint offerIndex, address takerToken, uint takerAmount) lock public {
        Offer storage offer = offers[offerIndex];
        require(offer.maker != address(0));
        // require that offer exists
        require(offer.taker == address(0) || offer.taker == msg.sender, "Coliquidity: CCAGD");
        require(takerToken != address(0), "Coliquidity: CCTNZ");
        require(takerAmount > 0, "Coliquidity: CCTGZ");
        TransferHelper.safeTransferFrom(takerToken, msg.sender, address(this), takerAmount);
        contributions.push(
            Contribution({offerIndex : offerIndex, taker : msg.sender, takerToken : takerToken, takerAmount : takerAmount})
        );
        contributionIndexesByOfferIndex[offerIndex].push(contributions.length - 1);
        emit ContributionCreated(msg.sender, offerIndex, contributions.length - 1);
    }

    function withdrawContribution(uint contributionIndex) lock public {
        Contribution storage contribution = contributions[contributionIndex];
        require(contribution.taker == msg.sender, "Coliquidity: WCMES");
        require(contribution.takerAmount > 0, "Coliquidity: WCMAZ");
        uint takerAmount = contribution.takerAmount;
        contribution.takerAmount = 0;
        TransferHelper.safeTransfer(contribution.takerToken, contribution.taker, takerAmount);
        emit ContributionWithdrawn(msg.sender, contribution.offerIndex, contributionIndex);
    }

    function createPair(uint offerIndex, address takerToken, uint deadline) lock public {
        Offer storage offer = offers[offerIndex];
        require(offer.maker == msg.sender, "Coliquidity: OPOMS");
        require(offer.pausedUntil == 0 || offer.pausedUntil <= block.timestamp, "Coliquidity: OPOPT");
        ContributionVars memory vars = ContributionVars(0, 0, 0, 0, 0);
        uint[] storage contributionIndexes = contributionIndexesByOfferIndex[offerIndex];
        for (uint i = 0; i < contributionIndexes.length; i++) {
            if (contributions[contributionIndexes[i]].takerToken != takerToken) continue;
            vars.takerAmountSum += contributions[contributionIndexes[i]].takerAmount;
        }
        vars.takerAmountSum = roundBy(vars.takerAmountSum, offer.takerDenominator);
        vars.takerAmountMax = offer.makerAmount * offer.takerDenominator / offer.makerDenominator;
        vars.takerAmountDesired = Math.min(vars.takerAmountSum, vars.takerAmountMax);
        vars.makerAmountMax = vars.takerAmountDesired * offer.makerDenominator / offer.takerDenominator;
        vars.makerAmountDesired = Math.min(offer.makerAmount, vars.makerAmountMax);
        (uint makerAmountDeposited, uint takerAmountDeposited, uint liquidityAmountReceived) = depositToPool(offer.makerToken, takerToken, vars.makerAmountDesired, vars.takerAmountDesired, vars.makerAmountDesired, vars.takerAmountDesired, deadline);
        offer.makerAmount -= makerAmountDeposited;
        for (uint i = 0; i < contributionIndexes.length; i++) {
            Contribution storage contribution = contributions[contributionIndexes[i]];
            if (contribution.takerToken != takerToken) continue;
            uint takerAmountDiff = Math.min(takerAmountDeposited, contribution.takerAmount);
            uint makerAmountDiff =
            contribution.takerAmount -= takerAmountDiff;
            takerAmountDeposited -= takerAmountDiff;
            positions.push(
                Position({offerIndex : offerIndex, maker : offer.maker, taker : contribution.taker, makerToken : offer.makerToken, takerToken : contribution.takerToken, makerAmount : makerAmountDeposited, takerAmount : takerAmountDiff, liquidityAmount : liquidityAmountReceived, lockedUntil : offer.lockedUntil})
            );
            emit PositionCreated(contribution.taker, offerIndex, positions.length - 1);
            if (takerAmountDeposited == 0) break;
        }
    }

    function createPosition(uint offerIndex, address takerToken, uint makerAmountDesired, uint takerAmountDesired, uint makerAmountMin, uint takerAmountMin, uint deadline) lock public {
        Offer storage offer = offers[offerIndex];
        // NOTE: _pairingToken is validated within addLiquidity call by UniswapV2Library
        // NOTE: _*Amount* are validated within addLiquidity call by UniswapV2Library
        // NOTE: _deadline is validated within addLiquidity call by ensure modifier
        require(offer.taker == address(0) || offer.taker == msg.sender, "Coliquidity: CPAGD");
        require(offer.pausedUntil == 0 || offer.pausedUntil <= block.timestamp, "Coliquidity: CPOPT");
        TransferHelper.safeTransferFrom(takerToken, msg.sender, address(this), takerAmountDesired);
        (uint makerAmountDeposited, uint takerAmountDeposited, uint liquidityAmountReceived) = depositToPool(offer.makerToken, takerToken, makerAmountDesired, takerAmountDesired, makerAmountMin, takerAmountMin, deadline);
        offer.makerAmount -= makerAmountDeposited;
        TransferHelper.safeTransfer(takerToken, msg.sender, takerAmountDesired - takerAmountDeposited);
        positions.push(
            Position({offerIndex : offerIndex, maker : offer.maker, taker : msg.sender, makerToken : offer.makerToken, takerToken : takerToken, makerAmount : makerAmountDeposited, takerAmount : takerAmountDeposited, liquidityAmount : liquidityAmountReceived, lockedUntil : offer.lockedUntil})
        );
        emit PositionCreated(msg.sender, offerIndex, positions.length - 1);
    }

    function depositToPool(address makerToken, address takerToken, uint makerAmountDesired, uint takerAmountDesired, uint makerAmountMin, uint takerAmountMin, uint deadline) internal returns (uint makerAmountDeposited, uint takerAmountDeposited, uint liquidityAmountReceived) {
        IERC20(makerToken).approve(router, makerAmountDesired);
        IERC20(takerToken).approve(router, takerAmountDesired);
        return IUniswapV2Router02(router).addLiquidity(
            makerToken,
            takerToken,
            makerAmountDesired,
            takerAmountDesired,
            makerAmountMin,
            takerAmountMin,
            address(this),
            deadline
        );
    }

    function withdrawOffer(uint offerIndex) lock public {
        Offer storage offer = offers[offerIndex];
        require(offer.maker == msg.sender, "Coliquidity: WOMES");
        require(offer.lockedUntil <= block.timestamp, "Coliquidity: WOLLT");
        require(offer.makerAmount > 0, "Coliquidity: WOMAZ");
        uint makerAmount = offer.makerAmount;
        offer.makerAmount = 0;
        TransferHelper.safeTransfer(offer.makerToken, offer.maker, makerAmount);
        emit OfferWithdrawn(msg.sender, offerIndex);
    }

    function withdrawPosition(uint positionIndex, uint liquidityAmount, uint makerAmountMin, uint takerAmountMin, uint deadline) lock public {
        Position storage position = positions[positionIndex];
        Offer storage offer = offers[position.offerIndex];
        require(position.maker == msg.sender || position.taker == msg.sender, "Coliquidity: WPMTS");
        require(position.lockedUntil <= block.timestamp, "Coliquidity: WPLLT");
        require(position.liquidityAmount >= liquidityAmount, "Coliquidity: WPLGL");
        // liquidity is validated within removeLiquidity call
        // makerAmountMin is validated within removeLiquidity call
        // takerAmountMin is validated within removeLiquidity call
        // deadline is validated within removeLiquidity call
        position.liquidityAmount -= liquidityAmount;
        (address token0, address token1) = sortTokens(position.makerToken, position.takerToken);
        address pair = IUniswapV2Factory(factory).getPair(token0, token1);
//        address pair = pairFor(factory, position.makerToken, position.takerToken);
        IERC20(pair).approve(router, liquidityAmount);
        (uint makerAmountWithdrawn, uint takerAmountWithdrawn) = IUniswapV2Router02(router).removeLiquidity(
            position.makerToken,
            position.takerToken,
            liquidityAmount,
            makerAmountMin,
            takerAmountMin,
            address(this),
            deadline
        );
        if (makerAmountWithdrawn > position.makerAmount) {
            uint makerFee = (makerAmountWithdrawn - position.makerAmount) * feeNumerator / feeDenominator;
            // should be `position.makerAmount -= makerAmountWithdrawn`, but the result is less than 0, so setting it to 0
            position.makerAmount = 0;
            if (offer.reinvest) {
                offer.makerAmount += makerAmountWithdrawn - makerFee;
            } else {
                TransferHelper.safeTransfer(position.makerToken, position.maker, makerAmountWithdrawn - makerFee);
            }
            TransferHelper.safeTransfer(position.makerToken, owner(), makerFee);
        } else {
            position.makerAmount -= makerAmountWithdrawn;
            if (offer.reinvest) {
                offer.makerAmount += makerAmountWithdrawn;
            } else {
                TransferHelper.safeTransfer(position.makerToken, position.maker, makerAmountWithdrawn);
            }
        }
        if (takerAmountWithdrawn > position.takerAmount) {
            uint takerFee = (takerAmountWithdrawn - position.takerAmount) * feeNumerator / feeDenominator;
            // should be `position.takerAmount -= takerAmountWithdrawn`, but the result is less than 0, so setting it to 0            position.takerAmount = 0;
            position.takerAmount = 0;
            // reinvest is not available for the taker
            TransferHelper.safeTransfer(position.takerToken, position.taker, takerAmountWithdrawn - takerFee);
            TransferHelper.safeTransfer(position.takerToken, owner(), takerFee);
        } else {
            position.takerAmount -= takerAmountWithdrawn;
            TransferHelper.safeTransfer(position.takerToken, position.taker, takerAmountWithdrawn);
        }
        emit PositionWithdrawn(msg.sender, position.offerIndex, positionIndex);
    }

    /* Views */

    function offersLength() public view returns (uint) {
        return offers.length;
    }

    function contributionsLength() public view returns (uint) {
        return contributions.length;
    }

    function positionsLength() public view returns (uint) {
        return positions.length;
    }

    function offersTakerTokens(uint offerIndex) public view returns (address[] memory) {
        return offers[offerIndex].takerTokens;
    }

    function offersByMaker(address maker, uint length) public view returns (IndexedOffer[] memory) {
        IndexedOffer[] memory _offersByMaker = new IndexedOffer[](length);
        uint _offersByMakerIndex = 0;
        for (uint i = 0; i < offers.length; i++) {
            if (offers[i].maker == maker) {
                _offersByMaker[_offersByMakerIndex] = IndexedOffer({index : i, offer : offers[i]});
                _offersByMakerIndex++;
                if (_offersByMakerIndex > length) break;
            }
        }
        return _offersByMaker;
    }

    function positionsByMaker(address maker, uint length) public view returns (IndexedPosition[] memory) {
        IndexedPosition[] memory _positionsByMaker = new IndexedPosition[](length);
        uint _positionsByMakerIndex = 0;
        for (uint i = 0; i < positions.length; i++) {
            if (positions[i].maker == maker) {
                _positionsByMaker[_positionsByMakerIndex] = IndexedPosition({index : i, position : positions[i]});
                _positionsByMakerIndex++;
                if (_positionsByMakerIndex > length) break;
            }
        }
        return _positionsByMaker;
    }

    function positionsByTaker(address taker, uint length) public view returns (IndexedPosition[] memory) {
        IndexedPosition[] memory _positionsByTaker = new IndexedPosition[](length);
        uint _positionsByTakerIndex = 0;
        for (uint i = 0; i < positions.length; i++) {
            if (positions[i].taker == taker) {
                _positionsByTaker[_positionsByTakerIndex] = IndexedPosition({index : i, position : positions[i]});
                _positionsByTakerIndex++;
                if (_positionsByTakerIndex > length) break;
            }
        }
        return _positionsByTaker;
    }

    /* UniswapV2Library functions - had to copy because it depends on SafeMath, which depends on Solidity =0.6.6, which is lower than our Solidity version */

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }
//
//    // calculates the CREATE2 address for a pair without making any external calls
//    function pairFor(address _factory, address tokenA, address tokenB) internal pure returns (address pair) {
//        (address token0, address token1) = sortTokens(tokenA, tokenB);
//        pair = address(uint160(uint(keccak256(abi.encodePacked(
//                hex'ff',
//                _factory,
//                keccak256(abi.encodePacked(token0, token1)),
//                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
//            )))));
//    }

    // ensures numerator is evenly divisible by denominator
    // may decrease numerator
    function roundBy(uint numerator, uint denominator) internal pure returns (uint numeratorEven) {
        return numerator / denominator * denominator;
    }
}
