// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./OmniToken.sol";
import "./OmniTokenNoBorrow.sol";
import "./SubAccount.sol";
import "./IIRM.sol";

struct MarketTrancheOverview {
    uint8 trancheIndex;
    uint256 totalDeposit;
    uint256 totalBorrow;
    uint256 totalDepositShare;
    uint256 totalBorrowShare;
    uint256 cumulativeTotalDeposit;
    uint256 cumulativeTotalBorrow;
    uint256 interestRate;
}

struct MarketTrancheUser {
    uint8 trancheIndex;
    uint256 userDeposit;
    uint256 userBorrow;
    uint256 userDepositShare;
    uint256 userBorrowShare;
}

contract OmniLens {
    using SubAccount for address;
    using SubAccount for bytes32;

    function getOmniMarketOverview(OmniToken _market) external returns (MarketTrancheOverview[] memory res) {
        _market.accrue();
        IIRM irm = IIRM(_market.irm());
        res = new MarketTrancheOverview[](_market.trancheCount());
        uint256 cumulativeTotalDeposit;
        uint256 cumulativeTotalBorrow;
        for (uint8 i = _market.trancheCount(); i > 0; --i) {
            uint8 innerI = i - 1;
            (uint256 totalDeposit, uint256 totalBorrow, uint256 totalDepositShare, uint256 totalBorrowShare) = _market.tranches(innerI);
            cumulativeTotalDeposit += totalDeposit;
            cumulativeTotalBorrow += totalBorrow;
            res[innerI] = MarketTrancheOverview({
                trancheIndex: innerI,
                totalDeposit: totalDeposit,
                totalBorrow: totalBorrow,
                totalDepositShare: totalDepositShare,
                totalBorrowShare: totalBorrowShare,
                cumulativeTotalDeposit: cumulativeTotalDeposit,
                cumulativeTotalBorrow: cumulativeTotalBorrow,
                interestRate: irm.getInterestRate(address(_market), innerI, cumulativeTotalDeposit, cumulativeTotalBorrow)
            });
        }
    }

    function getOmniMarketNoBorrowOverview(OmniTokenNoBorrow _market)
        external
        view
        returns (MarketTrancheOverview memory res)
    {
        res.cumulativeTotalDeposit = _market.totalSupply();
        res.totalDeposit = _market.totalSupply();
    }

    function getOmniMarketUser(OmniToken _market, address _addr, uint96 _subId)
        external
        returns (MarketTrancheUser[] memory res)
    {
        _market.accrue();
        res = new MarketTrancheUser[](_market.trancheCount());
        for (uint8 i = 0; i < res.length; ++i) {
            (uint256 totalDepositAmount, uint256 totalBorrowAmount, uint256 totalDepositShare, uint256 totalBorrowShare)
            = _market.tranches(i);
            (uint256 userDepositShare, uint256 userBorrowShare) =
                _market.getAccountSharesByTranche(_addr.toAccount(_subId), i);
            uint256 userDepositAmount =
                userDepositShare == 0 ? 0 : (userDepositShare * totalDepositAmount) / totalDepositShare;
            uint256 userBorrowAmount =
                userBorrowShare == 0 ? 0 : (userBorrowShare * totalBorrowAmount) / totalBorrowShare;
            res[i] = MarketTrancheUser({
                trancheIndex: i,
                userDeposit: userDepositAmount,
                userBorrow: userBorrowAmount,
                userDepositShare: userDepositShare,
                userBorrowShare: userBorrowShare
            });
        }
    }

    function getOmniMarketNoBorrowUser(OmniTokenNoBorrow _market, address _addr, uint96 _subId)
        external
        view
        returns (MarketTrancheUser memory res)
    {
        res.userDeposit = _market.balanceOfAccount(_addr.toAccount(_subId));
    }

    function getAccountBytesFromId(address _owner, uint96 _subId) external pure returns (bytes32) {
        return _owner.toAccount(_subId);
    }

    function fromAccountToAddress(bytes32 _account) external pure returns (address) {
        return _account.toAddress();
    }

    function fromAccountToSubId(bytes32 _account) external pure returns (uint96) {
        return _account.toSubId();
    }
}
