//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

interface ITokenVesting {
    event VestingTokenAdded(uint256 tokenId, address token);
    event AddWhitelist(uint256 tokenId, address wallet);
    event DeleteWhitelist(uint256 tokenId, address wallet);
    event UserCliffUpdated(uint256 tokenId, address wallet, uint256 cliff);
    event UserTokenAmountUpdated(
        uint256 tokenId,
        address wallet,
        uint256 amount
    );
    event VestingInfoAdded(
        uint256 strategy,
        uint256 cliff,
        uint256 start,
        uint256 duration
    );
    event VestingInfoDeleted(uint256 strategy);

    struct VestingInfo {
        uint256 strategy;
        uint256 cliff;
        uint256 start;
        uint256 duration;
        uint256 step;
        bool active;
    }

    struct WhitelistInfo {
        address wallet;
        uint256 tokenAmount;
        uint256 distributedAmount;
        uint256 joinDate;
        uint256 cliff;
        uint256 start;
        uint256 duration;
        uint256 step;
        uint256 nextReleaseTime;
        uint256 vestingOption;
        bool active;
    }

    function setVestingInfo(
        uint256 _strategy,
        uint256 _cliff,
        uint256 _start,
        uint256 _duration,
        uint256 _step
    ) external;

    function deleteVestingInfo(uint256 _strategy) external;

    function addWhitelists(
        uint256 _tokenId,
        address[] calldata _wallet,
        uint256[] calldata _tokenAmount,
        uint256[] calldata _option
    ) external;

    function deleteWhitelists(uint256 _tokenId, address[] calldata _wallet)
        external;

    function addVestingToken(uint256 _tokenId, IERC20 _token) external;

    function updateUserCliff(
        uint256 _tokenId,
        address _wallet,
        uint256 _cliff
    ) external;

    function updateUserTokenAmount(
        uint256 _tokenId,
        address _wallet,
        uint256 _tokenAmount
    ) external;

    function claimDistribution(uint256 _tokenId) external returns (bool);
}
