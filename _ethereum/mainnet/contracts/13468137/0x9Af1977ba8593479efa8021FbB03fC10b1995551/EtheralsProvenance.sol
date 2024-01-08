// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./VRFConsumerBase.sol";
import "./Ownable.sol";

contract EthernalsProvenance is VRFConsumerBase, Ownable {

    address internal LINK_ADDRESS = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address internal VRF_COORDINATOR = 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952;
    bytes32 internal KEY_HASH = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    uint internal FEE = 2 * 10 ** 18;

    uint256 public startingIndex;
    string public provenance;

    constructor() VRFConsumerBase( VRF_COORDINATOR, LINK_ADDRESS ) { }

    function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= FEE, "Not enough LINK");
        return requestRandomness(KEY_HASH, FEE);
    }

    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        startingIndex = (randomness % 5555) + 1;
    }

    function withdrawLink() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(LINK_ADDRESS);
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

    function setProvenance(string memory newProvenance) public onlyOwner {
        require( _isEmptyString(provenance), "Provenance has been already defined" );
        provenance = newProvenance;
    }

    function getProvenance() public view returns (string memory){
        return provenance;
    }

    function _isEmptyString(string memory text) internal view virtual returns (bool) {
        bytes memory tempEmptyStringTest = bytes(text);
        return (tempEmptyStringTest.length == 0);
    }
}
