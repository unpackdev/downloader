// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Strings.sol";
import "./NPassCore.sol";
import "./NPass.sol";
import "./IN.sol";

/**
 * @title Nbars contract
 * @author @discoblock
 * @notice This contract uses the amazing Npass project made by Tony Snark as a reference & uses its implementation
 */
contract Nbars is NPass {

    using Strings for uint256;
    bool public isSaleOpen = true;
    string public baseTokenURI = "https://yyy.mypinata.cloud/ipfs/QmNYZyYL8fMFuZRKurJPfMj1MSNoDRJyU5YxphUht9GxKQ/";

    constructor(
        string memory name,
        string memory symbol,
        bool onlyNHolders,
        uint256 maxTotalSupply,
        uint16 reservedAllowance,
        uint256 priceForNHoldersInWei,
        uint256 priceForOpenMintInWei
    )
        NPass(
            name,
            symbol,
            onlyNHolders,
            maxTotalSupply,
            reservedAllowance,
            priceForNHoldersInWei,
            priceForOpenMintInWei
        )
    {}

    /**
     * @notice Allow a n token holder to mint a token with one of their n token's id
     * @dev Taken from Npass core, add a require to allow minting only if sale is open
     * @param tokenId Id to be minted
     */
    function mintWithN(uint256 tokenId) public payable virtual override nonReentrant {
        require(
            // If no reserved allowance we respect total supply contraint
            (reservedAllowance == 0 && totalSupply() < maxTotalSupply) || reserveMinted < reservedAllowance,
            "NPass:MAX_ALLOCATION_REACHED"
        );
        require(n.ownerOf(tokenId) == msg.sender, "NPass:INVALID_OWNER");
        require(msg.value == priceForNHoldersInWei, "NPass:INVALID_PRICE");
        require(isSaleOpen, "Nbars:SALE_IS_CLOSED");

        // If reserved allowance is active we track mints count
        if (reservedAllowance > 0) {
            reserveMinted++;
        }
        _safeMint(msg.sender, tokenId);
    }

    /**
     * @dev Override the openzeppelin method to add ".json" at the end of metadata
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev function to update metadata url
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * @dev Close the sale
     * Once the sale is closed, there is no way to re open it
     */
    function closeSale() public onlyOwner {
        isSaleOpen = false;
    }
}
