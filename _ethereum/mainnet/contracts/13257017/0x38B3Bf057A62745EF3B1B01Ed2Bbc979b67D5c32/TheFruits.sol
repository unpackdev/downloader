// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract TheFruits is ERC721, Ownable {

    using SafeMath for uint256;





    /*
        Variables
    */

    uint256 public constant maxSupply = 5000;
    uint256 public price = 50000000000000000; // 0.05 ETH
    uint256 public reservedTokens = 250;

    bool public isSaleActive = false;

    string public FRUIT_PROVENANCE = "";





    /*
        Constructor
    */

    constructor() ERC721("TheFruits", "FRUIT") {}





    /*
        Set the base URI for all token IDs.
        It is automatically added as a prefix to the value returned in tokenURI.
    */

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
    }

    /*
        Set Provenance Hash
    */

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        FRUIT_PROVENANCE = _provenanceHash;
    }

    /*
        Activate/Deactivate Sale
    */

    function flipSaleState() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    /*
        Set Price
    */

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    /*
        Set Reserved Tokens
    */

    function setReservedTokens(uint256 _reservedTokens) public onlyOwner {
        reservedTokens = _reservedTokens;
    }

    /*
        Withdraw
    */

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
    }





    /*
        Claim Reserved Tokens
    */

    function claimReservedTokens(address _to, uint256 _numberOfTokens) public onlyOwner {
        require(_numberOfTokens <= reservedTokens, "That would exceed the max reserved tokens");
        uint256 supply = totalSupply();
        for (uint256 i = 0; i < _numberOfTokens; i++) {
            _safeMint(_to, supply.add(i));
        }
        reservedTokens = reservedTokens.sub(_numberOfTokens);
    }




    
    /*
        Mint
    */

    function mint(uint256 _numberOfTokens) public payable {
        uint256 supply = totalSupply();
        require(isSaleActive, "Sale must be active to mint tokens");
        require(_numberOfTokens < 11, "You cannot mint more than 10 tokens at once");
        require(supply.add(_numberOfTokens) <= maxSupply.sub(reservedTokens), "Not enough tokens left");
        require(_numberOfTokens.mul(price) <= msg.value, "Inconsistent amount sent");
        for (uint256 i = 0; i < _numberOfTokens; i++) {
            _safeMint(msg.sender, supply.add(i));
        }
    }





    /*
        List All Fruits of a Wallet
    */

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 _tokenCount = balanceOf(_owner);
        uint256[] memory _tokenIds = new uint256[](_tokenCount);
        for(uint256 i = 0; i < _tokenCount; i++){
            _tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return _tokenIds;
    }





}
