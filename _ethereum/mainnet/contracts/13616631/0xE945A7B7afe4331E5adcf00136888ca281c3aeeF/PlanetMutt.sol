// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//                                     ,(#%#(,                                    
//                           (&&&&&&&&&&&&&&&&&&&  /&&&(                          
//                      %&&&&&&&&&&&&&&&&&&&&&&&&         %&#                     
//                   %&&&&&&&&&&&&&&&&&&&&&&&&&/              &%                  
//                %&&&&&&&&&&&&&&&&&&&&&&&&&                     %%               
//              &&&&&&&&&&&&&&&&&&&&&&&&&&&              #&&&&     /&             
//            &&&&&&&&&&&%*                                 &&&&&&&&&&&           
//          &&&&&&&&&(  &&&&&&&&&&&&&           %&&&&&&&&&&&&&  (&&&&&&&&         
//         &&&&&&&, &&&&&&&&&&&&,                    %&&&&&&&&&&&# %&&&&&&        
//        &&&&&&  &&&&&&&&&&&&&                       (&&&&&&&&&&&&% *&&&&&       
//       &&&&&% #&&&&&&&&&&&&&                         ,&&&&&&&&&&&&&. &&&&&      
//      &&&&&&, &&&&&&&&&&&&%      (#            #(     .&&&&&&&&&&&&& #&&&&%     
//      &&&&&&& &&&&&&&&&&&#     &&&&&&        &&&&&&     &&&&&&&&&&&& &&&&&&     
//      &&&&&&&&  &&&&&&&.       &&&&&%        %&&&&&       &&&&&&&%  &&&&&&&     
//     .% (&&&&&&&&&%%&%% /           .%&&&&&&%.          , &%%//#&%&&&&&&&&&     
//      &       #&&&&&&&&           /&&&&&&&&&&&&          *&&&&&&&&&&&&&&& &     
//      &           &&&&             %&&&&&&&&&&             &&&&&&&&&&&&&& &     
//      #&         &&&&&        &(      &&&&&&         %      &&&&&&&&&&&  %(     
//       %(      &&&&&&%            (    %&&.      .&         &&&&&&&&%   #%      
//        &,     &&&&&&&%           /    &&&,                &&&&&&&&&   *&       
//         %%       &&&&&&&             &&&&&&             /&&&&&&&&&%  &%        
//          #&         *&&&&&&&#*..*&&&&&&%&&&&&&&&&&&&&&&&&&&&&&&&&&  &#         
//            %&          &&&&&&&&&&&&          %&&     &&&&&&&&&&&  &%           
//              %&        /&&&&&&&&&,&&#      %&&        &&&&&&&.  &%             
//                &&       .&&&&&%      &%&&%%                  .&%               
//                   %&(     *&&&&                           #&%                  
//                       &&&    %&&%                     &&&                      
//                            #&&&#,             ,#&&&#                           

import "./ERC721.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

