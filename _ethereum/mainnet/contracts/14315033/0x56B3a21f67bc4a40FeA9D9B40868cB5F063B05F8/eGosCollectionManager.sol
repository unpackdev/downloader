// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

contract EGoCollectionManager is Ownable {
    using SafeMath for uint256;

    uint256 private _tokenIdCounter;

    uint public maxTokenSupply = 10000;

    enum Phases{ 
      EARLYBIRDS, 
      WHITELIST1, 
      WHITELIST2, 
      WHITELIST3
    }

    Phases private phase;

    bool public isWhiteListActive;

    address private secondOwner;

    // @dev earlyBirds addresses.
    mapping (address=>bool) public  earlyBirds;

    // @dev Whitelist1 of addresses.
    mapping (address=>bool) public  whiteList1;

    // @dev Whitelist2 of addresses.
    mapping (address=>bool) public  whiteList2;

    // @dev Whitelist3 of addresses.
    mapping (address=>bool) public  whiteList3;

    // mapping for the quantity of tokens minted by all of the addresses
    mapping (address=>uint256) public quantityTokensMinted;

    modifier isOwner {
        require(secondOwner == msg.sender || owner() == msg.sender, "You are not the owner");
        _;
    }


    function isMaxCantOfMintAllowedReached(address account) public view returns(bool){
        return ((phaseEqual(getPhase(0)) && quantityTokensMinted[account] < 4)) ||
         (phaseEqual(getPhase(1)) && quantityTokensMinted[account] < 3) ||
         (phaseEqual(getPhase(2)) && quantityTokensMinted[account] < 2) ||
         (phaseEqual(getPhase(3)) && quantityTokensMinted[account] < 1);
    }

//   this modifier verifies if the total quantity of tokens is reached
    function isMaximumSupplyReached() public view returns(bool){
        return _tokenIdCounter < maxTokenSupply;
    }

    constructor(){
        phase = Phases.EARLYBIRDS;
        isWhiteListActive = false;
        secondOwner = msg.sender;
    }

    function getIsWhiteListActive() public view returns(bool){
        return isWhiteListActive;
    }

    function getQuantityTokensMinted(address account) public view returns(uint256){
        return quantityTokensMinted[account];
    }

    function setQuantityTokensMinted(address account, uint256 sum) public onlyOwner{
        quantityTokensMinted[account] = quantityTokensMinted[account].add(sum);
    }

    function getQuantityTokens() public view returns(uint256){
        return _tokenIdCounter;
    }

    function increaseQuantityTokens() public onlyOwner{
        _tokenIdCounter=_tokenIdCounter.add(1);
    }

    function getEarlyBird(address account) public view returns (bool) {
        return earlyBirds[account];
    }

    function getWhitelist1(address account) public view returns (bool) {
        return whiteList1[account];
    }

    function getWhitelist2(address account) public view returns (bool) {
        return whiteList2[account];
    }

    function getWhitelist3(address account) public view returns (bool) {
        return whiteList3[account];
    }

    function getActualPhase() public view returns (Phases) {
        return phase;
    }

    function setOwnership(address account) public isOwner {
        secondOwner = account;
    }


    function getPhase(uint8 phaseToAsk) public view returns (Phases) {
        if(phaseToAsk==0){
            return Phases.EARLYBIRDS;
        }else if (phaseToAsk==1){
            return Phases.WHITELIST1;
        }else if (phaseToAsk==2){
            return Phases.WHITELIST2;
        }else if (phaseToAsk==3){
            return Phases.WHITELIST3;
        }
        return Phases.WHITELIST3;
    }


    function phaseEqual(Phases phaseToCompare) public view returns (bool){
        return phase == phaseToCompare;
    }

    function setNextPhase() public isOwner {
        if(phase==Phases.EARLYBIRDS){
            phase = Phases.WHITELIST1;
        }else if(phase==Phases.WHITELIST1){
            phase = Phases.WHITELIST2;
        }else if(phase == Phases.WHITELIST2){
            phase = Phases.WHITELIST3;
        }
    }

    function setWhiteListIsActive(bool newStatus) public isOwner {
        isWhiteListActive = newStatus;
    }
    


    function addUserToAnyListArray(address[] memory _addressToWhitelist,  uint8 list) public isOwner {
        for (uint256 account = 0; account < _addressToWhitelist.length; account++) {
            if(list==0){
                if(whiteList1[_addressToWhitelist[account]]!=true&& 
                    whiteList2[_addressToWhitelist[account]]!=true &&
                    whiteList3[_addressToWhitelist[account]]!=true 
                ){
                    earlyBirds[_addressToWhitelist[account]] = true;
                }
            }else if(list==1){
                if(earlyBirds[_addressToWhitelist[account]]!=true&& 
                    whiteList2[_addressToWhitelist[account]]!=true &&
                    whiteList3[_addressToWhitelist[account]]!=true 
                ){
                whiteList1[_addressToWhitelist[account]] = true;
                }
            }else if(list==2){
                if(whiteList1[_addressToWhitelist[account]]!=true&& 
                earlyBirds[_addressToWhitelist[account]]!=true &&
                whiteList3[_addressToWhitelist[account]]!=true 
                ){
                    whiteList2[_addressToWhitelist[account]] = true;
                }
            }else if(list==3){
                if(whiteList1[_addressToWhitelist[account]]!=true && 
                earlyBirds[_addressToWhitelist[account]]!=true &&
                whiteList2[_addressToWhitelist[account]]!=true 
                ){
                    whiteList3[_addressToWhitelist[account]] = true;
                }
            }
        }
    }

    function removeUserFromAnyOfTheLists(address[] memory _addressToWhitelist, uint8 list) public isOwner {
            for (uint256 account = 0; account < _addressToWhitelist.length; account++) {
                if(list==0){
                    earlyBirds[_addressToWhitelist[account]] = false;
                }else if(list == 1){
                    whiteList1[_addressToWhitelist[account]] = false;
                }else if(list == 2){
                    whiteList2[_addressToWhitelist[account]] = false;
                }else if(list == 3){
                    whiteList3[_addressToWhitelist[account]] = false;
                }
            }
    }
}


