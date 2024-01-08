pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./math.sol";

interface CTokenInterface {
    function exchangeRateCurrent() external returns (uint256);
    function borrowBalanceCurrent(address account) external returns (uint256);
    function balanceOfUnderlying(address account) external returns (uint256);
    function underlying() external view returns (address);
    function balanceOf(address) external view returns (uint256);
}

interface OracleCompInterface {
    function getUnderlyingPrice(address) external view returns (uint256);
}

interface ComptrollerLensInterface {
    function markets(address)
        external
        view
        returns (
            bool,
            uint256,
            bool
        );

    function oracle() external view returns (address);
}

contract Variables {
    ComptrollerLensInterface public constant comptroller =
        ComptrollerLensInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    address public constant cethAddr =
        0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
}

contract Resolver is Variables, DSMath {
    function getPosition(
        uint256 networthAmount,
        uint256 rewardAmount,
        address[] memory supplyCtokens,
        address[] memory borrowCtokens,
        uint256[] memory supplyCAmounts,
        uint256[] memory borrowAmounts
    )
    public
    returns (
        uint256 claimableRewardAmount,
        uint256 claimableNetworth
    )
    {
        OracleCompInterface oracle = OracleCompInterface(comptroller.oracle());
        uint256 totalBorrowInUsd = 0;
        uint256 totalSupplyInUsd = 0;

        for (uint256 i = 0; i < supplyCtokens.length; i++) {
            require(supplyCAmounts[i] > 0, "InstaCompoundMerkleDistributor:: getPosition: supply camount not valid");
            CTokenInterface cToken = CTokenInterface(address(supplyCtokens[i]));
            uint256 priceInUSD = oracle.getUnderlyingPrice(address(cToken));
            require(priceInUSD > 0, "InstaCompoundMerkleDistributor:: getPosition: priceInUSD not valid");
            uint256 supplyAmount = wmul(supplyCAmounts[i], cToken.exchangeRateCurrent());
            uint256 supplyInUsd = wmul(supplyAmount, priceInUSD);
            totalSupplyInUsd = add(totalSupplyInUsd, supplyInUsd);
        }

        for (uint256 i = 0; i < borrowCtokens.length; i++) {
            require(borrowAmounts[i] > 0, "InstaCompoundMerkleDistributor:: getPosition: borrow amount not valid");
            CTokenInterface cToken = CTokenInterface(address(borrowCtokens[i]));
            uint256 priceInUSD = oracle.getUnderlyingPrice(address(cToken));
            require(priceInUSD > 0, "InstaCompoundMerkleDistributor:: getPosition: priceInUSD not valid");
            uint256 borrowInUsd = wmul(borrowAmounts[i], priceInUSD);
            totalBorrowInUsd = add(totalBorrowInUsd, borrowInUsd);
        }

        claimableNetworth = sub(totalSupplyInUsd, totalBorrowInUsd);
        if (networthAmount > claimableNetworth) {
            claimableRewardAmount = wdiv(claimableNetworth, networthAmount);
            claimableRewardAmount = wmul(rewardAmount, claimableRewardAmount);
        } else {
            claimableRewardAmount = rewardAmount;
        }
    }
}
contract InstaCompoundMerkleResolver is Resolver {
    string public constant name = "Compound-Merkle-Resolver-v1.0";
}
