// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;
pragma abicoder v2;

import "./IUnifarmNFTDescriptorUpgradeable.sol";
import "./IUnifarmCohort.sol";
import "./NFTDescriptor.sol";
import "./IERC20TokenMetadata.sol";
import "./CheckPointReward.sol";
import "./Initializable.sol";
import "./CohortHelper.sol";
import "./ConvertHexStrings.sol";

contract UnifarmNFTDescriptorUpgradeable is Initializable, IUnifarmNFTDescriptorUpgradeable {
    /// @notice registry contract address
    address public registry;

    /**
     * @notice construct a descriptor contract
     * @param registry_ registry address
     */

    function __UnifarmNFTDescriptorUpgradeable_init(address registry_) external initializer {
        __UnifarmNFTDescriptorUpgradeable_init_unchained(registry_);
    }

    /**
     * @dev internal function to set descriptor storage
     * @param registry_ registry address
     */

    function __UnifarmNFTDescriptorUpgradeable_init_unchained(address registry_) internal {
        registry = registry_;
    }

    /**
     * @dev get token ticker
     * @param farmToken farm token address
     * @return token ticker
     */

    function getTokenTicker(address farmToken) internal view returns (string memory) {
        return IERC20TokenMetadata(farmToken).symbol();
    }

    /**
     * @dev get Cohort details
     * @param cohortId cohort address
     * @param uStartBlock user start block
     * @param uEndBlock user End Block
     * @return cohortName cohort version
     * @return confirmedEpochs confirmed epochs
     */

    function getCohortDetails(
        address cohortId,
        uint256 uStartBlock,
        uint256 uEndBlock
    ) internal view returns (string memory cohortName, uint256 confirmedEpochs) {
        (string memory cohortVersion, , uint256 cEndBlock, uint256 epochBlocks, , , ) = CohortHelper.getCohort(registry, cohortId);
        cohortName = cohortVersion;
        confirmedEpochs = CheckPointReward.getCurrentCheckpoint(uStartBlock, (uEndBlock > 0 ? uEndBlock : cEndBlock), epochBlocks);
    }

    /**
     * @inheritdoc IUnifarmNFTDescriptorUpgradeable
     */

    function generateTokenURI(address cohortId, uint256 tokenId) public view override returns (string memory) {
        (uint32 fid, , uint256 stakedAmount, uint256 startBlock, uint256 sEndBlock, , , bool isBooster) = IUnifarmCohort(cohortId).viewStakingDetails(
            tokenId
        );

        (string memory cohortVersion, uint256 confirmedEpochs) = getCohortDetails(cohortId, startBlock, sEndBlock);

        (, address farmToken, , , , , ) = CohortHelper.getCohortToken(registry, cohortId, fid);

        return
            NFTDescriptor.createNftTokenURI(
                NFTDescriptor.DescriptionParam({
                    fid: fid,
                    cohortName: cohortVersion,
                    stakeTokenTicker: getTokenTicker(farmToken),
                    cohortAddress: ConvertHexStrings.addressToString(cohortId),
                    stakedBlock: startBlock,
                    tokenId: tokenId,
                    stakedAmount: stakedAmount,
                    confirmedEpochs: confirmedEpochs,
                    isBoosterAvailable: isBooster
                })
            );
    }

    uint256[49] private __gap;
}
