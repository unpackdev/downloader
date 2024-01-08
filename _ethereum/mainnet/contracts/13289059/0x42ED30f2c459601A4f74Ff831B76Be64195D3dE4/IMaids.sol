// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IUniswapV2Pair.sol";
import "./IMasterChefModule.sol";

interface IMaids is IERC721, IERC721Metadata, IERC721Enumerable, IMasterChefModule {
    event Support(uint256 indexed id, uint256 lpTokenAmount);
    event Desupport(uint256 indexed id, uint256 lpTokenAmount);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function PERMIT_ALL_TYPEHASH() external view returns (bytes32);

    function MAX_MAID_COUNT() external view returns (uint256);

    function nonces(uint256 id) external view returns (uint256);

    function noncesForAll(address owner) external view returns (uint256);

    function maids(uint256 id)
        external
        view
        returns (
            uint256 originPower,
            uint256 supportedLPTokenAmount,
            uint256 sushiRewardDebt
        );

    function powerAndLP(uint256 id) external view returns (uint256, uint256);

    function support(uint256 id, uint256 lpTokenAmount) external;

    function supportWithPermit(
        uint256 id,
        uint256 lpTokenAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function desupport(uint256 id, uint256 lpTokenAmount) external;

    function claimSushiReward(uint256 id) external;

    function pendingSushiReward(uint256 id) external view returns (uint256);

    function permit(
        address spender,
        uint256 id,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function permitAll(
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
