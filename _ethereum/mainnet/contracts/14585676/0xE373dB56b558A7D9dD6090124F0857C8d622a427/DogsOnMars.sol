// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ERC721A.sol";

contract DogsOnMars is ERC721A, Ownable {
    // settings for sale
    uint256 public immutable maxSupply = 555; // Total max supply
    uint256 public immutable freeMintCap = 100;
    // mint settings
    uint256 public mintStartTimestamp;
    uint256 public _mintPrice = 0.01 ether;


    // baseURI for token metadata 
    string private baseURI;

    /*
     * # isMintActive
     * checks if the mint is active
     */
    modifier isMintActive() {
        require(mintStartTimestamp != 0 && block.timestamp >= mintStartTimestamp, "Cannot interact because mint has not started");
        _;
    }

    // Constructor
    constructor() ERC721A("Dogs On Mars", "DOM") {
    }

    /*
     * # mint
     * mints nfts to the caller
    */
    function mint(uint256 _quantity) external payable isMintActive {
        require(totalSupply() + _quantity <= maxSupply, "Cannot mint more than max supply");
        require(msg.value >= _mintPrice * _quantity, "Insufficent ethereum amount sent");
        _mint(msg.sender, _quantity, "", false);
    }

    /*
     * # free mint
     * mints nfts to the caller for free
     */
    function freeMint() external isMintActive {
        require(totalSupply() < freeMintCap, "Free mint is over");
        _mint(msg.sender, 1, "", true);
    }
    /*
     * # setBaseURI
     * sets the metadata url once its live
     */
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    /*
     * # _baseURI
     * returns the metadata url to any DAPPs that use it (opensea for instance)
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /*
     * # withdraw
     * withdraws the funds from the smart contract to the owner
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }   

    /*
     * # setMintStartTimestamp
     * set the mint start timestamp 
     */
    function setMintStartTimestamp(uint256 _newTimestamp) public onlyOwner {
        mintStartTimestamp = _newTimestamp;
    }
}