//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

/*
    website: phopopopopopo.web.app
*/

/// @title Popo
/// @author Ring Leader Popo
/// @notice You can use this contract to mint or transfer a Popo.
/// @dev This contract is a derivative of the ERC721A contract.
contract Popo is ERC721A, Ownable {
    using Strings for uint256;

    // Public constants
    uint256 public constant MAX_SUPPLY = 2000;
    uint256 public constant MAX_PER_WALLET = 20;
    uint256 public constant PRICE = 0.003 ether;
    mapping(address => uint256) public balances;

    string private baseURI =
        "https://us-central1-mofos-69a62.cloudfunctions.net/app/popo/token/";

    constructor() ERC721A("OkPopo", "POPO") {}

    /// @notice Mint a new Popo. First 500 are free then .003 each afterwards.
    /// @param quantity The number of NFT's you want to mint, must be less than MAX_PER_WALLET
    function mint(uint256 quantity) external payable {
        require(
            balances[msg.sender] + quantity <= MAX_PER_WALLET,
            "You already have the maximum number of PHOSTs in your account."
        ); // Ensure the sender doesn't already have the maximum number of Popos minted
        require(quantity + _totalMinted() <= MAX_SUPPLY, "Too many Phosts"); // Ensure that this mint will not exceed the maximum supply
        if(_totalMinted() > 500){
        require(
            msg.value >= quantity * PRICE,
            "You don't have enough ether to mint this many PHOSTs."
        ); // Ensure that the sender has enough ether to pay for the transaction
        }
        balances[msg.sender] += quantity;
        _safeMint(
            msg.sender,
            quantity
        );
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @notice Get the metadata of a Popo
    /// @param tokenId The token ID number.
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    // Withdraws the balance of the contract
    function withdraw() onlyOwner public{
        payable(msg.sender).transfer(address(this).balance);
    }
}
