//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "./IERC20.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
// import "./console.sol";


contract AngryHaresERC721 is ERC721Enumerable, Ownable {
    enum ContractState { PAUSED, PUBLIC }
    ContractState public state = ContractState.PAUSED;
    event StateChanged(ContractState newState);

    string public baseURI;
    uint256 public maxHares = 5000;
    uint256 public harePrice = 0.08 ether;

    constructor() ERC721("Angry Hares", "AH") {}

    function setState(ContractState state_) public onlyOwner {
        state = state_;
        emit StateChanged(state_);
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setHarePrice(uint256 harePrice_) public onlyOwner {
        harePrice = harePrice_;
    }

    function mint(uint256 numberOfTokens) public payable {
        require(state == ContractState.PUBLIC, "Public minting is not open");
        require(numberOfTokens <= 10, "Can only mint 10 tokens at a time");
        require(totalSupply() + numberOfTokens <= maxHares, "Purchase would exceed max supply of Hares");
        require(harePrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply() + 1;  // start from 1
            if (totalSupply() < maxHares) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

}
