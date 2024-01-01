// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

struct TokenAmount {
    address[] token;
    uint256[] amount;
   
}

struct Garden {
    uint256 id;
    address owner;
    uint256 gardenerId;
    address gardenerAddress;
    TokenAmount[] composition;
    uint256 createdAt;
    string gardenerUsername;
    string gardenName;
}

interface IGardenBlokc {
    function createGarden(
        uint256 _gardenerId,
        uint256 _amount,
        string memory _gardenName
    ) external;

    function changeGardener(uint256 _gardenerId, uint256 _gardenId) external;

    function getGardensByAddress(
        address _userAddress
    ) external view returns (Garden[] memory);

    function changeGardenComposition(
        uint256 _idGarden,
        address _userAddress,
        TokenAmount[] memory composition
    ) external;
}