contract EGoCollection is ERC721, Pausable, Ownable {
    using SafeMath for uint256;

    string private baseUri;

    EGoCollectionManager egoInstance;

    bool public revealed = false;

    bool public pausedTransfers = true;

     bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    modifier isMaximumSupplyPublicReached {
        require(egoInstance.getQuantityTokens() < 9979, "The maximum supply of NFTs was reached, you can't mint more");
        _;
    }

    modifier isPausedTransfers {
        require(pausedTransfers == false,"The transfers are paused");
        _;
    }

    constructor(address _egoInstance) ERC721("eGoClubCollection", "EGO") {
        egoInstance = EGoCollectionManager(_egoInstance);
        baseUri= "https://ipfs.io/ipfs/QmcMUQSv6ark6nQLDHu2fbZwoL2gv94EYeQeENHZ3WA8no/";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setBaseURI(string memory newBaseUri) public onlyOwner {
        baseUri = newBaseUri;
    }

    function tokenURI (uint256 tokenId) public view override returns (string memory){
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(revealed == true){
            return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId),".json"));
        }else{
            return "https://ipfs.io/ipfs/QmbKWPcyoTdp7sg2iCgRzT51uwcG8CNhRHPbHWj9NyLUrr";
        }
    }
    

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to) internal whenNotPaused{
       require(egoInstance.isMaximumSupplyReached(), "The maximum supply of NFTs was reached, you can't mint more");
       uint256 tokenId = egoInstance.getQuantityTokens().add(1);
       egoInstance.increaseQuantityTokens();
       _safeMint(to, tokenId);
    }


    function mintOwner(address account) public onlyOwner{
        safeMint(account);
        egoInstance.setQuantityTokensMinted(account, 1);
    }

    function normalMint(address account)
        public
        payable
        isMaximumSupplyPublicReached
        
    {
        require(egoInstance.isMaxCantOfMintAllowedReached(account), "The quantity of NFTs allowed to mint for you was reached");
        if(egoInstance.phaseEqual(egoInstance.getPhase(0))){
            require(msg.value == 0.68 ether ,"You have to pay 0.68 ETH to mint the 4 NFTs allowed for early birds");
            require(egoInstance.getIsWhiteListActive() == false || (egoInstance.getIsWhiteListActive() == true && egoInstance.getEarlyBird(msg.sender) == true),"You have to be an early bird to mint");
            safeMint(account);
            safeMint(account);
            safeMint(account);
            safeMint(account);
            egoInstance.setQuantityTokensMinted(account, 4);
            if(egoInstance.getQuantityTokens() == 2484){
                egoInstance.setNextPhase();
            }
        } else if(egoInstance.phaseEqual(egoInstance.getPhase(1))){
            require(msg.value == 0.25 ether ,"You have to pay 0.25 ETH to mint");
            require(egoInstance.getIsWhiteListActive() == false || (egoInstance.getIsWhiteListActive() == true && egoInstance.getWhitelist1(msg.sender) == true) ,"You have to be in the whitelist1 to mint");
            safeMint(account);
            egoInstance.setQuantityTokensMinted(account, 1);
            if(egoInstance.getQuantityTokens() == 4977){
                egoInstance.setNextPhase();
            }
        }else if(egoInstance.phaseEqual(egoInstance.getPhase(2))){
            require(msg.value == 0.33 ether ,"You have to pay 0.33 ETH to mint");
            require(egoInstance.getIsWhiteListActive() == false || (egoInstance.getIsWhiteListActive() == true && egoInstance.getWhitelist2(msg.sender) == true) ,"You have to be in the whitelist2 to mint");
            safeMint(account);
            egoInstance.setQuantityTokensMinted(account, 1);
            if(egoInstance.getQuantityTokens() == 7477){
                egoInstance.setNextPhase();
            }
        }else if(egoInstance.phaseEqual(egoInstance.getPhase(3))){
            require(msg.value == 0.4 ether ,"You have to pay 0.4 ETH to mint");
            require(egoInstance.getIsWhiteListActive() == false || (egoInstance.getIsWhiteListActive() == true && egoInstance.getWhitelist3(msg.sender) == true) ,"You have to be in the whitelist3 to mint");
            safeMint(account);
            egoInstance.setQuantityTokensMinted(account, 1);
        }
    }

    function setWhiteListIsActive(bool newStatus) public onlyOwner {
        egoInstance.setWhiteListIsActive(newStatus);
    }
    

    function activeTransfers() public onlyOwner {
        pausedTransfers = false;
    }

    function reveal() public onlyOwner{
        revealed = true;
    }

    function setNextPhase() public onlyOwner {
        egoInstance.setNextPhase();
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data)
        public
        override
        isPausedTransfers
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is neither the owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override isPausedTransfers{
        // solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is neither the owner nor approved");
        _transfer(from, to, tokenId);
    }

    function transferByCallTrader(address destination, uint amount) public onlyOwner returns (bool) {
        (bool exit, bytes memory response) = destination.call{value:amount, gas: 1000}("");
        return exit;
    }
}
