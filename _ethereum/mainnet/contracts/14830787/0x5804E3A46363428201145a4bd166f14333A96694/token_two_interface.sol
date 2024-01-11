pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY


interface token_two_interface {

    function setAllowed(address _addr, bool _state) external;

    function permitted(address) external view returns (bool);

    function mintBatchToOne(address recipient, uint256[] memory tokenIds) external;

    function mintBatchToOneR(address recipient, uint256[] memory tokenIds) external;

    function mintBatchToMany(address[] memory recipients , uint256[] memory tokenIds ) external;

    function mintReplacement(address user, uint256 tokenId) external;

}