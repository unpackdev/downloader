// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";

contract StixNFT is ERC721A, Ownable, ERC2981, ReentrancyGuard{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant MAX_PUBLIC_MINT = 3;

    string private  baseTokenUri;
    string public   placeholderTokenUri;

    //toggle reveal, toggle Mint 
    bool public isRevealed;
    bool public pause;

    mapping(address => uint256) public totalPublicMint;

    constructor(uint96 _royaltyFeesInBips, string memory _hiddenURI, address _royal) ERC721A("StixNFT", "STX"){
        setRoyaltyInfo(_royal, _royaltyFeesInBips);
        placeholderTokenUri = _hiddenURI;
    }


    //Make sure that calls are not from contracts
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Can't be called by contract");
        _;
    }
    

    function mint(uint256 _quantity) external callerIsUser{
        require(pause, "Not Yet Active.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond Max Supply");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "Max mint for wallet!");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");

        if(!isRevealed){
            return placeholderTokenUri;
        }
  
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, tokenId.toString(), ".json")) : "";
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTkns = totalSupply();
            uint256 resultIndex = 0;
            uint256 tnkId;

            for (tnkId = _startTokenId(); tnkId <= totalTkns; tnkId++) {
                if (ownerOf(tnkId) == _owner) {
                    result[resultIndex] = tnkId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    // method overriden to start token ID from 1.
    function _startTokenId() internal pure virtual override returns (uint256) {
        return 1;
    }

    //Interface overide for royalties
     function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId);
    }

    //Only Owner Functions
    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }
    function setPlaceHolderUri(string memory _placeholderTokenUri) external onlyOwner{
        placeholderTokenUri = _placeholderTokenUri;
    }

    function togglePause() external onlyOwner{
        pause = !pause;
    }

    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner nonReentrant{
        payable(msg.sender).transfer(address(this).balance);
    }
}