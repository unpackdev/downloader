//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Useful for debugging. Remove when deploying to a live network.
//import "./console.sol";

// Use openzeppelin to inherit battle-tested implementations (ERC20, ERC721, etc)
// import "./Ownable.sol";

/**
 * A smart contract that allows changing a state variable of the contract and tracking the changes
 * It also allows the owner to withdraw the Ether in the contract
 * @author BuidlGuidl
 */
contract YourContract {

	// yo chat gpt gimme a shitty splitter function for a smart contract plz: 

	// This function allows the owner to send specified amounts of Ether
    // to a list of addresses.
    function split(address[] memory recipients, uint[] memory amounts) public payable {
        // Sanity checks
        require(recipients.length == amounts.length, "Array lengths do not match");
        uint total = 0;
        for (uint i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }
        require(total == msg.value, "Sent value does not match the total amounts to be distributed");

        // Sending specified amounts of Ether to the list of addresses
        for (uint i = 0; i < recipients.length; i++) {
            // Using .call to send Ether
            // This is a low-level function and must be used with caution
            (bool success, ) = recipients[i].call{value: amounts[i]}("");
            require(success, "Failed to send Ether");
        }
    }

}
