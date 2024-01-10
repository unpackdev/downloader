// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/*

                                     
,-----.                        ,--.        
|  |) /_  ,--,--. ,---.  ,---. |  | ,---.  
|  .-.  \' ,-.  || .-. || .-. :|  |(  .-'  
|  '--' /\ '-'  |' '-' '\   --.|  |.-'  `) 
`------'  `--`--'.`-  /  `----'`--'`----'  
                 `---'                     


 Hi Mom!

 by @mfer4198

*/

import "ERC721Enumerable.sol";
import "Ownable.sol";


contract Bagels is ERC721Enumerable, Ownable {

    bool public saleIsActive = false;
    string public baseURI;
    address payable immutable withdrawAddr;
    uint256 public priceInWei = 0.02 ether;

    // constants add 1 to utilize </> without equality
    uint256 public constant MAX_PER_TX = 48 + 1;
    uint256 public constant MAX_SUPPLY = 5000 + 1;
    


    constructor(address payable withdrawAddr_, string memory _baseURI) ERC721("Bagels", "BAGELS") {
        require(withdrawAddr_ != address(0));
        withdrawAddr = withdrawAddr_;
        baseURI = _baseURI;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint numTokensRequested) public payable  {
        uint numTokensToMint = numTokensRequested;
        uint issuedCount = _owners.length;

        require(saleIsActive, "Sale is not active");
        require(numTokensRequested < MAX_PER_TX, "Exceeded max token purchase");
        require(issuedCount + numTokensRequested < MAX_SUPPLY, "Purchase would exceed max supply of tokens");
        require(priceInWei * numTokensRequested == msg.value, "Incorrect ether value sent");

        // Baker's Dozen
        uint extraTokens = numTokensToMint / 6;
        uint remainingTokens = MAX_SUPPLY - issuedCount;
        if (extraTokens != 0) {
            uint remainingAfterMintOfRequested = remainingTokens - numTokensToMint;
            extraTokens = extraTokens < remainingAfterMintOfRequested ? extraTokens : remainingAfterMintOfRequested;
            numTokensToMint += extraTokens;
        }

        for(uint i; i < numTokensToMint; i++) { 
            _mint(_msgSender(), issuedCount + i);
        }

    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function withdraw() public onlyOwner {
        (bool success, ) = withdrawAddr.call{value: address(this).balance}("");
        require(success, "Withdraw failed.");
    }

    function setPrice(uint256 _priceInWei) public onlyOwner {
        priceInWei = _priceInWei;
    }

}

