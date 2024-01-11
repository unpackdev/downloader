// SPDX-License-Identifier: MIT
// Groovy Goblins NFT Smart Contract
//
// Developer: Pineapple

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract GroovyGoblins is ERC721A, Ownable {
    uint256 public constant PRICE = 0.005 ether;
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_MINT = 10;
    uint256 public constant RESERVE_QTY = 75;

    bool public saleLive = false;
    bool public reserved = false;

    string private _baseTokenURI = '';

    address private _devWallet = 0x17193312b3A2f16664b1041caED6cEDB090Fae5e;
    address private _teamWallet = 0xDeaA15eF80e866d9Efe20D378C9179845637D2A5;

    constructor() ERC721A("GroovyGoblins", "GG") {}

    //FUNCTIONS FOR PUBLIC
    //@dev These functions will be used by the general public to interact with
    //     the contract.

    //@dev Function that mints
    //@param: quantity | Number of Groovy Goblins a user wants to mint
    function mint(uint256 quantity) external payable {
        require(saleLive, "The public sale is not live yet!");
        require(quantity <= MAX_MINT, "Can't mint more than 10 Groovy Goblins per transaction!");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough Groovy Goblins left!");
        require(msg.value >= PRICE * quantity, "Need to send more ETH!");

        _safeMint(msg.sender, quantity);
    }

    //FUNCTIONS FOR THE TEAM/OWNER
    //@dev These functions will be used by contract owners. This includes
    //     functions that mutate the state of the contract or any other
    //     requirement for interaction

    //@dev Function to reserve NFTs for giveaways
    function reserveMints() external onlyOwner {
        require(!reserved, "Goblins were already reserved!");
        reserved = true;

        _safeMint(_teamWallet, RESERVE_QTY);
    }

    //@dev Function to start sale
    function flipSale() external virtual onlyOwner {
        saleLive = !saleLive;
    }

    //@dev Splits and withdraws funds to the developer and team wallets
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        
        payable(_devWallet).transfer((balance * 10)/100);
        
        (bool sent, ) = payable(_teamWallet).call{value: ((balance * 90)/100)}("");

        require(sent, "Failed to transfer to team safe!");
    }

    //@dev Changes team address
    function setTeamAddress(address teamWallet_) external onlyOwner {
        _teamWallet = teamWallet_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function contractURI() public pure returns (string memory){
        return "https://pineapple.mypinata.cloud/ipfs/QmTVRTj3Tq46osZ7zPSBnVHs1LQjWZQKrdWhEYAhBJUNTP";
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}