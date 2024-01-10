//SPDX-License-Identifier: MIT

/*
 
██╗░░██╗███████╗██████╗░░█████╗░  ███████╗██╗░░░██╗████████╗██╗░░░██╗██████╗░███████╗
╚██╗██╔╝██╔════╝██╔══██╗██╔══██╗  ██╔════╝██║░░░██║╚══██╔══╝██║░░░██║██╔══██╗██╔════╝
░╚███╔╝░█████╗░░██████╔╝██║░░██║  █████╗░░██║░░░██║░░░██║░░░██║░░░██║██████╔╝█████╗░░
░██╔██╗░██╔══╝░░██╔══██╗██║░░██║  ██╔══╝░░██║░░░██║░░░██║░░░██║░░░██║██╔══██╗██╔══╝░░
██╔╝╚██╗███████╗██║░░██║╚█████╔╝  ██║░░░░░╚██████╔╝░░░██║░░░╚██████╔╝██║░░██║███████╗
╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝░╚════╝░  ╚═╝░░░░░░╚═════╝░░░░╚═╝░░░░╚═════╝░╚═╝░░╚═╝╚══════╝                                                                                                                                                                                                                                     

*/

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Pausable.sol";
import "./MerkleProof.sol";
import "./Counters.sol";



contract XeroFuture is Ownable, ERC721Enumerable, ERC721Pausable {

    using Counters for Counters.Counter;

    event CardsClaimed(uint _totalClaimed, address indexed _owner, uint _numOfTokens, uint[] _tokenIds);

    Counters.Counter private _tokenIdTracker;
    
    
    string public metadataBaseURL;
    bool public claimEnabled;
    bool public wlclaimEnabled;
    uint public price;
    uint public maxCardsInTx;
    uint public maxCards;
    bytes32 public root;

    constructor (
        string memory _metadataBaseURL, 
        bytes32 _merkleroot
        ) 
        ERC721("Xero Future", "XF") {
            metadataBaseURL = _metadataBaseURL;
            root = _merkleroot;
            
            claimEnabled = false;
            wlclaimEnabled = false;
            price = 0.03 ether;
            maxCards = 6969;
            maxCardsInTx = 22;
    }

    function setBaseURI(string memory baseURL) public onlyOwner {
        metadataBaseURL = baseURL;
    }

    function flipClaimEnabled() public onlyOwner {
        claimEnabled = !(claimEnabled);
    }

    function flipWLClaimEnabled() public onlyOwner {
        wlclaimEnabled = !(wlclaimEnabled);
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setMaxCards(uint _numOfCards) public onlyOwner {
        maxCards = _numOfCards;
    }

    function setMaxCardsInTx(uint _numOfCards) public onlyOwner {
        maxCardsInTx = _numOfCards;
    }

    function setRoot(bytes32 _merkleroot) public onlyOwner {
        root = _merkleroot;
    }

    function withdraw() public onlyOwner {
        uint _balance = address(this).balance;
        address payable _sender = payable(_msgSender());
        _sender.transfer(_balance);
    }

    function mintCardToAddress(address to) public onlyOwner {
        require(_tokenIdTracker.current() < maxCards, "Xero: All cards have already been claimed");
        _safeMint(to, _tokenIdTracker.current() + 1);
        _tokenIdTracker.increment();
    }

    function reserveCards(uint num) public onlyOwner {
        uint i;
        for (i=0; i<num; i++)
            mintCardToAddress(msg.sender);
    }

    function pause() public virtual onlyOwner {
        _pause();
    }

    function unpause() public virtual onlyOwner {
        _unpause();
    }

    function _mint(uint numOfTokens) internal {

        uint256[] memory ids = new uint256[](numOfTokens);
        for(uint i=0; i<numOfTokens; i++) {
            uint256 _tokenid = _tokenIdTracker.current() + 1;
            ids[i] = _tokenid;
            _safeMint(msg.sender, _tokenid);
            _tokenIdTracker.increment();
        }

        emit CardsClaimed(_tokenIdTracker.current(), msg.sender, numOfTokens, ids);
    }

    function mintCard(uint numOfTokens) payable public {

        require(claimEnabled, "Xero: Cannot claim card at the moment");
        require(_tokenIdTracker.current() + numOfTokens <= maxCards, "Xero: Claim will exceed maximum available cards");
        require(numOfTokens > 0, "Xero: Must claim atleast one card");
        require(numOfTokens <= maxCardsInTx, "Xero: Cannot claim these many cards in one tx");
        require(msg.value >= (price * numOfTokens), "Xero: Insufficient funds to claim cards");

        _mint(numOfTokens);        
        
    }

    function whitelistMintCard(uint numOfTokens, bytes32[] memory proof) payable public {

        require(wlclaimEnabled, "Xero: Cannot whitelist claim card at the moment");
        require(_verify(msg.sender, proof), "Xero: Wallet is not whitelisted");
        
        require(_tokenIdTracker.current() + numOfTokens <= maxCards, "Xero: Claim will exceed maximum available cards");
        require(numOfTokens > 0, "Xero: Must claim atleast one card");
        require(numOfTokens <= maxCardsInTx, "Xero: Cannot claim more than 10 cards in one tx");
        require(msg.value >= (price * numOfTokens), "Xero: Insufficient funds to claim cards");

        _mint(numOfTokens);

    }

    function _verify(address _account, bytes32[] memory proof)
    internal view returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_account));
        return MerkleProof.verify(proof, root, leaf);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataBaseURL;
    }

    function _beforeTokenTransfer(
        address from, 
        address to, 
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Enumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}