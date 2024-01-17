// SPDX-License-Identifier: MIT

// Terms:
// By claiming or purchasing a y4rf you are
// acquiring the art itself: nothing more, nothing less.
// Owners have full commercial rights to their y4rf(s)
// and their respective assets.


pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract Y4rfs is ERC721A, Ownable {
    uint256 public constant max_supply = 4444;
    uint256 public constant max_mint = 2;
    uint256 public constant cost_two = 0.02 ether;
    string public token_uri = '';
    bool public sale_live = false;
    bool public reserved = false;
    address public team_address = 0x68F27cCBf0124f75fd64C16b84a4a28FCeE349Ca;

    constructor() ERC721A("y4rfs", "Y4RF") {}

    function openYarfs() external onlyOwner {
        require(!sale_live);
        sale_live = true;
    }

    function reserveYarfs() external onlyOwner {
        require(!reserved, "y4rfs already reserved!");
        _safeMint(msg.sender, 44);
        reserved = true;
    }
    
    function mint(uint256 amount) external payable {
        require(sale_live, "y4rf season hasn't started!");
        require(amount > 0, "Can't mint negative y4rfs!");
        require(_numberMinted(msg.sender) + amount <= max_mint, "only two y4rfs per wallet!");
        require(totalSupply() + amount <= max_supply, "chill on the y4rfs!");
        if (max_mint - amount - _numberMinted(msg.sender) == 0) {
            require(msg.value >= cost_two, "second y4rf costs 0.02 ETH!");
        }
        _safeMint(msg.sender, amount);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return token_uri;
    }

    function setURI(string calldata nuri) external virtual onlyOwner {
        token_uri = nuri;
    }

    function withdrawAll() external onlyOwner {
        payable(team_address).transfer(address(this).balance);
    }

    function withdrawOwner() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setTeamAddress (address nuaddress) external onlyOwner {
        team_address = nuaddress;
    }
}