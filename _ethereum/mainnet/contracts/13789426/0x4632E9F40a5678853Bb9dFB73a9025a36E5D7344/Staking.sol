// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

interface IERC20Mintable is IERC20 {
    function mint(address to, uint256 amount) external;
}

interface IBlocBurgers {
    function reservePrivate(uint256 reserveAmount, address reserveAddress) external;
    function transferOwnership(address newOwner) external;
    function ticketCounter() external view returns (uint256);
    function maxTotalSupply() external view returns (uint256);
}

contract Staking is IERC721Receiver, Ownable, ReentrancyGuard  {
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;

    event NftsRewarded(address indexed receiver, uint256 indexed amount);

    uint256 public rewardRate;
    uint256 public rewardRateBonusMultiplier;
    uint256 public nftMintPriceStage1;
    uint256 public nftMintPriceStage2;
    uint256 public nftMintPriceStage3;
    uint256 public nftMintPriceStage4;

    uint256 public lossEventMod; // set 10 for 10%
    uint256 public mintEventMod; // set 20 for 5%

    address public acceptedNftAddress;
    address public rewardTokenAddress;
    address public vaultAddress;

    mapping(address => mapping(uint256 => uint256)) public level1Timestamps;
    mapping(address => EnumerableSet.UintSet) private level1TokenIds;

    mapping(address => mapping(uint256 => uint256)) public level2Timestamps;
    mapping(address => EnumerableSet.UintSet) private level2TokenIds;

    uint256 public lastRandomSeed;

    constructor(
        address _acceptedNftAddress,
        address _rewardTokenAddress,
        address _vaultAddress,
        uint256 _rewardRate,
        uint256 _rewardRateBonusMultiplier,
        uint256 _nftMintPriceStage1,
        uint256 _nftMintPriceStage2,
        uint256 _nftMintPriceStage3,
        uint256 _nftMintPriceStage4,
        uint256 _mintEventMod,
        uint256 _lossEventMod
    ) {
        rewardRate = _rewardRate;
        rewardRateBonusMultiplier = _rewardRateBonusMultiplier;
        acceptedNftAddress = _acceptedNftAddress;
        rewardTokenAddress = _rewardTokenAddress;
        vaultAddress = _vaultAddress;
        nftMintPriceStage1 = _nftMintPriceStage1;
        nftMintPriceStage2 = _nftMintPriceStage2;
        nftMintPriceStage3 = _nftMintPriceStage3;
        nftMintPriceStage4 = _nftMintPriceStage4;
        mintEventMod = _mintEventMod;
        lossEventMod = _lossEventMod;
    }

    function stakeToLevel1(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(acceptedNftAddress).safeTransferFrom(_msgSender(), address(this), tokenIds[i], '');
            level1TokenIds[_msgSender()].add(tokenIds[i]);
            level1Timestamps[_msgSender()][tokenIds[i]] = block.timestamp;
        }
    }

    function unstakeFromLevel1(uint256[] calldata tokenIds) public nonReentrant {
        uint256 totalRewards = 0;

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            require(level1TokenIds[_msgSender()].contains(tokenId), 'Data contains not staked token ID');

            uint256 lastTimestampForTokenId = level1Timestamps[_msgSender()][tokenId];
            if (lastTimestampForTokenId > 0) {
                level1TokenIds[_msgSender()].remove(tokenId);
                IERC721(acceptedNftAddress).safeTransferFrom(address(this), _msgSender(), tokenId, '');

                uint256 rewardForTokenId = block.timestamp.sub(lastTimestampForTokenId).mul(rewardRate);
                totalRewards = totalRewards.add(rewardForTokenId);
                level1Timestamps[_msgSender()][tokenId] = block.timestamp;
            }
        }

        if (totalRewards > 0) IERC20Mintable(rewardTokenAddress).mint(_msgSender(), totalRewards);
    }

    function level1TokenIdsForAddress(address ownerAddress) external view returns (uint256[] memory) {
        EnumerableSet.UintSet storage addressLevel1TokenIds = level1TokenIds[ownerAddress];
        uint256[] memory tokenIds = new uint256[](addressLevel1TokenIds.length());

        for (uint256 i; i < addressLevel1TokenIds.length(); i++) {
            tokenIds[i] = addressLevel1TokenIds.at(i);
        }

        return tokenIds;
    }

    function stakeToLevel2(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(acceptedNftAddress).safeTransferFrom(_msgSender(), address(this), tokenIds[i], '');
            level2TokenIds[_msgSender()].add(tokenIds[i]);
            level2Timestamps[_msgSender()][tokenIds[i]] = block.timestamp;
        }
    }

    function unstakeFromLevel2(uint256[] calldata tokenIds) public nonReentrant {
        uint256 totalRewards = 0;
        uint256 totalReservations = 0;

        uint256 nftsReserved = IBlocBurgers(acceptedNftAddress).ticketCounter();
        uint256 maxTotalSupply = IBlocBurgers(acceptedNftAddress).maxTotalSupply();

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            require(level2TokenIds[_msgSender()].contains(tokenId), 'Data contains not staked token ID');

            uint256 lastTimestampForTokenId = level2Timestamps[_msgSender()][tokenId];
            if (lastTimestampForTokenId > 0) {
                level2TokenIds[_msgSender()].remove(tokenId);

                address nftReceiverAddress = _msgSender();

                uint256 randomNumber = getRandomNumber(tokenId);
                if (randomNumber % lossEventMod == 0) {
                    // 10% chance for nft lost
                    nftReceiverAddress = vaultAddress;
                } else if (randomNumber % mintEventMod == 0) {
                    // 5% chance for new burger, but check supply
                    if (nftsReserved.add(totalReservations.add(1)) <= maxTotalSupply) {
                        totalReservations = totalReservations.add(1);
                    }
                }

                lastRandomSeed = randomNumber;

                IERC721(acceptedNftAddress).safeTransferFrom(address(this), nftReceiverAddress, tokenId, '');

                uint256 rewardForTokenId = block.timestamp.sub(lastTimestampForTokenId).mul(rewardRate);
                uint256 increasedRewardForTokenId = rewardForTokenId.mul(rewardRateBonusMultiplier);
                totalRewards = totalRewards.add(increasedRewardForTokenId);
                level2Timestamps[_msgSender()][tokenId] = block.timestamp;
            }
        }

        if (totalReservations > 0) {
            IBlocBurgers(acceptedNftAddress).reservePrivate(totalReservations, _msgSender());
            emit NftsRewarded(_msgSender(), totalReservations);
        }

        if (totalRewards > 0) IERC20Mintable(rewardTokenAddress).mint(_msgSender(), totalRewards);
    }

    function level2TokenIdsForAddress(address ownerAddress) external view returns (uint256[] memory) {
        EnumerableSet.UintSet storage addressLevel2TokenIds = level2TokenIds[ownerAddress];
        uint256[] memory tokenIds = new uint256[](addressLevel2TokenIds.length());

        for (uint256 i; i < addressLevel2TokenIds.length(); i++) {
            tokenIds[i] = addressLevel2TokenIds.at(i);
        }

        return tokenIds;
    }

    function claimRewards() public nonReentrant {
        uint256 level1TokenIdsSetSize = level1TokenIds[_msgSender()].length();
        uint256 level2TokenIdsSetSize = level2TokenIds[_msgSender()].length();

        require(level1TokenIdsSetSize.add(level2TokenIdsSetSize) > 0, "Nothing staked");

        uint256 totalRewards = 0;

        for (uint256 i; i < level1TokenIdsSetSize; i++) {
            uint256 tokenId = level1TokenIds[_msgSender()].at(i);
            uint256 lastTimestampForTokenId = level1Timestamps[_msgSender()][tokenId];
            if (lastTimestampForTokenId > 0) {
                uint256 rewardForTokenId = block.timestamp.sub(lastTimestampForTokenId).mul(rewardRate);
                totalRewards = totalRewards.add(rewardForTokenId);
                level1Timestamps[_msgSender()][tokenId] = block.timestamp;
            }
        }

        for (uint256 i; i < level2TokenIdsSetSize; i++) {
            uint256 tokenId = level2TokenIds[_msgSender()].at(i);
            uint256 lastTimestampForTokenId = level2Timestamps[_msgSender()][tokenId];
            if (lastTimestampForTokenId > 0) {
                uint256 rewardForTokenId = block.timestamp.sub(lastTimestampForTokenId).mul(rewardRate);
                uint256 increasedRewardForTokenId = rewardForTokenId.mul(rewardRateBonusMultiplier);
                totalRewards = totalRewards.add(increasedRewardForTokenId);
                level2Timestamps[_msgSender()][tokenId] = block.timestamp;
            }
        }

        require(totalRewards > 0, "Nothing to claim");

        IERC20Mintable(rewardTokenAddress).mint(_msgSender(), totalRewards);
    }

    function calculateLevel1Rewards(address ownerAddress) public view returns (uint256) {
        uint256 totalRewards = 0;

        for (uint256 i; i < level1TokenIds[ownerAddress].length(); i++) {
            uint256 tokenId = level1TokenIds[ownerAddress].at(i);
            uint256 lastTimestampForTokenId = level1Timestamps[ownerAddress][tokenId];
            if (lastTimestampForTokenId > 0) {
                uint256 rewardForTokenId = block.timestamp.sub(lastTimestampForTokenId).mul(rewardRate);
                totalRewards = totalRewards.add(rewardForTokenId);
            }
        }

        return totalRewards;
    }

    function calculateLevel2Rewards(address ownerAddress) public view returns (uint256) {
        uint256 totalRewards = 0;

        for (uint256 i; i < level2TokenIds[ownerAddress].length(); i++) {
            uint256 tokenId = level2TokenIds[ownerAddress].at(i);
            uint256 lastTimestampForTokenId = level2Timestamps[ownerAddress][tokenId];
            if (lastTimestampForTokenId > 0) {
                uint256 rewardForTokenId = block.timestamp.sub(lastTimestampForTokenId).mul(rewardRate);
                uint256 increasedRewardForTokenId = rewardForTokenId.mul(rewardRateBonusMultiplier);
                totalRewards = totalRewards.add(increasedRewardForTokenId);
            }
        }

        return totalRewards;
    }

    function calculateTotalRewards(address ownerAddress) public view returns (uint256) {
        return calculateLevel1Rewards(ownerAddress).add(calculateLevel2Rewards(ownerAddress));
    }

    function mintNftWithRewardTokens(uint256 amount) public nonReentrant {
        require(amount > 0, "Wrong amount");

        uint256 nftsReserved = IBlocBurgers(acceptedNftAddress).ticketCounter();
        uint256 maxTotalSupply = IBlocBurgers(acceptedNftAddress).maxTotalSupply();
        require(nftsReserved.add(amount) <= maxTotalSupply, "Exceeds max supply");

        uint256 tokenBalance = IERC20Mintable(rewardTokenAddress).balanceOf(_msgSender());

        uint256 nftMintPrice = nftMintPriceStage4;
        if (nftsReserved <= 1000) {
            nftMintPrice = nftMintPriceStage1;
        } else if (nftsReserved <= 2000) {
            nftMintPrice = nftMintPriceStage2;
        } else if (nftsReserved <= 3000) {
            nftMintPrice = nftMintPriceStage3;
        }

        uint256 payableTokenAmount = nftMintPrice.mul(amount);
        require(payableTokenAmount <= tokenBalance, "Not enough token balance");

        uint256 allowance = IERC20Mintable(rewardTokenAddress).allowance(_msgSender(), address(this));
        require(payableTokenAmount <= allowance, "Not enough token allowance");

        IERC20Mintable(rewardTokenAddress).transferFrom(_msgSender(), vaultAddress, payableTokenAmount);
        IBlocBurgers(acceptedNftAddress).reservePrivate(amount, _msgSender());
    }

    function setAcceptedNftAddress(address _acceptedNftAddress) external onlyOwner {
        acceptedNftAddress = _acceptedNftAddress;
    }

    function setRewardTokenAddress(address _rewardTokenAddress) external onlyOwner {
        rewardTokenAddress = _rewardTokenAddress;
    }

    function setVaultAddress(address _vaultAddress) external onlyOwner {
        vaultAddress = _vaultAddress;
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
    }

    function setRewardRateBonusMultiplier(uint256 _bonusMultiplier) external onlyOwner {
        rewardRateBonusMultiplier = _bonusMultiplier;
    }

    function setMintEventMod(uint256 _mintEventMod) external onlyOwner {
        mintEventMod = _mintEventMod;
    }

    function setLossEventMod(uint256 _lossEventMod) external onlyOwner {
        lossEventMod = _lossEventMod;
    }

    function setNftMintPriceStage1(uint256 _nftMintPrice) external onlyOwner {
        nftMintPriceStage1 = _nftMintPrice;
    }

    function setNftMintPriceStage2(uint256 _nftMintPrice) external onlyOwner {
        nftMintPriceStage2 = _nftMintPrice;
    }

    function setNftMintPriceStage3(uint256 _nftMintPrice) external onlyOwner {
        nftMintPriceStage3 = _nftMintPrice;
    }

    function setNftMintPriceStage4(uint256 _nftMintPrice) external onlyOwner {
        nftMintPriceStage4 = _nftMintPrice;
    }

    function setAcceptedNftContractOwnership(address _newOwner) external onlyOwner {
        IBlocBurgers(acceptedNftAddress).transferOwnership(_newOwner);
    }

    function getRandomNumber(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            seed,
            lastRandomSeed
        ))) & 0xFFFF;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
