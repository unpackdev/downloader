// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ERC721A.sol";
import "./ReentrancyGuard.sol";


contract LuckGameOGPass is ERC721A,  Ownable, ReentrancyGuard {
using Strings for uint256;

uint256 public GoldPassPrice = 0.3 ether;
uint256 public _maxSupply = 1857;
uint256 private teamPercetage = 17;
bool public _saleIsActive = false;
address private _teamSafe = address(0);
address private _projectSafe = address(0);
string    private _tokenPreRevealURI  = '';
string    private _tokenRevealBaseURI = '';
    
constructor(address ProjectSafe, address teamSafe) 
        ERC721A("LuckGame OG Pass", "LGOG") {
        _projectSafe = ProjectSafe;
        _teamSafe =  teamSafe;
}

function mint(uint256 mintCount) external payable {
        bool sent;
        require(_saleIsActive, "Minting not start");
        require( GoldPassPrice * mintCount <= msg.value, "Incorrect Eth");
        uint256 amount  = ( msg.value * teamPercetage ) / 100 ;
        (sent,) = payable(_teamSafe).call{value: uint(amount) }("");  
        (sent,) = payable(_projectSafe).call{value: uint((msg.value-amount)) }("");  
        mintLG(msg.sender,mintCount);
        delete sent; 
        delete amount;     
}

function mintLG (address receiver, uint256 mintCount) internal {
      require(mintCount > 0, "count<=zero");
      require(totalSupply() + mintCount < _maxSupply, "Max Out");
      _safeMint(receiver, mintCount);
} 
function setPreRevealURI(string calldata URI) external onlyOwner {
      _tokenPreRevealURI = URI;
}
function setRevealBaseURI(string calldata URI) external onlyOwner {
      _tokenRevealBaseURI = URI;
}
function setPercentage( uint256 team) external onlyOwner{
        teamPercetage = team;
}    
function setGoldPassPrice(uint256 newPrice) external onlyOwner {
	GoldPassPrice = newPrice;
}
function setMintLive(bool status) external onlyOwner {
	_saleIsActive = status;
}
function setMaxSupply(uint256 MaxSupply) external onlyOwner {
	_maxSupply = MaxSupply;
}
function giveaway(address receiver, uint256 mintCount) external onlyOwner {
        mintLG(receiver, mintCount);
}
function withdraw(uint256 amount, address toaddress) external onlyOwner {
      require(amount <= address(this).balance, "Amount > Balance");
      if(amount == 0){
          amount = address(this).balance;
      }
      payable(toaddress).transfer(amount); 
}
function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');
        string memory baseURI = _tokenRevealBaseURI;
        return bytes(baseURI).length > 0 ?
        string(abi.encodePacked(baseURI, tokenId.toString())) :
        _tokenPreRevealURI;
}
// --- recovery of tokens sent to this address
function retrieveERC20(address _tracker, uint256 amount) external onlyOwner {
        IERC20(_tracker).transfer(msg.sender, amount);
}
function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
}
}    