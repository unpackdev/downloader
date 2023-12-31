// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;
import "./IERC20.sol";
import "./Ownable.sol";
import "./Math.sol";
import "./SafeMath.sol";

import "./IALSD.sol";
import "./IVEALSD.sol";

import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./ERC20.sol";
import "./EnumerableSet.sol";

/*
 * Website: alacritylsd.com
 * X/Twitter: x.com/alacritylsd
 * Telegram: t.me/alacritylsd
 */

/*
 * veALSD is the vote escrow token of Alacrity.
 * It provides users with the ability to participate in voting activities.
 * Additionally, users can convert their ALSD tokens into veALSD tokens at a 1:1 ratio,
 * where each ALSD token can be exchanged for 1 veALSD token.
 *
 * Alternatively, users can participate in the early liquidity mining event by contributing
 * to the liquidity pools.
 * One unique feature of veALSD is the ability for users to gradually unlock their tokens
 * and convert them back to ALSD within a specified time frame. During the unlock period,
 * which ranges from 5 to 10 days, users have the flexibility to choose when to unlock their
 * veALSD tokens.
 *
 * For example, they can choose to unlock their tokens after 7.5 days.
 * The gains received upon unlocking the tokens are proportional to the duration they were held.
 *
 * This approach allows users to have control over their investments and decide the optimal time
 * to unlock their veALSD tokens based on their individual preferences and market conditions.
 */

