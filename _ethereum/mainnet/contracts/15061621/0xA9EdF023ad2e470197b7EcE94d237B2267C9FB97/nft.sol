//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";

import "./Ownable.sol";
import "./Strings.sol";


contract EliteFox is Ownable, ERC721A {
    uint256 constant public MAX_SUPPLY = 2000;

    uint256 public publicPrice = 0.005 ether;

    uint256 constant public PUBLIC_MINT_LIMIT_TXN = 5;
    uint256 constant public PUBLIC_MINT_LIMIT = 10;

    string public revealedURI= "ipfs://QmQeb8KWsd784HHikXauhZC6nCW4gynyNdJsZTbXAr6pGL/";
    
    string public hiddenURI = "ipfs://QmWa2Hy1A2QHHxUtG8bcCFqBnC79CRvALsUTTzrpqDDXVX";

    // OpenSea CONTRACT_URI - https://docs.opensea.io/docs/contract-level-metadata
    string public CONTRACT_URI = "ipfs://QmWa2Hy1A2QHHxUtG8bcCFqBnC79CRvALsUTTzrpqDDXVX";

    bool public paused = false;
    bool public revealed = true;

    bool public freeSale = true;
    bool public publicSale = true;


    address public teamWallet = 0x00Ff0A24FD6Ed6134F3F9C5Ce81958eD1a42c55f;

    mapping(address => bool) public userMintedFree;
    mapping(address => uint256) public numUserMints;

    constructor() ERC721A("Elite Fox Club", "EFC") { }

    /*
private
    */

    // This function is if you want to override the first Token ID# for ERC721A
    // Note: Fun fact - by overloading this method you save a small amount of gas for minting (technically just the first mint)
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }



    /*
public function
    */

    function teamMint(uint256 quantity) public payable mintCompliance(quantity) {
        require(msg.sender == teamWallet, "Team minting only");

        _safeMint(msg.sender, quantity);
    }
    
    function mint(uint256 quantity) external payable mintCompliance(quantity) {
        require(freeSale, "Free sale inactive");
        require(msg.value == 0, "This phase is free");
        require(quantity == 1, "Only 1 free");

        uint256 newSupply = totalSupply() + quantity;
        
        require(newSupply <= 1000, "Not enough free supply");

        require(!userMintedFree[msg.sender], "User max free limit");
        
        userMintedFree[msg.sender] = true;

        if(newSupply == 1000) {
            freeSale = false;
            publicSale = true;
        }

        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable mintCompliance(quantity) {
        require(publicSale, "Public sale inactive");
        require(quantity <= PUBLIC_MINT_LIMIT_TXN, "Quantity too high");

        uint256 price = publicPrice;
        uint256 currMints = numUserMints[msg.sender];
                
        require(currMints + quantity <= PUBLIC_MINT_LIMIT, "User max mint limit");
        require(msg.value >= (price * quantity), "price not enough, 0.005ETH each");


        numUserMints[msg.sender] = (currMints + quantity);

        _safeMint(msg.sender, quantity);
    }

    /*
view function
    */


    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        // Note: You don't REALLY need this require statement since nothing should be querying for non-existing tokens after reveal.
            // That said, it's a public view method so gas efficiency shouldn't come into play.
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        if (revealed) {
            return string(abi.encodePacked(revealedURI, Strings.toString(_tokenId), ".json"));
        }
        else {
            return hiddenURI;
        }
    }

    // https://docs.opensea.io/docs/contract-level-metadata
    // https://ethereum.stackexchange.com/questions/110924/how-to-properly-implement-a-contracturi-for-on-chain-nfts
    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    /*
owner function
     */



    function setPublicPrice(uint256 _publicPrice) public onlyOwner {
        publicPrice = _publicPrice;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        revealedURI = _baseUri;
    }

    // Note: This method can be hidden/removed if this is a constant.
    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenURI = _hiddenMetadataUri;
    }

    function revealCollection(bool _revealed, string memory _baseUri) public onlyOwner {
        revealed = _revealed;
        revealedURI = _baseUri;
    }

    // https://docs.opensea.io/docs/contract-level-metadata
    function setContractURI(string memory _contractURI) public onlyOwner {
        CONTRACT_URI = _contractURI;
    }

    // Note: Another option is to inherit Pausable without implementing the logic yourself.
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol
    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setPublicEnabled(bool _state) public onlyOwner {
        publicSale = _state;
        freeSale = !_state;
    }
    function setFreeEnabled(bool _state) public onlyOwner {
        freeSale = _state;
        publicSale = !_state;
    }

    function setTeamWalletAddress(address _teamWallet) public onlyOwner {
        teamWallet = _teamWallet;
    }

    function withdraw() external payable onlyOwner {
        // Withdraw the ENTIRE remaining balance to the team wallet
        (bool succ, ) = payable(teamWallet).call{
            value: address(this).balance
        }("");
        require(succ, "Team (remaining) transfer failed");
    }

    modifier mintCompliance(uint256 quantity) {
        require(!paused, "Contract is paused");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough mints left");
        require(tx.origin == msg.sender, "No contract minting");
        _;
    }
}