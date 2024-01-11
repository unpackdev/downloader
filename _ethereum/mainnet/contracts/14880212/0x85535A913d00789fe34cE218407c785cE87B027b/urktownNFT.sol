//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract urktownNFT is ERC721A, Ownable, ReentrancyGuard{
    using Strings for uint256;

    string private _baseTokenURI;

    uint256 public MAX_SUPPLY = 10000;

    uint256 public MAX_TOKENS_PER_MINT = 15;

    uint256 public MAX_MINT_WALLET = 15;

    bool public minstatus = false;
    
    bool public rev = false;

    mapping(address => uint256) public howmanyurks;

    //modifiers
    modifier onlyOrigin() {
        // disallow access from contracts
        require(msg.sender == tx.origin, "Come on!!!");
        _;
    }

    constructor(string memory baseURI_) ERC721A("Urk Town", "URK") {
        _baseTokenURI = baseURI_;
    }

    function contractURI() public view returns (string memory) {
       string memory baseURI = _baseURI();
       return string(abi.encodePacked(baseURI, 'contract.json'));
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        if(rev){
        return string(abi.encodePacked(baseURI, tokenId.toString(),'.json'));
        }else {
        return string(abi.encodePacked(baseURI, 'undisclosed.json'));
        }
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI, bool _rev) external onlyOwner {
        _baseTokenURI = baseURI;
        rev = _rev;
    }

    function makeUrk(uint256 _urks) external nonReentrant onlyOrigin {
        require(minstatus,'Mint not started');
        require(totalSupply() + _urks < MAX_SUPPLY +1, "Max supply exceeded!");
        require(_urks < MAX_TOKENS_PER_MINT + 1, "Tx Limit!");
        require(howmanyurks[msg.sender] + _urks < MAX_MINT_WALLET +1);
        _safeMint(msg.sender, _urks);
        howmanyurks[msg.sender] += _urks;
    }

    function makeurksfly(address lord, uint256 _urks) external onlyOwner {
  	    require(totalSupply() + _urks < MAX_SUPPLY +1, "Max supply exceeded!");
        _safeMint(lord, _urks);
    }

    function setMintStatus(bool _minstatus) external onlyOwner {
        minstatus = _minstatus;
    }

}