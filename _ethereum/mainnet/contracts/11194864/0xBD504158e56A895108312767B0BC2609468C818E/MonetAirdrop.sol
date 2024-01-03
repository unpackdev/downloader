pragma solidity =0.5.16;

import "./Ownable.sol";
import "./SafeMath.sol";

contract MonetAirdrop is Ownable {
    using SafeMath for uint256;

    address public tokenCards;
    uint256 public laveCards;
    mapping(uint256 => uint256) cardNums;
    mapping(address => bool) public partner;

    constructor(address cards) public {
        tokenCards = cards;
    }

    // EXTERNAL
    function notify(address[] calldata accounts, uint256[] calldata cards) external onlyOwner {
        setCards(cards);
        setPartner(accounts);
    }

    function setPartner(address[] memory accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            partner[accounts[i]] = true;
        }
    }

    function setCards(uint256[] memory cards) public onlyOwner {
        require(cards.length > 0, "cards is empty");

        uint256 levelMax = 10;
        uint256 _laveCards = laveCards;
        for (uint256 i = 0; i < cards.length; i++) {
            cardNums[levelMax.sub(i)] = cards[i];
            _laveCards = _laveCards.add(cards[i]);
        }
        laveCards = _laveCards;
    }

    function airdrop() external onlyCaller(msg.sender) {
        require(laveCards > 0, "lave cards is zero");
        require(partner[msg.sender], "Caller is not partner");

        uint256 seed = uint256(
            keccak256(abi.encodePacked(block.difficulty, now))
        );
        uint256 num = 0;
        uint256 random = seed % laveCards;
        for (uint256 i = 10; i > 4; i--) {
            if (cardNums[i] == 0) continue;
            num = num.add(cardNums[i]);
            if (random <= num) {
                partner[msg.sender] = false;
                laveCards = laveCards.sub(1);
                cardNums[i] = cardNums[i].sub(1);
                uint256 color = (seed / 10 - seed) % 4;
                uint256[] memory cards = new uint256[](1);
                cards[0] = i.mul(10).add(color).add(1000);
                ICardERC(tokenCards).cardsBatchMint(msg.sender, cards);
                emit Airdrop(msg.sender, cards[0]);
                return;
            }
        }
    }

    // MODIFIER
    modifier onlyCaller(address account) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        require(size == 0, "account is contract");

        _;
    }

    // EVENT
    event Airdrop(address indexed sender, uint256 card);
}

interface ICardERC {
    function cardsBatchMint(address _to, uint256[] calldata _cards) external;
}
