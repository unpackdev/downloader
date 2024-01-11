// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ERC721A.sol";

contract EuroHeroes is ERC721A, Ownable {
    // settings for sale
    uint256 public immutable maxSupply = 333; // Total max supply
    // mint settings
    uint256 public mintStartTimestamp;

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
    constructor() ERC721A("Euro Heroes", "EOH") {
    }

    /*
     * # free mint
     * mints nfts to the caller for free
     */
    function freeMint() external isMintActive {
        require(totalSupply() <= maxSupply, "Free mint is over");
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
     * # setMintStartTimestamp
     * set the mint start timestamp 
     */
    function setMintStartTimestamp(uint256 _newTimestamp) public onlyOwner {
        mintStartTimestamp = _newTimestamp;
    }
}