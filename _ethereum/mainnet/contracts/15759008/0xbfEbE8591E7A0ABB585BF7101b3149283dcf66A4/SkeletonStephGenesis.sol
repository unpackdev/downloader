// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.6;

import "./ERC721URIStorage.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./base64.sol";

contract SkeletonStephGenesis is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;
    uint256 public totalMint = 2100;
    uint256 public stephReserve = 37;
    uint256 public price = 0.076 ether;
    bool public isPresale = true;
    bool public canUpdateMetadata = true;
    string public IMGURL = "https://sekerfactory.mypinata.cloud/ipfs/QmbFbb6uPWwFVwCTBRkgK7M67q3tppWv2ymmPTtFTGfYZ4/";
    address public FanboyPass = address(0x7d8d00dA54cB04cF725CD466a6813aF198cE41A1);

    mapping(uint256 => bool) public claimed;

    constructor() ERC721("Skeleton Steph Genesis", "Genesis") {}

    function allowlistMint(uint256 _amount, uint256[] memory _ids) public payable {
        require(isPresale, "presale has ended");
        require(_amount == _ids.length, "mint amount and number of IDs mismatch");
        for (uint256 i; i < _ids.length; i++) {
            require(IERC721(FanboyPass).ownerOf(_ids[i]) == msg.sender, "minter does not own an id");
            require(claimed[_ids[i]] == false, "id has already been claimed");
            claimed[_ids[i]] = true;
        }
        require(msg.value == price * _amount, "incorrect eth amount");
        for (uint256 i; i < _ids.length; i++) {
            uint256 newNFT = _tokenIds.current();
            _safeMint(msg.sender, newNFT);
            _tokenIds.increment();
        }
    }

    function mint(uint256 _amount) public payable {
        require(!isPresale, "public mint has not begun");
        require(
            (Counters.current(_tokenIds) + _amount) <= totalMint,
            "minting has reached its max"
        );
        require(msg.value == price * _amount, "Incorrect eth amount");
        for (uint256 i; i < _amount; i++) {
            uint256 newNFT = _tokenIds.current();
            _safeMint(msg.sender, newNFT);
            _tokenIds.increment();
        }
    }

    // Owner functions

    function mintSteph(uint256 _amount) public onlyOwner {
        require(
            (Counters.current(_tokenIds) + _amount) <= totalMint,
            "minting has reached its max"
        );
        for (uint256 i; i < _amount; i++) {
            require(stephReserve > 0, "steph reserve fully minted");
            uint256 newNFT = _tokenIds.current();
            _safeMint(msg.sender, newNFT);
            _tokenIds.increment();
            stephReserve--;
        }
    }

    function startPublicMint() public onlyOwner {
        isPresale = false;
    }

    function setFanboyPassAddress(address _newAddress) public onlyOwner {
        FanboyPass = _newAddress;
    }

    function updateTokenURI(string memory _newURI) public onlyOwner {
        require(canUpdateMetadata, "metadata updates have been burned");
        IMGURL = _newURI;
    }

    function updateTotalMint(uint256 _newSupply) public onlyOwner {
        require(_newSupply > _tokenIds.current(), "new supply less than already minted");
        totalMint = _newSupply;
    }

    function updatePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function burnMetadataUpdate() public onlyOwner {
        canUpdateMetadata = false;
    }

    // Utility functions

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "Clearance Cards: URI query for nonexistent token"
        );
        return string(abi.encodePacked(IMGURL, tokenId.toString(), ".json"));
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    // Withdraw
    function withdraw(address payable withdrawAddress)
        external
        payable
        onlyOwner
    {
        require(
            withdrawAddress == owner(),
            "can only withdraw to the owner"
        );
        require(address(this).balance >= 0, "Not enough eth");
        (bool sent, ) = withdrawAddress.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}