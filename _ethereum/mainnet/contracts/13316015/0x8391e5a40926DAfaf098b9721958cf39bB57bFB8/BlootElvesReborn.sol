// contracts/BlootElvesReborn.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract BlootElves is ERC721, Ownable {
    using SafeMath for uint256;
    using Strings for string;

    ERC721 bloot = ERC721(0x4F8730E0b32B04beaa5757e5aea3aeF970E5B613);

    uint256 MINT_PER_BLOOT = 2;
    uint256 MAX_SUPPLY = 5000;

    constructor()
        public
        ERC721("BlootElves", "B&Elves")
    {   
    }

    function requestNewBloot(
        uint256 tokenId,
        string memory _tokenURI
    ) public payable {
        // Require the claimer to have at least one bloot from the specified contract
        require(bloot.balanceOf(msg.sender) >= 1, "Need at least one bloot");
        // Set limit to no more than MINT_PER_BLOOT times of the owned bloot
        require(super.balanceOf(msg.sender) < bloot.balanceOf(msg.sender) * MINT_PER_BLOOT, "Purchase more bloot");
        require(super.totalSupply() < MAX_SUPPLY, "Maximum supply reached.");
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    function orginalBalanceOf(address owner) public view returns (uint256) {
        require(msg.sender != address(0), "ERC721: balance query for the zero address");
        return bloot.balanceOf(owner);
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return tokenURI(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _setTokenURI(tokenId, _tokenURI);
    }
}

contract BlootElvesReborn is ERC721, Ownable {
    using SafeMath for uint256;
    using Strings for string;

    ERC721 bloot = ERC721(0x4F8730E0b32B04beaa5757e5aea3aeF970E5B613);
    BlootElves oldElves = BlootElves(0x45c3844Dea2e9Fe9226524411DE6d907188A1a9F);

    uint256 MINT_PER_BLOOT = 2;
    uint256 MAX_SUPPLY = 5000;

    uint256 TOKEN_LIMIT_MIGRATE = 1480;
    uint256 TOKEN_LIMIT_NOTDONATED = 6000;
    uint256 TOKEN_LIMIT_DONATED = 9900;
    uint256 TOKEN_LIMIT_HONORARY = 10000;

    uint256 indexNotDonated = TOKEN_LIMIT_MIGRATE;
    uint256 indexDonated = TOKEN_LIMIT_NOTDONATED;
    uint256 indexHonorary = TOKEN_LIMIT_DONATED;

    bool pauseMint = true;
    bool pauseMigration = true;
    bool isMigrationPaused = true;

    constructor()
        public
        ERC721("BlootElvesReborn", "BlootElvesReborn")
        payable
    {
    }

    function requestNewBloot(
    ) external payable {
        // Require the pauseMint to be false
        require(pauseMint == false, "You are not allowed to mint until the owner lets you.");
        // Require the claimer to have at least one bloot from the specified contract
        require(bloot.balanceOf(msg.sender) >= 1, "Need at least one bloot");
        // Set limit to no more than MINT_PER_BLOOT times of the owned bloot
        require(super.balanceOf(msg.sender) < bloot.balanceOf(msg.sender) * MINT_PER_BLOOT, "Purchase more bloot");
        require(oldElves.balanceOf(msg.sender) == 0, "Migrate and Burn first");
        require(super.totalSupply() + oldElves.totalSupply() - oldElves.balanceOf(address(oldElves)) < MAX_SUPPLY, "Maximum supply reached.");
        require(msg.value == 0 || msg.value == 10000000000000000 || msg.value == 40000000000000000 || msg.value == 500000000000000000, "Invalid donation.");

        require(bytes(baseURI()).length != 0, "No baseURI, please wait");

        uint256 tokenId;
        if (msg.value == 0) {
            indexNotDonated = indexNotDonated + 1;
            tokenId = indexNotDonated;
        }
        else if (msg.value == 10000000000000000 || msg.value == 40000000000000000) {
            indexDonated = indexDonated + 1;
            tokenId = indexDonated;
        }
        else if (msg.value == 500000000000000000) {
            indexHonorary = indexHonorary + 1;
            tokenId = indexHonorary;
        }

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uint2str(tokenId));
    }

    function migrate(uint[] calldata _newIDs) external {
        // Require the pauseMigration to be false
        require(pauseMigration == false, "You are not allowed to migrate until the owner lets you.");
        require(oldElves.balanceOf(msg.sender) >= _newIDs.length, "Elv count mismatch");
        require(bytes(baseURI()).length != 0, "No baseURI, please wait");

        for(uint i = 0; i < _newIDs.length; i++) {
            require(_newIDs[i] < TOKEN_LIMIT_MIGRATE, "illegal try");
            _safeMint(msg.sender, _newIDs[i]);

            _setTokenURI(_newIDs[i], uint2str(_newIDs[i]));
            oldElves.setTokenURI(oldElves.tokenOfOwnerByIndex(msg.sender, 0), "https://gateway.pinata.cloud/ipfs/QmY6Jgz4o4YJqbPbtQjsBQdVAJwP8ECBCUqVrAJgwCYjkc");
            oldElves.transferFrom(msg.sender, address(oldElves), oldElves.tokenOfOwnerByIndex(msg.sender, 0));
        }
    }

    function setPauseMint(bool _pauseMint) external onlyOwner {
        pauseMint = _pauseMint;
    }

    function setPauseMigration(bool _pauseMigration) external onlyOwner {
        pauseMigration = _pauseMigration;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function setTokenURIs(uint256[] calldata tokenIDs, uint256[] calldata tokenURIs, uint256 len) external onlyOwner {
        for (uint256 i = 0; i < len; i++)
            _setTokenURI(tokenIDs[i], uint2str(tokenURIs[i]));
    }

    function orginalBalanceOf(address blootOwner) external view returns (uint256) {
        return bloot.balanceOf(blootOwner);
    }

    function getOldElfTokenID(address oldElfOwner) external view returns (uint256) {
        try oldElves.tokenOfOwnerByIndex(oldElfOwner, 0) returns (uint256 tokenID) {
            return (tokenID);
        } catch Error(string memory /*reason*/) {
            return 0;
        }
    }

    function currentHonorary() external view returns (uint256) {
        uint256 sum = indexHonorary - TOKEN_LIMIT_DONATED;
        return sum;
    }

    // Function to withdraw all Ether from this contract.
    function withdraw() external onlyOwner{
        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}