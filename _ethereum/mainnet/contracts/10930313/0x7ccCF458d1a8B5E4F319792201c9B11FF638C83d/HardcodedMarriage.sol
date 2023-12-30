pragma solidity ^0.6.1;


// With love from Evgeny & Rita!
contract HardcodedMarriage {
    string public partner_1_name = "Igor";
    string public partner_2_name = "Olya";

    function getNewFamilyName() pure public returns (string memory) {
        return "Zboichik";
    }

    function getDeclaration() pure public returns (string memory) {
        return "Igor & Olya got married on September 25th, 2020!";
    }
}