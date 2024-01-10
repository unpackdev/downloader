// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./PrivateSale.sol";
import "./PublicSale.sol";

contract OneToInfinityClub is
    ERC721Enumerable,
    Ownable,
    PrivateSale,
    PublicSale
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    string public baseTokenURI;
    uint256 public maxSupply = 508;
    uint256 public price;

    constructor(
        string memory baseURI,
        uint256 _privSaleStart,
        uint256 _privSaleExpiry,
        uint256 _publicSaleStart,
        uint256 _price
    )
        ERC721("One to Infinity Club", "OTIC")
        PrivateSale(_privSaleStart, _privSaleExpiry)
        PublicSale(_publicSaleStart)
    {
        setBaseURI(baseURI);
        price = _price;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token is not exist");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(_tokenId),
                        ".json"
                    )
                )
                : "";
    }

    /** Administrators */
    function updateSupply(uint256 _supply) public onlyOwner {
        uint256 current = _tokenIds.current();
        require(_supply >= current, "supply must greater than current");
        maxSupply = _supply;
    }

    function updatePrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function privateSaleMint()
        public
        payable
        privateSaleStart
        eligibleForWhitelistMint
    {
        uint256 qtyToMint = privateSaleMinterToAllowedMintQty[msg.sender];
        addressToHasMintedOnPrivateSale[msg.sender] = true;
        uint256 supply = maxSupply;
        safeMintNFT(qtyToMint, supply);

        for (uint256 i = 0; i < qtyToMint; i++) {
            lockedQtyForPrivateSale.decrement();
        }
    }

    function mintNFT(uint256 qty) public payable publicSaleActive {
        uint256 supply = maxSupply - lockedQtyForPrivateSale.current();
        safeMintNFT(qty, supply);
    }

    /**
     * @notice Mint an NFT
     */
    function safeMintNFT(uint256 qty, uint256 supply) private {
        require(qty > 0, "Cannot mint nothing");
        require(msg.value == price * qty, "Ether is too high or low");

        uint256 tokenToMint = _tokenIds.current();

        require(tokenToMint + qty - 1 < supply, "NFT run out of supply!");

        for (uint256 i = 0; i < qty; i++) {
            _safeMint(msg.sender, tokenToMint);
            _tokenIds.increment();
            tokenToMint = _tokenIds.current();
        }

        address owner = owner();
        (bool sent, ) = owner.call{value: price * qty}("");
        require(sent, "Failed to send ether");
    }

    /**
     * @notice Get a list of token id owned
     * @param _owner the address of the token owner
     * @return array of token id
     */
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }
}
