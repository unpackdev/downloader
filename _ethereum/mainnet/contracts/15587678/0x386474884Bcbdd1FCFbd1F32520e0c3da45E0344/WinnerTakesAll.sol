// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./Context.sol";
import "./Ownable.sol";

import "./ERC721A.sol";



pragma solidity ^0.8.7;


contract WIN1ETH is Ownable, ERC721A {
    
    uint256 public maxSupply                    = 666;
    uint256 public maxPerAddressDuringMint      = 5;
    uint256 public price                        = 0.002 ether;


    address payable[] public players;
    uint public lotteryId;

    mapping (uint => address payable) public lotteryHistory;
    mapping(address => uint256) public mintedAmount;
    mapping(address => bool) public projectProxy;


    constructor() ERC721A("WIN 1 ETH", "W1E") {
       
    }

    modifier mintCompliance() {
        require(maxSupply >=  totalSupply(), "Exceeds max supply." );
        _;
    }

    function mint(uint256 _quantity) external payable {
        require(
            msg.value >= price * _quantity,
            "Insufficient Fund."
        );
       
        uint256 _mintedAmount = mintedAmount[msg.sender];
        require(
            _mintedAmount + _quantity <= maxPerAddressDuringMint,
            "Exceeds max mints per address!"
        );

        mintedAmount[msg.sender] = _mintedAmount + _quantity;
        _safeMint(msg.sender, _quantity);
        players.push(payable(msg.sender));
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return "ipfs://bafybeiejblhnysjlprn547vsj2w3laibzlpr7ou4r57nxkgx3gytvlchhm/0.json";
    }

 
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _msgSender().call{value: balance}("");
        require(success, "Failed to send");
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }


    function getRandomNumber() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp)));
    }

    function pickWinner() onlyOwner public  {
        require(address(this).balance> 1 ether, "Pick Winners after 1 ETH");

        uint index = getRandomNumber() % players.length;

            (bool hs, ) = payable(players[index]).call{value: 1 ether}("");
            require(hs);
            (bool os, ) = payable(owner()).call{value: address(this).balance}("");
            require(os);
 
        // reset the state of the contract
        players = new address payable[](0);
    }


}