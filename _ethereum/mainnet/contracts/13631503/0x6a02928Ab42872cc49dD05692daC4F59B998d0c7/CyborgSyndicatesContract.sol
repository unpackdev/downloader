// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./Strings.sol";

/*              
                                     Smart Contract for the
  _____          __                           ____                  __   _              __           
 / ___/  __ __  / /  ___   ____  ___ _       / __/  __ __  ___  ___/ /  (_) ____ ___ _ / /_ ___   ___
/ /__   / // / / _ \/ _ \ / __/ / _ `/      _\ \   / // / / _ \/ _  /  / / / __// _ `// __// -_) (_-<
\___/   \_, / /_.__/\___//_/    \_, /      /___/   \_, / /_//_/\_,_/  /_/  \__/ \_,_/ \__/ \__/ /___/
       /___/                   /___/              /___/                                              
                                         NFT Collection
*/

contract CyborgSyndicates is ERC721, Ownable, ERC721Enumerable
{
    //Initalising of variables
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    
    uint256 public earlyBorgPrice = 0.06 ether;
    uint256 public borgPrice = 0.08 ether;
    
    uint256 public maxBorgsPerTx = 10;
    uint256 public preSaleSupply = 2000;
    uint256 public maxBorgSupply = 10000;
    uint256 public saleSupply = 10000;
    uint256 public maxBorgsInAddress = 10;

    bool public publicSaleActive = false;
    bool public preSaleActive = false;
    bool public whitelistActive = true;
    
    string public baseURI = "";
    string public prerevealURI = "";
    
    address[] private presaleAddresses; //Whitelisted Addresses
    
    //Called on contract deployment 
    constructor() ERC721("Cyborg Syndicates", "BORG") 
    {
    }
    
    /*
    ---------------
    Owner Functions
    ---------------
    */
    
    //Sends ETH amount from contract to input address - for dev use. 
    function withdrawETH(address _to, uint256 amount) public onlyOwner 
    {
        require(amount <= address(this).balance, "Amount Requested is too high!");
        Address.sendValue(payable(_to), amount);
    }
    
    //Enables/Disables Pre-Sale State.
    function togglePreSale() public onlyOwner
    {
        preSaleActive = !preSaleActive;
    }
    
    //Enables/Disables Main Sale State.
    function toggleMainSale() public onlyOwner
    {
        publicSaleActive = !publicSaleActive;
    }
    
    //Enables/Disables Main Sale State.
    function toggleWhitelistActive() public onlyOwner
    {
        whitelistActive = !whitelistActive;
    }
    
    //Updates borgs presale mint price, only use in the case ETH price fluctuates heavily.
    function setBorgPrice(uint256 _newBorgPrice) public onlyOwner
    {
        borgPrice = _newBorgPrice;
    }
    
    //Updates price of pre-sale borgs mint price, only use in the case ETH price fluctuates heavily.
    function setEarlyBorgPrice(uint256 _newEarlyBorgPrice) public onlyOwner
    {
        earlyBorgPrice = _newEarlyBorgPrice;
    }
    
    //Updates max amount supply for the presale
    function setPreSaleSupply(uint256 _newPreSaleSupply) public onlyOwner
    {
        preSaleSupply = _newPreSaleSupply;
    }
    
    //Updates max amount supply for the sale
    function setSaleSupply(uint256 _newSaleSupply) public onlyOwner
    {
        saleSupply = _newSaleSupply;
    }
    
    //Updates max amount of borgs able to be purchased in 1 transaction.
    function setMaxBorgsPerTx(uint256 _newMaxBorgsPerTx) public onlyOwner
    {
        maxBorgsPerTx = _newMaxBorgsPerTx;
    }
    
    function setMaxBorgsInAddress(uint256 _newMaxBorgsInAddress) public onlyOwner
    {
        maxBorgsInAddress = _newMaxBorgsInAddress;
    }
    
    //Updates the baseURI, used for revealing borgs.
    function setBaseURI(string memory _newBaseURI) public onlyOwner
    {
        baseURI = _newBaseURI;
    }
    
    //Updates the prereveal URI, here in case wrong URI is input.
    function setPreRevealURI(string memory _newPreRevealURI) public onlyOwner
    {
        prerevealURI = _newPreRevealURI;
    }
    
    //ERC20 Token recovery if mistakenly sent to contract.
    function retrieveERC20(address _tracker, uint256 amount) external onlyOwner 
    {
        IERC20(_tracker).transfer(msg.sender, amount);
    }
    
    //ERC721 Token recovery if mistakenly sent to contract.
    function retrieve721(address _tracker, uint256 id) external onlyOwner 
    {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }
    
    //Adds/Upates list of addresses for addresses whitelisted for presale.
    function whitelistAddress(address[] calldata _whitelisters) external onlyOwner
    {
        delete presaleAddresses;
        presaleAddresses = _whitelisters;
    }
    
    /*
    -----------------
    Minting Functions
    -----------------
    */
    
    //Mint reserved Borgs for devs, giveaways, airdrops etc..
    function devMint(address _to, uint256 _amount) public onlyOwner
    {
        require(totalSupply() + _amount <= maxBorgSupply, "Reserve mint would exceed max Borg limit");
        
        uint256 mintIndex = _tokenIdCounter.current();
        
        for (uint256 i = 1; i <= _amount; i++) 
        {
            mintIndex++;
            if(mintIndex <= maxBorgSupply)
            {
                _mint(_to, mintIndex);
                _tokenIdCounter.increment();
            }
        } 
    }
    
    //Minting for presale of Borgs
    function presaleMint(uint256 _amountOfBorgs) public payable
    {
        require(preSaleActive, "Presale is not active!"); //Requires presale to be active.
        require(_amountOfBorgs <= maxBorgsPerTx && _amountOfBorgs >= 1, string(abi.encodePacked("Minimum Borgs: 1. Maximum Borgs: ", Strings.toString(maxBorgsPerTx), " per transaction"))); //Requires a value within 1 & max cyborgs per transaction.
        require(_amountOfBorgs + balanceOf(msg.sender) <= maxBorgsInAddress, string(abi.encodePacked("A maximum of ", Strings.toString(maxBorgsInAddress), " in your wallet. You have ", Strings.toString(balanceOf(msg.sender))))); //Requires the sender to not have more than max Borgs per address.
        require((totalSupply() + _amountOfBorgs) <= preSaleSupply, "Mint would exceed max supply of the Presale"); //Requires the requested amount to not exceed max supply of Borgs for presale.
        require(msg.value >= (_amountOfBorgs * earlyBorgPrice), "Not enough ETH sent for the Borgs!"); //Requires the correct amount of ETH sent. 
        
        if(whitelistActive)
        {
            require(isAddressWhitelisted(msg.sender), "Address is not whitelisted for presale!"); //Requires msg.sender address to be whitelisted.
            uint256 mintIndex = _tokenIdCounter.current();
            for (uint256 i = 1; i <= _amountOfBorgs; i++) 
            {
                mintIndex++;
                if(mintIndex <= preSaleSupply)
                {
                _mint(msg.sender, mintIndex);
                _tokenIdCounter.increment();
                }
            }
         
        }
        else
        {
            uint256 mintIndex = _tokenIdCounter.current();
            for (uint256 i = 1; i <= _amountOfBorgs; i++) 
            {
                mintIndex++;
                if(mintIndex <= preSaleSupply)
                {
                _mint(msg.sender, mintIndex);
                _tokenIdCounter.increment();
                }
            }
        }
    }
    
    //Minting for main sale of Borgs
    function publicMint(uint256 _amountOfBorgs) public payable
    {
        require(publicSaleActive, "Public sale is not active!"); //Requires public sale to be active.
        require(_amountOfBorgs + balanceOf(msg.sender) <= maxBorgsInAddress, string(abi.encodePacked("You can have a maximum of ", Strings.toString(maxBorgsInAddress), " per address"))); //Requires the sender address to not have, or be able to have more than max Borgs per address.
        require(_amountOfBorgs <= maxBorgsPerTx && _amountOfBorgs >= 1, string(abi.encodePacked("Minimum Borgs: 1. Maximum Borgs: ", Strings.toString(maxBorgsPerTx), " per transaction"))); //Requires a value within 1 & max cyborgs per transaction.
        require(totalSupply() + _amountOfBorgs <= saleSupply, "Mint would exceed max Sale supply!"); //Requires requested amount to not exceed max supply of Borgs.
        require(msg.value >= (borgPrice * _amountOfBorgs), "Not enough ETH sent!"); //Requires the correct amount of ETH sent. 
        
        uint256 mintIndex = _tokenIdCounter.current();
        
        for (uint256 i = 1; i <= _amountOfBorgs; i++) 
        {
            mintIndex++;
            if(mintIndex <= saleSupply)
            {
                _mint(msg.sender, mintIndex);
                _tokenIdCounter.increment();
            }
        } 
    }
    
    
    /*
    ----------------------
    Public view & Other functions
    ----------------------
    */
    
    function isAddressWhitelisted(address _addressToVerify) public view returns (bool)
    {
        if(presaleAddresses.length > 0)
        {
            for(uint256 i = 0; i < presaleAddresses.length; i++)
            {
                if(presaleAddresses[i] == _addressToVerify)
                {
                    return true;
                }
            }
            return false;
        }
        return false;
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) 
    {
        require(_exists(tokenId), "Token Does Not Exist");
        
        string memory URISuffix = ".json";
        string memory base = baseURI;
        
        if(bytes(base).length == 0)
        {
            return string(prerevealURI);
        }
        else
        {
            return string(abi.encodePacked(base, Strings.toString(tokenId), URISuffix));
        }
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}