contract veALSD is
    Ownable,
    ReentrancyGuard,
    ERC20("ALSD vote escrow token", "veALSD"),
    IVEALSD
{
    using Address for address;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IALSD;

    struct VEALSDBalance {
        uint256 allocatedAmount;
        uint256 redeemingAmount;
    }

    EnumerableSet.AddressSet private _transferWhitelist;

    mapping(address => mapping(address => uint256)) public usageApprovals;
    mapping(address => mapping(address => uint256))
        public
        override usageAllocations;

    uint256 private constant MAX_DEALLOCATION_FEE = 200;
    mapping(address => uint256) private usagesDeallocationFee;

    uint256 private constant MAX_FIXED_RATIO = 100; // 100%

    struct RedeemInfo {
        uint256 alsdAmount;
        uint256 VEALSDAmount;
        uint256 endTime;
        IVEALSD dividendsAddress;
        uint256 dividendsAllocation;
    }

    IALSD public immutable alsdToken;
    IVEALSD public dividendsAddress;

    uint256 public minRedeemRatio = 50; // 1:0.5
    uint256 public maxRedeemRatio = 100; // 1:1
    uint256 public minRedeemDuration = 5 days;
    uint256 public maxRedeemDuration = 10 days;

    uint256 public redeemDividendsAdjustment = 0; // 50%

    mapping(address => VEALSDBalance) public VEALSDBalances;
    mapping(address => RedeemInfo[]) public userRedeems;

    constructor(IALSD _alsdToken) {
        _transferWhitelist.add(address(this));
        _transferWhitelist.add(msg.sender);
        alsdToken = _alsdToken;
    }

    modifier validateRedeem(address userAddress, uint256 redeemIndex) {
        require(
            redeemIndex < userRedeems[userAddress].length,
            "Redeem entry does not exist"
        );
        _;
    }

    function getVEALSDBalance(
        address userAddress
    ) external view returns (uint256 allocatedAmount, uint256 redeemingAmount) {
        VEALSDBalance storage balance = VEALSDBalances[userAddress];
        return (balance.allocatedAmount, balance.redeemingAmount);
    }

    function getUserRedeemsLength(
        address userAddress
    ) external view returns (uint256) {
        return userRedeems[userAddress].length;
    }

    function getUserRedeem(
        address userAddress,
        uint256 redeemIndex
    )
        external
        view
        validateRedeem(userAddress, redeemIndex)
        returns (
            uint256 alsdAmount,
            uint256 VEALSDAmount,
            uint256 endTime,
            address dividendsContract,
            uint256 dividendsAllocation
        )
    {
        RedeemInfo storage _redeem = userRedeems[userAddress][redeemIndex];
        return (
            _redeem.alsdAmount,
            _redeem.VEALSDAmount,
            _redeem.endTime,
            address(_redeem.dividendsAddress),
            _redeem.dividendsAllocation
        );
    }

    function getUsageApproval(
        address userAddress,
        address usageAddress
    ) external view returns (uint256) {
        return usageApprovals[userAddress][usageAddress];
    }

    function getAlsdByVestingDuration(
        uint256 amount,
        uint256 duration
    ) public view returns (uint256) {
        if (duration < minRedeemDuration) {
            return 0;
        }

        if (duration > maxRedeemDuration) {
            return amount.mul(maxRedeemRatio).div(100);
        }

        uint256 ratio = minRedeemRatio.add(
            (duration.sub(minRedeemDuration))
                .mul(maxRedeemRatio.sub(minRedeemRatio))
                .div(maxRedeemDuration.sub(minRedeemDuration))
        );

        return amount.mul(ratio).div(100);
    }

    function getUsageAllocation(
        address userAddress,
        address usageAddress
    ) external view returns (uint256) {
        return usageAllocations[userAddress][usageAddress];
    }

    function transferWhitelistLength() external view returns (uint256) {
        return _transferWhitelist.length();
    }

    function transferWhitelist(uint256 index) external view returns (address) {
        return _transferWhitelist.at(index);
    }

    function updateRedeemSettings(
        uint256 minRedeemRatio_,
        uint256 maxRedeemRatio_,
        uint256 minRedeemDuration_,
        uint256 maxRedeemDuration_,
        uint256 redeemDividendsAdjustment_
    ) external onlyOwner {
        require(minRedeemRatio_ <= maxRedeemRatio_, "Wrong ratio values");
        require(
            minRedeemDuration_ < maxRedeemDuration_,
            "Wrong duration values"
        );
        require(
            maxRedeemRatio_ <= MAX_FIXED_RATIO &&
                redeemDividendsAdjustment_ <= MAX_FIXED_RATIO,
            "Wrong ratio values"
        );

        minRedeemRatio = minRedeemRatio_;
        maxRedeemRatio = maxRedeemRatio_;
        minRedeemDuration = minRedeemDuration_;
        maxRedeemDuration = maxRedeemDuration_;
        redeemDividendsAdjustment = redeemDividendsAdjustment_;
    }

    function updateDividendsAddress(
        IVEALSD dividendsAddress_
    ) external onlyOwner {
        if (address(dividendsAddress_) == address(0)) {
            redeemDividendsAdjustment = 0;
        }

        dividendsAddress = dividendsAddress_;
    }

    function isTransferWhitelisted(
        address account
    ) external view override returns (bool) {
        return _transferWhitelist.contains(account);
    }

    function updateDeallocationFee(
        address usageAddress,
        uint256 fee
    ) external onlyOwner {
        require(fee <= MAX_DEALLOCATION_FEE, "Fee too high");

        usagesDeallocationFee[usageAddress] = fee;
    }

    function updateTransferWhitelist(
        address account,
        bool add
    ) external onlyOwner {
        require(
            account != address(this),
            "Cannot remove veALSD from whitelist"
        );

        if (add) _transferWhitelist.add(account);
        else _transferWhitelist.remove(account);
    }

    function approveUsage(IVEALSD usage, uint256 amount) external nonReentrant {
        require(address(usage) != address(0), "Approve to the zero address");

        usageApprovals[msg.sender][address(usage)] = amount;
    }

    function convertTo(
        uint256 amount,
        address to
    ) external override nonReentrant {
        require(address(msg.sender).isContract(), "Must be a contract");
        _convert(amount, to);
    }

    function finalizeRedeem(
        uint256 redeemIndex
    ) external nonReentrant validateRedeem(msg.sender, redeemIndex) {
        VEALSDBalance storage balance = VEALSDBalances[msg.sender];
        RedeemInfo storage _redeem = userRedeems[msg.sender][redeemIndex];
        require(
            block.timestamp >= _redeem.endTime,
            "Vesting duration has not ended yet"
        );

        balance.redeemingAmount = balance.redeemingAmount.sub(
            _redeem.VEALSDAmount
        );
        _finalizeRedeem(msg.sender, _redeem.VEALSDAmount, _redeem.alsdAmount);
        if (_redeem.dividendsAllocation > 0) {
            IVEALSD(_redeem.dividendsAddress).deallocate(
                msg.sender,
                _redeem.dividendsAllocation,
                new bytes(0)
            );
        }

        _deleteRedeemEntry(redeemIndex);
    }

    function convert(uint256 amount) external nonReentrant returns (bool) {
        _convert(amount, msg.sender);
        return true;
    }

    function redeem(
        uint256 VEALSDAmount,
        uint256 duration
    ) external nonReentrant {
        require(VEALSDAmount > 0, "VEALSDAmount cannot be null");
        require(duration >= minRedeemDuration, "Duration too low");

        _transfer(msg.sender, address(this), VEALSDAmount);
        VEALSDBalance storage balance = VEALSDBalances[msg.sender];

        uint256 alsdAmount = getAlsdByVestingDuration(VEALSDAmount, duration);

        if (duration > 0) {
            balance.redeemingAmount = balance.redeemingAmount.add(VEALSDAmount);

            uint256 dividendsAllocation = VEALSDAmount
                .mul(redeemDividendsAdjustment)
                .div(100);
            if (dividendsAllocation > 0) {
                dividendsAddress.allocate(
                    msg.sender,
                    dividendsAllocation,
                    new bytes(0)
                );
            }

            userRedeems[msg.sender].push(
                RedeemInfo(
                    alsdAmount,
                    VEALSDAmount,
                    block.timestamp.add(duration),
                    dividendsAddress,
                    dividendsAllocation
                )
            );
        } else {
            _finalizeRedeem(msg.sender, VEALSDAmount, alsdAmount);
        }
    }

    function updateRedeemDividendsAddress(
        uint256 redeemIndex
    ) external nonReentrant validateRedeem(msg.sender, redeemIndex) {
        RedeemInfo storage _redeem = userRedeems[msg.sender][redeemIndex];

        if (
            dividendsAddress != _redeem.dividendsAddress &&
            address(dividendsAddress) != address(0)
        ) {
            if (_redeem.dividendsAllocation > 0) {
                _redeem.dividendsAddress.deallocate(
                    msg.sender,
                    _redeem.dividendsAllocation,
                    new bytes(0)
                );
                dividendsAddress.allocate(
                    msg.sender,
                    _redeem.dividendsAllocation,
                    new bytes(0)
                );
            }

            _redeem.dividendsAddress = dividendsAddress;
        }
    }

    function cancelRedeem(
        uint256 redeemIndex
    ) external nonReentrant validateRedeem(msg.sender, redeemIndex) {
        VEALSDBalance storage balance = VEALSDBalances[msg.sender];
        RedeemInfo storage _redeem = userRedeems[msg.sender][redeemIndex];

        balance.redeemingAmount = balance.redeemingAmount.sub(
            _redeem.VEALSDAmount
        );
        _transfer(address(this), msg.sender, _redeem.VEALSDAmount);

        if (_redeem.dividendsAllocation > 0) {
            IVEALSD(_redeem.dividendsAddress).deallocate(
                msg.sender,
                _redeem.dividendsAllocation,
                new bytes(0)
            );
        }
        _deleteRedeemEntry(redeemIndex);
    }

    function allocateFromUsage(
        address userAddress,
        uint256 amount
    ) external override nonReentrant {
        _allocate(userAddress, msg.sender, amount);
    }

    function allocate(
        address usageAddress,
        uint256 amount,
        bytes calldata usageData
    ) external nonReentrant {
        _allocate(msg.sender, usageAddress, amount);

        IVEALSD(usageAddress).allocate(msg.sender, amount, usageData);
    }

    function deallocate(
        address usageAddress,
        uint256 amount,
        bytes calldata usageData
    ) external nonReentrant {
        _deallocate(msg.sender, usageAddress, amount);

        IVEALSD(usageAddress).deallocate(msg.sender, amount, usageData);
    }

    function deallocateFromUsage(
        address userAddress,
        uint256 amount
    ) external override nonReentrant {
        _deallocate(userAddress, msg.sender, amount);
    }

    function _convert(uint256 amount, address to) internal {
        require(amount != 0, "Amount cannot be null");

        _mint(to, amount);

        alsdToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function _finalizeRedeem(
        address userAddress,
        uint256 VEALSDAmount,
        uint256 ALSDAmount
    ) internal {
        uint256 alsdExcess = VEALSDAmount.sub(ALSDAmount);

        alsdToken.safeTransfer(userAddress, ALSDAmount);

        alsdToken.burn(alsdExcess);
        _burn(address(this), VEALSDAmount);
    }

    function _allocate(
        address userAddress,
        address usageAddress,
        uint256 amount
    ) internal {
        require(amount > 0, "Amount cannot be null");

        VEALSDBalance storage balance = VEALSDBalances[userAddress];

        uint256 approvedVEALSD = usageApprovals[userAddress][usageAddress];
        require(approvedVEALSD >= amount, "Non authorized amount");
        usageApprovals[userAddress][usageAddress] = approvedVEALSD.sub(amount);

        usageAllocations[userAddress][usageAddress] = usageAllocations[
            userAddress
        ][usageAddress].add(amount);

        balance.allocatedAmount = balance.allocatedAmount.add(amount);
        _transfer(userAddress, address(this), amount);
    }

    function _deleteRedeemEntry(uint256 index) internal {
        userRedeems[msg.sender][index] = userRedeems[msg.sender][
            userRedeems[msg.sender].length - 1
        ];
        userRedeems[msg.sender].pop();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /*amount*/
    ) internal view override {
        require(
            from == address(0) ||
                _transferWhitelist.contains(from) ||
                _transferWhitelist.contains(to),
            "Transfer not allowed"
        );
    }

    function _deallocate(
        address userAddress,
        address usageAddress,
        uint256 amount
    ) internal {
        require(amount > 0, "Amount cannot be null");

        uint256 allocatedAmount = usageAllocations[userAddress][usageAddress];
        require(allocatedAmount >= amount, "deallocate: non authorized amount");

        usageAllocations[userAddress][usageAddress] = allocatedAmount.sub(
            amount
        );

        uint256 deallocationFeeAmount = amount
            .mul(usagesDeallocationFee[usageAddress])
            .div(10000);

        VEALSDBalance storage balance = VEALSDBalances[userAddress];
        balance.allocatedAmount = balance.allocatedAmount.sub(amount);
        _transfer(
            address(this),
            userAddress,
            amount.sub(deallocationFeeAmount)
        );
        alsdToken.burn(deallocationFeeAmount);
        _burn(address(this), deallocationFeeAmount);
    }

    function getUserRedeems(
        address userAddress
    ) external view returns (RedeemInfo[] memory) {
        return userRedeems[userAddress];
    }
}
