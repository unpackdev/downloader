// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Bubblemates is ERC721A, Ownable{
    using Strings for uint256;

    string private  baseTokenUri;
    string public   placeholderTokenUri;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant PUBLIC_SALE_PRICE = .08 ether;


 
    bool public isRevealed;
    bool public pause;


    mapping(address => uint256) public totalPublicMint;

    constructor(
    string memory _initBaseURI,
    string memory _initNotRevealedUri

    ) ERC721A("Bubblemates", "BM"){
    setTokenUri(_initBaseURI);
    setPlaceHolderUri(_initNotRevealedUri);
    _safeMint(0x810B01e9c512A08013C4F3aeA8B63e458E7B1D29,4);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Bubblemates :: Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Bubblemates :: Beyond Max Supply");
        require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "Bubblemates :: Below ");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;

        if(!isRevealed){
            return placeholderTokenUri;
        }
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

    function setTokenUri(string memory _baseTokenUri) public onlyOwner{
        baseTokenUri = _baseTokenUri;
    }
    function setPlaceHolderUri(string memory _placeholderTokenUri) public onlyOwner{
        placeholderTokenUri = _placeholderTokenUri;
    }

    function togglePause() public onlyOwner{
        pause = !pause;
    }


    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner{
        uint256 withdrawAmount_10 = address(this).balance * 10/100;
        payable(0xeA8AFEB29a8f3BBbd9de7792D117024e31884e93).transfer(withdrawAmount_10);
        payable(0x810B01e9c512A08013C4F3aeA8B63e458E7B1D29).transfer(address(this).balance);
    }
}