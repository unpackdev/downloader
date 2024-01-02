// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./console.sol";

import "./IMOPNERC6551Account.sol";
import "./IERC6551Registry.sol";
import "./IMOPN.sol";
import "./IMOPNData.sol";
import "./IMOPNGovernance.sol";
import "./IMOPNToken.sol";
import "./IMOPNBomb.sol";
import "./Multicall.sol";

/*
.___  ___.   ______   .______   .__   __. 
|   \/   |  /  __  \  |   _  \  |  \ |  | 
|  \  /  | |  |  |  | |  |_)  | |   \|  | 
|  |\/|  | |  |  |  | |   ___/  |  . `  | 
|  |  |  | |  `--'  | |  |      |  |\   | 
|__|  |__|  \______/  | _|      |__| \__| 
*/
contract MOPNData is IMOPNData, Multicall {
    IMOPNGovernance public governance;

    constructor(address governance_) {
        governance = IMOPNGovernance(governance_);
    }

    function calcPerMOPNPointMinted() public view returns (uint256) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        if (mopn.MTStepStartBlock() > block.number) {
            return 0;
        }
        uint256 totalMOPNPoints = mopn.TotalMOPNPoints();
        uint256 perMOPNPointMinted = mopn.PerMOPNPointMinted();
        if (totalMOPNPoints > 0) {
            uint256 lastTickBlock = mopn.LastTickBlock();
            uint256 reduceTimes = mopn.MTReduceTimes();
            if (reduceTimes == 0) {
                perMOPNPointMinted +=
                    ((block.number - lastTickBlock) * mopn.MTOutputPerBlock()) /
                    totalMOPNPoints;
            } else {
                uint256 nextReduceBlock = mopn.MTStepStartBlock() +
                    mopn.MTReduceInterval();
                for (uint256 i = 0; i <= reduceTimes; i++) {
                    perMOPNPointMinted +=
                        ((nextReduceBlock - lastTickBlock) *
                            mopn.currentMTPPB(i)) /
                        totalMOPNPoints;
                    lastTickBlock = nextReduceBlock;
                    nextReduceBlock += mopn.MTReduceInterval();
                    if (nextReduceBlock > block.number) {
                        nextReduceBlock = block.number;
                    }
                }
            }
        }
        return perMOPNPointMinted;
    }

    /**
     * @notice get collection realtime unclaimed minted mopn token
     * @param collectionAddress collection contract address
     */
    function calcCollectionSettledMT(
        address collectionAddress
    ) public view returns (uint256 inbox) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        IMOPN.CollectionDataStruct memory collectionData = mopn
            .getCollectionData(collectionAddress);
        inbox = collectionData.SettledMT;
        uint256 perMOPNPointMinted = calcPerMOPNPointMinted();
        uint256 CollectionPerMOPNPointMinted = collectionData
            .PerMOPNPointMinted;
        uint256 CollectionMOPNPoints = collectionData.CollectionMOPNPoint *
            collectionData.OnMapNftNumber;
        uint256 OnMapMOPNPoints = collectionData.OnMapMOPNPoints;

        if (
            CollectionPerMOPNPointMinted < perMOPNPointMinted &&
            OnMapMOPNPoints > 0
        ) {
            inbox +=
                (((perMOPNPointMinted - CollectionPerMOPNPointMinted) *
                    (CollectionMOPNPoints + OnMapMOPNPoints)) * 5) /
                100;
        }
    }

    function calcPerCollectionNFTMintedMT(
        address collectionAddress
    ) public view returns (uint256 result) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        IMOPN.CollectionDataStruct memory collectionData = mopn
            .getCollectionData(collectionAddress);
        result = collectionData.PerCollectionNFTMinted;

        uint256 CollectionMOPNPoints = collectionData.CollectionMOPNPoint *
            collectionData.OnMapNftNumber;

        if (CollectionMOPNPoints > 0) {
            uint256 CollectionPerMOPNPointMinted = collectionData
                .PerMOPNPointMinted;
            uint256 PerMOPNPointMinted = calcPerMOPNPointMinted();

            result +=
                ((PerMOPNPointMinted - CollectionPerMOPNPointMinted) *
                    CollectionMOPNPoints) /
                collectionData.OnMapNftNumber;
        }
    }

    /**
     * @notice get avatar realtime unclaimed minted mopn token
     * @param account account wallet address
     */
    function calcAccountMT(
        address account
    ) public view returns (uint256 inbox) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        IMOPN.AccountDataStruct memory accountData = mopn.getAccountData(
            account
        );
        inbox = accountData.SettledMT;
        uint256 AccountOnMapMOPNPoint = mopn.getAccountOnMapMOPNPoint(account);
        uint256 AccountPerMOPNPointMintedDiff = calcPerMOPNPointMinted() -
            accountData.PerMOPNPointMinted;

        if (AccountPerMOPNPointMintedDiff > 0 && AccountOnMapMOPNPoint > 0) {
            inbox +=
                ((AccountPerMOPNPointMintedDiff * AccountOnMapMOPNPoint) * 90) /
                100;
            uint256 AccountPerCollectionNFTMintedDiff = calcPerCollectionNFTMintedMT(
                    getAccountCollection(account)
                ) - accountData.PerCollectionNFTMinted;

            if (AccountPerCollectionNFTMintedDiff > 0) {
                inbox += (AccountPerCollectionNFTMintedDiff * 90) / 100;
            }
        }
    }

    function calcLandsMT(
        uint32[] memory LandIds,
        address[][] memory tileAccounts
    ) public view returns (uint256[] memory amounts) {
        amounts = new uint256[](LandIds.length);
        for (uint256 i = 0; i < LandIds.length; i++) {
            amounts[i] = calcLandMT(LandIds[i], tileAccounts[i]);
        }
    }

    function calcLandMT(
        uint32 LandId,
        address[] memory tileAccounts
    ) public view returns (uint256 amount) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        uint24 tileCoordinate = mopn.tileAtLandCenter(LandId);
        for (uint256 i; i < tileAccounts.length; i++) {
            IMOPN.AccountDataStruct memory accountData = mopn.getAccountData(
                tileAccounts[i]
            );
            if (mopn.tiledistance(tileCoordinate, accountData.Coordinate) < 6) {
                amount += calcLandAccountMT(tileAccounts[i]);
            }
        }
    }

    function calcLandAccountMT(
        address account
    ) public view returns (uint256 amount) {
        if (account != address(0)) {
            IMOPN mopn = IMOPN(governance.mopnContract());
            IMOPN.AccountDataStruct memory accountData = mopn.getAccountData(
                account
            );
            uint256 AccountPerMOPNPointMintedDiff = calcPerMOPNPointMinted() -
                accountData.PerMOPNPointMinted;

            if (AccountPerMOPNPointMintedDiff > 0) {
                address collectionAddress = getAccountCollection(account);
                uint256 AccountPerCollectionNFTMintedDiff = calcPerCollectionNFTMintedMT(
                        collectionAddress
                    ) - accountData.PerCollectionNFTMinted;
                uint256 AccountOnMapMOPNPoint = mopn.getAccountOnMapMOPNPoint(
                    account
                );
                amount +=
                    ((AccountPerMOPNPointMintedDiff * AccountOnMapMOPNPoint) *
                        5) /
                    100;
                if (AccountPerCollectionNFTMintedDiff > 0) {
                    amount += (AccountPerCollectionNFTMintedDiff * 5) / 100;
                }
            }
        }
    }

    function getAccountCollection(
        address account
    ) public view returns (address collectionAddress) {
        (, collectionAddress, ) = IMOPNERC6551Account(payable(account)).token();
    }

    function getAccountData(
        address account
    ) public view returns (AccountDataOutput memory accountData) {
        accountData.account = account;
        (, address collectionAddress, uint256 tokenId) = IMOPNERC6551Account(
            payable(account)
        ).token();

        accountData.tokenId = tokenId;
        accountData.contractAddress = collectionAddress;

        IMOPN mopn = IMOPN(governance.mopnContract());
        IMOPN.AccountDataStruct memory mopnAccountData = mopn.getAccountData(
            account
        );
        IMOPN.CollectionDataStruct memory collectionData = mopn
            .getCollectionData(collectionAddress);

        accountData.AgentPlacer = mopnAccountData.AgentPlacer;
        accountData.AgentAssignPercentage = mopnAccountData
            .AgentAssignPercentage;
        accountData.owner = IMOPNERC6551Account(payable(account)).owner();
        accountData.CollectionMOPNPoint = collectionData.CollectionMOPNPoint;
        accountData.MTBalance = IMOPNToken(governance.tokenContract())
            .balanceOf(account);
        accountData.OnMapMOPNPoint = IMOPN(governance.mopnContract())
            .getAccountOnMapMOPNPoint(account);
        accountData.TotalMOPNPoint = IERC20(governance.pointContract())
            .balanceOf(account);
        accountData.tileCoordinate = mopnAccountData.Coordinate;
    }

    function getAccountsData(
        address[] memory accounts
    ) public view returns (AccountDataOutput[] memory accountDatas) {
        accountDatas = new AccountDataOutput[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            accountDatas[i] = getAccountData(accounts[i]);
        }
    }

    function getAccountByNFT(
        NFTParams calldata params
    ) public view returns (address) {
        return
            IERC6551Registry(governance.ERC6551Registry()).account(
                governance.ERC6551AccountProxy(),
                block.chainid,
                params.collectionAddress,
                params.tokenId,
                0
            );
    }

    /**
     * @notice get avatar info by nft contractAddress and tokenId
     * @param params  collection contract address and tokenId
     * @return accountData avatar data format struct AvatarDataOutput
     */
    function getAccountDataByNFT(
        NFTParams calldata params
    ) public view returns (AccountDataOutput memory accountData) {
        accountData = getAccountData(getAccountByNFT(params));
    }

    /**
     * @notice get avatar infos by nft contractAddresses and tokenIds
     * @param params array of collection contract address and token ids
     * @return accountDatas avatar datas format struct AvatarDataOutput
     */
    function getAccountsDataByNFTs(
        NFTParams[] calldata params
    ) public view returns (AccountDataOutput[] memory accountDatas) {
        accountDatas = new AccountDataOutput[](params.length);
        for (uint256 i = 0; i < params.length; i++) {
            accountDatas[i] = getAccountData(getAccountByNFT(params[i]));
        }
    }

    function getBatchAccountMTBalance(
        address[] memory accounts
    ) public view returns (uint256[] memory MTBalances) {
        MTBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            MTBalances[i] = IMOPNToken(governance.tokenContract()).balanceOf(
                accounts[i]
            );
        }
    }

    function getWalletStakingMTs(
        address[] memory collections,
        address wallet
    ) public view returns (uint256 amount) {
        for (uint256 i = 0; i < collections.length; i++) {
            address collectionVault = governance.getCollectionVault(
                collections[i]
            );
            amount += IMOPNCollectionVault(collectionVault).V2MTAmountRealtime(
                IMOPNCollectionVault(collectionVault).balanceOf(wallet)
            );
        }
    }

    /**
     * get collection contract, on map num, avatar num etc from IGovernance.
     */
    function getCollectionData(
        address collectionAddress
    ) public view returns (CollectionDataOutput memory cData) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        cData.contractAddress = collectionAddress;
        cData.collectionVault = governance.getCollectionVault(
            collectionAddress
        );

        IMOPN.CollectionDataStruct memory collectionData = mopn
            .getCollectionData(collectionAddress);

        cData.OnMapNum = collectionData.OnMapNftNumber;
        cData.OnMapAgentPlaceNftNumber = collectionData
            .OnMapAgentPlaceNftNumber;
        cData.MTBalance = IMOPNToken(governance.tokenContract()).balanceOf(
            cData.collectionVault
        );
        cData.UnclaimMTBalance = calcCollectionSettledMT(collectionAddress);

        cData.OnMapMOPNPoints = collectionData.OnMapMOPNPoints;

        if (cData.collectionVault != address(0)) {
            cData.AskStruct = IMOPNCollectionVault(cData.collectionVault)
                .getAskInfo();
            cData.BidStruct = IMOPNCollectionVault(cData.collectionVault)
                .getBidInfo();
            cData.PMTTotalSupply = IMOPNCollectionVault(cData.collectionVault)
                .totalSupply();
            cData.CollectionMOPNPoint = IMOPNCollectionVault(
                cData.collectionVault
            ).getCollectionMOPNPoint();
            cData.CollectionMOPNPoints =
                cData.CollectionMOPNPoint *
                cData.OnMapNum;
        } else {
            cData.BidStruct.currentPrice = cData.UnclaimMTBalance / 5;
        }
    }

    function getCollectionsData(
        address[] memory collectionAddresses
    ) public view returns (CollectionDataOutput[] memory cDatas) {
        cDatas = new CollectionDataOutput[](collectionAddresses.length);
        for (uint256 i = 0; i < collectionAddresses.length; i++) {
            cDatas[i] = getCollectionData(collectionAddresses[i]);
        }
    }

    function getTotalCollectionVaultMinted() public view returns (uint256) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        return ((mopn.MTTotalMinted() +
            (calcPerMOPNPointMinted() - mopn.PerMOPNPointMinted()) *
            mopn.TotalMOPNPoints()) / 20);
    }
}
