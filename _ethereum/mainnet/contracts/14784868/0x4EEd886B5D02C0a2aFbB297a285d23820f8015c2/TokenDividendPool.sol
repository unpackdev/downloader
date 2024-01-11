// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "./IIERC20Snapshot.sol";
// import "./Math.sol";
// import "./SafeMath.sol";
// import "./SafeCast.sol";

import "./ITokenDividendPool.sol";
import "./LibTokenDividendPool.sol";

import "./AccessibleCommon.sol";
import "./TokenDividendPoolStorage.sol";

//import "./console.sol";

contract TokenDividendPool is
    TokenDividendPoolStorage,
    AccessibleCommon,
    ITokenDividendPool
{
    event Claim(address indexed token, uint256 amount, uint256 snapshotId);
    event Distribute(address indexed token, uint256 amount, uint256 snapshotId);

    /// @dev Check if a function is used or not
    modifier ifFree {
        require(free == 1, "LockId is already in use");
        free = 0;
        _;
        free = 1;
    }

    /// @inheritdoc ITokenDividendPool
    function claimBatch(address[] calldata _tokens) external override {
        for (uint i = 0; i < _tokens.length; ++i) {
            claim(_tokens[i]);
        }
    }

    /// @inheritdoc ITokenDividendPool
    function claim(address _token) public override {
        _claimUpTo(
            _token,
            msg.sender,
            distributions[_token].snapshots.length
        );
    }

    /// @inheritdoc ITokenDividendPool
    function claimUpTo(address _token, uint256 _endSnapshotId) public override {
        require(claimableUpTo(_token, msg.sender, _endSnapshotId) > 0, "Amount to be claimed is zero");

        (bool found, uint256 snapshotIndex) = _getSnapshotIndexForId(_token, _endSnapshotId);
        require(found, "No such snapshot ID is found");
        uint256 endSnapshotIndex = snapshotIndex + 1;
        _claimUpTo(_token, msg.sender, endSnapshotIndex);
    }

    /// @inheritdoc ITokenDividendPool
    function distribute(address _token, uint256 _amount)
        external
        override
        ifFree
    {
        require(
            IIERC20Snapshot(erc20DividendAddress).totalSupply() > 0,
            "Total Supply is zero"
        );

        LibTokenDividendPool.Distribution storage distr = distributions[_token];
        IIERC20Snapshot(_token).transferFrom(msg.sender, address(this), _amount);
        if (distr.exists == false) {
            distributedTokens.push(_token);
        }

        uint256 newBalance = IIERC20Snapshot(_token).balanceOf(address(this));
        uint256 increment = newBalance - distr.lastBalance;
        distr.exists = true;
        distr.lastBalance = newBalance;
        distr.totalDistribution = distr.totalDistribution + increment;

        uint256 snapshotId = IIERC20Snapshot(erc20DividendAddress).snapshot();
        distr.snapshots.push(
            LibTokenDividendPool.SnapshotInfo(snapshotId, increment, block.timestamp)
        );
        emit Distribute(_token, _amount, snapshotId);
    }

    /// @inheritdoc ITokenDividendPool
    function getAvailableClaims(address _account) public view override returns (address[] memory claimableTokens, uint256[] memory claimableAmounts) {
        uint256[] memory amounts = new uint256[](distributedTokens.length);
        uint256 claimableCount = 0;
        for (uint256 i = 0; i < distributedTokens.length; ++i) {
            amounts[i] = claimable(distributedTokens[i], _account);
            if (amounts[i] > 0) {
                claimableCount += 1;
            }
        }

        claimableAmounts = new uint256[](claimableCount);
        claimableTokens = new address[](claimableCount);
        uint256 j = 0;
        for (uint256 i = 0; i < distributedTokens.length; ++i) {
            if (amounts[i] > 0) {
                claimableAmounts[j] = amounts[i];
                claimableTokens[j] = distributedTokens[i];
                j++;
            }
        }
    }

    /// @inheritdoc ITokenDividendPool
    function claimable(address _token, address _account) public view override returns (uint256) {
        LibTokenDividendPool.Distribution storage distr = distributions[_token];
        uint256 startSnapshotIndex = distr.nonClaimedSnapshotIndex[_account];
        uint256 endSnapshotIndex = distr.snapshots.length;
        return _calculateClaim(
            _token,
            _account,
            startSnapshotIndex,
            endSnapshotIndex
        );
    }

    /// @inheritdoc ITokenDividendPool
    function claimableUpTo(
        address _token,
        address _account,
        uint256 _endSnapshotId
    ) public view override returns (uint256) {
        (bool found, uint256 snapshotIndex) = _getSnapshotIndexForId(_token, _endSnapshotId);
        require(found, "No such snapshot ID is found");
        uint256 endSnapshotIndex = snapshotIndex + 1;

        LibTokenDividendPool.Distribution storage distr = distributions[_token];
        uint256 startSnapshotIndex = distr.nonClaimedSnapshotIndex[_account];
        return _calculateClaim(
            _token,
            _account,
            startSnapshotIndex,
            endSnapshotIndex
        );
    }


    /// @inheritdoc ITokenDividendPool
    function totalDistribution(address _token) public view override returns (uint256) {
        LibTokenDividendPool.Distribution storage distr = distributions[_token];
        return distr.totalDistribution;
    }

    /// @dev Get the snapshot index for given `_snapshotId`
    function _getSnapshotIndexForId(address _token, uint256 _snapshotId) view internal returns (bool found, uint256 index) {
        LibTokenDividendPool.SnapshotInfo[] storage snapshots = distributions[_token].snapshots;
        if (snapshots.length == 0) {
            return (false, 0);
        }

        index = snapshots.length - 1;
        while (true) {
            if (snapshots[index].id == _snapshotId) {
                return (true, index);
            }

            if (index == 0) break;
            index --;
        }
        return (false, 0);
    }

    /// @dev Claim rewards
    function _claimUpTo(address _token, address _account, uint256 _endSnapshotIndex) internal ifFree {
        LibTokenDividendPool.Distribution storage distr = distributions[_token];
        uint256 startSnapshotIndex = distr.nonClaimedSnapshotIndex[_account];
        uint256 amountToClaim = _calculateClaim(
            _token,
            _account,
            startSnapshotIndex,
            _endSnapshotIndex
        );

        require(amountToClaim > 0, "Amount to be claimed is zero");
        IIERC20Snapshot(_token).transfer(msg.sender, amountToClaim);

        distr.nonClaimedSnapshotIndex[_account] = _endSnapshotIndex;
        distr.lastBalance -= amountToClaim;
        emit Claim(_token, amountToClaim, _endSnapshotIndex);
    }

    /// @dev Amount claimable
    function _calculateClaim(
        address _token,
        address _account,
        uint256 _startSnapshotIndex,
        uint256 _endSnapshotIndex
    ) internal view returns (uint256) {
        LibTokenDividendPool.Distribution storage distr = distributions[_token];

        uint256 accumulated = 0;
        for (
            uint256 snapshotIndex = _startSnapshotIndex;
            snapshotIndex < _endSnapshotIndex;
            snapshotIndex = snapshotIndex + 1
        ) {
            uint256 snapshotId = distr.snapshots[snapshotIndex].id;
            uint256 totalDividendAmount = distr.snapshots[snapshotIndex].totalDividendAmount;
            accumulated +=  _calculateClaimPerSnapshot(
                                _account,
                                snapshotId,
                                totalDividendAmount
                            );
        }
        return accumulated;
    }

    /// @dev Calculates claim portion
    function _calculateClaimPerSnapshot(
        address _account,
        uint256 _snapshotId,
        uint256 _totalDividendAmount
    ) internal view returns (uint256) {
        uint256 balance = IIERC20Snapshot(erc20DividendAddress).balanceOfAt(_account, _snapshotId);
        if (balance == 0) {
            return 0;
        }

        uint256 supply = IIERC20Snapshot(erc20DividendAddress).totalSupplyAt(_snapshotId);
        if (supply == 0) {
            return 0;
        }
        //console.log("Balance: %d, Total: %d, Dividend Amount: %d", balance, supply, _totalDividendAmount);
        return _totalDividendAmount * balance / supply;
    }
}