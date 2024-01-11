// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract FakeThoughts is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

	// baseURI
    string private baseURI;

    // Mint
    uint256 public constant MAX_SUPPLY = 1000;
    bool public saleIsActive = false;
    Counters.Counter public _nextTokenId;

    // Withdraw addresses
    address WITHDRAW_ADDRESS = 0x6907495b99FF6270B6de708c04f3DaCAedD40A40;

    /*
     *  Constructor
     */
    constructor(string memory newBaseURI) ERC721("FakeThoughts", "FAKETHOUGHTS")  {
        _nextTokenId.increment();
        setBaseURI(newBaseURI);
    }

    /*
     *  Minting
     */
    function mint() public payable {
        uint256 supply = totalSupply();
        require( saleIsActive, "Sale is not currently active" );
        require( supply < MAX_SUPPLY, "Purchase would exceed maximum supply" );
        require( msg.value >= getPrice(supply), "Value sent is not correct" );
        _safeMint(msg.sender, _nextTokenId.current() - 1);
        _nextTokenId.increment();
    }

    /*
     *  Current Supply
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    /*
     *  baseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /*
     *  Price
     */
    function getPrice(uint256 _tokenId) public pure returns (uint256) {
        return ((_tokenId / 100) + 1) * 0.1 ether;
    }

    /*
     *  Sale state
     */
    function pauseSale() public onlyOwner() {
        require(saleIsActive == true, "Sale is already paused");
        saleIsActive = false;
    }

    function startSale() public onlyOwner() {
        require(saleIsActive == false, "Sale has already started");
        saleIsActive = true;
    }

    /*
     *  Tokens at address
     */
    function walletOfOwner(address _address) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(_address);
        uint256[] memory tokenIds = new uint256[](balance);
        uint256 index;
        uint256 loopThrough = totalSupply();
        for (uint256 i; i < loopThrough; i++) {
            if (ownerOf(i) == _address) {
                tokenIds[index] = i;
                index++;
            }
        }
        return tokenIds;
    }

    /*
     *  Withdraw
     */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        require(payable(WITHDRAW_ADDRESS).send(balance));
    }

}