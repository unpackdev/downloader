// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract GrumpyHedgehogs is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 2222;
    uint256 public constant MAX_PUBLIC_MINT = 5;
    string private  baseTokenUri;

    bool public pause=true;
    bool public teamMinted;

    mapping(address => uint256) public totalPublicMint;

    constructor() ERC721A("Grumpy Hedgehog Society", "GHS"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external callerIsUser{
        require(pause==false,"Minting hasn't started yet.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "We are out of Hedgies :(");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "Limit exceeds max amount.");
        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }


    function teamMint() external onlyOwner{
        require(!teamMinted, "Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, 17);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;

        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    /// @dev walletOf() function shouldn't be called on-chain due to gas consumption
    function walletOf() external view returns(uint256[] memory){
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for(uint256 index = 0; index < numberOfOwnedNFT; index++){
            ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }
    
    function togglePause() external onlyOwner{
        pause = !pause;
    }



    function withdraw() external onlyOwner{
        //35% to utility/investors wallet
        uint256 withdrawAmount = address(this).balance;
        payable(0x0fffFD62CcCB458faE551Be0EF1058EF854d1808).transfer(withdrawAmount);
        payable(msg.sender).transfer(address(this).balance);
    }

    function count() public view returns (uint256) {
        uint256 numberOfOwnedNFT = balanceOf(msg.sender);
        return numberOfOwnedNFT;
    }

}