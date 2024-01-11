//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC721.sol";
import "./EnumerableSetUpgradeable.sol";
import "./INeuron.sol";

///@title BigBrainKids Staking Contract
///@author mtp721

contract BBKStaking is
    Initializable,
    IERC721ReceiverUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    address public genAddress;
    address public gen2Address;
    address public erc20Address;
    uint256 public gen2Rate;
    uint256 public rareRate;
    uint256 public legendaryRate;

    struct Bag {
        EnumerableSetUpgradeable.UintSet genTokenIds;
        EnumerableSetUpgradeable.UintSet gen2TokenIds;
    }

    mapping(uint256 => uint256) public genToTimestamp;
    mapping(uint256 => uint256) public gen2ToTimestamp;

    mapping(uint256 => address) public genToStaker;
    mapping(uint256 => address) public gen2ToStaker;

    mapping(address => Bag) private stakerToBag;

    mapping(uint256 => bool) public isLegendaryToken;

    mapping(address => int256) private balance;

    function initialize(
        address _genAddress,
        address _gen2Address,
        address _erc20Address
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        genAddress = _genAddress;
        gen2Address = _gen2Address;
        erc20Address = _erc20Address;

        //emission rates per day
        gen2Rate = 1 * 1e18;
        rareRate = 5 * 1e18;
        legendaryRate = 10 * 1e18;
    }

    //External functions

    function stake(
        uint256[] calldata genTokenIds,
        uint256[] calldata gen2TokenIds
    ) external whenNotPaused {
        //setApprovalForAll required before staking
        for (uint256 i = 0; i < genTokenIds.length; i++) {
            uint256 curTokenId = genTokenIds[i];
            IERC721 nftContract = IERC721(genAddress);
            nftContract.safeTransferFrom(msg.sender, address(this), curTokenId);

            stakerToBag[msg.sender].genTokenIds.add(curTokenId);
            genToStaker[curTokenId] = msg.sender;
            genToTimestamp[curTokenId] = block.timestamp;
        }
        for (uint256 i = 0; i < gen2TokenIds.length; i++) {
            uint256 curTokenId = gen2TokenIds[i];
            IERC721 nftContract = IERC721(gen2Address);
            nftContract.safeTransferFrom(msg.sender, address(this), curTokenId);

            stakerToBag[msg.sender].gen2TokenIds.add(curTokenId);
            gen2ToStaker[curTokenId] = msg.sender;
            gen2ToTimestamp[curTokenId] = block.timestamp;
        }
    }

    function unstake(
        uint256[] calldata genTokenIds,
        uint256[] calldata gen2TokenIds
    ) external whenNotPaused {
        for (uint256 i = 0; i < genTokenIds.length; i++) {
            uint256 curTokenId = genTokenIds[i];
            require(
                genToStaker[curTokenId] == msg.sender,
                "You don't own this Token"
            );
            uint256 rewardForToken = _calculateRewardForToken(curTokenId);
            if (rewardForToken > 0) {
                balance[msg.sender] += int256(rewardForToken);
            }
            genToStaker[curTokenId] = address(0);
            genToTimestamp[curTokenId] = 0;
            stakerToBag[msg.sender].genTokenIds.remove(curTokenId);
            IERC721(genAddress).safeTransferFrom(
                address(this),
                msg.sender,
                curTokenId
            );
        }
        for (uint256 i = 0; i < gen2TokenIds.length; i++) {
            uint256 curTokenId = gen2TokenIds[i];
            require(
                gen2ToStaker[curTokenId] == msg.sender,
                "You don't own this Token"
            );
            uint256 rewardForToken = _calculateRewardForTokenGen2(curTokenId);
            if (rewardForToken > 0) {
                balance[msg.sender] += int256(rewardForToken);
            }
            gen2ToStaker[curTokenId] = address(0);
            gen2ToTimestamp[curTokenId] = 0;
            stakerToBag[msg.sender].gen2TokenIds.remove(curTokenId);
            IERC721(gen2Address).safeTransferFrom(
                address(this),
                msg.sender,
                curTokenId
            );
        }
    }

    function claimRewards() external nonReentrant whenNotPaused {
        EnumerableSetUpgradeable.UintSet storage tokenIds = stakerToBag[
            msg.sender
        ].genTokenIds;
        EnumerableSetUpgradeable.UintSet storage tokenIdsGen2 = stakerToBag[
            msg.sender
        ].gen2TokenIds;

        int256 reward = 0;
        for (uint256 i = 0; i < tokenIds.length(); i++) {
            uint256 curTokenId = tokenIds.at(i);
            uint256 stakedSince = genToTimestamp[curTokenId];
            genToTimestamp[curTokenId] = block.timestamp;
            uint256 timePassed = block.timestamp - stakedSince;
            uint256 _rate = isLegendaryToken[curTokenId]
                ? legendaryRate
                : rareRate;
            reward += int256(
                (timePassed / 60) * (((_rate / 1440) / 1e12) * 1e12)
            );
        }
        for (uint256 i = 0; i < tokenIdsGen2.length(); i++) {
            uint256 curTokenId = tokenIdsGen2.at(i);
            uint256 stakedSince = gen2ToTimestamp[curTokenId];
            gen2ToTimestamp[curTokenId] = block.timestamp;
            uint256 timePassed = block.timestamp - stakedSince;
            reward += int256(
                (timePassed / 60) * (((gen2Rate / 1440) / 1e12) * 1e12)
            );
        }

        reward = reward + balance[msg.sender];
        balance[msg.sender] = 0;

        require(reward > 0, "reward is less or equal 0");
        INeuron(erc20Address).mint(msg.sender, uint256(reward));
    }

    function deductFromBalance(uint256 amount) external whenNotPaused {
        _deductFromBalanceOf(msg.sender, amount);
    }

    /**
    @notice deduct a specific amount from the total claimable token balance of an account
     */
    function deductFromBalanceOf(address account, uint256 amount)
        external
        whenNotPaused
    {
        //requires allowance of $Neuron for caller
        require(
            INeuron(erc20Address).allowance(account, msg.sender) >= amount,
            "ERC20: insufficient allowance"
        );
        _deductFromBalanceOf(account, amount);
    }

    function setGenAddress(address _genAddress) external onlyOwner {
        genAddress = _genAddress;
    }

    function setGen2Address(address _gen2Address) external onlyOwner {
        gen2Address = _gen2Address;
    }

    function setErc20Address(address _erc20Address) external onlyOwner {
        erc20Address = _erc20Address;
    }

    function setGen2Rate(uint256 _gen2Rate) external onlyOwner {
        gen2Rate = _gen2Rate;
    }

    function setRareRate(uint256 _rareRate) external onlyOwner {
        rareRate = _rareRate;
    }

    function setLegendaryRate(uint256 _legendaryRate) external onlyOwner {
        legendaryRate = _legendaryRate;
    }

    function setLegendaryTokenIds(uint256[] calldata tokenIds)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            isLegendaryToken[tokenIds[i]] = true;
        }
    }

    function setPaused(bool b) external onlyOwner {
        b ? _pause() : _unpause();
    }

    function genDepositsOf(address addr)
        external
        view
        returns (uint256[] memory)
    {
        return stakerToBag[addr].genTokenIds.values();
    }

    function gen2DepositsOf(address addr)
        external
        view
        returns (uint256[] memory)
    {
        return stakerToBag[addr].gen2TokenIds.values();
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    //Public functions

    /**
    @notice computes available rewards for account for every minute that nfts are staked
    */

    function calculateRewards(address account) public view returns (uint256) {
        EnumerableSetUpgradeable.UintSet storage tokenIds = stakerToBag[account]
            .genTokenIds;
        EnumerableSetUpgradeable.UintSet storage tokenIdsGen2 = stakerToBag[
            account
        ].gen2TokenIds;

        int256 reward = 0;
        for (uint256 i = 0; i < tokenIds.length(); i++) {
            uint256 curTokenId = tokenIds.at(i);
            uint256 stakedSince = genToTimestamp[curTokenId];
            uint256 timePassed = block.timestamp - stakedSince;
            uint256 _rate = isLegendaryToken[curTokenId]
                ? legendaryRate
                : rareRate;
            reward += int256(
                (timePassed / 60) * (((_rate / 1440) / 1e12) * 1e12)
            );
        }
        for (uint256 i = 0; i < tokenIdsGen2.length(); i++) {
            uint256 curTokenId = tokenIdsGen2.at(i);
            uint256 stakedSince = gen2ToTimestamp[curTokenId];
            uint256 timePassed = block.timestamp - stakedSince;
            reward += int256(
                (timePassed / 60) * (((gen2Rate / 1440) / 1e12) * 1e12)
            );
        }
        reward = reward + balance[account];
        return reward > 0 ? uint256(reward) : 0;
    }

    function genBalanceOf(address addr) public view returns (uint256) {
        return stakerToBag[addr].genTokenIds.length();
    }

    function gen2BalanceOf(address addr) public view returns (uint256) {
        return stakerToBag[addr].gen2TokenIds.length();
    }

    //Internal functions

    function _calculateRewardForToken(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        if (genToStaker[tokenId] == address(0)) {
            return 0;
        }
        uint256 stakedSince = genToTimestamp[tokenId];
        uint256 timePassed = block.timestamp - stakedSince;
        uint256 _rate = isLegendaryToken[tokenId] ? legendaryRate : rareRate;
        uint256 reward = (timePassed / 60) * (((_rate / 1440) / 1e12) * 1e12);
        return reward;
    }

    function _calculateRewardForTokenGen2(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        if (gen2ToStaker[tokenId] == address(0)) {
            return 0;
        }
        uint256 stakedSince = gen2ToTimestamp[tokenId];
        uint256 timePassed = block.timestamp - stakedSince;
        uint256 reward = (timePassed / 60) *
            (((gen2Rate / 1440) / 1e12) * 1e12);
        return reward;
    }

    function _deductFromBalanceOf(address account, uint256 amount) internal {
        require(amount <= uint256(type(int256).max), "amount overflow");
        uint256 reward = calculateRewards(account);
        require(reward >= amount, "balance insufficient");
        balance[account] -= int256(amount);
    }
}
