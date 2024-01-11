// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155Holder.sol";

interface IAlphaGang {
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

interface IGangToken {
    function mint(address to, uint256 amount) external;
}

contract AGStake is Ownable, ERC1155Holder {
    event Stake(address owner, uint256 tokenId, uint256 count);
    event Unstake(address owner, uint256 tokenId, uint256 count);
    event StakeAll(address owner, uint256[] tokenIds, uint256[] counts);
    event UnstakeAll(address owner, uint256[] tokenIds, uint256[] counts);

    /**
     * Event called when a stake is claimed by user
     * Args:
     * owner: address for which it was claimed
     * amount: amount of $GANG tokens claimed
     * count: count of staked(hard or soft) tokens
     * multiplier: flag indicating wheat the applied multiplier is
     */
    event Claim(
        address owner,
        uint256 amount,
        uint256 count,
        uint256 multiplier
    );

    // references to the AG contracts
    IAlphaGang alphaGang;
    IGangToken gangToken;

    uint256 public ogStakeRate = 496031746031746;
    uint256 public softStakeRate = 124007936507936;

    // maps tokenId to stake
    mapping(uint256 => mapping(address => uint256)) private vault;
    // records block timestamp when last claim occured
    mapping(address => uint256) lastClaim;
    mapping(address => uint256) lastSoftClaim;
    // default start time for claiming rewards
    uint256 public immutable START;

    constructor(IAlphaGang _nft, IGangToken _token) {
        alphaGang = _nft;
        gangToken = _token;
        START = block.timestamp;
    }

    function stakeSingle(uint256 tokenId, uint256 tokenCount) external {
        address _owner = msg.sender;

        alphaGang.safeTransferFrom(
            _owner,
            address(this),
            tokenId,
            tokenCount,
            ""
        );

        // claim unstaked tokens, since count/rate will change
        // claiming after transfer, not to waste too much gas in case user doesn't have any tokens
        claimForAddress(_owner, true);
        claimForAddress(_owner, false);
        unchecked {
            vault[tokenId][_owner] += tokenCount;
        }

        emit Stake(_owner, tokenId, tokenCount);
    }

    function unstakeSingle(uint256 tokenId, uint256 tokenCount) external {
        address _owner = msg.sender;
        uint256 totalStaked = vault[tokenId][_owner];

        require(
            totalStaked >= 0,
            "You do have any tokens available for unstaking"
        );
        require(
            totalStaked >= tokenCount,
            "You do not have requested token amount available for unstaking"
        );

        // claim rewards before unstaking
        claimForAddress(_owner, true);
        claimForAddress(_owner, false);
        unchecked {
            vault[tokenId][_owner] -= tokenCount;
        }

        alphaGang.safeTransferFrom(
            address(this),
            _owner,
            tokenId,
            tokenCount,
            ""
        );

        emit Unstake(msg.sender, tokenId, tokenCount);
    }

    function _stakeAll() internal {
        address _owner = msg.sender;
        uint256[] memory totalAvailable = unstakedBalanceOf(_owner);

        uint256[] memory tokens = new uint256[](3);
        tokens[0] = 1;
        tokens[1] = 2;
        tokens[2] = 3;

        alphaGang.safeBatchTransferFrom(
            _owner,
            address(this),
            tokens,
            totalAvailable,
            ""
        );

        // loop over and update the vault
        unchecked {
            for (uint32 i = 1; i < 4; i++) {
                vault[i][_owner] += totalAvailable[i - 1];
            }
        }

        emit StakeAll(msg.sender, tokens, totalAvailable);
    }

    function _unstakeAll() internal {
        address _owner = msg.sender;
        uint256[] memory totalStaked = stakedBalanceOf(_owner);

        uint256[] memory tokens = new uint256[](3);
        tokens[0] = 1;
        tokens[1] = 2;
        tokens[2] = 3;

        // loop over and update the vault
        unchecked {
            for (uint32 i = 1; i < 4; i++) {
                vault[i][_owner] -= totalStaked[i - 1];
            }
        }

        alphaGang.safeBatchTransferFrom(
            address(this),
            _owner,
            tokens,
            totalStaked,
            ""
        );

        emit UnstakeAll(_owner, tokens, totalStaked);
    }

    /** Views */
    function stakedBalanceOf(address account)
        public
        view
        returns (uint256[] memory _tokenBalance)
    {
        uint256[] memory tokenBalance = new uint256[](3);

        unchecked {
            for (uint32 i = 1; i < 4; i++) {
                uint256 stakedCount = vault[i][account];
                if (stakedCount > 0) {
                    tokenBalance[i - 1] += stakedCount;
                }
            }
        }
        return tokenBalance;
    }

    function unstakedBalanceOf(address account)
        public
        view
        returns (uint256[] memory _tokenBalance)
    {
        // This consumes ~4k gas less than batchBalanceOf with address array
        uint256[] memory totalTokenBalance = new uint256[](3);
        totalTokenBalance[0] = alphaGang.balanceOf(account, 1);
        totalTokenBalance[1] = alphaGang.balanceOf(account, 2);
        totalTokenBalance[2] = alphaGang.balanceOf(account, 3);

        return totalTokenBalance;
    }

    /**
     * Contract addresses referencing functions in case we make a mistake in constructor setting
     */
    function setAlphaGang(address _alphaGang) external onlyOwner {
        alphaGang = IAlphaGang(_alphaGang);
    }

    function setGangToken(address _gangToken) external onlyOwner {
        gangToken = IGangToken(_gangToken);
    }

    /**
     * FE Call fns
     */
    function claim() external {
        _claim(msg.sender);
    }

    function claimSoft() external {
        _claimSoft(msg.sender);
    }

    function claimForAddress(address account, bool hardStake) public {
        if (hardStake) {
            _claim(account);
        } else {
            _claimSoft(account);
        }
    }

    function stakeAll() external {
        _claim(msg.sender);
        _claimSoft(msg.sender);
        _stakeAll();
    }

    function unstakeAll() external {
        _claim(msg.sender);
        _claimSoft(msg.sender);
        _unstakeAll();
    }

    function _claim(address account) internal {
        uint256 stakedAt = lastClaim[account] >= START
            ? lastClaim[account]
            : START;

        uint256 tokenCount = 0;

        // bonus of 6.25% is applied for holding all 3 assets(can only be applied once)
        uint256 triBonusCount = 0;

        // 300 per week for hard, 75 for soft staked
        uint256 stakeRate = 496031746031746;

        uint256[] memory stakedCount = stakedBalanceOf(account);

        unchecked {
            for (uint32 i; i < 3; i++) {
                if (stakedCount[i] > 0) {
                    tokenCount += stakedCount[i];
                    triBonusCount++;
                }
            }
        }
        if (tokenCount > 0) {
            // 35%, 52.5%, 61.25% | Order: 50, Mac, Riri
            uint256 bonusBase = 350_000;
            uint256 bonus = 1_000_000; // multiplier of 1

            unchecked {
                // calculate total bonus to be applied, start adding bonus for more hodls
                for (uint32 j = 1; j < tokenCount; j++) {
                    bonus += bonusBase;
                    bonusBase /= 2;
                }

                // triBonus for holding all 3 OGs
                if (triBonusCount == 3) {
                    bonus += 87_500;
                }
            }

            uint256 timestamp = block.timestamp;

            // by default we will have 10*18 decimal points for $GANG, take away factor of 1000 we added to the bonus to get 10**15
            uint256 earned = ((timestamp - stakedAt) * bonus * stakeRate) /
                1_000_000;

            lastClaim[account] = timestamp;

            gangToken.mint(account, earned);

            emit Claim(account, earned, tokenCount, bonus);
        }
    }

    function _claimSoft(address account) internal {
        uint256 stakedAt = lastSoftClaim[account] >= START
            ? lastSoftClaim[account]
            : START;

        uint256 tokenCount = 0;

        uint256 stakeRate = 124007936507936;

        uint256[] memory stakedCount = unstakedBalanceOf(account);

        unchecked {
            for (uint32 i; i < 3; i++) {
                if (stakedCount[i] > 0) {
                    tokenCount += stakedCount[i];
                }
            }
        }
        if (tokenCount > 0) {
            uint256 timestamp = block.timestamp;

            uint256 earned = ((timestamp - stakedAt) * stakeRate);

            lastSoftClaim[account] = timestamp;

            gangToken.mint(account, earned);

            emit Claim(account, earned, tokenCount, block.timestamp);
        }
    }

    function getSoftPendingRewards(address account)
        external
        view
        returns (uint256 rewards)
    {
        uint256 stakedAt = lastSoftClaim[account] >= START
            ? lastSoftClaim[account]
            : START;

        uint256 tokenCount = 0;

        uint256 stakeRate = 124007936507936;

        uint256[] memory stakedCount = unstakedBalanceOf(account);

        unchecked {
            for (uint32 i; i < 3; i++) {
                if (stakedCount[i] > 0) {
                    tokenCount += stakedCount[i];
                }
            }
        }
        if (tokenCount == 0) {
            return 0;
        }
        uint256 timestamp = block.timestamp;

        uint256 earned = ((timestamp - stakedAt) * stakeRate);
        return earned;
    }

    function getPendingRewards(address account)
        external
        view
        returns (uint256 rewards)
    {
        uint256 stakedAt = lastClaim[account] >= START
            ? lastClaim[account]
            : START;

        uint256 tokenCount = 0;

        // bonus of 6.25% is applied for holding all 3 assets(can only be applied once)
        uint256 triBonusCount = 0;

        uint256 stakeRate = 496031746031746;

        uint256[] memory stakedCount = stakedBalanceOf(account);

        unchecked {
            for (uint32 i; i < 3; i++) {
                if (stakedCount[i] > 0) {
                    tokenCount += stakedCount[i];
                    triBonusCount++;
                }
            }
        }
        if (tokenCount == 0) {
            return 0;
        }
        // 35%, 52.5%, 61.25% | Order: 50, Mac, Riri
        uint256 bonusBase = 350_000;
        uint256 bonus = 1_000_000; // multiplier of 1

        unchecked {
            // calculate total bonus to be applied, start adding bonus for more hodls
            for (uint32 j = 1; j < tokenCount; j++) {
                bonus += bonusBase;
                bonusBase /= 2;
            }

            // triBonus for holding all 3 OGs
            if (triBonusCount == 3) {
                bonus += 87_500;
            }
        }

        uint256 timestamp = block.timestamp;

        // by default we will have 10*18 decimal points for $GANG, take away factor of 1000 we added to the bonus to get 10**15
        uint256 earned = ((timestamp - stakedAt) * bonus * stakeRate) /
            1_000_000;

        return earned;
    }

    function setStakeRate(uint256 _newRate, bool isOGRate) external onlyOwner {
        if (isOGRate) {
            ogStakeRate = _newRate;
        } else {
            softStakeRate = _newRate;
        }
    }
}
