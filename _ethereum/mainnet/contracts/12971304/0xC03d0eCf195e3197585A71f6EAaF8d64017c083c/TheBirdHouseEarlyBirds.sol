// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract TheBirdHouseEarlyBirds is ERC721Enumerable, Ownable {
    mapping(uint256 => string) ArtTokens;
    mapping(uint256 => uint256) TokenToArtToken;
    mapping(address => bool) HasClaimed;
    mapping(address => bool) CanClaim;

    string currentContractURI = "https://fqaebjmuhoho4btu4jvfxhh5q5nkniozjhkz4pzfthn7lwunjluq.arweave.net/LABApZQ7ju4GdOJqW5z9h1qmodlJ1Z4_JZnb9dqNSuk";

    constructor() ERC721("TheBirdHouse: Early Birds", "EarlyBird") {}

    function addArtwork(uint256 newArtId, string memory newTokenURI)
        public
        onlyOwner
    {
        ArtTokens[newArtId] = newTokenURI;
    }

    function getArtworkForId(uint256 artId)
        public
        view
        returns (string memory)
    {
        require(bytes(ArtTokens[artId]).length > 0, "Art Token must exist!");
        return ArtTokens[artId];
    }

    function claim(uint256 artId) public {
        require(bytes(ArtTokens[artId]).length > 0, "Art Token must exist!");
        require(
            CanClaim[msg.sender] == true,
            "Only users that have been selected can claim!"
        );
        require(
            HasClaimed[msg.sender] == false,
            "Only users that have not yet claimed can claim!"
        );

        uint256 newItemId = totalSupply() + 1;

        _mint(msg.sender, newItemId);

        TokenToArtToken[newItemId] = artId;

        HasClaimed[msg.sender] = true;

        return;
    }

    
    function changeContractURI(string memory newContractURI)
        public 
        onlyOwner 
        returns (string memory)
    {
        currentContractURI = newContractURI;
        return (currentContractURI);
    }

    function addAllowedUsers(address[] memory users) public onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            CanClaim[users[i]] = true;
        }
    }

    function removeAllowedUsers(address[] memory users) public onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            CanClaim[users[i]] = false;
        }
    }

    function isAddressAllowed(address userAddress) public view  returns (bool){
        return CanClaim[userAddress];
    }

    function hasAddressClaimed(address userAddress) public view  returns (bool){
        return HasClaimed[userAddress];
    }

    
    function contractURI() public view returns (string memory) {
        return currentContractURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent artwork!"
        );

        return ArtTokens[TokenToArtToken[tokenId]];
    }
}
