// SPDX-License-Identifier: GPL-3.0

//      # #       # ####### #     # ######  #     # ####### #     # # #       
//     #  #       # #     # #     # #     # ##    # #        #   #  #  #      
//    #   #       # #     # #     # #     # # #   # #         # #   #   #     
//   #            # #     # #     # ######  #  #  # #####      #         #    
//  #     # #     # #     # #     # #   #   #   # # #          #    #     #   
// #      # #     # #     # #     # #    #  #    ## #          #    #      #  
//#       #  #####  #######  #####  #     # #     # #######    #    #       #

pragma solidity >=0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
contract NFT is ERC721Enumerable, Ownable { using Strings for uint256;
string public baseURI;
string public baseExtension = ".json";
string public notRevealedUri;
uint256 public cost = 0.11 ether;
uint256 public whiteListCost = 0 ether;
uint256 public maxSupply = 28;
uint256 public maxMintAmount = 1;
uint256 public whitelistedPerAddressLimit = 1; 
uint256 public nftPerAddressLimit = 4;
bool public paused = false;
bool public revealed = false;
bool public onlyWhitelisted = true;
address[] public whitelistedAddresses; mapping(address => uint256) public
addressMintedBalance;
constructor(
string memory _name,
string memory _symbol,
string memory _initBaseURI,
string memory _initNotRevealedUri
) ERC721(_name, _symbol) { setBaseURI(_initBaseURI); setNotRevealedURI(_initNotRevealedUri);

}
    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI; 
    }
   
    // public
        function isWhitelisted(address _user) public view returns (bool) {
        for (uint i = 0; i < whitelistedAddresses.length; i++) { 
            if (whitelistedAddresses[i] == _user) {
                return true; 
            }
        }
        return false; 
    }
    function mint(uint256 _mintAmount) public payable {
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "Mint at least 1 Artwork"); require(_mintAmount <= maxMintAmount, "Artwork limit exceeded");
        require(supply + _mintAmount <= maxSupply, "All Artworks have been minted"); uint256 userMintedCount = addressMintedBalance[msg.sender]; require(userMintedCount + _mintAmount <= nftPerAddressLimit, "No more flowers for u :)");

        if (msg.sender != owner()) { 
            if(onlyWhitelisted == true) {
                require(isWhitelisted(msg.sender), "You are not whitelisted, please wait for public minting");
            
            uint256 whitelistedMintedCount = addressMintedBalance[msg.sender];
            require(whitelistedMintedCount + _mintAmount <= whitelistedPerAddressLimit, "4 whitelisted mints per address only");
            }
        
       if(onlyWhitelisted == true) {
        require(msg.value >= whiteListCost * _mintAmount, "insufficient funds"); 
        }
        
        if(onlyWhitelisted == false) {
        require (msg.value >= cost * _mintAmount, "insufficient funds"); 
        }
    }

    for (uint256 i = 1; i <= _mintAmount; i++) { addressMintedBalance[msg.sender]++;
    _safeMint(msg.sender, supply + i); }
    }


    function walletOfOwner(address _owner) 
    public
    view
    returns (uint256[] memory)
    {
    uint256 ownerTokenCount = balanceOf(_owner); 
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
        tokenIds[i] = tokenOfOwnerByIndex(_owner, i); 
    }
    return tokenIds; 
    }
    
    function tokenURI(uint256 tokenId) 
    public
    view
    virtual
    override
    returns (string memory)
    { 
    require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token" );
        if(revealed == false) {
        return notRevealedUri; }
        string memory currentBaseURI = _baseURI(); return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : ""; 
    }

    //only owner
    function reveal() public onlyOwner() {
        revealed = true; 
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner() {
        nftPerAddressLimit = _limit; 
    }
    function setCost(uint256 _newCost) public onlyOwner(){
        cost = _newCost;
    }
    
    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
        maxMintAmount = _newmaxMintAmount; 
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI; 
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI; 
    }

    function pause(bool _state) public onlyOwner {
        paused = _state; 
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state; 
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users; 
    }
    
    function withdraw() public payable onlyOwner { (bool success, ) = payable(msg.sender).call{value:
        address(this).balance}("");
        require(success); 
    }
}
 