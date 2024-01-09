// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Address.sol";
import "./ERC721Pausable.sol";

contract MechagnomesNFT is ERC721Pausable, ERC721Enumerable, Ownable {

    uint256 public immutable totalMintSupply = 7654;

    uint256 public immutable protocolReserveCount = 100;

    uint256 internal mintPrice;

    uint256 public maxMintPerWallet = 50;
    uint256 public maxMintPerTx = 10;

    uint256 internal whitelistSaleStartTime;
    uint256 internal whitelistSaleDuration;
    uint256 internal whitelistReserveCount;
    uint256 internal whitelistMintCount;
    mapping(address => uint8) public whiteListRegistrations;
    mapping(address => uint8) public freeMints;

    uint256 internal publicSaleStartTime;
    uint256 internal publicSaleDuration;

    bool internal whitelistSaleActive;
    bool internal publicSaleActive;

    string private baseURI;

    event SaleStarted(bool whitelist);

    event RegisteredWhitelisters(address[] registrants);

    event MintedMechagnome(bool whitelist, uint256 amount);

    event ContractPaused();

    event ContractUnpaused();

    event FreeMintsDistributed(uint256 addressCount, uint256 freeCount);

    constructor(
        string memory name,
        string memory symbol,
        string memory uri,
        uint256 _mintPrice
    ) ERC721(name, symbol) {
        baseURI = uri;
        mintPrice = _mintPrice;
    }

    function isWhitelistSale() public view returns (bool) {
        return whitelistSaleActive;
    }

    function isPublicSale() public view returns (bool) {
        return publicSaleActive;
    }

    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    function setMintPrice(uint256 price) external onlyOwner {
        require(price >= 0 && price != mintPrice, "price_zero_or_set");
        mintPrice = price;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function mint(uint256 amount, bool claimFree) external payable canMint(amount, claimFree) _onlyWhitelist {
        uint256 _mintCost = claimFree ? 0 : mintPrice * amount;
        require(_mintCost <= msg.value, "invalid_ether_amount");

        bool whitelistSale = isWhitelistSale();

        for(uint256 i = 0; i < amount; i++) {
            uint256 index = totalSupply() + 1;
            if(whitelistSale) {
                whitelistReserveCount--;
                whiteListRegistrations[msg.sender] -= 1;
            }
            _safeMint(msg.sender, index);
        }

        emit MintedMechagnome(whitelistSale, amount);
    }

    function grantFree(address[] calldata addresses, uint8[] calldata amounts) external onlyOwner whenNotPaused {
        require(addresses.length == amounts.length, "invalid_address_amounts");
        for(uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            uint8 amount = amounts[i];
            freeMints[addr] = amount;
        }

        emit FreeMintsDistributed(addresses.length, amounts.length);
    }

    function startWhitelist(uint totalReserveCount) external onlyOwner {
        require(!isWhitelistSale() && !isPublicSale(), "existing_sale_running");
        require(totalReserveCount > 0, "reserveCount_zero");
        whitelistReserveCount = totalReserveCount;
        whitelistSaleStartTime = block.timestamp;
        whitelistSaleActive = true;

        emit SaleStarted(true);
    }

    function startPublicSale() external onlyOwner {
        require(!isPublicSale(), "existing_sale_running");
        whitelistSaleActive = false;
        whitelistReserveCount = 0;
        publicSaleStartTime = block.timestamp;
        publicSaleActive = true;

        emit SaleStarted(false);
    }

    function registerWhitelisters(address[] calldata registrants, uint8 perAddressCount, bool freeMint) external onlyOwner {
        require(registrants.length > 0, "registrants_empty");
        require(perAddressCount >= 0, "per_address_count_zero");
        for(uint256 i = 0; i < registrants.length; i++) {
            address registrant = registrants[i];
            // ignore if whitelister has already been added.
            if(whiteListRegistrations[registrant] == 0) {
                whiteListRegistrations[registrant] = perAddressCount;
                if(freeMint) {
                    freeMints[registrant] = 1;
                }
            }
        }

        emit RegisteredWhitelisters(registrants);
    }

    function getElapsedSaleTime() internal view returns (uint256) {
        return publicSaleActive ? (publicSaleStartTime > 0 ? block.timestamp - publicSaleStartTime : 0)
            : (whitelistSaleStartTime > 0 ? block.timestamp - whitelistSaleStartTime : 0);
    }

    function getRemainingMintable() external view returns (uint256) {
        return whitelistSaleActive ? whitelistReserveCount : (totalMintSupply - totalSupply()) - protocolReserveCount;
    }

    function getReservedCountForWhitelister() external view returns (uint256 amount) {
        amount = whiteListRegistrations[msg.sender];
    }

    function getFreeMintCount() external view returns (uint256 amount) {
        amount = freeMints[msg.sender];
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();

        emit ContractPaused();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();

        emit ContractUnpaused();
    }

    function _pause() internal override onlyOwner whenNotPaused {
        super._pause();
    }

    function _unpause() internal override onlyOwner whenPaused {
        super._unpause();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    modifier canMint(uint256 amount, bool claimFree) {
        require(isWhitelistSale() || isPublicSale(), "no_active_sale");
        require(amount > 0, "amount_leq_zero");
        require(totalSupply() + amount <= totalMintSupply - protocolReserveCount, "exceeds_total_supply");
        require(amount <= maxMintPerTx, "exceeds_maxMintPerTx");
        require(balanceOf(msg.sender) + amount <= maxMintPerWallet, "exceeds_max_mint");
        if(isWhitelistSale()) {
            require(whitelistReserveCount >= amount, "exceeds_whitelist_reserve");
            if(claimFree) {
                require(freeMints[msg.sender] > 0, "no_free_mints_available");
            } else {
                uint8 reservedCount = whiteListRegistrations[msg.sender];
                require(amount <= reservedCount, "exceeds_whitelist_allowance");
            }
        }
        _;
    }

    modifier _onlyWhitelist() {
        if(isWhitelistSale()) {
            require(whiteListRegistrations[msg.sender] > 0, "not_whitelisted");
        }
        _;
    }
}
