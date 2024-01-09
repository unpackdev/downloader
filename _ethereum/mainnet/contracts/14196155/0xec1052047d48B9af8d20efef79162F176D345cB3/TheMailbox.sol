// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";

contract TheMailbox is ERC721A {
    address _contractOwner;
    string baseUri = 'https://storage.googleapis.com/the-mailbox/meta-';
    /**
    * Early access is 6 hours, February 14th 2022 00:00 - 06:00
    * This can be changed when contract is reused
    */
    uint public freeToken = 2000;
        
    // This also can be changed
    uint256 pricePerMint = 0.02 ether;
    /***
    * @dev - Save contract owner's address 
    */
    constructor() ERC721A("The Mailbox", "MBX") {
        _contractOwner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == _contractOwner, "Only contract owner can execute this function");
        _;
    }

    /***
    * Control Functions
    */
    /***
    * @dev - Allow contract owner to change mint price
    */
    function setupMintPrice(uint256 newPrice) onlyOwner external{
            pricePerMint = newPrice;
    }   
    /***
    * @dev - Allow contract's eth to be withdrawn to contract owner
    */
    function withdraw(uint256 amount) external onlyOwner{
        require(amount <= address(this).balance,"Contract balance is lower than requested");
        payable(_contractOwner).transfer(amount);
    }
 
    /***
    * @dev - Check if mint quota exceeds limit. Only 9999 NFTs are available
    */
    //   function isMintAllowed() external view returns(bool){
    //     return currentIndex < maxToken;
    //   }
    /***
    * @dev - Shortcut to get balance. Might have to be removed later
    */
    function getEthAmount() public view returns(uint256){
        return address(this).balance;
    }
    /***
    * @dev - Check mint condition first.
    */
    function mint(address to) external payable{
    // require(currentIndex < maxToken, "Only 10000 NFTs are available. You're running out of quota :(");
        if(_currentIndex >= freeToken){
            require(msg.value == pricePerMint, "Minting requires 0.02 Eth per amount");
        }
        _safeMint(to, 1);
    }
    /***
    * @dev - Check if mint price has gone up due to free mint sold out
    */
    function mintPrice() view external returns(uint256){
        if(_currentIndex < freeToken) return 0 ether;
        else return pricePerMint;
    }
    /***
    * @dev - Change this later
    */
    function _baseURI() override internal view virtual returns (string memory) {
        return baseUri;
    }
    function updateBaseURI(string memory newBaseUri) external onlyOwner{
        baseUri = newBaseUri;
    }
    function updateFreeToken(uint freeTokenIndex) external onlyOwner{
        freeToken = freeTokenIndex;
    }
}