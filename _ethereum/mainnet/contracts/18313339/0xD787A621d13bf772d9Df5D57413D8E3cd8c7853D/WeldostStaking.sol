// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./EnumerableSet.sol";
import "./IERC20.sol";

contract WeldostStaking is Ownable, ERC1155Holder {
    using EnumerableSet for EnumerableSet.UintSet;

    // Contract Addresses
    IERC1155 public immutable nftAddress;
    IERC20 public immutable usdtAddress;
    address private immutable fund;

    uint64 public constant Interval = 30 days;

    bool public isStopped;
    uint64 public stopTime;
    // Staking Tracking
    mapping(address => uint256) public _currentIDs;
    mapping(address => EnumerableSet.UintSet) private _activeIDs;
    mapping(address => mapping(uint256 => StakeInfo)) public _stakeInfo;
    uint256[] public rewards = [
        5_000_000,
        25_000_000,
        50_000_000,
        75_000_000,
        125_000_000,
        250_000_000
    ];

    struct StakeInfo {
        uint64 tokenId;
        uint64 startTime;
        uint64 claimTime;
    }

    // Events
    event Stake(address addr, uint256[] tokenIds, uint256[] quantities);
    event Unstake(address addr, uint256 stakeId, uint256 tokenId);
    event Claim(address addr, uint256 amount);

    constructor(IERC1155 _nftAddress, IERC20 _usdtAddress, address _fund) {
        nftAddress = _nftAddress;
        usdtAddress = _usdtAddress;
        fund = _fund;
    }

    /**
     * Stake multiple NFTs into the contract
     */
    function stake(
        uint256[] calldata tokenIds,
        uint256[] calldata quantities
    ) external {
        require(!isStopped, "This staking contract has been deprecated");
        require(
            tokenIds.length == quantities.length,
            "TokenIds do not match quantities"
        );
        for (uint256 i; i < tokenIds.length; i++) {
            for (uint j = 0; j < quantities[i]; j++) {
                uint256 stakeID = _currentIDs[msg.sender];
                StakeInfo storage newStake = _stakeInfo[msg.sender][stakeID];
                unchecked {
                    newStake.tokenId = uint64(tokenIds[i]);
                    newStake.startTime = uint64(block.timestamp);
                    newStake.claimTime = uint64(block.timestamp);
                    _activeIDs[msg.sender].add(stakeID);
                    _currentIDs[msg.sender]++;
                }
            }
        }
        nftAddress.safeBatchTransferFrom(
            msg.sender,
            address(this),
            tokenIds,
            quantities,
            ""
        );
        emit Stake(msg.sender, tokenIds, quantities);
    }

    /**
    @notice unstaking a token that has unrealized USDT forfeits the USDT associated
     * with the token(s) being unstaked. This was done intentionally as a holder may
     * not to pay the gas costs associated with claiming USDT. Please see unstakeAndClaim
     * to also claim USDT.
     *
     * Unstaking your NFT transfers ownership back to the address that staked it.
     * When an NFT is unstaked, you will no longer be earning USDT.
     */
    function unstakeMultiple(uint256[] calldata stakeIds) public {
        require(
            stakeIds.length <= _activeIDs[msg.sender].length(),
            "Withdrawing exceeds amount of stakings"
        );
        for (uint256 i; i < stakeIds.length; i++) {
            unstake(stakeIds[i]);
        }
    }

    /**
    @notice unstaking a token that has unrealized USDT forfeits the USDT associated
     * with the token(s) being unstaked. This was done intentionally as a holder may
     * not to pay the gas costs associated with claiming USDT. Please see unstakeAndClaim
     * to also claim USDT.
     *
     * Unstaking your NFT transfers ownership back to the address that staked it.
     * When an NFT is unstaked, you will no longer be earning USDT.
     */
    function unstake(uint256 stakeId) public {
        StakeInfo storage stakeInfo = _stakeInfo[msg.sender][stakeId];
        require(
            uint64(block.timestamp) - stakeInfo.startTime > Interval ||
                isStopped,
            "You can't unstake NFT in the first 30 days"
        );
        uint256 tokenId = stakeInfo.tokenId;
        bool success = _activeIDs[msg.sender].remove(stakeId);
        require(success, "Staking not active");
        nftAddress.safeTransferFrom(address(this), msg.sender, tokenId, 1, "");
        emit Unstake(msg.sender, stakeId, tokenId);
    }

    /**
     * @dev claim earned USDT without unstaking
     */
    function claim(uint256 stakeId) public {
        require(
            _activeIDs[msg.sender].contains(stakeId),
            "StakingID not active"
        );
        StakeInfo storage stakeInfo = _stakeInfo[msg.sender][stakeId];
        uint64 stakedTime;
        if (!isStopped) {
            stakedTime = uint64(block.timestamp) - stakeInfo.claimTime;
        } else {
            stakedTime = stopTime - stakeInfo.claimTime;
        }
        require(stakedTime > Interval, "Nothing accrued yet");
        uint64 intervalsPassed = stakedTime / Interval;
        stakeInfo.claimTime += Interval * intervalsPassed;

        uint256 totalReward = intervalsPassed * rewards[stakeInfo.tokenId];
        require(
            usdtAddress.balanceOf(fund) > totalReward,
            "Not enough tokens in the fund. Contact Team."
        );
        bool success = usdtAddress.transferFrom(fund, msg.sender, totalReward);
        require(success, "Error while transfering tokens");
        emit Claim(msg.sender, totalReward);
    }

    function claimMultiple(uint256[] calldata stakeIds) public {
        require(
            stakeIds.length <= _activeIDs[msg.sender].length(),
            "Withdrawing exceeds amount of stakings"
        );
        for (uint256 i; i < stakeIds.length; i++) {
            claim(stakeIds[i]);
        }
    }

    function getActiveStakingsInfo(
        address account
    ) public view returns (StakeInfo[] memory) {
        EnumerableSet.UintSet storage active = _activeIDs[account];
        StakeInfo[] memory result = new StakeInfo[](active.length());
        for (uint i = 0; i < active.length(); i++) {
            result[i] = _stakeInfo[account][active.at(i)];
        }
        return result;
    }

    /**
     * Track stakings of an account
     */
    function getActiveStakingsID(
        address account
    ) external view returns (uint256[] memory) {
        EnumerableSet.UintSet storage active = _activeIDs[account];
        uint256[] memory stakeIds = new uint256[](active.length());
        for (uint256 i; i < active.length(); i++) {
            stakeIds[i] = active.at(i);
        }
        return stakeIds;
    }

    /**
     * @dev unstakeAndClaim will unstake the token and realize the USDT that it has earned.
     * If you are not interested in earning USDT you can call unstaske and save the gas.
     * Unstaking your NFT transfers ownership back to the address that staked it.
     * When an NFT is unstaked you will no longer be earning USDT.
     */
    function claimAndUnstake(uint256[] calldata _stakeIds) external {
        claimMultiple(_stakeIds);
        unstakeMultiple(_stakeIds);
    }

    /**
     * Allows contract owner to withdraw ERC20 tokens from the contract
     */
    function withdrawTokens(IERC20 _usdtAddress) external onlyOwner {
        uint256 tokenSupply = _usdtAddress.balanceOf(address(this));
        _usdtAddress.transfer(msg.sender, tokenSupply);
    }

    function stopContract() external onlyOwner {
        isStopped = true;
        stopTime = uint64(block.timestamp);
    }
}
