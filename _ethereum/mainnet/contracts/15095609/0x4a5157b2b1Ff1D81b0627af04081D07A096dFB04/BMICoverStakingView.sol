// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Math.sol";

import "./IBMICoverStaking.sol";
import "./ILiquidityMining.sol";
import "./IBMICoverStakingView.sol";
import "./IContractsRegistry.sol";
import "./IRewardsGenerator.sol";
import "./IPolicyBook.sol";

import "./AbstractDependant.sol";

import "./Globals.sol";

contract BMICoverStakingView is IBMICoverStakingView, AbstractDependant {
    using SafeMath for uint256;
    using Math for uint256;

    IBMICoverStaking public bmiCoverStaking;
    IRewardsGenerator public rewardsGenerator;
    ILiquidityMining public liquidityMining;

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        rewardsGenerator = IRewardsGenerator(_contractsRegistry.getRewardsGeneratorContract());
        bmiCoverStaking = IBMICoverStaking(_contractsRegistry.getBMICoverStakingContract());
    }

    /// @notice Retunrs the APY of a policybook address
    /// @dev returns 0 for non whitelisted policybooks
    /// @param policyBookAddress address of the policybook
    /// @return uint256 apy amount
    function getPolicyBookAPY(address policyBookAddress, uint256 bmiPriceInUSDT)
        public
        view
        override
        returns (uint256)
    {
        require(bmiPriceInUSDT > 0, "Invalid BMI price");
        return
            IPolicyBook(policyBookAddress).whitelisted()
                ? rewardsGenerator.getPolicyBookAPY(policyBookAddress, bmiPriceInUSDT)
                : 0;
    }

    /// @notice gets the policy addres given an nft token id
    /// @param tokenId uint256 numeric id of the nft token
    /// @return policyBookAddress
    function policyBookByNFT(uint256 tokenId) external view override returns (address) {
        (address policyBookAddress, ) = bmiCoverStaking._stakersPool(tokenId);
        return policyBookAddress;
    }

    /// @notice exhaustive information about staker's stakes
    /// @param staker is a user to return information for
    /// @param policyBooksAddresses is an array of PolicyBooks to check the stakes in
    /// @param offset is a starting ordinal number of user's NFT
    /// @param limit is a number of NFTs to check per function's call
    /// @return policyBooksInfo - an array of infos (totalStakedSTBL, rewardPerBlock (in BMI), stakingAPY, liquidityAPY)
    /// @return usersInfo - an array of user's info per PolicyBook (totalStakedBMIX, totalStakedSTBL, totalBmiReward)
    /// @return nftsCount - number of NFTs for each respective PolicyBook
    /// @return nftsInfo - 2 dimensional array of NFTs info per each PolicyBook
    ///     (nftIndex, uri, stakedBMIXAmount, stakedSTBLAmount, reward (in BMI))
    function stakingInfoByStaker(
        address staker,
        address[] calldata policyBooksAddresses,
        uint256 bmiPriceInUSDT,
        uint256 offset,
        uint256 limit
    )
        external
        view
        override
        returns (
            IBMICoverStaking.PolicyBookInfo[] memory policyBooksInfo,
            IBMICoverStaking.UserInfo[] memory usersInfo,
            uint256[] memory nftsCount,
            IBMICoverStaking.NFTsInfo[][] memory nftsInfo
        )
    {
        uint256 to = (offset.add(limit)).min(bmiCoverStaking.balanceOf(staker)).max(offset);

        policyBooksInfo = new IBMICoverStaking.PolicyBookInfo[](policyBooksAddresses.length);
        usersInfo = new IBMICoverStaking.UserInfo[](policyBooksAddresses.length);
        nftsCount = new uint256[](policyBooksAddresses.length);
        nftsInfo = new IBMICoverStaking.NFTsInfo[][](policyBooksAddresses.length);

        for (uint256 i = 0; i < policyBooksAddresses.length; i++) {
            nftsInfo[i] = new IBMICoverStaking.NFTsInfo[](to - offset);

            policyBooksInfo[i] = IBMICoverStaking.PolicyBookInfo(
                rewardsGenerator.getStakedPolicyBookSTBL(policyBooksAddresses[i]),
                rewardsGenerator.getPolicyBookRewardPerBlock(policyBooksAddresses[i]),
                getPolicyBookAPY(policyBooksAddresses[i], bmiPriceInUSDT),
                IPolicyBook(policyBooksAddresses[i]).getAPY()
            );

            for (uint256 j = offset; j < to; j++) {
                uint256 nftIndex = bmiCoverStaking.tokenOfOwnerByIndex(staker, j);
                (address policyBookAddress, uint256 stakedBMIXAmount) =
                    bmiCoverStaking._stakersPool(nftIndex);

                if (policyBookAddress == policyBooksAddresses[i]) {
                    nftsInfo[i][nftsCount[i]] = IBMICoverStaking.NFTsInfo(
                        nftIndex,
                        bmiCoverStaking.uri(nftIndex),
                        stakedBMIXAmount,
                        rewardsGenerator.getStakedNFTSTBL(nftIndex),
                        bmiCoverStaking.getBMIProfit(nftIndex)
                    );

                    usersInfo[i].totalStakedBMIX = usersInfo[i].totalStakedBMIX.add(
                        nftsInfo[i][nftsCount[i]].stakedBMIXAmount
                    );
                    usersInfo[i].totalStakedSTBL = usersInfo[i].totalStakedSTBL.add(
                        nftsInfo[i][nftsCount[i]].stakedSTBLAmount
                    );
                    usersInfo[i].totalBmiReward = usersInfo[i].totalBmiReward.add(
                        nftsInfo[i][nftsCount[i]].reward
                    );

                    nftsCount[i]++;
                }
            }
        }
    }

    /// @notice Returns a StakingInfo (policyBookAdress and stakedBMIXAmount) for a given nft index
    /// @param tokenId numeric id of the nft index
    /// @return _stakingInfo IBMICoverStaking.StakingInfo
    function stakingInfoByToken(uint256 tokenId)
        external
        view
        override
        returns (IBMICoverStaking.StakingInfo memory _stakingInfo)
    {
        (_stakingInfo.policyBookAddress, _stakingInfo.stakedBMIXAmount) = bmiCoverStaking
            ._stakersPool(tokenId);
        require(_stakingInfo.policyBookAddress != address(0), "BDS: Token doesn't exist");
    }
}
