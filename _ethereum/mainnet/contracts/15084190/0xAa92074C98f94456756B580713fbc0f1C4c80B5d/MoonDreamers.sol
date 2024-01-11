// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//.................................................................................................................................................................
//.MMMMM...MMMMM.....OOOOOO........OOOOOO.....NNNN....NNN..DDDDDDDDD....RRRRRRRRR....EEEEEEEEEE.....AAAA......MMMMM...MMMMM..EEEEEEEEEE..RRRRRRRRR......SSSSSS.....
//.MMMMM...MMMMM...OOOOOOOOOO....OOOOOOOOOO...NNNN....NNN..DDDDDDDDDD...RRRRRRRRRRR..EEEEEEEEEE.....AAAAA.....MMMMM...MMMMM..EEEEEEEEEE..RRRRRRRRRRR..SSSSSSSSS....
//.MMMMM...MMMMM..OOOOOOOOOOOO..OOOOOOOOOOOO..NNNNN...NNN..DDDDDDDDDDD..RRRRRRRRRRR..EEEEEEEEEE.....AAAAA.....MMMMM...MMMMM..EEEEEEEEEE..RRRRRRRRRRR..SSSSSSSSSS...
//.MMMMM...MMMMM..OOOO....OOOO..OOOO....OOOO..NNNNN...NNN..DDD....DDDD..RRR.....RRR..EEE...........AAAAAA.....MMMMM...MMMMM..EEE.........RRR.....RRR..SSS...SSSS...
//.MMMMMM.MMMMMM..OOO......OOO..OOO......OOO..NNNNNN..NNN..DDD.....DDD..RRR.....RRR..EEE...........AAAAAAA....MMMMMM.MMMMMM..EEE.........RRR.....RRR..SSSS.........
//.MMMMMM.MMMMMM.MOOO......OOOOOOOO......OOOO.NNNNNNN.NNN..DDD.....DDDD.RRRRRRRRRRR..EEEEEEEEEE...AAAA.AAA....MMMMMM.MMMMMM..EEEEEEEEEE..RRRRRRRRRRR..SSSSSSS......
//.MMMMMM.MMMMMM.MOOO......OOOOOOOO......OOOO.NNN.NNN.NNN..DDD.....DDDD.RRRRRRRRRR...EEEEEEEEEE...AAA..AAAA...MMMMMM.MMMMMM..EEEEEEEEEE..RRRRRRRRRR....SSSSSSSS....
//.MMMMMMMMMMMMM.MOOO......OOOOOOOO......OOOO.NNN.NNNNNNN..DDD.....DDDD.RRRRRRRR.....EEEEEEEEEE...AAAAAAAAA...MMMMMMMMMMMMM..EEEEEEEEEE..RRRRRRRR........SSSSSSS...
//.MMM.MMMMM.MMM..OOO......OOO..OOO......OOO..NNN..NNNNNN..DDD.....DDD..RRR..RRRR....EEE.........AAAAAAAAAA...MMM.MMMMM.MMM..EEE.........RRR..RRRR...........SSSS..
//.MMM.MMMMM.MMM..OOOO....OOOO..OOOO....OOOO..NNN..NNNNNN..DDD....DDDD..RRR...RRRR...EEE.........AAAAAAAAAAA..MMM.MMMMM.MMM..EEE.........RRR...RRRR..RSSS....SSSS..
//.MMM.MMMMM.MMM..OOOOOOOOOOOO..OOOOOOOOOOOO..NNN...NNNNN..DDDDDDDDDDD..RRR....RRRR..EEEEEEEEEEE.AAA.....AAA..MMM.MMMMM.MMM..EEEEEEEEEEE.RRR....RRRR..SSSSSSSSSS...
//.MMM..MMMM.MMM...OOOOOOOOOO....OOOOOOOOOO...NNN....NNNN..DDDDDDDDDD...RRR....RRRR..EEEEEEEEEEEEAAA.....AAAA.MMM..MMMM.MMM..EEEEEEEEEEE.RRR....RRRR..SSSSSSSSSS...
//.MMM..MMM..MMM.....OOOOOO........OOOOOO.....NNN....NNNN..DDDDDDDDD....RRR.....RRRR.EEEEEEEEEEEEAA......AAAA.MMM..MMM..MMM..EEEEEEEEEEE.RRR.....RRRR...SSSSSS.....
//.................................................................................................................................................................

import "./ERC721A.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Address.sol";

contract MoonDreamers is ERC721A, Ownable {
    using Address for address payable;
    using Strings for uint256;

    string private _baseTokenURI;
    bool private _saleStatus = false;
    uint256 private _salePrice = 0.00 ether;
    uint256 private _teamSupply = 500;
    uint256 private _reservedSupply;

    uint256 public MAX_SUPPLY = 10000;
    uint256 public FREE_PER_WALLET = 4;
    uint256 public MAX_MINTS_PER_TX = 4;
    uint256 public MAX_PER_WALLET = 4;

    constructor() ERC721A("MoonDreamers", "MOONDREAMERS") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function setMaxMintPerTx(uint256 maxMint) external onlyOwner {
        MAX_MINTS_PER_TX = maxMint;
    }

    function setSalePrice(uint256 price) external onlyOwner {
        _salePrice = price;
    }

    function toggleSaleStatus() external onlyOwner {
        _saleStatus = !_saleStatus;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json"));
    }
    
    function trackUserMinted(address minter) external view returns (uint32 userMinted) {
        return uint32(_numberMinted(minter));
    }        

    function mint(uint256 quantity)
        external
        payable
        callerIsUser
    {
        uint256 userMintCount = uint256(_numberMinted(msg.sender));
        uint256 freeQuantity = 0;

        if (userMintCount < FREE_PER_WALLET) {
            uint256 freeLeft = FREE_PER_WALLET - userMintCount;
            freeQuantity += freeLeft > quantity ? quantity : freeLeft;
        }

        uint256 totalPrice = (quantity - freeQuantity) * _salePrice;

        if (totalPrice > msg.value)
            revert("MoonDreamers: Insufficient fund");

        if (!isSaleActive()) revert("MoonDreamers: Sale not started");
        
        if (quantity > MAX_MINTS_PER_TX)
            revert("MoonDreamers: Amount exceeds transaction limit");
        if (quantity + userMintCount > MAX_PER_WALLET)
            revert("MoonDreamers: Amount exceeds wallet limit");
        if (totalSupply() + quantity > (MAX_SUPPLY))
            revert("MoonDreamers: Amount exceeds supply");

        _safeMint(msg.sender, quantity);
        if (msg.value > totalPrice) {
            payable(msg.sender).sendValue(msg.value - totalPrice);
        }              
    }

    function adminMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "MoonDreamers: Amount exceeds supply");

        _safeMint(msg.sender, quantity);
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 1;
        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= totalSupply()
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function mintToAddress(address to, uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > MAX_SUPPLY)
            revert("MoonDreamers: Amount exceeds supply");

        _safeMint(to, quantity);
    }

    function isSaleActive() public view returns (bool) {
        return _saleStatus;
    }

    function getSalePrice() public view returns (uint256) {
        return _salePrice;
    }

}