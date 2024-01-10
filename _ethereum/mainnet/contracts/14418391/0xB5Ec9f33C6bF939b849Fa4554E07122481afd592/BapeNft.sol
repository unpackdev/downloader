// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./Base64.sol"; 

contract BabyApePrimeEvolution is ReentrancyGuard,Ownable,ERC721URIStorage {
    struct NFTMinter{
        address minterAddress;
        uint256 numberOfMintAvailable;
        uint256 mintedNfts;
    }

    struct NFT{
        uint256 tokenID;
        address creator;
        string tokenURI;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;
    mapping(string => uint256) public hashes;
    mapping(uint256 => string) public _tokenURIs;
    mapping(uint256=>NFT) public NFTs;

    bool public isPresaleActive = false;
    bool public isPublicSaleAvailable = false;
    mapping(address=>NFTMinter) public nftMinters;
    uint256 public price = 0.15 ether;
    uint256 public whitelistedPrice = 0.12 ether;
    uint256 public staffPrice = 0.00 ether;

    uint256 public teamPrice=0;
    uint256 public whiteListAmount=4;
    uint256 public ogListAmount=4;
    uint256 public maxSupply = 8888;
    
    uint256 private TOTAL_PERC=10000;
    
    uint256 public benificiaryOnePerc = 3885;
    uint256 public benificiaryTwoPerc = 3885;
    uint256 public benificiaryThreePerc = 2230;

    mapping(address=>uint256) public ogList;
    mapping(address=>uint256) public whitelist;
    mapping(address=>uint256) public teamList;

    address payable beneficiaryOne; // add setter
    address payable beneficiaryTwo; // add setter
    address payable beneficiaryThree; // add setter

    string public baseURI;
    
    constructor(
        address payable _benificiaryOne,
        address payable _benificiaryTwo, 
        address payable _benificiaryThree,
        string memory _baseURI
        ) ERC721("Baby Ape Prime Evolution", "(B.A.P.E)") {
        beneficiaryOne = _benificiaryOne;
        beneficiaryTwo = _benificiaryTwo;
        beneficiaryThree = _benificiaryThree;
        baseURI = _baseURI;
    }

    modifier onlyBenificiaries{
        require(
            beneficiaryOne==msg.sender ||
            beneficiaryTwo==msg.sender ||
            beneficiaryThree==msg.sender
            ,"Only benificiaries are allowed for this method");
        _;
    }

    function createNFT(
        string memory hash,
        string memory metadata
    ) public payable returns (uint256) {
        require(hashes[hash] != 1, "Already Known this NFT");
        require(
            isPublicSaleAvailable ||
             (isPresaleActive && nftMinters[msg.sender].numberOfMintAvailable>0),
             "You are not allowed");

        require(_tokenId.current()<maxSupply,"Max supply is reached");

        uint256 _nftPrice = price;

        if(whitelist[msg.sender]>0){
            _nftPrice = whitelistedPrice;
        }
        if(ogList[msg.sender]>0){
            _nftPrice = staffPrice;
        }
        if(teamList[msg.sender]>0){
            _nftPrice = teamPrice;
        }

        require(msg.value>=_nftPrice,"Invalid value");

        if(isPresaleActive && !isPublicSaleAvailable){
            nftMinters[msg.sender].numberOfMintAvailable--;
        }
        if(whitelist[msg.sender]>0){
            whitelist[msg.sender]--;
        }
        if(ogList[msg.sender]>0){
            ogList[msg.sender]--;
        }
        if(teamList[msg.sender]>0){
            teamList[msg.sender]--;
        }

        hashes[hash] = 1;

        _tokenId.increment();

        uint256 newItemId = _tokenId.current();

        _mint(msg.sender, newItemId);

        _setTokenURI(newItemId, metadata);

        NFTs[newItemId] = NFT({
            tokenID:newItemId,
            creator:msg.sender,
            tokenURI:metadata
        });

        return newItemId;
    }

function tokenURI(uint256 _id)
        public
        view
        override
        returns (string memory)
    {
        NFT memory nft = NFTs[_id];
        return
            string(abi.encodePacked(baseURI, nft.tokenURI));
    }
    function batchMinting(
        string[] memory hash,
        string[] memory metadata
    )public payable {
        require(hash.length==metadata.length,"Both arguments must be of same length");
        require(
            isPublicSaleAvailable ||
             (isPresaleActive && nftMinters[msg.sender].numberOfMintAvailable>0),
             "You are not allowed");
        require(_tokenId.current()+hash.length<maxSupply,"Max supply exceeded");

        uint256 _nftPrice = price;

        if(whitelist[msg.sender]>0){
            _nftPrice = whitelistedPrice;
        }
        if(ogList[msg.sender]>0){
            _nftPrice = staffPrice;
        }
        if(teamList[msg.sender]>0){
            _nftPrice = teamPrice;
        }

        _nftPrice = _nftPrice * hash.length;

        require(msg.value>=_nftPrice,"Invalid value");

        

        for(uint256 i=0;i<hash.length;i++){
        require(hashes[hash[i]] != 1, "Already Known this NFT");

        if(isPresaleActive && !isPublicSaleAvailable){
            nftMinters[msg.sender].numberOfMintAvailable--;
        }
        if(whitelist[msg.sender]>0){
            whitelist[msg.sender]--;
        }
        if(ogList[msg.sender]>0){
            ogList[msg.sender]--;
        }
        if(teamList[msg.sender]>0){
            teamList[msg.sender]--;
        }

        hashes[hash[i]] = 1;

        _tokenId.increment();

        uint256 newItemId = _tokenId.current();

        _mint(msg.sender, newItemId);

        _setTokenURI(newItemId, metadata[i]);

        NFTs[newItemId] = NFT({
            tokenID:newItemId,
            creator:msg.sender,
            tokenURI:metadata[i]
        });

        
        }
    }

    function batchTransfer(
        address[] memory _receivers,
        uint256[] memory _tokenIds
    ) public {
        require(_receivers.length==_tokenIds.length,"Both arguments must be of same length");
        for(uint256 i=0;i<_receivers.length;i++){
            safeTransferFrom(msg.sender,_receivers[i],_tokenIds[i]);
        }
    }


    function setPresaleSale(bool value) public onlyOwner{
        isPresaleActive = value;
    }

    function setPublicSale(bool value) public onlyOwner{
        isPublicSaleAvailable = value;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner{
        require(_newMaxSupply!=maxSupply,"New Max supply cannot be same with ");
        maxSupply = _newMaxSupply;
    }

    function setWhitelistForPresale(
        address receipentAddress,
        uint256 numberOfMints    
    ) public onlyOwner{
        nftMinters[receipentAddress].numberOfMintAvailable = numberOfMints;
    }

    function addToOgList(address _addr,uint256 _amount) public onlyOwner{
        ogList[_addr] = _amount;
        nftMinters[_addr].numberOfMintAvailable +=_amount;
    }

    function addToWhitelist(address _addr,uint256 _amount) public onlyOwner{
        whitelist[_addr] = _amount;
        nftMinters[_addr].numberOfMintAvailable +=_amount;
    }
    function addToTeamList(address _addr,uint256 _amount) public onlyOwner{
        teamList[_addr] = _amount;
        nftMinters[_addr].numberOfMintAvailable +=_amount;
    }

    function setBenificiaryOne(address payable _newBenificiaryAddress) public onlyOwner {
        require(beneficiaryOne!=_newBenificiaryAddress,"New Beniciary cannot be same with previous Beniciary");
        beneficiaryOne = _newBenificiaryAddress;
    }

    function setBenificiaryTwo(address payable _newBenificiaryAddress) public onlyOwner {
        require(beneficiaryTwo!=_newBenificiaryAddress,"New Beniciary cannot be same with previous Beniciary");
        beneficiaryTwo = _newBenificiaryAddress;
    }

    function setBenificiaryThree(address payable _newBenificiaryAddress) public onlyOwner {
        require(beneficiaryThree!=_newBenificiaryAddress,"New Beniciary cannot be same with previous Beniciary");
        beneficiaryThree = _newBenificiaryAddress;
    }

    function withdraw() public onlyBenificiaries{
        uint256 totalBalance = address(this).balance;
        uint256 benificiaryOneAmount = (totalBalance * benificiaryOnePerc) / TOTAL_PERC;
        uint256 benificiaryTwoAmount = (totalBalance * benificiaryTwoPerc) / TOTAL_PERC;
        uint256 benificiaryThreeAmount = (totalBalance * benificiaryThreePerc) / TOTAL_PERC;
        beneficiaryOne.transfer(benificiaryOneAmount);
        beneficiaryTwo.transfer(benificiaryTwoAmount);
        beneficiaryThree.transfer(benificiaryThreeAmount);
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }


    function setBaseURI(string memory newBaseURI) public onlyOwner{
        baseURI = newBaseURI;        
    }

    function concatenate(string memory a,string memory b) public pure returns (string memory){
        return string(abi.encodePacked(a,'',b));
    } 


}