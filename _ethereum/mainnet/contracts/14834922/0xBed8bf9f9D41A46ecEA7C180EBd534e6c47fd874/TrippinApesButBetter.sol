// SPDX-License-Identifier: MIT

/*
 █     █░▓█████     ▄▄▄       ██▀███  ▓█████     ███▄    █  ▒█████  ▄▄▄█████▓   ▄▄▄█████▓ ██▀███   ██▓ ██▓███   ██▓███   ██▓ ███▄    █   ▄████     ▄▄▄       ██▓███  ▓█████   ██████ 
▓█░ █ ░█░▓█   ▀    ▒████▄    ▓██ ▒ ██▒▓█   ▀     ██ ▀█   █ ▒██▒  ██▒▓  ██▒ ▓▒   ▓  ██▒ ▓▒▓██ ▒ ██▒▓██▒▓██░  ██▒▓██░  ██▒▓██▒ ██ ▀█   █  ██▒ ▀█▒   ▒████▄    ▓██░  ██▒▓█   ▀ ▒██    ▒ 
▒█░ █ ░█ ▒███      ▒██  ▀█▄  ▓██ ░▄█ ▒▒███      ▓██  ▀█ ██▒▒██░  ██▒▒ ▓██░ ▒░   ▒ ▓██░ ▒░▓██ ░▄█ ▒▒██▒▓██░ ██▓▒▓██░ ██▓▒▒██▒▓██  ▀█ ██▒▒██░▄▄▄░   ▒██  ▀█▄  ▓██░ ██▓▒▒███   ░ ▓██▄   
░█░ █ ░█ ▒▓█  ▄    ░██▄▄▄▄██ ▒██▀▀█▄  ▒▓█  ▄    ▓██▒  ▐▌██▒▒██   ██░░ ▓██▓ ░    ░ ▓██▓ ░ ▒██▀▀█▄  ░██░▒██▄█▓▒ ▒▒██▄█▓▒ ▒░██░▓██▒  ▐▌██▒░▓█  ██▓   ░██▄▄▄▄██ ▒██▄█▓▒ ▒▒▓█  ▄   ▒   ██▒
░░██▒██▓ ░▒████▒    ▓█   ▓██▒░██▓ ▒██▒░▒████▒   ▒██░   ▓██░░ ████▓▒░  ▒██▒ ░      ▒██▒ ░ ░██▓ ▒██▒░██░▒██▒ ░  ░▒██▒ ░  ░░██░▒██░   ▓██░░▒▓███▀▒    ▓█   ▓██▒▒██▒ ░  ░░▒████▒▒██████▒▒
░ ▓░▒ ▒  ░░ ▒░ ░    ▒▒   ▓▒█░░ ▒▓ ░▒▓░░░ ▒░ ░   ░ ▒░   ▒ ▒ ░ ▒░▒░▒░   ▒ ░░        ▒ ░░   ░ ▒▓ ░▒▓░░▓  ▒▓▒░ ░  ░▒▓▒░ ░  ░░▓  ░ ▒░   ▒ ▒  ░▒   ▒     ▒▒   ▓▒█░▒▓▒░ ░  ░░░ ▒░ ░▒ ▒▓▒ ▒ ░
  ▒ ░ ░   ░ ░  ░     ▒   ▒▒ ░  ░▒ ░ ▒░ ░ ░  ░   ░ ░░   ░ ▒░  ░ ▒ ▒░     ░           ░      ░▒ ░ ▒░ ▒ ░░▒ ░     ░▒ ░      ▒ ░░ ░░   ░ ▒░  ░   ░      ▒   ▒▒ ░░▒ ░      ░ ░  ░░ ░▒  ░ ░
  ░   ░     ░        ░   ▒     ░░   ░    ░         ░   ░ ░ ░ ░ ░ ▒    ░           ░        ░░   ░  ▒ ░░░       ░░        ▒ ░   ░   ░ ░ ░ ░   ░      ░   ▒   ░░          ░   ░  ░  ░  
    ░       ░  ░         ░  ░   ░        ░  ░            ░     ░ ░                          ░      ░                     ░           ░       ░          ░  ░            ░  ░      ░  
                                                                                                                                                                                     
                                                                                                                                                                                     
                                                                                                                                                                                       ░     ░  ░           ░  ░   ░                         ░      ░                     ░           ░                ░  ░            ░  ░      ░  */

pragma solidity ^ 0.8 .9;

import "./ERC721A.sol";
import "./Ownable.sol";

contract WeAreNotTrippingApes is ERC721A, Ownable {
   using Strings
    for uint256;
    
    uint256 private constant maxSupply = 5555;
    uint256 public isPublicCost = 9000000000000000;
    uint256 public isMaxPublicSaleMints = 10;
    uint256 public isFree = 697; // RIP, 696.9 but rounded!
    string public BaseURI = "https://bafybeide55r45wbbketz6qequx62vtz5svu2r2p4wddugkuvxroydrnadq.ipfs.nftstorage.link/"; // 

    mapping(address=>uint256) public hasPublicMinted;

    constructor() ERC721A("We are not Trippin Apes", "WANTA") { }

    function TeamApeMint(uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= maxSupply, "We are not Trippin Apes :: Exceeds total supply.");
        _safeMint(msg.sender, _quantity);
    }

    modifier transactionCheck(uint256 _quantity, uint256 hasMinted) {   
        uint toPay = isPublicCost;
        if(totalSupply() + _quantity <= isFree){
            toPay = 0;
        }
        require(msg.value == toPay *_quantity, "We are not Trippin Apes :: You're not paying the right amount of ETH!...");
        require(hasMinted + _quantity <= isMaxPublicSaleMints, "We are not Trippin Apes :: Max mints reached.");
        require(totalSupply() + _quantity <= maxSupply, "We are not Trippin Apes :: Mint finished; no more supply.");
        hasPublicMinted[msg.sender] +=  _quantity;
        _;
    }

    function mint(uint256 _quantity) external payable transactionCheck(_quantity, hasPublicMinted[msg.sender]){
        _safeMint(msg.sender, _quantity);
    }
    

    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
        require(_exists(_tokenId), "URI query for non-existent token");
        return string(abi.encodePacked(BaseURI, _tokenId.toString(), ".json"));
    }

    function _startTokenId() internal view virtual override(ERC721A) returns(uint256) {
        return 1;
    }

    function withdrawal() public onlyOwner {
        (bool t1, ) = payable(0xeCca2Fa2e89c4680c1d9d1a9F1A0aE2e83181Eb5).call {
            value: address(this).balance/100*50
        } ("");
        require(t1, "We are not Trippin Apes :: Cannot transact to the address...");
        (bool t2, ) = payable(0x2B15Dd0b3A5F34aE4eA30cA5300F449E07D0ca21).call {
            value: address(this).balance
        } ("");        
        require(t2, "We are not Trippin Apes :: Cannot transact to the address...");
    }
}