// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract StrangeTurtles is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10000;
    address public fundWallet;
    address public secondaryWallet;

    ERC721 public districtMembership;

    uint256 public itemPrice = 0.0799 ether;
    uint256 public minted;
    uint256 public maxPurchase = 5;
    uint256 public preSaleWalletLimit = 2;
    
    bool public isSaleActive;
    bool public isPreSaleActive;
    
    string private baseURI;

    mapping(uint256 => uint256) public presaleMinted;

    modifier whenPublicSaleActive() {
        require(isSaleActive, "Public sale is not active");
        _;
    }

     modifier whenPreSaleActive() {
        require(isPreSaleActive, "Pre sale is not active");
        _;
    }

    constructor(address _fundWallet, address _secondaryWallet, ERC721 _districtMembership) ERC721("Strange Turtles in District99", "STID99") {
        fundWallet = _fundWallet;
        secondaryWallet = _secondaryWallet;
        districtMembership = _districtMembership;
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
        uint256 costToMint = itemPrice * _howMany;
        require(costToMint <= msg.value, "Ether value sent is not correct");
    }

    function preSaleMint(uint256 _howMany, uint256[] memory _membershipId) external payable nonReentrant whenPreSaleActive {
        _beforeMint(_howMany);
		require(_howMany == _membershipId.length, "Invalid data");

        for (uint256 i = 0; i < _howMany; i++) {
		    require(districtMembership.ownerOf(_membershipId[i]) == _msgSender(), "NFT ownership required");
            require(presaleMinted[_membershipId[i]] < preSaleWalletLimit, "Presale max limit exceeds");
            presaleMinted[_membershipId[i]]++;
            minted++;
            _safeMint(_msgSender(), minted);
		}
    }

    function saleMint(uint256 _howMany) external payable nonReentrant whenPublicSaleActive {
        _beforeMint(_howMany);
        _mintToken(_msgSender(), _howMany);
    }

    function _mintToken(address _to, uint256 _count) private {
        for (uint256 i = 0; i < _count; i++) {
            minted++;
            _safeMint(_to, minted);
		}
	}

    function startPublicSale() external onlyOwner {
        require(!isSaleActive, "Public sale has already begun");
        isSaleActive = true;
    }

    function pausePublicSale() external onlyOwner whenPublicSaleActive {
        isSaleActive = false;
    }

    function startPreSale() external onlyOwner {
        require(!isPreSaleActive, "Pre sale has already begun");
        isPreSaleActive = true;
    }

    function pausePreSale() external onlyOwner whenPreSaleActive {
        isPreSaleActive = false;
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

    function setMembershipContract(ERC721 _districtMembership) external onlyOwner {
        districtMembership = _districtMembership;
    }

    function setPrice(uint256 _itemPrice) external onlyOwner {
        itemPrice = _itemPrice;
    }
    
    function updateWallets(address _fundWallet, address _secondaryWallet) external onlyOwner {
        fundWallet = _fundWallet;
        secondaryWallet = _secondaryWallet;
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
        payable(fundWallet).transfer((address(this).balance * 8) / 10);
        payable(secondaryWallet).transfer((address(this).balance * 2) / 10);
    }

}