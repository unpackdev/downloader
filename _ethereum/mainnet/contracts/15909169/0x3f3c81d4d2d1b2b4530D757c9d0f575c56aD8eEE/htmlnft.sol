// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;

// import some OpenZeppelin Contracts.
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./console.sol";

// import "./Base64.sol";

contract htmlnft is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public owner;

    event NewDance(string dancedata);

    constructor() ERC721 ("Disco Dance", "DISCODANCE") {
        owner = msg.sender;
     }

    function generateDance(string memory _dancedata) public payable{
        require(msg.value == 0.02 ether, "Need to send exactly 0.01 ether");
        uint256 newItemId = _tokenIds.current();

        // Actually mint the NFT to the sender using msg.sender.
        _safeMint(msg.sender, newItemId);

        // Set the NFTs data.
        _setTokenURI(newItemId, _dancedata);

        // Increment the counter for when the next NFT is minted.
        _tokenIds.increment();

        emit NewDance(_dancedata);
    }

    function getTotalNFTsMintedSoFar() public view returns (uint256) {
        return _tokenIds.current();
    }


    function withdraw() public onlyOwner{
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner { 
        require(msg.sender == owner, "Sender is not owner");
        _; 
    }
}