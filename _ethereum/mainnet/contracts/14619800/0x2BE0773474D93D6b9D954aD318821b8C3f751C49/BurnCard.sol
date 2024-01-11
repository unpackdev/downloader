// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.7;

import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC20.sol";

contract BurnCard is ERC721, Ownable {
    using Strings for uint256;

    IERC20 immutable public SHIBA_DOGE;
    uint256 public minShibaDogeBalance;

    IERC20 public burnToken;
    bool public tokenLocked;
    bool public incinerateValueLocked;

    uint256 public incinerateValue = 15000000000 * (10**18); // .015 max supply
    uint256 public constant MAX_SUPPLY = 69;
    
    uint256 public publicPrice = 5 ether;
    uint256 public totalSupply;

    uint256 public maxPerWallet;
    mapping (address => uint256) public numMinted;

    bool public isPublicSale;
    bool public burnLaunched;

    bool public isURIFrozen;
    
    string public baseURI = "TODO";

    event tokenIncinerated(address owner, uint256 tokenId);

    event launchedBurn();

    event burnTokenSet(address token);
    event lockedToken();
    
    event incincerateValueSet(uint256 incinerateValue);
    event lockedIncinerateValue();

    event URIFrozen();
    event URISet(string URI);

    event publicPriceSet(uint256 publicPrice);
    event publicSaleToggled(bool isPublicSale);

    event minShibaDogeBalanceUpdated(uint256 minShibaDogeBalance);

    event totalWalletMinted(address sender, uint256 amount);
    event maxPerWalletUpdated(uint256 amount);
 
    constructor(IERC20 _ShibaDoge, uint256 _minShibaDoge, uint256 _maxPerWallet) ERC721("BurnCard", "BURNCARD") {
        SHIBA_DOGE = _ShibaDoge;
        minShibaDogeBalance = _minShibaDoge;
        maxPerWallet = _maxPerWallet;
    }

    function mint(uint256 amount) external payable {
        // Sale must be active
        require(isPublicSale, "Public Sale Inactive");

        // must mint at least 1
        require(amount > 0, "Number of tokens should be more than 0");

        // cannot mint more than max supply
        require(totalSupply + amount <= MAX_SUPPLY, "Sold Out");

        // must send enough funds to purchase
        require(publicPrice * amount <= msg.value, "Insufficient Funds");

        // must have enough ShibaDoge to purchase
        uint256 sdBalance = SHIBA_DOGE.balanceOf(msg.sender);
        require(sdBalance >= minShibaDogeBalance, "Sender does not hold enough ShibaDoge");

        // can only mint a maximum number of burn cards per wallet
        require(maxPerWallet >= numMinted[msg.sender] + amount, "Wallet has already claimed maximum mints");
        numMinted[msg.sender] += amount;
        emit totalWalletMinted(msg.sender, numMinted[msg.sender]);

        // do the mint
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, ++totalSupply);
        }
    }

    function reserve(uint256 amount, address destination) external onlyOwner {
        require(amount > 0, "cannot mint 0");
        require(totalSupply + amount <= MAX_SUPPLY, "Sold Out");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(destination, ++totalSupply);
        }
    }

    function incinerate(uint256 tokenId) external {
        require(burnLaunched, "Incinerator not warmed up yet");
        require(msg.sender == ownerOf(tokenId), "Caller does not own NFT");
        _burn(tokenId);
        
        require(burnToken.transfer(msg.sender, incinerateValue));
        emit tokenIncinerated(msg.sender, tokenId);
    }

    function launchBurn() external onlyOwner {
        require(!burnLaunched, "Already launched");
        require(address(burnToken) != address(0), "burnToken must be set");
        require(burnToken.balanceOf(address(this)) >= MAX_SUPPLY * incinerateValue);
        burnLaunched = true;
        emit launchedBurn();
    }

    function togglePublicSale() external onlyOwner {
        isPublicSale = !isPublicSale;
        emit publicSaleToggled(isPublicSale);
    }

    function setIncinerateValue(uint256 value) external onlyOwner {
        require(!incinerateValueLocked);
        incinerateValue = value;
        emit incincerateValueSet(incinerateValue);
    }

    function lockIncinerateValue() external onlyOwner {
        incinerateValueLocked = true;
        emit lockedIncinerateValue();
    }

    function setBurnToken(address token) external onlyOwner {
        require(!tokenLocked, "Token is already locked");
        burnToken = IERC20(token);
        emit burnTokenSet(token);
    }

    function lockBurnToken() external onlyOwner {
        require(!tokenLocked, "Token already locked");
        tokenLocked = true;
        emit lockedToken();
    }
    
    function setPublicPrice(uint256 _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
        emit publicPriceSet(publicPrice);
    }

    function freezeURI() external onlyOwner {
        isURIFrozen = true;
        emit URIFrozen();
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function setURI(string calldata _newURI) external onlyOwner {
        require(!isURIFrozen, "URI is Frozen");
        baseURI = _newURI;
        emit URISet(baseURI);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return baseURI;
    }

    function setMinShibaDoge(uint256 amount) external onlyOwner {
        minShibaDogeBalance = amount;
        emit minShibaDogeBalanceUpdated(minShibaDogeBalance);
    }

    function setMaxPerWallet(uint256 amount) external onlyOwner {
        maxPerWallet = amount;
        emit maxPerWalletUpdated(amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

}