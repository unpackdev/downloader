// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./ERC721AQueryable.sol";
import "./Whitelist.sol";

/// @author tempest-sol<tempest@stableinternetmoney.com>
contract Curiosities is Ownable, Whitelist, ERC721AQueryable {

    enum SaleType { STAGING, WHITELIST, PUBLIC, CONCLUDED }

    SaleType public currentSale;

    uint256 public immutable maxSupply;
    uint256 public immutable reserveCount;
    uint8 public reservesMinted;

    uint256 public cost;

    struct SaleDefinition {
        uint8 count;
        bool perTx;
    }

    mapping(SaleType => SaleDefinition) private saleDefinitions;

    mapping(address => mapping(SaleType => uint16)) private mintCount;

      ///////////////////
     ////   Events   ///
    ///////////////////
    event SaleTypeChanged(SaleType indexed saleType);
    event MintCostChanged(uint256 indexed cost);

    //!!!!!!!!!!!!!!!!!!!!!!!!! 
    // SET URI
    //!!!!!!!!!!!!!!!!!!!!!!!!!

    string public uri;

    constructor() ERC721A("Curiosities", "CRS") {
        maxSupply = 5000;
        reserveCount = 150;
        saleDefinitions[SaleType.WHITELIST] = SaleDefinition(3, false);
        saleDefinitions[SaleType.PUBLIC] = SaleDefinition(5, true);
        cost = 0.04 ether;
    }

    function updateUri(string memory _uri) external onlyOwner {
        uri = _uri;
    }

    function setSaleType(SaleType sale) external onlyOwner {
        require(currentSale != sale, "sale_already_set");
        currentSale = sale;

        if(sale == SaleType.WHITELIST) {
            whitelistActive = true;
        } else if(whitelistActive) {
            whitelistActive = !whitelistActive;
        }

        emit SaleTypeChanged(sale);
    }

    function updateSalePrice(uint256 amount) external onlyOwner {
        require(cost != amount, "amount_already_set");
        cost = amount;
        emit MintCostChanged(amount);
    }

    function mint(uint8 amount, bytes32[] calldata proof) external onlyWhitelisted(proof) canMint(amount) payable {
        SaleDefinition memory definition = saleDefinitions[currentSale];
        uint16 currentCount = mintCount[msg.sender][currentSale];
        require(amount <= definition.count, "exceeds_mint_limit");
        if(!definition.perTx) {
            require(currentCount + amount <= definition.count, "exceeds_mint_allowance");
        }
        uint256 totalCost = amount * cost;
        require(msg.sender.balance >= totalCost, "not_enough_ether");
        require(msg.value == totalCost, "invalid_eth_value");
        mintCount[msg.sender][currentSale] += amount;
        if(_totalMinted() + amount == maxSupply) {
            currentSale = SaleType.CONCLUDED;
            emit SaleTypeChanged(currentSale);
        }
        _safeMint(msg.sender, amount);
    }

    function mintFreeFor(address[] calldata addresses) external onlyOwner {
        require(_totalMinted() + addresses.length <= maxSupply - reserveCount, "max_mint_exceeded");
        address nullAddr = address(0x0);
        address addr;
        for(uint8 i=0;i<addresses.length;++i) {
            addr = addresses[i];
            require(addr != nullAddr, "address_invalid");
            mintCount[addr][currentSale]++;
            _safeMint(addr, 1);
        }
    }

    function mintReservedFor(address to, uint8 quantity) external onlyOwner {
        require(reservesMinted + quantity <= reserveCount, "exceeds_reserves");
        reservesMinted += quantity;
        _safeMint(to, quantity);
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

     function _baseURI() internal view override returns (string memory) {
        return uri;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    modifier canMint(uint8 amount) {
        require(currentSale > SaleType.STAGING, "sale_inactive");
        require(currentSale != SaleType.CONCLUDED, "sale_concluded");
        require(_totalMinted() + amount <= maxSupply - reserveCount, "exceeds_max_supply");
        _;  
    }

    receive() external payable {}

}