// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./SharedDataTypes.sol";

interface IUZV1Staking {
    /* view functions */
    function getTVLs() external view returns (uint256[] memory);

    function getTVLs(uint256 _blocknumber)
        external
        view
        returns (uint256[] memory);

    function getUserTVLShare(address _user, uint256 _precision)
        external
        view
        returns (uint256[] memory);

    function getUsersStakedAmountOfToken(address _user, address _token)
        external
        view
        returns (uint256);

    function getUserData(address _user)
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256
        );

    function getActiveTokens() external view returns (address[] memory);

    function getTokenWeights()
        external
        view
        returns (uint256[] memory weights, uint256 combinedWeight);

    function getUserStakesSnapshots(
        address _user,
        address _token,
        uint256 _startBlock,
        uint256 _endBlock
    )
        external
        view
        returns (SharedDataTypes.StakeSnapshot[] memory startBlocks);

    function getUserStakes(address _user)
        external
        view
        returns (uint256[] memory);

    function getUserStakes(address _user, uint256 _blocknumber)
        external
        view
        returns (uint256[] memory);

    /* mutating functions */
    function stake(uint256 _amount) external returns (uint256);

    function stake(address _lpToken, uint256 _amount)
        external
        returns (uint256);

    function withdraw(uint256 _amount) external returns (uint256);

    function withdraw(address _lpToken, uint256 _amount)
        external
        returns (uint256);
}
