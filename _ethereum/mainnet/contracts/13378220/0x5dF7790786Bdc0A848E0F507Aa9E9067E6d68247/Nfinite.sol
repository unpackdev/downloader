//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./NPassCore.sol";
import "./IN.sol";

/**
 * @title Nfinite
 * @author maximonee (twitter.com/maximonee_)
 * @notice This contract provides minting for the Nfinite NFT by visualldreams (twitter.com/visualldreams)
 */
contract Nfinite is NPassCore {
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

    bool public isPreSaleActive = false;
    bool public isSaleHalted = false;

    uint16 public constant M_PERCENT_CUT = 20;
    uint16 public constant V_PERCENT_CUT = 80;
    uint16 public constant MAX_NUMBER_OF_MINTS = 5;

    address public constant mAddress = 0x0acFA78eB4A99A5C666bF2fEe98Ab827d3710526;
    address public constant vAddress = 0x9388AE20749ac8ab89Bd7787569eF08991A0F199;

    string public baseTokenURI = "https://arweave.net/KCfmd-uK8A5Elela-7m59fb3nwW-Zz0MMND2E5tlksQ/";

    // October 8th, 20:00 UTC (1PM PST)
    uint32 launchTime = 1633723200;

    /**
    Updates the presale state for n holders
     */
    function setPreSaleState(bool _preSaleActiveState) public onlyOwner {
        isPreSaleActive = _preSaleActiveState;
    }
    
    /**
    Give the ability to halt the sale if necessary due to automatic sale enablement based on time
     */
    function setSaleHaltedState(bool _saleHaltedState) public onlyOwner {
        isSaleHalted = _saleHaltedState;
    }

    modifier activeSale() {
        require(block.timestamp >= launchTime || isPreSaleActive, "SALE_NOT_LIVE");
        require(!isSaleHalted, "SALE_HALTED");
        _;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
    Update the base token URI
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Allow a n token holder to bulk mint tokens
     */
    function multiMintWithN(uint256 numberOfMints) public payable virtual nonReentrant activeSale {
        require(numberOfMints + balanceOf(msg.sender) <= MAX_NUMBER_OF_MINTS, "REACHED_MINT_THRESHOLD");
        require(
            // If no reserved allowance we respect total supply contraint
            (reservedAllowance == 0 && totalSupply() + numberOfMints <= maxTotalSupply) ||
                reserveMinted + numberOfMints <= reservedAllowance,
            "NPass:MAX_ALLOCATION_REACHED"
        );

        require(msg.value >= priceForNHoldersInWei * numberOfMints, "NPass:INVALID_PRICE");
        require(n.balanceOf(msg.sender) > 0, "MUST_BE_AN_N_OWNER");

        // If reserved allowance is active we track mints count
        if (reservedAllowance > 0) {
            reserveMinted += uint16(numberOfMints);
        }

        for (uint256 i = 0; i < numberOfMints; i++) {
            uint256 tokenId = _tokenIds.current();
            _safeMint(msg.sender, tokenId);
            _tokenIds.increment();
        }

        _sendEthOut();
    }

    /**
     * @notice Allow a n token holder to mint a token with one of their n token's id
     */
    function mintWithN() public payable virtual nonReentrant activeSale {
        require(balanceOf(msg.sender) + 1 <= MAX_NUMBER_OF_MINTS, "REACHED_MINT_THRESHOLD");
        require(
            // If no reserved allowance we respect total supply contraint
            (reservedAllowance == 0 && totalSupply() < maxTotalSupply) || reserveMinted < reservedAllowance,
            "NPass:MAX_ALLOCATION_REACHED"
        );
        require(n.balanceOf(msg.sender) > 0, "MUST_BE_AN_N_OWNER");
        require(msg.value >= priceForNHoldersInWei, "NPass:INVALID_PRICE");

        // If reserved allowance is active we track mints count
        if (reservedAllowance > 0) {
            reserveMinted++;
        }

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
        _tokenIds.increment();

        _sendEthOut();
    }

    function _sendEthOut() internal {
        uint256 value = msg.value;
        _sendTo(mAddress, (value * M_PERCENT_CUT) / 100);
        _sendTo(vAddress, (value * V_PERCENT_CUT) / 100);
    }

    function _sendTo(address to_, uint256 value) internal {
        address payable to = payable(to_);
        (bool success, ) = to.call{value: value}("");
        require(success, "ETH_TRANSFER_FAILED");
    }
}
