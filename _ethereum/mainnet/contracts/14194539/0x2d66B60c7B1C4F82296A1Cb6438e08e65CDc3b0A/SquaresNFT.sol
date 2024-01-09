// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Address.sol";

enum ClaimState {
        Off,
        Active,
        SoldOut
    }

contract SquaresNFT is ERC721, ERC721Enumerable  {

    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    uint256 public constant MAX_TILE_NUMBER = 100;
    Counters.Counter private tileCounter; 

    ClaimState public claimState;
    string public baseURI;

    mapping(uint256 => bool) public tilePurchased;
    mapping(address => bool) public addressHasPurchased;

    constructor() ERC721("SQUARES", "SQUARES") {
        claimState = ClaimState.Off;
    }

    function mint(uint256 _tile) external payable {
        require(claimState == ClaimState.Active, "Sale not active");
        require(_tile <= MAX_TILE_NUMBER, "Tile number must be below 100");
        require(_tile > 0,"Tile 0 is not valid");
        require(!tilePurchased[_tile], "Tile already purchased");
        require(!addressHasPurchased[msg.sender], "Caller has already purchased a tile");
        require(!msg.sender.isContract(),"Caller cannot be a smart contract");

        _safeMint(msg.sender, _tile);
        tileCounter.increment();
        addressHasPurchased[msg.sender] = true;
        tilePurchased[_tile] = true;

        if(tileCounter.current()==100){
            stopClaim();
        }
        
    }

    function startClaim() public virtual{
        require(claimState == ClaimState.Off, "Sale already started and/or completed");
        claimState = ClaimState.Active;
    }
    
    function stopClaim() private {
        claimState = ClaimState.SoldOut;
    }

    function setBaseURI(string memory _URI) public virtual {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    // Read only, not to be used in smart contract calls
    function getTileOwners(uint256 _lower, uint256 _upper) public view returns (address[] memory) {
        require(_upper < 101, "Upper cannot exceed 100");
        require(_lower > 0, "Lower must be greater than zero");
        require(_upper > _lower, "Upper must be larger than lower");
        address[] memory tileOwners = new address[](100);
        for(uint256 i = _lower; i <= _upper; i++ ){
            if(tilePurchased[i]){
                tileOwners[i-1] = ownerOf(i);
            }
            else{
                tileOwners[i-1] = address(0);
            }
        }
        return tileOwners;

    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}