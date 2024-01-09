// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract WLGBT is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;

    uint256 public immutable TOTAL_TOKENS;
    uint256 public immutable FREE_MINT_TOKENS;
    uint256 public immutable RESERVED_TOKENS;
    uint256 public PAID_MINT_TOKENS;
    uint256 public PUBLICT_MINT_TOKENS;
    uint256 public LAUNCH_DATE;

    // mint related
    uint256 public MINT_PRICE = 0.039 ether;
    uint256 public FREE_MINT_MAX_PER_ADDR = 5;
    uint256 public TOTAL_MINT_MAX_PER_ADDR = 20;

    uint256 public public_minted = 0;
    uint256 public reserved_minted = 0;

    // private
    string private _baseTokenURI;
    Counters.Counter private _tokenIds;

    constructor(
        uint256 total_tokens,
        uint256 free_mint_tokens,
        uint256 reserved_tokens,
        string memory base_uri,
        uint256 launch_date
    ) ERC721("World of LGBT", "WLGBT") {
        TOTAL_TOKENS = total_tokens;
        FREE_MINT_TOKENS = free_mint_tokens;
        RESERVED_TOKENS = reserved_tokens;
        PAID_MINT_TOKENS = total_tokens - reserved_tokens - free_mint_tokens;
        PUBLICT_MINT_TOKENS = total_tokens - reserved_tokens;
        _baseTokenURI = base_uri;
        LAUNCH_DATE = launch_date;
        _pause();
    }

    modifier notLocked() {
        require(LAUNCH_DATE <= block.timestamp, "Mint is locked");
        _;
   }

    function totalSupply() public view returns (uint256) {
        return public_minted + reserved_minted;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function publicMint(uint256 number) external payable whenNotPaused notLocked{
        require(number >= 1, "Number is 0");
        if (public_minted < FREE_MINT_TOKENS) {
            require(balanceOf(msg.sender) + number <= FREE_MINT_MAX_PER_ADDR, "Beyond max number of free tokens");
            require(public_minted + number <= FREE_MINT_TOKENS, "Not enought free tokens");
        }else{
            require(balanceOf(msg.sender) + number <= TOTAL_MINT_MAX_PER_ADDR, "Beyond max number of tokens");
            require(public_minted + number <= PUBLICT_MINT_TOKENS, "Sold out");
            require(MINT_PRICE * number <= msg.value, "Invalid payment amount");
        }

        for (uint256 i = 0; i < number; i++) {
            uint256 currentTokenId = _tokenIds.current();
            _tokenIds.increment();
            public_minted++;
            _safeMint(msg.sender, currentTokenId);
        }
    }

    function reservedMint(address[] calldata receivers) external onlyOwner {
        require(reserved_minted + receivers.length <= RESERVED_TOKENS, "Reserved sold out");
        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 currentTokenId = _tokenIds.current();
            _tokenIds.increment();
            reserved_minted++;
            _safeMint(receivers[i], currentTokenId);
        }
    }


    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setPaused(bool paused) external onlyOwner {
        if (paused) _pause();
        else _unpause();
    }

    function setMintPrice(uint256 price) external onlyOwner {
        MINT_PRICE = price;
    }

    function setBaseURI(string memory base_uri) external onlyOwner{
        _baseTokenURI = base_uri;
    }

    function setFreeMintMaxPerAddr(uint256 number) external onlyOwner {
        FREE_MINT_MAX_PER_ADDR = number;
    }

    function setTotalMintMaxPerAddr(uint256 number) external onlyOwner {
        TOTAL_MINT_MAX_PER_ADDR = number;
    }

    function setLaunchDate(uint256 timestamp) external onlyOwner {
        LAUNCH_DATE = timestamp;
    }
}