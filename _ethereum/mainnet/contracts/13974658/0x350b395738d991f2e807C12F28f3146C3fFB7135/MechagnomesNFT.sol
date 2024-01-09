// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Address.sol";
import "./Pausable.sol";

contract MechagnomesNFT is ERC721, Pausable, Ownable {

    uint256 public immutable totalMintSupply = 7654;

    uint256 public immutable protocolReserveCount = 100;

    uint256 public mintPrice;

    uint256 public maxMintPerWallet = 50;
    uint256 public maxMintPerTx = 10;

    uint256 internal whitelistReserveCount;
    uint256 internal whitelistMintCount;
    mapping(address => uint8) public whiteListRegistrations;
    mapping(address => uint8) public freeMints;

    bool internal whitelistSaleActive;
    bool internal publicSaleActive;

    event SaleStarted(bool whitelist);

    event RegisteredWhitelisters(address[] registrants);

    event MintedMechagnome(bool whitelist, uint256 amount, bool claimed);

    event ContractPaused();

    event ContractUnpaused();

    event FreeMintsDistributed(uint256 addressCount, uint256 freeCount);

    constructor(
        string memory name,
        string memory symbol,
        string memory uri,
        uint256 _mintPrice
    ) ERC721(name, symbol) {
        _setBaseURI(uri);
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

    function mint(uint8 amount) external payable canMint(amount) onlySale whenNotPaused {
        uint256 _mintCost = mintPrice * amount;
        require(_mintCost <= msg.value, "invalid_ether_amount");

        bool whitelistSale = isWhitelistSale();

        uint256 supply = totalSupply();

        for(uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, supply + i);
        }

        if(whitelistSale) {
            whiteListRegistrations[msg.sender] -= amount;
            whitelistReserveCount -= amount;
        }

        emit MintedMechagnome(whitelistSale, amount, false);
    }

    function claimFree(uint8 amount) external canClaim(amount) whenNotPaused {
        uint256 supply = totalSupply();
        for(uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, supply + i);
        }

        freeMints[msg.sender] -= amount;

        emit MintedMechagnome(isWhitelistSale(), amount, true);
    }

    function grantFree(address[] calldata addresses, uint8[] calldata amounts) external onlyOwner {
        require(addresses.length == amounts.length, "invalid_address_amounts");
        for(uint256 i = 0; i < addresses.length; i++) {
            freeMints[addresses[i]] += amounts[i];
        }

        emit FreeMintsDistributed(addresses.length, amounts.length);
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory result) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            result = new uint256[](0);
        } else {
            result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
        }
    }

    function startWhitelist(uint totalReserveCount) external onlyOwner {
        require(!isWhitelistSale() && !isPublicSale(), "existing_sale_running");
        require(totalReserveCount > 0, "reserveCount_zero");
        whitelistReserveCount = totalReserveCount;
        whitelistSaleActive = true;

        emit SaleStarted(true);
    }

    function startPublicSale() external onlyOwner {
        require(!isPublicSale(), "existing_sale_running");
        whitelistSaleActive = false;
        whitelistReserveCount = 0;
        publicSaleActive = true;

        emit SaleStarted(false);
    }

    function registerWhitelisters(address[] calldata registrants, uint8 perAddressCount, bool freeMint, uint8 freeMintCount) external onlyOwner {
        require(registrants.length > 0, "registrants_empty");
        require(perAddressCount >= 0, "per_address_count_zero");
        for(uint256 i = 0; i < registrants.length; i++) {
            address registrant = registrants[i];
            // ignore if whitelister has already been added.
            if(whiteListRegistrations[registrant] == 0) {
                whiteListRegistrations[registrant] = perAddressCount;
                if(freeMint) {
                    freeMints[registrant] += freeMintCount;
                }
            }
        }

        emit RegisteredWhitelisters(registrants);
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
        super._pause();

        emit ContractPaused();
    }

    function unpause() external onlyOwner whenPaused {
       super._unpause();

        emit ContractUnpaused();
    }

    function setBaseURI(string memory uri) external onlyOwner {
        _setBaseURI(uri);
    }

    modifier canMint(uint256 amount) {
        require(isWhitelistSale() || isPublicSale(), "no_active_sale");
        require(amount > 0, "amount_leq_zero");
        require(totalSupply() + amount <= totalMintSupply - protocolReserveCount, "exceeds_total_supply");
        require(amount <= maxMintPerTx, "exceeds_maxMintPerTx");
        require(balanceOf(msg.sender) + amount <= maxMintPerWallet, "exceeds_max_mint");
        if(isWhitelistSale()) {
            require(whitelistReserveCount >= amount, "exceeds_whitelist_reserve");
            uint8 reservedCount = whiteListRegistrations[msg.sender];
            require(amount <= reservedCount, "exceeds_whitelist_allowance");
        }
        _;
    }

    modifier canClaim(uint256 amount) {
        require(amount > 0, "amount_zero");
        require(freeMints[msg.sender] >= amount, "amount_exceeds_Free_mints");
        _;
    }

    modifier onlySale() {
        if(isWhitelistSale()) {
            require(whiteListRegistrations[msg.sender] > 0, "not_whitelisted");
        }
        _;
    }
}
