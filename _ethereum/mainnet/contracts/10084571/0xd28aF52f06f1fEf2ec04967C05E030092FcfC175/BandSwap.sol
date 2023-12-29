pragma solidity 0.5.17;

contract BandSwap {
    mapping (address => string) public bandAddresses;
    
    function setBandAddress(string memory bandAddress) public {
        require(bytes(bandAddress).length == 43, "INVALID_BAND_ADDRESS_LENGTH");
        bandAddresses[msg.sender] = bandAddress;   
    }
}