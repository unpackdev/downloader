// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "./IERC721Metadata.sol";
import "./ICloneNurseEnumerable.sol";
import "./ISupportable.sol";
import "./INursePart.sol";
import "./IMaidCoin.sol";
import "./ITheMaster.sol";

interface ICloneNurses is IERC721, IERC721Metadata, ICloneNurseEnumerable, ISupportable {
    event Claim(uint256 indexed id, address indexed claimer, uint256 reward);
    event ElongateLifetime(uint256 indexed id, uint256 rechargedLifetime, uint256 lastEndBlock, uint256 newEndBlock);

    function nursePart() external view returns (INursePart);

    function maidCoin() external view returns (IMaidCoin);

    function theMaster() external view returns (ITheMaster);

    function nurseTypes(uint256 typeId)
        external
        view
        returns (
            uint256 partCount,
            uint256 destroyReturn,
            uint256 power,
            uint256 lifetime
        );

    function nurseTypeCount() external view returns (uint256);

    function nurses(uint256 id)
        external
        view
        returns (
            uint256 nurseType,
            uint256 endBlock,
            uint256 lastClaimedBlock
        );

    function assemble(uint256 nurseType, uint256 parts) external;

    function assembleWithPermit(
        uint256 nurseType,
        uint256 parts,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function elongateLifetime(uint256[] calldata ids, uint256[] calldata parts) external;

    function destroy(uint256[] calldata ids, uint256[] calldata toIds) external;

    function claim(uint256[] calldata ids) external;

    function pendingReward(uint256 id) external view returns (uint256);

    function findSupportingTo(address supporter) external view returns (address, uint256);

    function exists(uint256 id) external view returns (bool);
}
