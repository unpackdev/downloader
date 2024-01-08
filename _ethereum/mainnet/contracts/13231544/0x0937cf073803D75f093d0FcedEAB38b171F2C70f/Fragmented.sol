// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Strings.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./NPassCore.sol";
import "./IN.sol";

/**
 * @title Fragmented Contract
 * @author maximonee (twiiter.com/maximonee_)
 * @notice This contract provides minting for Fragmented NFT by Crayonz (Fragmented4N twitter.com/fragmented4n)
 */
contract Fragmented is NPassCore {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(
        string memory name,
        string memory symbol,
        address _nContractAddress,
        bool onlyNHolders,
        uint256 maxTotalSupply,
        uint16 reservedAllowance,
        uint256 priceForNHoldersInWei,
        uint256 priceForOpenMintInWei) NPassCore(
            name,
            symbol,
            IN(_nContractAddress),
            onlyNHolders,
            maxTotalSupply,
            reservedAllowance,
            priceForNHoldersInWei,
            priceForOpenMintInWei
        ) {
            // Start token IDs at 1
            _tokenIds.increment();
        }

    bool public isDayOneSaleActive = false;
    bool public isDayTwoSaleActive = false;

    uint16 public constant DAY_ONE_END = 150;
    uint16 public constant DAY_TWO_END = 350;

    string public baseTokenURI = "ipfs://QmNymaYB6RdT9FWESRcy3QHv8g3ZTDKdzqjxMVx2MmUSQE/";

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
    To be updated once day one quota is minted. This will deactivate the sale for day one and is done automatically
     */
    function setDayOneSaleActive(bool _isDayOneSaleActive) public onlyOwner {
        isDayOneSaleActive = _isDayOneSaleActive;
    }

    /**
    To be updated once day two quota is minted. This will deactivate the sale for day two and is done automatically
     */
    function setDayTwoSaleActive(bool _isDayTwoSaleActive) public onlyOwner {
        isDayTwoSaleActive = _isDayTwoSaleActive;
    }

    /**
    Update the base token URI
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Allow a n token holder to mint a token on day 1
     */
    function mintWithNDayOne() public virtual nonReentrant {
        require(isDayOneSaleActive, "DAY_ONE_SALE_NOT_OPEN");

        uint256 currentSupply = totalSupply();
        require(currentSupply < DAY_ONE_END, "DAY_ONE_SALE_OVER");

        require(
            // If no reserved allowance we respect total supply contraint
            (reservedAllowance == 0 && currentSupply < maxTotalSupply) || reserveMinted < reservedAllowance,
            "NPass:MAX_ALLOCATION_REACHED"
        );

        require(n.balanceOf(msg.sender) >= 1, "NOT_AN_N_HOLDER");
        require(balanceOf(msg.sender) == 0, "CANNOT_MINT_MORE_THAN_ONE");

        // If reserved allowance is active we track mints count
        if (reservedAllowance > 0) {
            reserveMinted++;
        }

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
        _tokenIds.increment();

        if (currentSupply + 1 >= DAY_ONE_END) {
            setDayOneSaleActive(false);
        }
    }

    /**
     * @notice Allow a n token holder to mint a token on day 2
     */
    function mintWithNDayTwo() public virtual nonReentrant {
        require(isDayTwoSaleActive, "DAY_TWO_SALE_NOT_OPEN");

        uint256 currentSupply = totalSupply();
        require(currentSupply < DAY_TWO_END, "DAY_TWO_SALE_OVER");

        require(
            // If no reserved allowance we respect total supply contraint
            (reservedAllowance == 0 && totalSupply() < maxTotalSupply) || reserveMinted < reservedAllowance,
            "NPass:MAX_ALLOCATION_REACHED"
        );

        require(n.balanceOf(msg.sender) >= 1, "NOT_AN_N_HOLDER");
        require(balanceOf(msg.sender) == 0, "CANNOT_MINT_MORE_THAN_ONE");

        // If reserved allowance is active we track mints count
        if (reservedAllowance > 0) {
            reserveMinted++;
        }

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
        _tokenIds.increment();

        if (currentSupply + 1 >= DAY_TWO_END) {
            setDayTwoSaleActive(false);
        }
    }
}
