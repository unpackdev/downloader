// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//..............................................................................................................................................................
//.WWWW.....WWWWW.....WWWW....AAAAA.............GGGGGGG......GMMMMM......MMMMMM..MIIII.............AAAAAA.......APPPPPPPPPP.....PEEEEEEEEEEEEE......SSSSSS......
//.WWWW.....WWWWW....WWWWW...AAAAAAA..........GGGGGGGGGGG....GMMMMMM.....MMMMMM..MIIII.............AAAAAA.......APPPPPPPPPPPP...PEEEEEEEEEEEEE....SSSSSSSSSS....
//.WWWW....WWWWWW....WWWWW...AAAAAAA.........GGGGGGGGGGGGG...GMMMMMM.....MMMMMM..MIIII.............AAAAAAA......APPPPPPPPPPPPP..PEEEEEEEEEEEEE...SSSSSSSSSSSS...
//.WWWWW...WWWWWWW...WWWW....AAAAAAA........GGGGGGGGGGGGGGG..GMMMMMM....MMMMMMM..MIIII............AAAAAAAA......APPPPPPPPPPPPP..PEEEEEEEEEEEEE..ESSSSSSSSSSSS...
//.WWWWW...WWWWWWW...WWWW...AAAAAAAAA......GGGGGG.....GGGGG..GMMMMMMM...MMMMMMM..MIIII............AAAAAAAA......APPP.....PPPPP..PEEE............ESSSS....SSSSS..
//..WWWW..WWWWWWWW...WWWW...AAAA.AAAA......GGGGG.......GG....GMMMMMMM...MMMMMMM..MIIII...........AAAAAAAAAA.....APPP......PPPP..PEEE............ESSSS....SSSSS..
//..WWWW..WWWWWWWW..WWWWW...AAAA.AAAAA.....GGGG..............GMMMMMMM..MMMMMMMM..MIIII...........AAAAA.AAAA.....APPP......PPPP..PEEE............ESSSSSSS........
//..WWWWW.WWWW.WWWW.WWWW...AAAAA.AAAAA....AGGGG..............GMMMMMMMM.MMMMMMMM..MIIII...........AAAA..AAAA.....APPP.....PPPPP..PEEEEEEEEEEEE....SSSSSSSSSS.....
//..WWWWW.WWWW.WWWW.WWWW...AAAA...AAAA....AGGGG....GGGGGGGG..GMMMMMMMM.MMM.MMMM..MIIII..........AAAAA..AAAAA....APPPPPPPPPPPPP..PEEEEEEEEEEEE....SSSSSSSSSSSS...
//...WWWWWWWW..WWWW.WWWW...AAAA...AAAAA...AGGGG....GGGGGGGG..GMMMMMMMM.MMM.MMMM..MIIII..........AAAAA...AAAA....APPPPPPPPPPPP...PEEEEEEEEEEEE......SSSSSSSSSSS..
//...WWWWWWWW..WWWWWWWWW..AAAAAAAAAAAAA....GGGG....GGGGGGGG..GMMMM.MMMMMMM.MMMM..MIIII..........AAAAAAAAAAAAA...APPPPPPPPPPPP...PEEEEEEEEEEEE.........SSSSSSSS..
//...WWWWWWWW...WWWWWWW...AAAAAAAAAAAAA....GGGG....GGGGGGGG..GMMMM.MMMMMMM.MMMM..MIIII.........AAAAAAAAAAAAAA...APPPPPPPPPP.....PEEE............ESSS.....SSSSS..
//...WWWWWWWW...WWWWWWW...AAAAAAAAAAAAAA...GGGGG.......GGGG..GMMMM.MMMMMMM.MMMM..MIIII.........AAAAAAAAAAAAAA...APPP............PEEE............ESSS......SSSS..
//....WWWWWW....WWWWWWW..WAAAAAAAAAAAAAA...GGGGGG.....GGGGG..GMMMM.MMMMMM..MMMM..MIIII.........AAAAAAAAAAAAAAA..APPP............PEEE............ESSSS....SSSSS..
//....WWWWWW.....WWWWWW..WAAA.......AAAAA...GGGGGGGGGGGGGGG..GMMMM..MMMMM..MMMM..MIIII........ AAAA......AAAAA..APPP............PEEEEEEEEEEEEE..ESSSSSSSSSSSSS..
//....WWWWWW.....WWWWW..WWAAA.......AAAAA....GGGGGGGGGGGGGG..GMMMM..MMMMM..MMMM..MIIII........ AAAA.......AAAA..APPP............PEEEEEEEEEEEEE...SSSSSSSSSSSS...
//....WWWWWW.....WWWWW..WWAAA........AAAA.....GGGGGGGGGGG....GMMMM..MMMMM..MMMM..MIIII........ AAA........AAAAA.APPP............PEEEEEEEEEEEEE....SSSSSSSSSS....
//.....WWWW.......WWWW..WWAA.........AAAAA......GGGGGGG......GMMMM..MMMM...MMMM..MIIII....... AAA........AAAAA.APPP............PEEEEEEEEEEEEE......SSSSSS......
//..............................................................................................................................................................


import "./ERC721A.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Address.sol";

contract WagmiApes is ERC721A, Ownable {
    using Address for address payable;
    using Strings for uint256;

    string private _baseTokenURI;
    bool private _saleStatus = false;
    uint256 private _salePrice = 0.00 ether;
    uint256 private _teamSupply = 200;
    uint256 private _reservedSupply;

    uint256 public MAX_SUPPLY = 3333;
    uint256 public FREE_PER_WALLET = 5;
    uint256 public MAX_MINTS_PER_TX = 5;
    uint256 public MAX_PER_WALLET = 5;

    constructor() ERC721A("WagmiApes", "WAGMIAPES") {}

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
            revert("WagmiApes: Insufficient fund");

        if (!isSaleActive()) revert("WagmiApes: Sale not started");
        
        if (quantity > MAX_MINTS_PER_TX)
            revert("WagmiApes: Amount exceeds transaction limit");
        if (quantity + userMintCount > MAX_PER_WALLET)
            revert("WagmiApes: Amount exceeds wallet limit");
        if (totalSupply() + quantity > (MAX_SUPPLY))
            revert("WagmiApes: Amount exceeds supply");

        _safeMint(msg.sender, quantity);
        if (msg.value > totalPrice) {
            payable(msg.sender).sendValue(msg.value - totalPrice);
        }              
    }

    function adminMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "WagmiApes: Amount exceeds supply");

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
            revert("WagmiApes: Amount exceeds supply");

        _safeMint(to, quantity);
    }

    function isSaleActive() public view returns (bool) {
        return _saleStatus;
    }

    function getSalePrice() public view returns (uint256) {
        return _salePrice;
    }

}