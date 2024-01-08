// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
// import "./Counters.sol";

contract rustyKeys is Ownable, ERC721{

    using SafeMath for uint256;
    
     // address private mainContract = "";
    
    bool public isURIFrozen = false;
    
    string public baseURI = "https://";
    
    uint256 public MAX_SUPPLY = 350;
    
    bool public mintIsActive = true;
    
    uint256 public totalSupply = 0;
    
    address public upComing;

    bool public mtrac;
    
    bytes public dta;
    
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {
       
    }

    function _baseURI() internal view override returns (string memory)  {
        return baseURI;
    }
    
    function toggleURI() external onlyOwner {
        isURIFrozen = !isURIFrozen;
    }
    
    function toggleMint() external onlyOwner {
        mintIsActive = !mintIsActive;
    }
    
    function setBaseURI(string calldata newURI) external onlyOwner {
        require(!isURIFrozen, "URI is Frozen");
        baseURI = newURI;
    }
    
    function setUpcoming(address upcomingContract) external onlyOwner {
        upComing = upcomingContract;
    }
    
    function airdropRustyKeys( address[] memory recepients) external onlyOwner {
        require(mintIsActive, "Minting has not commenced or has ended");
        require(totalSupply < MAX_SUPPLY, "All Airdropped!");
        for(uint i = 0; i < recepients.length; i++) {
            if(balanceOf(recepients[i]) == 0){
                totalSupply++;
                _safeMint(recepients[i], totalSupply);
            }
        }
    }
    
    function burn(uint256 _tokenId) public {
        require(!mintIsActive, "Ongoing Sale");
        require(_exists(_tokenId), "Token Does Not Exist");
        require(msg.sender == ownerOf(_tokenId), "Unauthorised Burn");
        totalSupply -= 1;
        _burn(_tokenId);
    }
    
    function burnAndMint(uint256 _tokenId) public {
        require(!mintIsActive, "Ongoing Sale");
        require(_exists(_tokenId), "Token Does Not Exist");
        require(msg.sender == ownerOf(_tokenId), "Unauthorised Burn");
        (bool success, bytes memory data) = upComing.call(
            abi.encodeWithSignature("mintNFT(uint256,address)", _tokenId, msg.sender)
        );
        
        require(success, "Minting Failed");
        mtrac = success;
        dta = data;
    
        totalSupply -= 1;
        _burn(_tokenId);
    }

    function withdrawAll(address treasury) external payable onlyOwner {
        require(payable(treasury).send(address(this).balance));
    }
}
