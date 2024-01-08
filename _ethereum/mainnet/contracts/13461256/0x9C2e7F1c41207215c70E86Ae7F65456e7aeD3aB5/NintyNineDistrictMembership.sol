// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract NintyNineDistrictMembership is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;

    struct Whitelist {
        bool approved;
        uint256 minted;
    }

    uint256 public constant SALE_ENDING_PRICE = 0.099 ether;
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant SALE_START_PRICE = 0.99 ether;
    uint256 public constant DROP_DURATION = 16200;
    address public immutable fundWallet;

    uint256 public minted;
    uint256 public maxPurchase = 5;

    // Public sale params
    uint256 public publicSaleStartTime;
    uint256 public publicSaleDuration;
    uint256 public publicSaleStartingPrice;

    // pre sale params
    uint256 public preSaleStartTime;
    uint256 public preSaleDuration;
    uint256 public preSaleStartingPrice;
    uint256 public preSaleWalletLimit = 1;
    
    bool public isSaleActive;
    bool public isPreSaleActive;
    
    string private baseURI;

    mapping(address => Whitelist) private whitelistInfo;

    event SaleStart(
        uint256 indexed _saleDuration,
        uint256 indexed _saleStartTime
    );
    event SalePaused(
        uint256 indexed _currentPrice,
        uint256 indexed _timeElapsed
    );

    modifier whenPublicSaleActive() {
        require(isSaleActive, "Public sale is not active");
        _;
    }

     modifier whenPreSaleActive() {
        require(isPreSaleActive, "Pre sale is not active");
        _;
    }

    constructor(address _fundWallet) ERC721("99 District Membership", "99DM") {
        fundWallet = _fundWallet;
    }

    function forAirdrop(address[] memory _to, uint256[] memory _count) external onlyOwner {
        uint256 _length = _to.length;
        for (uint256 i = 0; i < _length; i++) {
			giveaway(_to[i], _count[i]);
		}
	}

    function giveaway(address _to, uint256 _howMany) public onlyOwner {
        require(_to != address(0), "Zero address");
        require(_howMany > 0, "Mint amount should be greater than 1");
        _mintToken(_to, _howMany);
	}

    function _beforeMint(uint256 _howMany) private view {
        require(_howMany > 0, "Must mint at least one");
        require(_howMany <= maxPurchase, "Requested number exceeds maximum");
        require(minted + _howMany <= MAX_SUPPLY, "Minting would exceed max supply");
        require(!_isContract(_msgSender()), "Caller cannot be contract");
    }

    function preSaleMint(uint256 _howMany) public payable nonReentrant whenPreSaleActive {
        _beforeMint(_howMany);
        require(isWhitelisted(_msgSender()), "Not whitelisted");
        require(whitelistUserMint(_msgSender()) + _howMany <= preSaleWalletLimit, "Presale max limit exceeds");

        uint256 costToMint = getPreSaleMintPrice() * _howMany;
        require(costToMint <= msg.value, "Ether value sent is not correct");

        _mintToken(_msgSender(), _howMany);
        
        whitelistInfo[_msgSender()].minted = _howMany;

        if (msg.value > costToMint) {
            Address.sendValue(payable(_msgSender()), msg.value - costToMint);
        }
    }

    function saleMint(uint256 _howMany) public payable nonReentrant whenPublicSaleActive {
        _beforeMint(_howMany);

        uint256 costToMint = getPublicSaleMintPrice() * _howMany;
        require(costToMint <= msg.value, "Ether value sent is not correct");

        _mintToken(_msgSender(), _howMany);

        if (msg.value > costToMint) {
            Address.sendValue(payable(_msgSender()), msg.value - costToMint);
        }
    }

    function _mintToken(address _to, uint256 _count) private {
        for (uint256 i = 0; i < _count; i++) {
            minted++;
            _safeMint(_to, minted);
		}
	}

    function startPublicSale(uint256 _saleDuration, uint256 _saleStartPrice) external onlyOwner {
        require(!isSaleActive, "Public sale has already begun");
        publicSaleStartTime = block.timestamp;
        publicSaleDuration = _saleDuration;
        publicSaleStartingPrice = _saleStartPrice;
        publicSaleStartTime = block.timestamp;
        isSaleActive = true;
        emit SaleStart(publicSaleDuration, publicSaleStartTime);
    }

    function pausePublicSale() external onlyOwner whenPublicSaleActive {
        uint256 currentSalePrice = getPublicSaleMintPrice();
        isSaleActive = false;
        emit SalePaused(currentSalePrice, getElapsedPublicSaleTime());    
    }

    function startPreSale(uint256 _saleDuration, uint256 _saleStartPrice) external onlyOwner {
        require(!isPreSaleActive, "Pre sale has already begun");
        preSaleStartTime = block.timestamp;
        preSaleDuration = _saleDuration;
        preSaleStartingPrice = _saleStartPrice;
        preSaleStartTime = block.timestamp;
        isPreSaleActive = true;
        emit SaleStart(preSaleDuration, preSaleStartTime);
    }

    function pausePreSale() external onlyOwner whenPreSaleActive {
        uint256 currentSalePrice = getPreSaleMintPrice();
        isPreSaleActive = false;
        emit SalePaused(currentSalePrice, getElapsedPreSaleTime());    
    }

    function addToWhitelistMultiple(address[] memory _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            addToWhitelist(_addresses[i]);
        }
    }

    function addToWhitelist(address _address) public onlyOwner {
        whitelistInfo[_address].approved = true;
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelistInfo[_address].approved;
    }

    function whitelistUserMint(address _address) public view returns(uint256) {
        return whitelistInfo[_address].minted;
    }

    function getElapsedPreSaleTime() public view returns (uint256) {
        return preSaleStartTime > 0 ? block.timestamp - preSaleStartTime : 0;
    }

    function getRemainingPreSaleTime() external view returns (uint256) {
        require(preSaleStartTime > 0, "Pre sale hasn't started yet");
        if (getElapsedPreSaleTime() >= preSaleDuration) {
            return 0;
        }
        return (preSaleStartTime + preSaleDuration) - block.timestamp;
    }

    function getPreSaleMintPrice() public view  returns (uint256) {
        uint256 elapsed = getElapsedPreSaleTime();
        if (elapsed >= preSaleDuration) {
            return SALE_ENDING_PRICE;
        } else {
            uint256 currentPrice = ((preSaleDuration - elapsed) * preSaleStartingPrice) / preSaleDuration;
            return currentPrice > SALE_ENDING_PRICE ? currentPrice : SALE_ENDING_PRICE;
        }
    }

    function getElapsedPublicSaleTime() public view returns (uint256) {
        return publicSaleStartTime > 0 ? block.timestamp - publicSaleStartTime : 0;
    }

    function getRemainingPublicSaleTime() external view returns (uint256) {
        require(publicSaleStartTime > 0, "Public sale hasn't started yet");
        if (getElapsedPublicSaleTime() >= publicSaleDuration) {
            return 0;
        }
        return (publicSaleStartTime + publicSaleDuration) - block.timestamp;
    }

    function getPublicSaleMintPrice() public view  returns (uint256) {
        uint256 elapsed = getElapsedPublicSaleTime();
        if (elapsed >= publicSaleDuration) {
            return SALE_ENDING_PRICE;
        } else {
            uint256 currentPrice = ((publicSaleDuration - elapsed) * publicSaleStartingPrice) / publicSaleDuration;
            return currentPrice > SALE_ENDING_PRICE ? currentPrice : SALE_ENDING_PRICE;
        }
    }

    function _isContract(address _addr) private view returns (bool) {
        uint32 _size;
        assembly {
            _size := extcodesize(_addr)
        }
        return (_size > 0);
    }

    function modifyPreSaleWalletLimit(uint256 _preSaleWalletLimit) external onlyOwner {
        preSaleWalletLimit = _preSaleWalletLimit;
    }

    function modifyMaxPurchase(uint256 _maxPurchase) external onlyOwner {
        maxPurchase = _maxPurchase;
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function burn(uint256 tokenId) external virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        _burn(tokenId);
    }

    function withdraw() external onlyOwner {
        payable(fundWallet).transfer(address(this).balance);
    }

}