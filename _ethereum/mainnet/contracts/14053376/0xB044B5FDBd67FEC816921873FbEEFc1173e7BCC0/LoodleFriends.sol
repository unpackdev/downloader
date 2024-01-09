//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";
 
contract LoodleFriends is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;
    uint public MAX_TOKENS = 5000;
    uint public FREE_TOKENS = 500;
    uint public MAX_TOKENS_PER_SALE = 20;
    uint public price = 19000000 gwei;
    string private ipfsCID;
    bool public paused = true;
 
    constructor (string memory _ipfsCID) ERC721 ("Loodle Friends", "LLF"){
        ipfsCID = _ipfsCID;
    }
 
    function totalSupply() public view returns(uint) {
        return tokenIds.current();
    }
 
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        return string(abi.encodePacked("ipfs://", ipfsCID, "/", Strings.toString(tokenId), ".json"));
    }
 
    function toggleMinting() public onlyOwner {
        paused = !paused;
    }
 
    function createCollectible(uint256 _amount) public payable {
        require(!paused, "Minting is paused!");
        require(MAX_TOKENS > _amount + tokenIds.current() + 1, "All the tokens are sold out!");
        require(_amount > 0 && _amount < MAX_TOKENS_PER_SALE + 1, string(abi.encodePacked("You can buy max ",  Strings.toString(MAX_TOKENS_PER_SALE), " tokens per transaction.")));
        if (tokenIds.current() + _amount > FREE_TOKENS) {
            require(msg.value >= price * _amount, string(abi.encodePacked("Not enough ETH! At least ", Strings.toString(price*_amount), " wei has to be sent!")));
        }
        for(uint256 i=0; i < _amount; i++) {
            tokenIds.increment();
            uint256 newItemId = tokenIds.current();
            _safeMint(msg.sender, newItemId);
        }
    }
 
    function withdraw() external payable onlyOwner() {
        (bool success, ) = payable(owner()).call{value:address(this).balance}("");
        require(success, "Withdrawal failed!");
    }
}
