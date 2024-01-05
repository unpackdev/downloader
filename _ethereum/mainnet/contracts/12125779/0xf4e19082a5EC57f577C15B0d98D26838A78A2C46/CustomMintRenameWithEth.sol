pragma solidity >=0.6.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./CustomMintRename.sol";
import "./CostUtils.sol";
import "./TokenMetadata.sol";

pragma experimental ABIEncoderV2;

abstract contract CustomMintRenameWithEth is CustomMintRename {
    uint256 private ETH_RENAME_FEE = 10**17; // 0.1
    using CostUtils for uint256;
    address internal constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function updateRenameFeeEth(uint256 renameFeeInWei) public {
        require(owner() == _msgSender(), "Must be owner");
        ETH_RENAME_FEE = renameFeeInWei;
    }

    function mintFromEth(uint256 jNumber) public payable {
        address minter = _msgSender();
        require(jNumber < 100 && jNumber > 0, "Invalid jnumber");
        require(!_exists(jNumber), "Already minted");

        uint256 cost = CostUtils.getMintCost(jNumber, 18);
        uint256 weiSent = msg.value;

        // Check the contract exact amount to mint
        require(weiSent == cost, "Incorrect eth sent for jNumber");

        // Sweep fee to owner
        uint256 fee = CostUtils.getMintFee(jNumber, 18);
        payable(owner()).transfer(fee);

        _safeMint(minter, jNumber);
    }

    function renameWithEth(uint32 jNumber, string memory newName)
        public
        payable
    {
        uint256 tokenID = jNumber;
        address ownerOfNft = ownerOf(tokenID);

        require(_exists(tokenID), "Not minted");
        require(ownerOfNft == _msgSender(), "Must be owner");
        require(
            validateName(newName),
            "Invalid name. Must be 1-10 ASCII chars."
        );
        require(nameAvailable(newName), "Name already taken sorry");

        uint256 weiSent = msg.value;
        _allocateAndSweepRenameFee(tokenID, weiSent);
        _rename(tokenID, newName);
    }

    function _allocateAndSweepRenameFee(uint256 tokenID, uint256 weiSent)
        private
    {
        if (freeRenameAvailable(tokenID)) {
            if (weiSent != 0) {
                // Send them back their ETH
                _msgSender().transfer(weiSent);
            }
            return;
        }
        J_TYPE_EPOCH[ETH_ADDRESS] += 1;
        // Flat 10% rename fee paid to the contract owner
        uint256 feeCollectorFeeAmount = (ETH_RENAME_FEE * 10) / 100;
        uint256 allocatableFee = ETH_RENAME_FEE - feeCollectorFeeAmount;
        uint256 remainderOfAllocation = allocatableFee % _totalShares;
        uint256 feePlusRemainder =
            feeCollectorFeeAmount + remainderOfAllocation;

        payable(owner()).transfer(feePlusRemainder);
    }

    function burnForEth(uint32 jNumber) public {
        uint256 tokenID = jNumber;
        require(_exists(tokenID), "Not minted");
        require(ownerOf(tokenID) == _msgSender(), "Must be owner.");
        address payable tokenOwner = payable(ownerOf(tokenID));
        // Give the owner back their stake
        tokenOwner.transfer(CostUtils.getBurnValue(jNumber, 18));

        // Free up old name
        _rename(tokenID, "");

        _burn(tokenID);
    }

    function claimRenameFeesEth(uint32 jNumber) public {
        require(ownerOf(uint256(jNumber)) == _msgSender(), "Must be owner.");

        address payable tokenOwner = payable(_msgSender());
        uint256 ownerFeeAmount = _getRenameFeesAvailableToClaimEth(jNumber);
        if (ownerFeeAmount == 0) {
            return;
        }
        // Move the last claimed epoch to the current j type epoch
        J_LAST_CLAIMED_EPOCH[uint256(jNumber)] = J_TYPE_EPOCH[ETH_ADDRESS];
        tokenOwner.transfer(ownerFeeAmount);
    }

    function hasUsedFreeRenameEth(uint32 jNumber) public view returns (bool) {
        return !freeRenameAvailable(jNumber);
    }

    function getRenameFeesAvailableToClaimEth(uint32 jNumber)
        public
        view
        returns (uint256)
    {
        return _getRenameFeesAvailableToClaimEth(jNumber);
    }

    function getTokensForEth()
        external
        view
        returns (TokenMetadata[100] memory)
    {
        TokenMetadata[100] memory tokens;
        for (uint32 jNumber = 0; jNumber < 100; jNumber++) {
            uint256 tokenId = jNumber;
            if (_exists(tokenId)) {
                TokenMetadata memory tmd =
                    TokenMetadata({
                        exists: true,
                        tokenId: tokenId,
                        jNumber: jNumber,
                        erc20ContractAddress: address(0),
                        claimableRenameFees: getRenameFeesAvailableToClaimEth(
                            jNumber
                        ),
                        hasFreeRename: freeRenameAvailable(tokenId),
                        name: nameOf(tokenId),
                        ownerAddress: ownerOf(tokenId)
                    });
                tokens[jNumber] = tmd;
            } else {
                TokenMetadata memory tmd =
                    TokenMetadata({
                        exists: false,
                        tokenId: tokenId,
                        jNumber: jNumber,
                        erc20ContractAddress: address(0),
                        claimableRenameFees: getRenameFeesAvailableToClaimEth(
                            jNumber
                        ),
                        hasFreeRename: freeRenameAvailable(tokenId),
                        name: "",
                        ownerAddress: address(0)
                    });
                tokens[jNumber] = tmd;
            }
        }

        return tokens;
    }

    function _getRenameFeesAvailableToClaimEth(uint32 jNumber)
        internal
        view
        returns (uint256)
    {
        uint256 tokenID = jNumber;
        uint256 jEpoch = J_TYPE_EPOCH[ETH_ADDRESS];
        uint256 lastClaimed = J_LAST_CLAIMED_EPOCH[tokenID];
        if (jEpoch <= lastClaimed) {
            return 0;
        }
        uint256 feeMultiplier = jEpoch - lastClaimed;
        // E.g 99/4950 * 1 * 0.1 * 90% (flat 10% was paid to contract owner)
        // 10% is paid to contract owner, so 90% remains for the nft holders
        uint256 adjustedCostOfRename = (ETH_RENAME_FEE * 90) / 100;
        uint256 remainderAfterAllocation = adjustedCostOfRename % _totalShares;
        uint256 evenlyDivisibleAllocation =
            adjustedCostOfRename - remainderAfterAllocation;
        uint256 ownerFeeAmount =
            ((((uint256(jNumber) * PRECISION_MULTIPLIER)) *
                feeMultiplier *
                evenlyDivisibleAllocation) / PRECISION_MULTIPLIER) /
                _totalShares;

        return ownerFeeAmount;
    }
}
