// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.13;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC20.sol";
import "./Math.sol";
import "./UntransferableERC721.sol";

/**
 * MMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMWXOxdlllloxOKNWNXXK000OOO000KXXX0OOkOO0XWMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMW0o:,''''''''';cc:;;,,,'''''',,;;;,''''',;cd0WMMMMMMMMMMMMM
 * MMMMMMMMMMNx;'''''''''''''''''''''''''''''''''''''''''',dXMMMMMMMMMMMM
 * MMMMMMMMMM0:',lol;'.';cllc,',''',,,,,''''',''''''''''''''dNMMMMMMMMMMM
 * MMMMMMMMMM0c':kkc'';;;d00x;'',,'','''''',lxl,....,:cll;'';xXWMMMMMMMMM
 * MMMMMMMMMMXo';dx;.':;'lOkc,'',,,,,'''''';dOc'.;c;,o00Ol'''':xXMMMMMMMM
 * MMMMMMMMMWO:'';:,'..'';::,',''''','''''',cd;..,:,,d0Od;''''''lKWMMMMMM
 * MMMMMMMMMKl,''''''''','''',,',,',,'''''''','''''',clc,''''''''cKMMMMMM
 * MMMMMMMMNd,''''','''''''''''''''''',,,'''''''''''''''''''''''''dNMMMMM
 * MMMMMMMWk;'','''''''''''''''''''''''''''''''''''','','','''''''cKMMMMM
 * MMMMMMW0c,','',''''''''''''''',,,,'''''''''''''',,,,;;;,,''''''cKMMMMM
 * MMMMMNkl::;,,,,,,'''''''''''''''',''''''',,,,;;::ccccllc;''''''oNMMMMM
 * MMMMMXo:lllllc:;;;;,,,,,,,,,,,,,,,;;;;::::::ccccllllllc;,''''':OMMMMMM
 * MMMMMWx:cccccccccc::::::::::::::::::::ccccccccllllcc:;,'''''';kWMMMMMM
 * MMMMMW0occlllllcccccccccccccccccccccclllllllcc::;,,,'''''''':OWMMMMMMM
 * MMMMMMWN0xoc:::::ccccclllllllccccccc::::;;,,,,'''''''''''',oKWMMMMMMMM
 * MMMMMMMMMMWX0koc,'',,,,,,,,,,,,,,,''''''',,''''''''''''';o0WMMMMMMMMMM
 * MMMMMMMMMMMMMMWN0xo;'''''''''''''''''''''''''''''''.';lxKWMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMWKko:,''''''''''''''''''''''.',;cdkKWMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMWNKOxolc:;,,'''''',,,;:codk0XWMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMWNNXK000OOO00KKXNWMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 *
 * @title StakeFrogs
 * @custom:website www.plaguenft.com
 * @author @lozzereth (www.allthingsweb3.com)
 * @notice NFT Staking contract for The Plague. Staking will entitle its holders to a
 *         staked nft and yield token. Contract is the custodian of a fixed amount of
 *         token which is then distributed as rewards to its holders.
 */
