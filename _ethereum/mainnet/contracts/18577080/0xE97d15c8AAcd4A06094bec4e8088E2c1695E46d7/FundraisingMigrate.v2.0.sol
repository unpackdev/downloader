// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

// Local imports - Structs
import "./BaseTypesV1.sol";
import "./StorageTypes.sol";
import "./EnumTypes.sol";

// Local imports - Storages
import "./LibRaiseV1.sol";
import "./LibAppStorage.sol";
import "./LibRaise.sol";
import "./LibInvestorFundsInfo.sol";
import "./LibERC20Asset.sol";
import "./LibBaseAsset.sol";
import "./LibBadge.sol";

/// @dev Migration initializer for v2.0 of fundraising.
contract FundraisingMigrate200 {
    error InvalidRaisedAmount();

    function init() external {
        // raise id
        string memory raiseId_ = "68494a4c-4f9c-485c-8b64-0edbfdfb2c7d";

        // investors
        address[49] memory investorsAddresses_ = [
            0x03BA893125C2b040a1A663E8dA03f1C6E6eb3C46,
            0x0802A99978C1F337a239f7330eB3B675594402C6,
            0x094e6C1dbF92647323856f836480b861133243E2,
            0x0b58521DC753E0601A153996443eCfD19263Ee92,
            0x0eA9239001E8EBe447d9dEC97b3433E5eFcEC5A8,
            0x131305Df1F5AbB242b553b35051a3e23354C35AA,
            0x1EEFb96E69842CEb1a6caD7d2569Ba7F2439A708,
            0x1F7e13EB0809B432F1DD68793560AB44Cf081C57,
            0x230bC8CB574144e2ABe8769506B7BE1E198B6031,
            0x284FE240F02965fAC933654Fe2dd5fc32855873F,
            0x2Ec8A6d3D9408d7725369897C5d3AAE0b4aDaf82,
            0x3941578e47Bcb7AC5f006488De8D0CA8461bB0b5,
            0x39E81f83D04C5D525D759ca0f1b0B063961cFB4b,
            0x3B2d6C922Ced5958a0bf0bC206F01482833e1302,
            0x48F2F50eC429cbA82AbDA785fbF8c6b81Ff2702F,
            0x4c8f9d39c3707bE9B3078d1dCeBAb9e725885367,
            0x4dAC7754cfcaCa449EBD55b6Da169CA8bF238179,
            0x5c8628263CF70433dc98BAa5a9c7E2BeD292303c,
            0x5d1c62ef8C7d70b6A8d8d98FE791360cdf380920,
            0x6541DB661B1F9957FF6ce0612e06BB09551E2E7d,
            0x66606cdE5B16F11eC8623a59af7028Cd2915A741,
            0x686D068AA2F69EAa56C024b4952BCC9Ebb529aF8,
            0x6a3Be4eAD5F37ffBdE3bbf4F9e32616aB59cb425,
            0x72E94c577D510dd32CA795a5D1Ee0AA9e8d0B868,
            0x73Ea1807Cd3eB5a878641a3349f20f4b196De0B0,
            0x811aD3a946C66d772D768C5d73D0B1457088f810,
            0x8A50cD7Bc9Fa0F7bfc3d5a7f6935bB1D0323bCE5,
            0x8dE9c4dB1FFAebDb7631E918714364790917c65E,
            0x935d9B02e6d62caEa0E638bfC6E6c2cb932f450a,
            0x9a1683891fD219DE61925fCE16b48EACFA96F479,
            0x9Db22Ff3FDaF5fF50cCDA45270a54203A9F4f6d9,
            0xa265A250B2b774aA9fee8a002d44cc6638E31db5,
            0xA89f83BafFE03e33556e1cc526fAf3007D9c874b,
            0xaa1aB91ada1296DaD4A3DE898d5E60B022517EC4,
            0xAdD055D0456f506544056E54e0B0270715956d1D,
            0xb63f8e77975e220aC3D1B50d07EFcb6beaF2E5CC,
            0xc1447EEE840543115cD74b6fD151F3b13D581B92,
            0xCb9B40B8Ab77529AB49c1CfC614b40039fF069C7,
            0xcf8b4dE779c0C55b10986B62C4C1F970daF34A5b,
            0xd1f06B5e69eCA96FE354f424e1CA514f061912f8,
            0xd6286633E302eb61Eb5D9D7cA4F21DB60722978c,
            0xD7f4beF4BB899EEDa8264a5896B7cE09Fb0B86B5,
            0xD959dF95169BFF5d293df05817C3a5d19047177e,
            0xDee64feCD5c798305705C0c4Bf9A33545f868535,
            0xe8DeaA5c7F36aaB55137a07F90aAdA53717e760a,
            0xf4212A9769545864E05A376aE768a12E7230C1cb,
            0xf4E67D814B17306DcfdA1118f2f5B0178d5e371e,
            0xF7DE62B65768a169279be74b12FaA65a22FB38D3,
            0xFD599045A2B72e598bb7401bE13B2686a7a42263
        ];

        uint256 investorsAddressesLength_ = investorsAddresses_.length;

        // --------- get data from old storage ---------

        // get USDT address
        address usdt_ = address(LibAppStorage.getUSDT());

        // get raise
        BaseTypesV1.Raise memory oldRaise_ = LibRaiseV1.getRaise(raiseId_);

        // get vested
        BaseTypesV1.Vested memory oldVested_ = LibRaiseV1.getVested(raiseId_);

        // get raised amount
        uint256 oldRaised_ = LibRaiseV1.getTotalInvestment(raiseId_);

        // --------- create structs for new storage data ---------

        // new Raise struct
        StorageTypes.Raise memory newRaise_ = StorageTypes.Raise({
            raiseId: oldRaise_.raiseId,
            raiseType: EnumTypes.RaiseType(uint8(oldRaise_.raiseType)),
            owner: oldRaise_.owner
        });

        // new RaiseDetails struct
        StorageTypes.RaiseDetails memory newRaiseDetails_ = StorageTypes.RaiseDetails({
            tokensPerBaseAsset: oldRaise_.raiseDetails.price.tokensPerBaseAsset,
            hardcap: oldRaise_.raiseDetails.hardcap,
            softcap: oldRaise_.raiseDetails.softcap,
            start: oldRaise_.raiseDetails.start,
            end: oldRaise_.raiseDetails.end
        });

        // new RaiseDataCrossChain struct
        StorageTypes.RaiseDataCC memory newRaiseDataCC_ = StorageTypes.RaiseDataCC({ raised: oldRaised_, merkleRoot: bytes32(0) });

        // new ERC20Asset struct
        StorageTypes.ERC20Asset memory newERC20Asset_ = StorageTypes.ERC20Asset({
            erc20: oldVested_.erc20,
            chainId: block.chainid,
            amount: oldVested_.amount
        });

        // new BaseAsset struct
        StorageTypes.BaseAsset memory newBaseAsset_ = StorageTypes.BaseAsset({ base: usdt_, chainId: block.chainid });

        // --------- save data for raise, assets and investors ---------

        // set Raise in the new storage
        LibRaise.setRaise(raiseId_, newRaise_);
        // set RaiseDetails in the new storage
        LibRaise.setRaiseDetails(raiseId_, newRaiseDetails_);
        // set RaiseDataCrossChain in the new storage
        LibRaise.setRaiseDataCrosschain(raiseId_, newRaiseDataCC_);
        // set ERC20Asset in the new storage
        LibERC20Asset.setERC20Asset(raiseId_, newERC20Asset_);
        // set BaseAsset in the new storage
        LibBaseAsset.setBaseAsset(raiseId_, newBaseAsset_);
        // set badge URI in the new storage
        LibBadge.setBadgeUri(raiseId_, oldRaise_.raiseDetails.badgeUri);

        // value needed in sanity check
        uint256 raisedAmount_ = 0;

        for (uint256 i = 0; i < investorsAddressesLength_; i++) {
            // get investor address
            address investor_ = investorsAddresses_[i];

            // get investment amount for given investor
            uint256 investment_ = LibRaiseV1.getInvestment(raiseId_, investor_);

            // increase value needed in sanity check
            raisedAmount_ += investment_;

            // set invested amount in the new storage
            LibInvestorFundsInfo.increaseInvested(raiseId_, investor_, investment_);

            // reset invested amount in the old storage
            LibRaiseV1.resetInvestment(raiseId_, investor_);
        }

        // invested total amount sanity check
        if (raisedAmount_ != oldRaised_) {
            revert InvalidRaisedAmount();
        }

        // --------- prepare data for reset old storage ---------

        // old Price struct with empty values
        BaseTypesV1.Price memory emptyOldPrice_ = BaseTypesV1.Price({ tokensPerBaseAsset: 0, asset: BaseTypesV1.Asset.USDT });

        // old RaiseDetails struct with empty values
        BaseTypesV1.RaiseDetails memory emptyOldRaiseDetails_ = BaseTypesV1.RaiseDetails({
            price: emptyOldPrice_,
            hardcap: 0,
            softcap: 0,
            start: 0,
            end: 0,
            badgeUri: ""
        });

        // old Raise struct with empty values
        BaseTypesV1.Raise memory emptyOldRaise_ = BaseTypesV1.Raise({
            raiseId: "",
            raiseType: BaseTypesV1.RaiseType.Standard,
            raiseDetails: emptyOldRaiseDetails_,
            owner: address(0)
        });

        // old Vested struct with empty values
        BaseTypesV1.Vested memory emptyOldVested_ = BaseTypesV1.Vested({ erc20: address(0), amount: 0 });

        // --------- reset old storage ---------

        // set USDT address to address(0)
        LibAppStorage.setUSDT(address(0));

        // reset raise in the old storage
        LibRaiseV1.saveRaise(raiseId_, emptyOldRaise_, emptyOldVested_);

        // reset total raised amount in the old storage
        LibRaiseV1.resetRaised(raiseId_);
    }
}