//Opensea
contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract PlanetMutt is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    // Opensea
    address proxyRegistryAddress = address(0xa5409ec958C83C3f309868babACA7c86DCB077c1);
    string private _baseURIPrefix = "https://planetmutt.s3.amazonaws.com/mint/";

    uint private constant maxTokensPerTransaction = 20;
    uint256 public tokenPrice = 30000000000000000; //0.03 ETH
    uint256 public constant nftsNumber = 2500;
    uint256 private constant nftsPublicNumber = 2450;
    address donationAddr = address(0xaC051d89983805305BcEB844Eea130a1C0CC7B3B);
    uint donationDiv = 2; // Divide balance by this to calculate donation

    Counters.Counter private _tokenIdCounter;
    
    mapping(uint256 => string) public tokenName;

    // Opensea
    string public contractURI = "https://planetmutt.s3.amazonaws.com/mint/contract.json";

    uint256 public startingTimestamp =1637082000; // Nov 16, 2021 5pm UTC/1pm EST, 10am PST
    uint256 public endingTimestamp =0;

    mapping(address => bool) public whitelist;
   
    event NameChange(uint256 indexed tokenId, string newName);

    constructor() ERC721("Planet Mutt", "PlanetMutt") {
        _tokenIdCounter.increment();
    }

    function setBaseURI(string memory baseURIPrefix) public onlyOwner {
        _baseURIPrefix = baseURIPrefix;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    override (ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(_baseURIPrefix).length > 0 ? string(abi.encodePacked(_baseURIPrefix, tokenId.toString(), ".json")) : "";
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        // calculate and send donation amount
        uint256 donationAmount = balance.div(donationDiv);
        payable(donationAddr).transfer(donationAmount);
        // send remaining balance
        balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function directMint(address to, uint256 tokenId) public onlyOwner {
        require(tokenId > nftsPublicNumber, "Tokens number to mint must exceed number of public tokens");
        _safeMint(to, tokenId);
    }

    function mintMutt(address to) whenNotPaused private 
    {
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(to, tokenId);
            _tokenIdCounter.increment();
    }
    
    function buyMutts(uint tokensNumber) whenNotPaused public payable {
        require(tokensNumber > 0, "Wrong amount");
        require(tokensNumber <= maxTokensPerTransaction, "Max tokens per transaction number exceeded");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber, "Tokens number to mint exceeds number of public tokens");
        require(tokenPrice.mul(tokensNumber) <= msg.value, "Ether value sent is too low");
        require(startingTimestampPassed(), "Sale hasn't started yet!");
        require(!endingTimestampPassed(), "Sale has ended");

        for(uint i = 0; i < tokensNumber; i++) {
            mintMutt(msg.sender);
        }
    }

    function totalSupply() public view override returns (uint256) {
        return _tokenIdCounter.current();
    }
    
    function setStartingTimestamp(uint256 _startingTimestamp) public onlyOwner
    {
        startingTimestamp=_startingTimestamp;
    }

    function setEndingTimestamp(uint256 _endingTimestamp) public onlyOwner
    {
        endingTimestamp=_endingTimestamp;
    }
    
    function giveAway(address to, uint tokensNumber) public onlyOwner {
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber, "Tokens number to mint exceeds number of public tokens");

        for(uint i = 0; i < tokensNumber; i++) {
            mintMutt(to);
        }
   }

    function changeName(uint256 tokenId, string memory newName) public virtual {
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner, "You are not the owner");
        require(validateName(newName) == true, "Not a valid new name");
        require(
            sha256(bytes(newName)) != sha256(bytes(tokenName[tokenId])),
            "New name is same as the current one"
        );

        tokenName[tokenId] = newName;
        emit NameChange(tokenId, newName);
    }
    
    function validateName(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > 25) return false; // Cannot be longer than 25 characters
        if (b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            ) return false;

            lastChar = char;
        }

        return true;
    }

    // ERC721Enumerable
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function supportsInterface(bytes4 interfaceID) public view override (ERC721, ERC721Enumerable) returns (bool) {
        return
            super.supportsInterface(interfaceID); 
    }
    
    // https://docs.opensea.io/docs/contract-level-metadata
    function setContractURI(string memory newContractURI) public onlyOwner {
        contractURI = newContractURI;
    }

    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function startingTimestampPassed() public view returns (bool)
    {
        return (startingTimestamp != 0 && block.timestamp > startingTimestamp);
    }
   
    function endingTimestampPassed() public view returns (bool)
    {
        return (endingTimestamp != 0 && block.timestamp > endingTimestamp);
    }
    
    function isMinting() public view returns (bool) 
    {
        if (!startingTimestampPassed() || endingTimestampPassed() || paused()) {
            return false;
        }
        return true;
    }
    
    function mintStatus() public view returns (string memory)
    {
        if (!startingTimestampPassed() && _tokenIdCounter.current() == 1) {
            return "Minting hasn't started yet";
        }
        if (endingTimestampPassed() || _tokenIdCounter.current() >= nftsNumber) {
            return "Sold out!";
        }
        if (paused()) {
            return "Minting is paused.";
        }
        return "Now minting!";
    }
}
