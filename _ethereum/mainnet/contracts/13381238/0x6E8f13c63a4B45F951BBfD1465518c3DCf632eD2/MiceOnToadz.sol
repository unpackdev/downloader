// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./Ownable.sol"; 
import "./ERC721Enumerable.sol"; 
import "./Strings.sol"; 
import "./IERC20.sol";

contract MiceOnToadz is ERC721Enumerable, Ownable {
    using Strings for uint256;
    event MintMiceOnToadz(address indexed sender, uint256 startWith, uint256 times);

    //supply counters 
    uint256 public totalMiceOnToadz;
    uint256 public totalCount = 2800;
    uint256 public publicMiceOnToadz = 1355;
    uint256 public totalPublicmice = 1355;
    //token Index tracker 
    uint256 public MAXBATCH = 1;
    //create a variable for the $STACK token address.
    address public stackAddress;
    
    //string
    string public baseURI;

    //bool
    bool private started;

    mapping (address => bool) public whiteList;

     //constructor args : initialize the stack token address
    constructor(string memory name_, string memory symbol_, address _stackTokenAddress, string memory baseURI_) ERC721(name_, symbol_) {
        baseURI = baseURI_; 
        stackAddress = _stackTokenAddress;
    }

    //basic functions. 
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }
    function setWhitelist(address[] calldata whiteListAddresses) public onlyOwner {
        for (uint256 i; i< whiteListAddresses.length; i++) {
            whiteList[whiteListAddresses[i]] = true;
        }
    }

    //erc721 
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token."); 
        
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '.json';  
    }
    function setStart(bool _start) public onlyOwner {
        started = _start;
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }
    //public view function that returns the currentStackPrice
        function currentStackPrice()  public view returns (uint256) {
            if (totalPublicmice <= 1355) {
                    return 250000000000000000000;
            } else if (totalPublicmice > 1355 && totalPublicmice <= 1600) {
                    return 250000000000000000000;
            } else if (totalPublicmice > 1600 && totalPublicmice<= 1900) {
                    return 450000000000000000000;
            } else if (totalPublicmice> 1900 && totalPublicmice<= 2200) {
                    return 650000000000000000000;
            } else if (totalPublicmice> 2500 && totalPublicmice<= 2800) {
                    return 850000000000000000000;
            } else if(totalPublicmice> 2800 && totalPublicmice<= 3200) {
                    return 1050000000000000000000;
            }
            revert();
        }


    //leave the first mintWhitelist function, its done
    function mintWhitelist(uint256 _times) public {
        require(whiteList[msg.sender] == true, "must be whitelisted");
        require(_times == 1, "may only redeem one");
        require(totalMiceOnToadz + _times <= totalCount, "max supply reached!");
        emit MintMiceOnToadz(_msgSender(), totalMiceOnToadz+1, _times); 
        for(uint256 i=0; i< _times; i++){ 
            _mint(_msgSender(), 1 + totalMiceOnToadz++); 
        }
        whiteList[msg.sender] = false;
    }

    function mintWithStack(uint256 _times, uint256 amount) public {
        require(started, "not started");
        require(amount >= currentStackPrice() * _times, "not enough tokens");  
        require(publicMiceOnToadz + _times <= totalCount, "max supply reached!");
        require(_times <= MAXBATCH, "too many!"); 
        IERC20(stackAddress).transferFrom(msg.sender, address(this), currentStackPrice() * _times); 
        emit MintMiceOnToadz(_msgSender(), publicMiceOnToadz+1, _times); 
        _mint(_msgSender(), 1 + publicMiceOnToadz++);  
    }

    function withdrawStack() public onlyOwner {
        uint256 stackSupply = IERC20(stackAddress).balanceOf(address(this));
        IERC20(stackAddress).transfer(msg.sender, stackSupply);
    }
}



