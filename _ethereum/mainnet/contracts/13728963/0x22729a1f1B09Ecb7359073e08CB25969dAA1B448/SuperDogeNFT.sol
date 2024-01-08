// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import "./ERC721Enumerable.sol";

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

/**
 * @title RookieCard
 * @dev Abstract base implementation for Rookie Card contract functions.
 */
abstract contract RookieCard {
    using SafeMath for uint256;
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract SuperDogeNFT is
    ERC721Enumerable,
    Ownable,
    PaymentSplitter,
    ReentrancyGuard
{
    using Strings for uint256;
    string public baseURI = "https://web3.superdoge.io/api/superdoge-nft/";
    bool public saleIsActive;
    mapping(uint256 => bool) public rookieCardClaims;

    uint256 public price = 0.07 ether;
    uint256 public constant maximumSupply = 10000;
    address[] private treasuryWallets = [
        0x23BE0C03A61B6d3F70C714d85AE121D15FBbF79e,
        0x4AB78e58f5BD1BF4EE2254628fd68d18438C675a
    ];
    uint256[] private treasuryShares = [85, 15];

    RookieCard public rookieCardContract = RookieCard(0xc546C6CF0a6d06Ce75f0b83fF782b9777a4841EB);

    /**
     * @param startingId The first ID to be minted.
     * @param amt Number of tokens to be minted.
     * @dev Event to keep track of minted tokens.
     */
    event SuperDogeNFTMint(uint256 startingId, uint256 amt);

    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) PaymentSplitter(treasuryWallets, treasuryShares) {}

    /**
     * @dev Returns the base URI.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    /**
     * @param amt Number of Super Doge NFTs to mint.
     * @dev Public minting function.
     */
    function mint(uint256 amt) public payable nonReentrant {
        uint256 s = totalSupply();

        require(saleIsActive, "SuperDogeNFT: Sale is not active.");
        require(amt > 0, "SuperDogeNFT: Must mint number greater than zero.");
        require(s + amt <= maximumSupply, "SuperDogeNFT: Cannot mint more than the max supply.");
        require(msg.value >= price * amt, "SuperDogeNFT: Ether amount sent not correct.");
        
        for (uint256 i = 0; i < amt; ++i) {
            _safeMint(msg.sender, s + i, "");
        }

        emit SuperDogeNFTMint(s, amt);

        delete s;
    }
    
    /**
     * @param amt Number of Super Doge NFTs to mint.
     * @param to Address to mint to.
     * @dev Admin minting function.
     * @dev Can only be called by owner.
     */
    function reserve(uint256[] calldata amt, address[] calldata to)
        external
        onlyOwner
    {
        require(
            amt.length == to.length,
            "SuperDogeNFT: Amount array length does not match recipient array length."
        );

        uint256 s = totalSupply();
        uint256 t = arraySumAssembly(amt);

        require(s + t <= maximumSupply, "SuperDogeNFT: Cannot mint more than max supply.");

        for (uint256 i = 0; i < to.length; ++i) {
            for (uint256 j = 0; j < amt[i]; ++j) {
                _safeMint(to[i], s++, "");
            }
        }

        emit SuperDogeNFTMint(s - t, t);

        delete t;
        delete s;
    }

    /**
     * @param tokenId Token ID to retrieve URI for.
     * @dev Retrieves token URI for given ID.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "SuperDogeNFT: Nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    /**
     @param newPrice New price of one Super Doge NFT.
     @dev Sets the price for a single Super Doge NFT.
     @dev Can only be called by owner.
     */
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    /**
     @param newBaseURI New base URI.
     @dev Sets the base URI.
     @dev Can only be called by owner.
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * @dev Paused (false) or active (true).
     * @dev Can only be called by contract owner.
     */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
     * @param _data Array to sum over.
     * @dev Sums over array entries using only assembly.
     */
    function arraySumAssembly(uint256[] memory _data) private pure returns (uint256 sum) {
        assembly {
            let len := mload(_data)
            let data := add(_data, 0x20)
            for
                { let end := add(data, mul(len, 0x20)) }
                lt(data, end)
                { data := add(data, 0x20) }
            {
                sum := add(sum, mload(data))
            }
        }
    }

    /**
     * @param newRookieCardContractAddress Address of the rookie card contract.
     * @dev Sets the address for the referenced rookie card ERC721 contract.
     * @dev Can only be called by contract owner.
     */
    function setRookieCardContractAddress(address newRookieCardContractAddress) public onlyOwner {
        rookieCardContract = RookieCard(newRookieCardContractAddress);
    }

    /**
     * @param rookieCardId ID of the held rookie card
     * @dev Free NFT claim function for rookie card holders.
     */
    function rookieCardMint(uint256 rookieCardId) public nonReentrant {
        uint256 s = totalSupply();
        address ownerOfRookieCard = RookieCard(rookieCardContract).ownerOf(rookieCardId);

        require(saleIsActive, "SuperDogeNFT: Sale is not active.");
        require(s + 1 <= maximumSupply, "SuperDogeNFT: Cannot mint more than the max supply.");
        require(ownerOfRookieCard == msg.sender, "SuperDogeNFT: Caller does not own specified rookie card.");
        require(rookieCardClaims[rookieCardId] == false, "SuperDogeNFT: Free SuperDogeNFT already claimed for specified Rookie Card.");

        _safeMint(msg.sender, s + 1, "");
        rookieCardClaims[rookieCardId] = true;

        emit SuperDogeNFTMint(s, 1);

        delete s;
        delete ownerOfRookieCard;
    }
}
