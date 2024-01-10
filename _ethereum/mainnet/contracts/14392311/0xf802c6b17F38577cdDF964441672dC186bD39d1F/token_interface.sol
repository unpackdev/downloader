pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY


interface token_interface {

    function setAllowed(address _addr, bool _state) external;

    function permitted(address) external view returns (bool);

    function mintCards(uint256 numberOfCards, address recipient) external;

    function tokenPreRevealURI() external view returns (string memory);

}