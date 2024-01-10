// SPDX-License-Identifier: GNU-3.0-or-later
pragma solidity ^0.8.12;

import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

/// @author tempest-sol<tempest@stableinternetmoney.com>
contract OutbackMartians is Ownable, ERC721Enumerable, Pausable {
    enum SaleType {
        INACTIVE,
        PGC,
        GOAT,
        MVP,
        VIP,
        PUBLIC
    }

    string private baseURI;

    uint16 public immutable maxMartians = 8500;
    uint16 public immutable reservedMartians = 100;

    uint16 public reservedMinted;

    uint8 public txMintLimit = 10;
    uint48 public initialSaleTimestamp = 1648306800;

    uint256 private withdrawLimit = 1.25 ether;
    uint256 private withdrawn;
    address private accessor;

    mapping(SaleType => bytes32) private merkleRoots;
    mapping(SaleType => uint256) public salePrices;

    event MartianMinted(address owner, uint256 tokenId);
    event MartianReserved(address to, uint256 tokenId);
    event SalePriceUpdated(SaleType saleType, uint256 value);

    constructor(address _accessor, string memory _uri) ERC721("Outback Martians", "OMNFT") {
        accessor = _accessor;
        baseURI = _uri;
        salePrices[SaleType.PGC]    = 0.05 ether;
        salePrices[SaleType.GOAT]   = 0.06 ether;
        salePrices[SaleType.MVP]    = 0.075 ether;
        salePrices[SaleType.VIP]    = 0.09 ether;
        salePrices[SaleType.PUBLIC] = 0.11 ether;
    }

    function updateStartTime(uint48 timestamp) external onlyOwner {
        initialSaleTimestamp = timestamp;
    }

    function updateSalePrice(SaleType saleType, uint256 value) external onlyOwner {
        require(value > 0, "value_zero");
        require(salePrices[saleType] != value, "already_set_price");
        salePrices[saleType] = value;
        emit SalePriceUpdated(saleType, value);
    }

    function mint(bytes32[] calldata merkleProof, uint8 amount) external payable whenNotPaused {
        (SaleType saleType, uint256 cost) = getCurrentSale();
        require(saleType != SaleType.INACTIVE, "no_active_sale");
        require(totalSupply() + amount <= maxMartians - reservedMartians, "max_mint_acquired");
        if(saleType != SaleType.PUBLIC) {
            require(saleType == SaleType.PGC ? amount > 0 : amount > 0 && amount <= txMintLimit, "invalid_mint_amount");
            require(whitelistData(saleType, merkleProof), "not_on_whitelist");
        } else {
            require(amount > 0, "amount_Zero");
        }
        require(msg.value == amount * cost, "invalid_ether_amount");
        uint256 tokenId = totalSupply();
        for(uint8 i=0;i<amount;++i) {
            _safeMint(msg.sender, tokenId + i);
            emit MartianMinted(msg.sender, tokenId);
        }
    }

    function mintReserved(address to, uint8 amount) external onlyOwner {
        require(reservedMinted + amount <= reservedMartians, "exceeds_reserve_count");

        uint256 tokenId = totalSupply();
        for(uint8 i=0;i<amount;++i) {
            _mint(to, tokenId + i);
            emit MartianReserved(to, tokenId);
        }
        reservedMinted += amount;
    }

    function setMerkleRoots(SaleType[] memory sales, bytes32[] memory merkles) external onlyOwner {
        require(sales.length == merkles.length, "mismatched_data");
        for(uint8 i=0;i<sales.length;++i) {
            merkleRoots[sales[i]] = merkles[i];
        }
    }

    function updateMerkleRoot(SaleType saleType, bytes32 merkle) external onlyOwner {
        merkleRoots[saleType] = merkle;
    }

    function getCurrentSale() public view returns (SaleType saleType, uint256 cost) {
        uint48 currTimestamp = uint48(block.timestamp);
        if (currTimestamp < initialSaleTimestamp) return (saleType = SaleType.INACTIVE, 0);
        uint48 passedTime = currTimestamp - initialSaleTimestamp;
        if(passedTime < 4 days) return (saleType = SaleType.PGC, salePrices[SaleType.PGC]);
        else if(passedTime >= 4 days && passedTime < 8 days) return (saleType = SaleType.GOAT, salePrices[SaleType.GOAT]);
        else if(passedTime >= 8 days && passedTime < 11 days) return (saleType = SaleType.MVP, salePrices[SaleType.MVP]);
        else if(passedTime >= 11 days && passedTime < 13 days) return (saleType = SaleType.VIP, salePrices[SaleType.VIP]);
        else if(passedTime >= 13 days) return (saleType = SaleType.PUBLIC, salePrices[SaleType.PUBLIC]);
    }

    function canMint(bytes32[] calldata merkleProof) public view returns (bool) {
        (SaleType saleType,) = getCurrentSale();
        if(saleType == SaleType.PUBLIC) return true;
        if(saleType == SaleType.INACTIVE) return false;
        return whitelistData(saleType, merkleProof);
    }

    function whitelistData(SaleType saleType, bytes32[] calldata _merkleProof) internal view returns (bool valid) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        valid = MerkleProof.verify(_merkleProof, merkleRoots[saleType], leaf);
    }

    function withdraw(bool all, uint256 amount) external {
        require(msg.sender == owner() || msg.sender == accessor, "invalid_access");
        require(amount > 0, "amount_zero");
        uint256 balance = address(this).balance;
        if(!all) {
            require(balance >= amount, "insufficient_balance");
        }
        if(msg.sender == accessor) {
            require(withdrawn + amount <= withdrawLimit, "already_withdrew_max");
            withdrawn += amount;
            payable(accessor).transfer(amount);
        } else payable(owner()).transfer(all ? balance : amount);
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        require(_owner != address(0), "owner_zero_address");
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount <= 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit Unpaused(msg.sender);
    }

    function updateBaseUri(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
