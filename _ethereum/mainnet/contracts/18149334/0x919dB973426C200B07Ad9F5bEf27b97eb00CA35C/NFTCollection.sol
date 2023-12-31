// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Counters.sol";

contract NFTCollection is Ownable {
    using Counters for Counters.Counter;

    string public name;
    string public symbol;
    string public baseURI;
    uint256 public collection_ID;
    string public original_chain;
    address public eth_chain_address;
    mapping(string => string) public chain_contract_addresses;

    Counters.Counter private _token_Id_counter;

    event Add_Chain(address collection, string chain, string contractAddress);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory original_chain_,
        address eth_chain_address_
    ) {
        name = name_;
        symbol = symbol_;
        baseURI = baseURI_;
        original_chain = original_chain_;
        eth_chain_address = eth_chain_address_;
        collection_ID = _token_Id_counter.current();
        _token_Id_counter.increment();
    }

    /**
     * Add Contract address in chain to collection
     */
    function add_chain_contract(
        string memory chain,
        string memory contract_address
    ) external onlyOwner {
        require(
            !compare_strings(chain, "ETH"),
            "Cannot add ETH contract address here"
        );
        chain_contract_addresses[chain] = contract_address;
        emit Add_Chain(address(this), chain, contract_address);
    }

    /**
     * Get Contract address of chain in collection
     */
    function get_chain_contract(
        string memory chain
    ) external view returns (string memory) {
        require(
            bytes(chain_contract_addresses[chain]).length != 0,
            "No contract associated with the chain"
        );
        return chain_contract_addresses[chain];
    }

    /**
     * Get Contract address of chain in collection
     */
    function is_original_chain_ETH() external view returns (bool) {
        return compare_strings(original_chain, "ETH");
    }

    //Helper Functions
    function compare_strings(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        if (bytes(a).length != bytes(b).length) {
            return false;
        }
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }
}
