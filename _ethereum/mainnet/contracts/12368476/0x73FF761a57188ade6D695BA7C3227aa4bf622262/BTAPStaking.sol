// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC1155Holder.sol";

struct Staker {
    uint256 amount;
    uint256 stones;
    uint256 stone_timestamp;
    uint256 reward_timestamp;
}

struct Card {
    uint24 quantity;
    uint256 sold;
    uint256 value;
}

contract BTAPStaking is ERC1155Holder, Ownable {
    using SafeMath for uint256;

    uint256 public minContribution = 10000 * 10**18;
    uint256 public maxContribution = 1000000 * 10**18;
    uint256 public APY = 60;
    uint256 public total;

    uint256 totalRewards;

    mapping(address => Staker) public stakers;

    mapping(uint256 => Card) public cards;

    IERC20 private _btapToken;
    IERC1155 private _nftToken;

    constructor(IERC20 _tokenAddr, IERC1155 _nftAddr) {
        _btapToken = _tokenAddr;
        _nftToken = _nftAddr;
    }

    function setMinContribution(uint256 _minContribute) external onlyOwner {
        minContribution = _minContribute;
    }

    function setMaxContribution(uint256 _maxContribute) external onlyOwner {
        maxContribution = _maxContribute;
    }

    function setBTAPAddress(IERC20 _btapAddr) external onlyOwner {
        _btapToken = _btapAddr;
    }

    function setNFTAddress(IERC1155 _nftAddr) external onlyOwner {
        _nftToken = _nftAddr;
    }

    function totalStakeOf(address sender) public view returns (uint256) {
        // Returns how many BTAP this account has farmed
        return (stakers[sender].amount);
    }

    function addCard(
        uint256 id,
        uint24 quantity,
        uint256 value
    ) public onlyOwner {
        require(cards[id].value == 0, "The card is already exists!");
        _nftToken.safeTransferFrom(
            _msgSender(),
            address(this),
            id,
            quantity,
            ""
        );
        cards[id] = Card(quantity, 0, value);
    }

    function removeCard(uint256 id) public onlyOwner {
        uint256 _leftAmount = cards[id].quantity - cards[id].sold;

        require(_leftAmount > 0, "removeCard: no remaining nfts");
        _nftToken.safeTransferFrom(
            address(this),
            _msgSender(),
            id,
            _leftAmount,
            ""
        );
        cards[id].quantity = 0;
        cards[id].sold = 0;
        cards[id].value = 0;
    }

    function addCardBatch(
        uint256[] memory ids,
        uint24[] memory quantities,
        uint256[] memory amounts
    ) public onlyOwner {
        require(
            ids.length == quantities.length && ids.length == amounts.length,
            "Cards aren't consistent!"
        );

        for (uint24 i = 0; i < ids.length; i++) {
            addCard(ids[i], quantities[i], amounts[i]);
        }
    }

    function isCardPayable(uint256 id) public view returns (bool) {
        if (cards[id].quantity == cards[id].sold) {
            return false;
        }

        return true;
    }

    function purchaseNFT(uint256 id) external {
        consolidateStones(_msgSender());

        uint256 amount = cards[id].value;

        require(isCardPayable(id), "Card is not payable!");
        require(stakers[_msgSender()].stones >= amount, "Insufficient stones!");

        stakers[_msgSender()].stones = stakers[_msgSender()].stones.sub(amount);
        _nftToken.safeTransferFrom(address(this), _msgSender(), id, 1, "");
        cards[id].sold = cards[id].sold.add(1);
    }

    function rewardedStones(address staker) public view returns (uint256) {
        if (stakers[staker].amount < minContribution) {
            return stakers[staker].stones;
        }

        uint256 _seconds =
            block.timestamp.sub(stakers[staker].stone_timestamp).div(1 seconds);
        return
            stakers[staker].stones.add(
                stakers[staker]
                    .amount
                    .div(1e18)
                    .mul(_seconds)
                    .mul(3858024691358025)
                    .div(1e6)
            );
    }

    function rewardedBtaps(address staker) public view returns (uint256) {
        uint256 _timePast =
            block.timestamp.sub(stakers[staker].reward_timestamp);
        uint256 _rewards =
            stakers[staker].amount.mul(_timePast).mul(APY).div(100).div(
                365 days
            );

        if (_rewards > totalRewards) return totalRewards;
        return _rewards;
    }

    function consolidateStones(address staker) internal {
        uint256 stones = rewardedStones(staker);
        stakers[staker].stones = stones;
        stakers[staker].stone_timestamp = block.timestamp;
    }

    function stake(uint256 amount) public {
        address sender = _msgSender();
        require(
            stakers[sender].amount.add(amount) <= maxContribution,
            "Limit MAX BTAP"
        );
        require(
            stakers[sender].amount.add(amount) >= minContribution,
            "Limit MIN BTAP"
        );

        _btapToken.transferFrom(sender, address(this), amount);

        if (stakers[sender].amount > 0) {
            uint256 rewards = rewardedBtaps(sender);
            if (rewards > 0) {
                _btapToken.transfer(sender, rewards);
                totalRewards = totalRewards.sub(rewards);
            }
        }

        consolidateStones(sender);
        total = total.add(amount);
        stakers[sender].amount = stakers[sender].amount.add(amount);
        stakers[sender].reward_timestamp = block.timestamp;
    }

    function claimReward() public {
        uint256 rewards = rewardedBtaps(_msgSender());
        require(rewards > 0, "You don't have any rewards!");

        _btapToken.transfer(_msgSender(), rewards);
        totalRewards = totalRewards.sub(rewards);
        stakers[_msgSender()].reward_timestamp = block.timestamp;
    }

    function withdraw() public {
        address sender = _msgSender();
        uint256 amount = stakers[sender].amount;

        uint256 rewards = rewardedBtaps(_msgSender());

        require(amount > 0, "You're not staking");
        require(_btapToken.transfer(sender, amount), "Transfer error!");

        if (rewards > 0) {
            _btapToken.transfer(sender, rewards);
            totalRewards = totalRewards.sub(rewards);
        }

        consolidateStones(sender);
        stakers[sender].amount = 0;
        total = total.sub(amount);
    }

    function depositeRewards(uint256 amount) public onlyOwner {
        require(amount > 0, "You can't deposite zero amount!");

        _btapToken.transferFrom(_msgSender(), address(this), amount);
        totalRewards = totalRewards.add(amount);
    }

    function removeRewards() public onlyOwner {
        require(totalRewards > 0, "removeRewards: There's no reward left");
        _btapToken.transfer(_msgSender(), totalRewards);
        totalRewards = 0;
    }
}
