// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";


contract BillyTheBoy is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public cost = 0.03 ether;
    uint256 public constant MAX_SUPPLY = 10000;
    bool public pause = false;

    string public baseURI;
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    )ERC721(_name, _symbol){
            setBaseURI(_initBaseURI);
            mint(msg.sender,4);
    }


    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function mint(address _to, uint256 _mintAmount) public payable{
        uint256 supply = totalSupply();
        require(!pause);     
        require(_mintAmount>0);
        require(supply + _mintAmount <= MAX_SUPPLY);

        if (msg.sender != owner()){
            require(msg.value >= cost * _mintAmount);
        }
        for (uint256 i = 1; i<= _mintAmount; i++){
        _safeMint(_to, supply+i);
        }

    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory){
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
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI,"/",tokenId.toString()))
        : "";
    }


      function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPause(bool _state) public onlyOwner {
        pause = _state;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

}