pragma solidity =0.5.16;

import "./SafeMath.sol";
import "./Math.sol";
import "./Card.sol";
import "./Ownable.sol";

contract MonetV1Router is Ownable {
    using SafeMath for uint256;

    address public tokenCard;
    address public tokenLucky;
    address public tokenMonet;

    uint256 public cardsReward = 1575e18;

    uint256 public startTime;
    uint256 public lotteryPrice = 1e18;

    uint256 public rate = 8;
    uint256 public ratePeriodFinish;

    uint256 public laveCards = 8e3;
    uint256 public lavePeriodFinish;

    uint256 public unit = 1e10;

    constructor(address lucky, address card, address monet) public {
        tokenCard = card;
        tokenLucky = lucky;
        tokenMonet = monet;
    }


    // VIEW
    function cardsNumOf(address from, uint256 level) public view returns (uint256) {
        return ICardERC(tokenCard).cardsNumOf(from, level, unit);
    }

    function cardsNumOfAll(address from) public view returns (uint256[10] memory) {
        return ICardERC(tokenCard).cardsNumOfAll(from, unit);
    }

    // PRIVATE
    function _pkgCards( uint256 umax, uint256 mmax, uint256[] memory unums, uint256[] memory mnums, uint256 level ) private view returns (uint256[] memory ucards, uint256[] memory mcards) {
        require( unums.length == mnums.length, "nnums size not equal to mnums");
        ucards = new uint256[](umax);
        mcards = new uint256[](mmax);
        uint256 upos;
        uint256 mpos;
        for (uint256 i = 0; i < unums.length; i++) {
            if (unums[i] > 0) (upos, ) = _makeCards(level.sub(i), unums[i], upos, ucards);
            if (mnums[i] > 0) (mpos, ) = _makeCards(level.sub(i).sub(1), mnums[i], mpos, mcards);
        }
    }

    function _calcLevelCardsMerge( address from, uint256 level, uint256 num ) private view returns (uint256[] memory, uint256[] memory) {
        uint256 nums = cardsNumOf(from, level);
        uint256 min = Card.min(nums, unit);
        require(num <= min, "insufficient card resources");

        uint256[] memory unums = new uint256[](1);
        uint256[] memory mnums = new uint256[](1);
        (uint256 mmax, uint256 merge) = _randCards(0, num);
        unums[0] = Card.make(num, num, num, num, unit);
        mnums[0] = merge;
        return _pkgCards(4, mmax, unums, mnums, level);
    }

    function _calcCardsMerge(address from) private view returns (uint256[] memory, uint256[] memory) {
        uint256 colorMax = 4;
        uint256[10] memory nums = cardsNumOfAll(from);
        uint256[] memory mnums = new uint256[](10);
        uint256[] memory unums = new uint256[](10);
        uint256 umax;
        uint256 mmax;
        uint256 seed = uint256(keccak256(abi.encodePacked(block.difficulty, now)));
        for (uint256 i = 0; i < 9; i++) {
            uint256 _num = nums[i];
            if (i > 0 && mnums[i.sub(1)] > 0) _num = Card.merge(_num, mnums[i.sub(1)], unit);
            uint256 min = Card.min(_num, unit);
            if (min == 0) continue;
            (uint256 num, uint256 merge) = _randCards((seed = seed >> 1), min);
            mnums[i] = merge;
            mmax = mmax.add(num);
            umax = umax.add(colorMax);

            uint256 ucard = Card.make(min, min, min, min, unit);
            if (i > 0 && mnums[i.sub(1)] > 0) {
                uint256 cards = mnums[i.sub(1)];
                if (cards == 0) {
                    continue;
                }
                for (uint256 j = 0; j < colorMax; j++) {
                    uint256 cnum = Card.num(cards, j, unit);
                    uint256 mnum = Math.min(cnum, min);
                    if (mnum > 0) {
                        cards = Card.sub(cards, j, mnum, unit);
                        ucard = Card.sub(ucard, j, mnum, unit);
                        if (mnum == min) umax = umax.sub(1);
                        if (mnum == cnum) mmax = mmax.sub(1);
                    }
                }
                mnums[i.sub(1)] = cards;
            }
            unums[i] = ucard;
        }
        return _pkgCards(umax, mmax, unums, mnums, 10);
    }

    function _makeCards( uint256 level, uint256 nums, uint256 pos, uint256[] memory cards ) private view returns (uint256, uint256[] memory) {
        for (uint256 i = 0; i < 4; i++) {
            uint256 num = Card.num(nums, i, unit);
            if (num > 0) {
                require(pos < cards.length, "pos gt array size");
                cards[pos] = num.mul(1000).add(level.mul(10)).add(i);
                pos = pos.add(1);
            }
        }
        return (pos, cards);
    }

    function _randCards(uint256 seed, uint256 total) private view returns (uint256 num, uint256) {
        uint256[4] memory nums = [uint256(0), 0, 0, 0];
        if (seed == 0)
            seed = uint256(keccak256(abi.encodePacked(block.difficulty, now)));

        uint256 left = total.sub(total % 4);
        uint256 avg = left.div(4).add(1);
        uint256 va = Math.sqrt(avg);
        for (uint256 i = 0; i < 3; i++) {
            nums[i] = Math.min(total, avg.add(seed % va.mul(2).add(1)).sub(va));
            total = total.sub(nums[i]);
            seed = seed / 10 - seed;
            if (nums[i] > 0) num = num.add(1);
        }
        nums[3] = total;
        if (nums[3] > 0) num = num.add(1);

        for (uint256 i = 0; i < 4; i++) {
            uint256 j = (seed = seed / 10 - seed) % 4;
            (nums[i], nums[j]) = (nums[j], nums[i]);
        }
        return (num, Card.make(nums[0], nums[1], nums[2], nums[3], unit));
    }

    function _transferCards( address from, uint256[] memory ucards, uint256[] memory mcards ) private {
        require(ucards.length > 0 && mcards.length > 0, "merge error");

        ICardERC(tokenCard).cardsBatchBurnFrom(from, ucards);
        ICardERC(tokenCard).cardsBatchMint(from, mcards);
        emit TransferCards(from, ucards, mcards);
    }

    function merge(uint256 level, uint256 num) external validateSender(msg.sender) {
        require(level > 1 && level <= 10, "illegal level");

        uint256[] memory ucards;
        uint256[] memory mcards;
        (ucards, mcards) = _calcLevelCardsMerge(msg.sender, level, num);
        _transferCards(msg.sender, ucards, mcards);
    }

    function oneKeyMerge() external validateSender(msg.sender) {
        uint256[] memory ucards;
        uint256[] memory mcards;
        (ucards, mcards) = _calcCardsMerge(msg.sender);
        _transferCards(msg.sender, ucards, mcards);
    }

    function lottery(uint256 num) external validateSender(msg.sender) rateRevise laveCardsReset {
        require(startTime <= block.timestamp, "startTime gt block.timestamp");
        require(num > 0, "num equals zero");
        require(IERC20(tokenLucky).burnFrom(msg.sender, num.mul(lotteryPrice)), "lucky burn fail");     

        uint256 obtain;
        uint256 one = uint256(1000).div(rate);
        uint256 seed = uint256(
            keccak256(abi.encodePacked(block.difficulty, now))
        );

        if (one > 0) {
            uint256 avg = num.div(one);
            uint256 va = Math.sqrt(avg);
            uint256 rand = seed % 100;
            if (rand <= 76) {
                obtain = avg.add(seed % va.mul(2).add(1)).sub(va);
            } else if (rand <= 88) {
                obtain = avg.add(seed % va.add(1)).add(va);
            } else {
                obtain = avg.sub(seed % va.add(1)).sub(va);
            }
        }

        if (num % one >= (seed % one).add(1)) {
            obtain = obtain.add(1);
        }
        obtain = Math.min(obtain, laveCards);
        laveCards = laveCards.sub(obtain);


        uint256[] memory cards;
        if (obtain > 0) {
            (uint256 cnum, uint256 mnums) = _randCards(seed, obtain);
            cards = new uint256[](cnum);
            _makeCards(10, mnums, 0, cards);

            ICardERC(tokenCard).cardsBatchMint(msg.sender, cards);
        }
        emit Lottery(msg.sender, cards);
    }

    function reward(uint256 color, uint256 num) external validateSender(msg.sender) {
        require(color < 4 && num > 0, "color gt 4");

        uint256[] memory cards = new uint256[](1);
        cards[0] = color.add(10).add(num.mul(1000));

        ICardERC(tokenCard).cardsBatchBurnFrom(msg.sender, cards);
        IERC20(tokenMonet).transfer(msg.sender, num.mul(cardsReward));

        emit Reward(msg.sender, cards);
    }

    function setUnit(uint256 _unit) external onlyOwner {
        unit = _unit;
    }

    function notify(uint256 unixtime) external onlyOwner {
        require(startTime == 0, 'startTime not equal zero');
        startTime = unixtime;
        lavePeriodFinish = unixtime.add(1 days);
        ratePeriodFinish = unixtime.add(30 days);
    }

    // MODIFIER
    modifier rateRevise(){
        if (rate != 1 && block.timestamp > ratePeriodFinish) {
            rate = rate.div(2);
            ratePeriodFinish = ratePeriodFinish.add(30 days);
        }

        _;
    }

    modifier laveCardsReset() {
        if (lavePeriodFinish <= block.timestamp) {
            laveCards = rate.mul(1e3);
            lavePeriodFinish = lavePeriodFinish.add(1 days);
        }  

        _;
    }

    modifier validateSender(address account) {
        uint256 size;
        assembly { size := extcodesize(account) }
        require(size == 0, "account is contract");

        _;
    }

    // EVENT
    event Reward(address indexed sender, uint256[] cards);
    event Lottery(address indexed sender, uint256[] cards);
    event TransferCards(address indexed sender, uint256[] burnCards, uint256[] issueCards);
}

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function burnFrom(address from, uint256 value) external returns (bool);
}

interface ICardERC {
    function cardsBatchMint(address _to, uint256[] calldata _cards) external;
    function cardsBatchBurnFrom(address _from, uint256[] calldata _cards) external;
    function cardsNumOf(address _owner, uint256 _level, uint256 _carry) external view returns (uint256);
    function cardsNumOfAll(address _owner, uint256 _carry) external view returns (uint256[10] memory);
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}