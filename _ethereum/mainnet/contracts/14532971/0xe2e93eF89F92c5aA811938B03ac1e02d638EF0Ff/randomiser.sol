// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "./console.sol";


contract randomiser {

    struct random_tool {
        bool        substituted;
        uint128     value;
    }

    mapping(uint => uint)                          num_tokens_left;
    mapping(uint => mapping (uint => random_tool)) random_eyes;
    uint256                             immutable  startsWithZero;

    constructor(uint256 oneIfStartsWithZero) {
        startsWithZero = oneIfStartsWithZero;
    }

    function getTID(uint256 projectID, uint256 pos) internal view returns (uint128){
        random_tool memory data = random_eyes[projectID][pos];
        if (!data.substituted) return uint128(pos);
        return data.value;
    }

    function randomTokenURI(uint256 projectID, uint256 rand) internal returns (uint256) {
        uint256 ntl = num_tokens_left[projectID];
        require(ntl > 0,"All tokens taken");
        uint256 nt = (rand % ntl--);
        random_tool memory data = random_eyes[projectID][nt];

        uint128 endval = getTID(projectID,ntl);
        random_eyes[projectID][nt] = random_tool( true,endval);
        num_tokens_left[projectID] = ntl;

        if (data.substituted) return data.value+startsWithZero;
        return nt+startsWithZero;
    }

    function setNumTokensLeft(uint256 projectID, uint256 num) internal {
        num_tokens_left[projectID] = num;
    }

    function numLeft(uint projectID) external view returns (uint) {
        return num_tokens_left[projectID];
    }

}