// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC721.sol";

interface IStakingNFT is IERC721 {

    function owner() external view returns (address);

    function isMinterAddress(address minterAddress_) external view returns (bool);

    function checkTokenExistence(uint256 tokenId_) external view returns (bool);

    function getStakeTokenData(uint256 tokenId_)
        external
        view
        returns (
            address ownerAddress,
            uint256 startAt,
            uint256 stakeAmount,
            uint16 rewardPercent,
            address minterAddress
        );

    function mintToken(
        address addressTo_,
        uint256 stakeAmount_,
        uint16 rewardPercent_
    )
        external
        returns (uint256);


    function transfer(address to_, uint256 tokenId_) external returns (bool);

    function burnToken(uint256 tokenId_) external returns (bool);
}
