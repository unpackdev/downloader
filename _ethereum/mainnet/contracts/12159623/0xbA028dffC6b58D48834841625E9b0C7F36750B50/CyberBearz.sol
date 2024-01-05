// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract CyberBearz is ERC721, Ownable {  

    using SafeMath for uint256;

    uint256 public constant BEARS_CAP = 2222;
    bool public hasSaleStarted = false;

    mapping (uint256 => string) private cyberBearsNames;

    constructor(string memory myBase) ERC721("CYBERBEARZ", "CBRBRZ") {
        _setBaseURI(myBase);
    }

    modifier isOwnerOfCyberBear(uint _tokenId) {
        require(msg.sender == ownerOf(_tokenId), "You do not own this CyberBear");
        _;
    }

    /**
    * @dev CyberBears reactor
    */
    function getCyberBear(uint256 _numOfCyberBears) 
	public 
	payable 
    {
        require(totalSupply() < BEARS_CAP, "All CyberBears are already ownd");
        require(_numOfCyberBears > 0 && _numOfCyberBears <= 10, "Min 1. Max 10");
        require(totalSupply().add(_numOfCyberBears) <= BEARS_CAP, "Exceeds Capacity, grab less, please");
        require(msg.value >= getCyberBearPrice().mul(_numOfCyberBears), "You havent sent enough eth");
        
        for (uint256 i = 0; i < _numOfCyberBears; i++) {
            uint mintIndex = totalSupply().add(1); //we start from tokenId = 1, not from 0
            _safeMint(msg.sender, mintIndex);
        }                        
    }

    /**
     *  @dev sets name for bear
    */ 

    function setCyberBearName(uint256 _tokenId, string memory _cyberBearName) public isOwnerOfCyberBear(_tokenId) {
        cyberBearsNames[_tokenId] = _cyberBearName;
    }

    /**
    * @dev returns name
    */
    function getCyberBearName(uint256 _tokenId) public view returns(string memory) {
        return cyberBearsNames[_tokenId];
    }

    /**
     *  @dev sets new base URI in case old is broken
    */ 
    function _setNewBaseURI(string memory _newBaseURI) external onlyOwner {
        _setBaseURI(_newBaseURI); 
    }

    function startDrop() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseDrop() public onlyOwner {
        hasSaleStarted = false;
    }

    /**
    * @dev Returns current CyberBear price.
    */

    function getCyberBearPrice() public view returns (uint256) {
        
        require(hasSaleStarted == true, "Sale hasnt started");
        
        require(totalSupply() < BEARS_CAP, "All CyberBears are already owned");

        uint currentSupply = totalSupply();

        if (currentSupply >= 2200) {
            return 2000000000000000000; // last 2 Bearz = 2 ETH
        } else {
            return ( 1+ (currentSupply / 222)) * 2 * (10 ** 16); // each 222 bearz price increases 0,02 eth
        }
    }

    /**
     * @dev Withdraw ether from this contract 
    */
    function withdraw() onlyOwner public {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
    }
    
    /**
    * @dev Admin key
    */
    function giveCyberBear(address _toAddress) onlyOwner
	public 
    {
        require(totalSupply() < BEARS_CAP, "All CyberBears are already grabbed");
        uint mintIndex = totalSupply().add(1); //we start from tokenId = 1, not from 0
        _safeMint(_toAddress, mintIndex);
                                
    }

    function setCyberBearNameAdmin(uint256 _tokenId, string memory _cyberBearName) public onlyOwner {
        cyberBearsNames[_tokenId] = _cyberBearName;
    }

}