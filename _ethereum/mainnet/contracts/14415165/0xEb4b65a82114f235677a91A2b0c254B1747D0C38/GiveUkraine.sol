// SPDX-License-Identifier: GPL-3.0
// 
// 🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦
//
//        Made with ❤️ for Ukraine 
//    Hope to support in their fight 🆘
//  
// 🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦🇺🇦
//
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC721.sol";

contract GiveUkraineOrg is ERC721, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // Private variables
    Counters.Counter private _tokenSupply;
    string private _contractURI;

    // Constants
    address public constant UKRAINE_DONATION_ADDRESS = 0x165CD37b4C644C2921454429E7F9358d18A45e14;
    uint256 public constant MAX_SUPPLY = 24891;
    uint256 public constant MAX_GIFTS = 42;
    uint256 public constant MIN_DONATION_PER_NFT = 0.024081991 ether;
    string public constant BASE_EXTENSION = ".json";

    // We will reveal the collection in batches to avoid making all the donars wait till full mint
    // 4200 NFTs per batch except the first and last batch
    string[6] public baseURIs;
    bool[6] public revealed = [false, false, false, false, false, false];
    bool uriFrozen = false;
    string public notRevealedURI;
    uint256 public giftedAmount = 0;

    constructor(string memory _initContractURI, string memory _initNotRevealedURI) ERC721("Give Ukraine Org", "GIVEUA") {
        setContractURI(_initContractURI);
        setNotRevealedURI(_initNotRevealedURI);
    }

    /////////////////////////////////
    //      Private & Internal
    /////////////////////////////////
    function _batchId(uint256 tokenId) internal pure returns (uint256) {
        return tokenId.div(4200);
    }

    function _safeMint(address _to) private {
        _tokenSupply.increment();
        _safeMint(_to, _tokenSupply.current());
    }
    
    modifier withinSupply(uint256 mintAmount) {
        require(mintAmount > 0, "Mint at least 1!");
        require(_tokenSupply.current() + mintAmount <= MAX_SUPPLY, "Exceeds max supply!");
         _;
    }

    modifier costs(uint256 mintCost) {
        require(msg.value >= mintCost, "Not enough ETH to mint!");
        _;
    }

    modifier legalBatch(uint256 batch) {
        require(batch >= 0, "Batch number must be 0 or higher!");
        require(batch < baseURIs.length, "Batch number overflow!");
        _;
    }

    modifier urlMutable() {
        require(!uriFrozen, "URIs are frozen. Can't update.");
        _;
    }

    /////////////////////////////////
    //          Public
    /////////////////////////////////

    /**
     * @dev I want to donate and mint NFTs...
     */
    function donateAndMint(uint256 _mintAmount) 
        public 
        payable
        withinSupply(_mintAmount) 
        costs(MIN_DONATION_PER_NFT * _mintAmount)
    {
        if (address(this).balance >= 3 ether) {
            donate();
        }

        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender);
        }
    }

    /**
     * @dev Lock in royalties to Ukraine address
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Show me the NFT
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist!");
        uint256 batchId = _batchId(tokenId);
        
        if (revealed[batchId] == false) {
            return notRevealedURI;
        }

        string memory batchBaseURI = baseURIs[batchId];
        return bytes(batchBaseURI).length > 0
            ? string(abi.encodePacked(batchBaseURI, tokenId.toString(), BASE_EXTENSION))
            : "";
    }

    /**
     * @dev I wonder how many GiveUAs are left?
     */
    function remainingSupply() public view returns (uint256) {
        return MAX_SUPPLY - _tokenSupply.current();
    }

    /**
     * @dev I wonder how many GiveUAs are minted?
     */
    function tokenSupply() public view returns (uint256) {
        return _tokenSupply.current();
    }
    
    /** 
     * @dev Donate any remaining balance to Ukraine...❤️
     */
    function donate() public payable {
        (bool os, ) = payable(UKRAINE_DONATION_ADDRESS).call{value: address(this).balance}("");
        require(os);
    }

    /////////////////////////////////
    //          Owner only
    /////////////////////////////////
    
    /**
     * @dev For the team, early promoters and such. 
     *  - Limited to MAX_GIFTS
     */
    function mintGifts(address[] calldata receivers) 
        public 
        onlyOwner
        withinSupply(receivers.length) 
    {
        require(giftedAmount + receivers.length <= MAX_GIFTS, "Ran out of gift tokens");

        for (uint256 i = 0; i < receivers.length; i++) {
            giftedAmount++;
            _safeMint(receivers[i]);
        }
    }

    /**
     * @dev Meh
     */
    function setNotRevealedURI(string memory _newNotRevealedURI) 
        public 
        onlyOwner
        urlMutable  
    {
        notRevealedURI = _newNotRevealedURI;
    }
    
    /** 
     * @dev Image cart coming through...
     */
    function setBaseURI(uint256 _batch, string memory _newBaseURI) 
        public 
        onlyOwner 
        legalBatch(_batch)
        urlMutable 
    {
        baseURIs[_batch] = _newBaseURI;
        revealed[_batch] = true;
    }

    /**
     * @dev Meh
     */
    function setContractURI(string memory _contractURINew) 
        public 
        onlyOwner
        urlMutable 
    {
        _contractURI = _contractURINew;
    }
    
    /** 
     * @dev Setting things in stone
     */
    function freezeURI() public onlyOwner {
        uriFrozen = true;
    }

}