// SPDX-License-Identifier: MIT

/// @title A Sign Of The Times
/// @author @GBERGPHOTO
/// @notice ASOTT is a photographic diary by Gregory Berg
/// @dev @0xORPHAN x @TRANSMENTAL
/*
 █████╗     ███████╗██╗ ██████╗ ███╗   ██╗        
██╔══██╗    ██╔════╝██║██╔════╝ ████╗  ██║        
███████║    ███████╗██║██║  ███╗██╔██╗ ██║        
██╔══██║    ╚════██║██║██║   ██║██║╚██╗██║        
██║  ██║    ███████║██║╚██████╔╝██║ ╚████║        
╚═╝  ╚═╝    ╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝        
 ██████╗ ███████╗    ████████╗██╗  ██╗███████╗    
██╔═══██╗██╔════╝    ╚══██╔══╝██║  ██║██╔════╝    
██║   ██║█████╗         ██║   ███████║█████╗      
██║   ██║██╔══╝         ██║   ██╔══██║██╔══╝      
╚██████╔╝██║            ██║   ██║  ██║███████╗    
 ╚═════╝ ╚═╝            ╚═╝   ╚═╝  ╚═╝╚══════╝    
████████╗██╗███╗   ███╗███████╗███████╗           
╚══██╔══╝██║████╗ ████║██╔════╝██╔════╝           
   ██║   ██║██╔████╔██║█████╗  ███████╗           
   ██║   ██║██║╚██╔╝██║██╔══╝  ╚════██║           
   ██║   ██║██║ ╚═╝ ██║███████╗███████║           
   ╚═╝   ╚═╝╚═╝     ╚═╝╚══════╝╚══════╝                                                                                      
*/   

pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";


contract ASignOfTheTimes is ERC721A, ReentrancyGuard, ERC2981, Ownable {

    string public baseExtension = ".json";
    string public baseURI;

    address payable public GregoryBerg = payable(0x33602B325F169741662cD33C3F693Eee8dbD20D5);

    bool public paused = true;

    uint public nftPerAddress = 2;
    uint public maxSupply = 100;
    uint256 public cost = 0.15 ether;

    mapping(address => uint256) public addressMintedBalance;

    event RoyaltiesChanged(address _newReceiver, uint96 _newValue);

    constructor(
        string memory _initBaseURI
    )ERC721A("A Sign Of The Times", "ASOTT") 
    {
        baseURI= _initBaseURI;
        _setDefaultRoyalty(GregoryBerg, 1000);
    }

    modifier unPaused() {
        require(!paused, 'Contract paused');
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, 'The caller is another contract.');
        _;
    }

    function developNFT(
        uint256 _amount
    ) 
        public 
        payable 
        unPaused() 
        callerIsUser() 
    {
        uint supply = totalSupply();
        require((_amount + supply) <= maxSupply, "Sold Out");
        require(_amount + addressMintedBalance[msg.sender] <= nftPerAddress, "Can only has 2");
        require(msg.value >= (cost * _amount), "not enough ether value");

        for (uint256 i = 1; i <= _amount; i++) {
            addressMintedBalance[msg.sender]++;
        }
        _safeMint(msg.sender, _amount);
    }



    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function togglePaused(bool _state) external onlyOwner {
        paused = _state;
    }

    function setMintCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function setNftPerAddress(uint _nftPerAddress) external onlyOwner {
        nftPerAddress = _nftPerAddress;
    }

    function setBaseExtension(string memory _baseExtension) external onlyOwner {
        baseExtension = _baseExtension;
    }

    function setRoyalties(address _receiver, uint96 _value ) external onlyOwner {
        _setDefaultRoyalty(_receiver, _value);

        emit RoyaltiesChanged(_receiver, _value);
    }

    function withdraw() public onlyOwner {
        (bool success, ) = GregoryBerg.call{value: address(this).balance}("");
        require(success, "Failed to send to Greg.");
    }

    function tokenURI(uint256 _tokenId) 
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), baseExtension));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _startTokenId() 
        internal 
        view 
        virtual 
        override 
        returns(uint256)
    {
        return 1;
    }
}


/*
 █████╗     ███████╗██╗ ██████╗ ███╗   ██╗        
██╔══██╗    ██╔════╝██║██╔════╝ ████╗  ██║  
███████║    ███████╗██║██║  ███╗██╔██╗ ██║        
██╔══██║    ╚════██║██║██║   ██║██║╚██╗██║        
██║  ██║    ███████║██║╚██████╔╝██║ ╚████║        
╚═╝  ╚═╝    ╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝        
 ██████╗ ███████╗    ████████╗██╗  ██╗███████╗    
██╔═══██╗██╔════╝    ╚══██╔══╝██║  ██║██╔════╝    
██║   ██║█████╗         ██║   ███████║█████╗      
██║   ██║██╔══╝         ██║   ██╔══██║██╔══╝      
╚██████╔╝██║            ██║   ██║  ██║███████╗    
 ╚═════╝ ╚═╝            ╚═╝   ╚═╝  ╚═╝╚══════╝    
████████╗██╗███╗   ███╗███████╗███████╗           
╚══██╔══╝██║████╗ ████║██╔════╝██╔════╝           
   ██║   ██║██╔████╔██║█████╗  ███████╗           
   ██║   ██║██║╚██╔╝██║██╔══╝  ╚════██║           
   ██║   ██║██║ ╚═╝ ██║███████╗███████║           
   ╚═╝   ╚═╝╚═╝     ╚═╝╚══════╝╚══════╝                                                                                      
*/    