contract StakeFrogs is UntransferableERC721, IERC721Receiver {
    using Math for uint256;

    /// @notice Contract addresses
    address public immutable erc721Address;
    address public erc20Address;

    /// @notice First is default, followed by bonusIntervals rates
    uint256[3] public periodEmissions = [100, 200, 300];

    /// @notice Period that one full emission occurs
    uint256 public periodDenominator = 30 days;

    /// @notice Minimum interval (interval * demoninator) to begin bonus emissions
    uint256[2] public bonusIntervals = [3, 6];

    /// @notice Track the deposit and claim state of tokens
    struct StakedToken {
        uint256 depositedAt;
        uint256 claimedAt;
    }
    mapping(uint256 => StakedToken) public staked;

    /// @notice Token non-existent
    error TokenNonExistent(uint256 tokenId);

    /// @notice Not an owner of the frog
    error TokenNonOwner(uint256 tokenId);

    /// @notice Using a non-zero value
    error NonZeroValue();

    constructor(address _erc721Address, address _erc20Address)
        UntransferableERC721("The Plague Staked", "sFROG")
    {
        erc721Address = _erc721Address;
        erc20Address = _erc20Address;
        setBaseURI("ipfs://QmNyaURfnPtYQzDepeEFLDxTWdJHXRBP37HwxyJUvgMSm3/");
    }

    /**
     * @notice Track deposits of an account
     * @dev Intended for off-chain computation having O(totalSupply) complexity
     * @param account - Account to query
     * @return tokenIds
     */
    function depositsOf(address account)
        external
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsLength = balanceOf(account);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i; tokenIdsIdx != tokenIdsLength; ++i) {
                if (!_exists(i)) {
                    continue;
                }
                if (ownerOf(i) == account) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    /**
     * @dev Control the staking bonus for when denominator crosses
     * @param tokens - an array of intervals, denominated by {periodDenominator}
     *                 i.e. [3, 6] being respectively [3 months, 6 months] iff
     *                 {periodDenominator} = 1 month
     */
    function setBonusInterval(uint256[2] calldata tokens) external onlyOwner {
        bonusIntervals = tokens;
    }

    /**
     * @dev Adjust the emission rate (in wei)
     * @param rates - an array such that [default, bonusIntervals[0], bonusIntervals[1]
     */
    function setPeriodEmission(uint256[3] calldata rates) external onlyOwner {
        periodEmissions = rates;
    }

    /**
     * @dev Adjust the period of emission
     * @param interval - the interval, could be 1 day, 1 month, etc...
     */
    function setPeriodDenominator(uint256 interval) external onlyOwner {
        if (interval == 0) revert NonZeroValue();
        periodDenominator = interval;
    }

    /**
     * @notice Calculates the rewards for specific tokens under an address
     * @param account - account to check
     * @param tokenIds - token ids to check against
     * @return rewards
     */
    function calculateRewards(address account, uint256[] memory tokenIds)
        public
        view
        returns (uint256[] memory rewards)
    {
        rewards = new uint256[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (!_exists(tokenId)) {
                revert TokenNonExistent(tokenId);
            }
            if (ownerOf(tokenId) != account) {
                revert TokenNonOwner(tokenId);
            }
            unchecked {
                // tiny gas save
                uint256 interval = periodDenominator;
                uint256 depositedAt = staked[tokenId].depositedAt;
                uint256 claimedAt = staked[tokenId].claimedAt;

                // calculate rewards since deposit
                uint256 sinceDeposit = (block.timestamp - depositedAt) /
                    interval;
                uint256 accrued = _accruedRewards(sinceDeposit);

                // deduct all claims made to date
                if (claimedAt > depositedAt) {
                    uint256 sinceClaim = (claimedAt - depositedAt) / interval;
                    accrued -= _accruedRewards(sinceClaim);
                }
                rewards[i] = accrued;
            }
        }
        return rewards;
    }

    /**
     * @dev Finds the accrued rewards for a period relative to {periodDenominator}
     * @param period - Period of time, i.e 12 [days/months/...]
     * @return Rewards
     */
    function _accruedRewards(uint256 period) private view returns (uint256) {
        return
            Math.min(bonusIntervals[0], period) *
            periodEmissions[0] +
            Math.min(
                bonusIntervals[0] > period ? 0 : period - bonusIntervals[0],
                bonusIntervals[0]
            ) *
            periodEmissions[1] +
            (bonusIntervals[1] > period ? 0 : period - bonusIntervals[1]) *
            periodEmissions[2];
    }

    /**
     * @notice Claim the rewards for the tokens
     * @param tokenIds - Array of token ids
     */
    function claimRewards(uint256[] calldata tokenIds) public {
        uint256 reward;
        uint256[] memory rewards = calculateRewards(msg.sender, tokenIds);
        for (uint256 i; i < tokenIds.length; i++) {
            staked[tokenIds[i]].claimedAt = block.timestamp;
            unchecked {
                reward += rewards[i];
            }
        }

        if (reward > 0) {
            _safeTransferRewards(msg.sender, reward * 1e18);
        }
    }

    /**
     * @notice Deposit tokens into the contract
     * @param tokenIds - Array of token ids to stake
     */
    function deposit(uint256[] calldata tokenIds) public {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            staked[tokenId].depositedAt = block.timestamp;
            IERC721(erc721Address).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId,
                ""
            );
            _mint(msg.sender, tokenId);
        }
    }

    /**
     * @notice Withdraw tokens from the contract
     * @param tokenIds - Array of token ids to stake
     */
    function withdraw(uint256[] calldata tokenIds) public {
        claimRewards(tokenIds);
        _withdraw(tokenIds);
    }

    /**
     * @notice Withdraw tokens from the contract without any rewards
     * @param tokenIds - Array of token ids to stake
     */
    function emergencyWithdraw(uint256[] calldata tokenIds) public {
        _withdraw(tokenIds);
    }

    /**
     * @dev Withdraw token IDs from the contract
     * @param tokenIds - Array of token ids to stake
     */
    function _withdraw(uint256[] calldata tokenIds) private {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (!_exists(tokenId)) {
                revert TokenNonExistent(tokenId);
            }
            if (ownerOf(tokenId) != msg.sender) {
                revert TokenNonOwner(tokenId);
            }
            _burn(tokenId);
            IERC721(erc721Address).safeTransferFrom(
                address(this),
                msg.sender,
                tokenId,
                ""
            );
        }
    }

    /**
     * @notice Withdraw tokens from the staking contract
     * @param amount - Amount in wei to withdraw
     */
    function withdrawTokens(uint256 amount) external onlyOwner {
        _safeTransferRewards(msg.sender, amount);
    }

    /**
     * @dev Issues tokens only if there is a sufficient balance in the contract
     * @param recipient - receiving address
     * @param amount - amount in wei to transfer
     */
    function _safeTransferRewards(address recipient, uint256 amount) private {
        uint256 balance = IERC20(erc20Address).balanceOf(address(this));
        if (amount <= balance) {
            IERC20(erc20Address).transfer(recipient, amount);
        }
    }

    /**
     * @dev Modify the ERC20 token being emitted
     * @param tokenAddress - address of token to emit
     */
    function setErc20Address(address tokenAddress) external onlyOwner {
        erc20Address = tokenAddress;
    }

    /**
     * @dev Receive ERC721 tokens
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
