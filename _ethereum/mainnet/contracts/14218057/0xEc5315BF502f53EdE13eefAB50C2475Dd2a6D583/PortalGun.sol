// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC1155Pausable.sol";
import "./ERC1155Holder.sol";
import "./Strings.sol";

contract PortalGun is Ownable, ERC1155Pausable, ERC1155Holder {
    using Strings for uint256;

    uint8 public constant MAX_PER_TX = 10;
    uint8 public constant MAX_GOLD_GUNS = 250;
    uint16 public constant MAX_GUNS = 2250;

    uint16 public totalGunsMinted;
    uint8 public totalGoldGunsMinted;

    string private baseURI;

    uint256[] public itemIds;

    bool public publicSaleActive;

    uint256 public publicSaleCost;

    mapping(uint256 => bool) public registeredItems;

    event UpdateBaseURI(string uri);

    event UpdateInjector(address injector);

    event ItemAdded(uint256 itemId);

    event ItemDisabled(uint256 itemId);
    
    event ItemCostUpdated(uint256 oldCost, uint256 newCost);

    event ItemPurchased(address purchaser, uint256 itemId, uint256 amount);

    event ItemDestroyed(address destroyer, uint256 itemId, uint256 amount);

    event PublicSaleStatusFlipped(bool previous, bool current);

    event GunsMinted(address owner, uint256 tokenId, uint8 amount);

    constructor(string memory _baseURI) ERC1155(_baseURI) {
        baseURI = _baseURI;
        registeredItems[0] = true;
        registeredItems[1] = true;

        publicSaleActive = true;
        publicSaleCost = 0.025 ether;
    }

    function transferItems(uint256 itemId) external onlyOwner {
        safeTransferFrom(address(this), msg.sender, itemId, balanceOf(address(this), itemId), "");
    }

    function destroyItem(uint256 itemId, uint256 amount) external whenNotPaused {
        _burn(msg.sender, itemId, amount);
        emit ItemDestroyed(msg.sender, itemId, amount);
    }

    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        _setURI(_baseURI);
        emit UpdateBaseURI(baseURI);
    }

    function mintPublicSale(uint8 amount) external payable _onlyPublicSale() {
        require(amount > 0, "amount_zero");
        require(msg.value >= publicSaleCost * amount, "not_enough_ether");
        mint(msg.sender, 0, amount);
    }

    function mint(address owner, uint256 tokenId, uint8 amount) internal _canMint(amount) {
        for(uint i=0;i<amount;++i) {
            uint256 randomNum = random(tokenId);
            bool mustMintGold = totalGunsMinted == MAX_GUNS;
            bool mustMintRegular = totalGoldGunsMinted == MAX_GOLD_GUNS;
            if(!mustMintRegular && (mustMintGold || randomNum % 10 == 1)) {
                totalGoldGunsMinted += 1;
                _mint(owner, 1, 1, "");
            } else {
                totalGunsMinted += 1;
                _mint(owner, 0, 1, "");
            }
        }
        
        emit GunsMinted(owner, tokenId, amount);
    }

    function mintBatch(uint256[] memory ids, uint256[] memory amounts) external onlyOwner {
        _mintBatch(owner(), ids, amounts, "");
    }

    function mintBatchFor(uint256[] memory ids, uint256[] memory amounts, address to) external onlyOwner {
        _mintBatch(to, ids, amounts, "");
    }

    function flipPublicSaleStatus() external onlyOwner {
        publicSaleActive = !publicSaleActive;

        emit PublicSaleStatusFlipped(!publicSaleActive, publicSaleActive);
    }

    function updatePublicSaleCost(uint256 cost) external onlyOwner {
        publicSaleCost = cost;
    }

    function currentMintCost() external view returns (uint256 cost) {
        cost = publicSaleCost;
    }

    function uri(uint256 typeId)
        public
        view                
        override
        returns (string memory)
    {
        require(
            registeredItems[typeId],
            "URI requested for invalid item type"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, typeId.toString()))
                : baseURI;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function random(uint256 seed) internal view returns (uint256) {
        return uint256(
            keccak256(abi.encodePacked(tx.origin, blockhash(block.number - 1), block.timestamp, seed))
        );
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function pause() external onlyOwner whenNotPaused {
        super._pause();
    }

    function unpause() external onlyOwner whenPaused {
        super._unpause();
    }

    modifier _onlyPublicSale() {
        require(publicSaleActive, "public_sale_not_active");
        _;
    }

    modifier _canMint(uint8 amount) {
        require(totalGunsMinted + totalGoldGunsMinted + amount <= MAX_GUNS + MAX_GOLD_GUNS, "maximum_guns_minted");
        require(amount <= MAX_PER_TX, "amount_exceeds_tx_max");
        _;
    }
}