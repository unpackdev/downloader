/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./ToonTokenV0Extended.sol";

abstract contract ToonTokenMaintainerAccess {
    address payable private _toonTokenContractAddress;

    modifier maintainerAuthorized() {
        require(onlyAuthorized(), "you shall not pass");

        _;
    }

    function setToonTokenContractAddress(
        address payable nextToonTokenContractAddress
    ) external maintainerAuthorized {
        _toonTokenContractAddress = nextToonTokenContractAddress;
    }

    function setWallets(address nextMaintainerWallet, address nextBountyWallet)
        external
        maintainerAuthorized
    {
        ToonTokenV0Extended(_toonTokenContractAddress).setWallets(
            nextMaintainerWallet,
            nextBountyWallet
        );
    }

    function setBountyObligationReferencePrice(uint256 referencePrice)
        external
        maintainerAuthorized
    {
        ToonTokenV0Extended(_toonTokenContractAddress)
            .setBountyObligationReferencePrice(referencePrice);
    }

    function proposeDistribution(
        address payable nextProposedDistributionAddress,
        uint256 nextProposedDistributionAmount
    ) external maintainerAuthorized {
        ToonTokenV0Extended(_toonTokenContractAddress).proposeDistribution(
            nextProposedDistributionAddress,
            nextProposedDistributionAmount
        );
    }

    function proposeUpgrade(address nextProposedUpgradeImpl)
        external
        maintainerAuthorized
    {
        ToonTokenV0Extended(_toonTokenContractAddress).proposeUpgrade(
            nextProposedUpgradeImpl
        );
    }

    function holdElectionsAndUpdate() external maintainerAuthorized {
        ToonTokenV0Extended(_toonTokenContractAddress).holdElectionsAndUpdate();
    }

    function confirmConsensusAndUpdate(
        address winningCandidate,
        address[] memory voters,
        address[] memory abstainedVoters
    ) external {
        ToonTokenV0Extended(_toonTokenContractAddress)
            .confirmConsensusAndUpdate(
                winningCandidate,
                voters,
                abstainedVoters
            );
    }

    function onlyAuthorized() public virtual returns (bool);

    function getToonTokenContractAddress()
        public
        view
        returns (address payable)
    {
        return _toonTokenContractAddress;
    }

    // solhint-disable-next-line ordering
    uint256[49] private __gap;
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode
