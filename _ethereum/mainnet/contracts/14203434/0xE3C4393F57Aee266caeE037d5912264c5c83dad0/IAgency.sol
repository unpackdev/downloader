// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./StakeApe.sol";

interface IAgency {

    /** Put Apes into agency. Will transfer 721 tokens to the agency in order to play.
     */
    function putApesToAgency(uint[] memory ids, address owner) external;

    /** Transfer back the Apes from the Agency to original owner's wallet.
     */
    function getApesFromAgency(uint[] memory ids, address owner) external;

    function setStateForApes(uint[] memory ids, address sender, bytes1 newState) external;

    function stopStateForApe(uint id, address sender) external returns(uint);

    function getApe(uint id) external view returns(uint256,address,bytes1,uint256);

    function setApeState(uint id, bytes1 state, uint256 date) external;

    function getOwnerApes(address a) external view returns(uint[] memory);

    function transferApesBackToOwner() external;

    function returnApeToOwner(uint256 tokenId) external;

    function returnApeToAddress(uint256 tokenId, address owner) external;


}
