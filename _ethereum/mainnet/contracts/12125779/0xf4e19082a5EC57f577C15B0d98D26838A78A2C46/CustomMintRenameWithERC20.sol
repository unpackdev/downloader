pragma solidity >=0.6.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./IERC20.sol";
import "./CustomMintRename.sol";
import "./CostUtils.sol";
import "./TokenMetadata.sol";

pragma experimental ABIEncoderV2;

abstract contract CustomMintRenameWithERC20 is CustomMintRename {
    using CostUtils for uint256;

    struct SupportedTokenData {
        address erc20ContractAddress;
        uint32 decimals;
        uint256 renameFee;
    }

    SupportedTokenData[] private supportedErc20Contracts;

    function upsertNewErc20Token(
        address erc20ContractAddress,
        uint32 decimals,
        uint256 renameFee,
        string memory nameOf0thJ
    ) public {
        require(owner() == _msgSender(), "Must be owner");

        for (uint256 i = 0; i < supportedErc20Contracts.length; i++) {
            if (
                supportedErc20Contracts[i].erc20ContractAddress ==
                erc20ContractAddress
            ) {
                supportedErc20Contracts[i].decimals = decimals;
                supportedErc20Contracts[i].renameFee = renameFee;
                return;
            }
        }

        SupportedTokenData memory std =
            SupportedTokenData({
                erc20ContractAddress: erc20ContractAddress,
                decimals: decimals,
                renameFee: renameFee
            });
        supportedErc20Contracts.push(std);

        // MINT the 0th J to the owner when we push a new supported contract
        uint256 tokenID = _getTokenId(erc20ContractAddress, 0);
        _safeMint(owner(), tokenID);
        _rename(tokenID, nameOf0thJ);
    }

    function mintFromERC20(address erc20ContractAddress, uint32 jNumber)
        public
    {
        address minter = _msgSender();
        // check erc20 address is in allow list
        uint256 tokenID = _getTokenId(erc20ContractAddress, jNumber);
        address thisContractAddress = address(this);

        require(jNumber < 100 && jNumber > 0, "Invalid jnumber");
        require(!_exists(tokenID), "Already minted");

        uint256 decimals = _getDecimalsForContractAddress(erc20ContractAddress);
        // Get Total Cost
        uint256 cost = CostUtils.getMintCost(jNumber, decimals);
        // Transfer total cost from minter to our contract
        _safeTransferFrom(
            erc20ContractAddress,
            minter,
            thisContractAddress,
            cost
        );
        // Sweep fee from contract to owner
        uint256 fee = CostUtils.getMintFee(jNumber, decimals);
        _safeTransfer(erc20ContractAddress, owner(), fee);
        _safeMint(minter, tokenID);
    }

    function renameWithERC20(
        address erc20ContractAddress,
        uint32 jNumber,
        string memory newName
    ) public {
        uint256 tokenID = _getTokenId(erc20ContractAddress, jNumber);
        address ownerOfNft = ownerOf(tokenID);

        require(_exists(tokenID), "Not minted");
        require(ownerOfNft == _msgSender(), "Must be owner");
        require(
            validateName(newName),
            "Invalid name. Must be 1-10 ASCII chars."
        );
        require(nameAvailable(newName), "Name already taken sorry");

        _allocateAndSweepRenameFee(tokenID, erc20ContractAddress, ownerOfNft);
        _rename(tokenID, newName);
    }

    function getTokensForERC20(address erc20ContractAddress)
        external
        view
        returns (TokenMetadata[100] memory)
    {
        TokenMetadata[100] memory tokens;
        for (uint32 jNumber = 0; jNumber < 100; jNumber++) {
            uint256 tokenId = _getTokenId(erc20ContractAddress, jNumber);
            if (_exists(tokenId)) {
                TokenMetadata memory tmd =
                    TokenMetadata({
                        exists: true,
                        tokenId: tokenId,
                        jNumber: jNumber,
                        erc20ContractAddress: erc20ContractAddress,
                        claimableRenameFees: getRenameFeesAvailableToClaimERC20(
                            erc20ContractAddress,
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
                        erc20ContractAddress: erc20ContractAddress,
                        claimableRenameFees: getRenameFeesAvailableToClaimERC20(
                            erc20ContractAddress,
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

    function _allocateAndSweepRenameFee(
        uint256 tokenID,
        address erc20ContractAddress,
        address ownerOfNft
    ) private {
        if (freeRenameAvailable(tokenID)) {
            return;
        }

        // Transfer total cost from minter to our contract
        uint256 costOfRename =
            _getRenameFeeForContractAddress(erc20ContractAddress);
        _safeTransferFrom(
            erc20ContractAddress,
            ownerOfNft,
            address(this),
            costOfRename
        );

        // We increase the J Type Epoch counter
        // When fees are claimed in the future it is calculated
        // from the difference of J_TYPE_EPOCH-lastClaimedEpoch.
        // E.g 3-1=2 implies the nft is elligible for a percentage of 2*fees
        J_TYPE_EPOCH[erc20ContractAddress] += 1;

        // We pay out the flat 10% fee on the cost of renames
        // E.g  0.1 * 10%
        uint256 feeCollectorFeeAmount = (costOfRename * 10) / 100;
        uint256 allocatableFee = costOfRename - feeCollectorFeeAmount;
        uint256 remainderOfAllocation = allocatableFee % _totalShares;
        uint256 feePlusRemainder =
            feeCollectorFeeAmount + remainderOfAllocation;

        _safeTransfer(erc20ContractAddress, owner(), feePlusRemainder);
    }

    function burnForERC20(address erc20ContractAddress, uint32 jNumber) public {
        uint256 tokenID = _getTokenId(erc20ContractAddress, jNumber);
        require(_exists(tokenID), "Not minted");
        require(ownerOf(tokenID) == _msgSender(), "Must be owner.");

        // Give the owner back their stake
        _safeTransfer(
            erc20ContractAddress,
            ownerOf(tokenID),
            CostUtils.getBurnValue(
                jNumber,
                _getDecimalsForContractAddress(erc20ContractAddress)
            )
        );

        // Free up old name
        _rename(tokenID, "");

        _burn(tokenID);
    }

    function claimRenameFeesERC20(address erc20ContractAddress, uint32 jNumber)
        public
    {
        uint256 tokenID = _getTokenId(erc20ContractAddress, jNumber);
        require(_exists(tokenID), "Not minted");
        address owner = ownerOf(tokenID);
        require(owner == _msgSender(), "Must be owner.");

        uint256 ownerFeeAmount =
            _getRenameFeesAvailableToClaimERC20(erc20ContractAddress, jNumber);

        if (ownerFeeAmount == 0) {
            return;
        }
        // Move the last claimed epoch to the current nft type epoch
        J_LAST_CLAIMED_EPOCH[tokenID] = J_TYPE_EPOCH[erc20ContractAddress];
        // Transfer the funds to the owner
        _safeTransfer(erc20ContractAddress, owner, ownerFeeAmount);
    }

    function hasUsedFreeRenameERC20(
        address erc20ContractAddress,
        uint32 jNumber
    ) public view returns (bool) {
        uint256 tokenID = _getTokenId(erc20ContractAddress, jNumber);
        return !freeRenameAvailable(tokenID);
    }

    function getRenameFeesAvailableToClaimERC20(
        address erc20ContractAddress,
        uint32 jNumber
    ) public view returns (uint256) {
        return
            _getRenameFeesAvailableToClaimERC20(erc20ContractAddress, jNumber);
    }

    function _getRenameFeesAvailableToClaimERC20(
        address erc20ContractAddress,
        uint32 jNumber
    ) private view returns (uint256) {
        uint256 tokenID = _getTokenId(erc20ContractAddress, jNumber);
        uint256 jEpoch = J_TYPE_EPOCH[erc20ContractAddress];
        uint256 lastClaimed = J_LAST_CLAIMED_EPOCH[tokenID];
        if (jEpoch <= lastClaimed) {
            return 0;
        }
        uint256 feeMultiplier = jEpoch - lastClaimed;
        // E.g 99/4950 * 1 * 0.1 * 90% (flat 10% was paid to contract owner)
        uint256 costOfRename =
            _getRenameFeeForContractAddress(erc20ContractAddress);
        // 10% is paid to contract owner, so 90% remains for the nft holders
        uint256 adjustedCostOfRename = (costOfRename * 90) / 100;
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

    function getSupportedErc20Contracts()
        external
        view
        returns (SupportedTokenData[] memory)
    {
        return supportedErc20Contracts;
    }

    function _getRenameFeeForContractAddress(address erc20TokenAddress)
        private
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < supportedErc20Contracts.length; i++) {
            if (
                supportedErc20Contracts[i].erc20ContractAddress ==
                erc20TokenAddress
            ) {
                return supportedErc20Contracts[i].renameFee;
            }
        }
        revert("Token not supported");
    }

    function _getDecimalsForContractAddress(address erc20TokenAddress)
        private
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < supportedErc20Contracts.length; i++) {
            if (
                supportedErc20Contracts[i].erc20ContractAddress ==
                erc20TokenAddress
            ) {
                return supportedErc20Contracts[i].decimals;
            }
        }
        revert("Token not supported");
    }

    function _getTokenId(address erc20ContractAddress, uint32 jNumber)
        internal
        pure
        returns (uint256)
    {
        return
            uint256(keccak256(abi.encodePacked(erc20ContractAddress, jNumber)));
    }

    // Some tokens on Mainnet are problematic in that some may not throw if the transfer fails
    // but return `false` and some might not return `true` as a value in the case of success
    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(
                abi.encodeWithSelector(
                    IERC20.transferFrom.selector,
                    from,
                    to,
                    value
                )
            );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Failed to transferFrom"
        );
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(
                abi.encodeWithSelector(IERC20.transfer.selector, to, value)
            );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Failed to transfer"
        );
    }
}
