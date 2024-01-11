// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

interface IUniswapV2Router02 {
    function getAmountsOut(uint, address[] memory) external view returns (uint[] memory);
    function WETH() external pure returns (address);
}

contract SaitokiNFTCompanions is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    bool public saleIsActive = false;
    bool public isAllowListActive = false;
    bool public isDiscountEnabled = true;

    string private _baseURIextended;

    uint256 public MAX_SUPPLY = 1111;
    uint256 public MAX_WL_SUPPLY = ~uint256(0);
    uint256 public MAX_TX_MINT = 5;
    uint256 public PRICE_PER_TOKEN_PUBLIC_SALE = 0.08 ether;
    uint256 public PRICE_PER_TOKEN_PRE_SALE = 0.06 ether;
    uint256 public PRICE_PER_TOKEN_FOR_HOLDERS = 0.06 ether;
    uint256 public MINIMUM_HOLD_AMOUNT = 0.5 ether;

    mapping(address => bool) private _allowList;

    address public MononokeInu = 0x4da08a1Bff50BE96bdeD5C7019227164b49C2bFc;
    address public Fortune = 0x9F009D03E1b7F02065017C90e8e0D5Cb378eB015;
    address public SaitokiInu = 0xa3c56427683a19F7574b9fc219CFD27d5d6e87Fa;

    event TokenMinted(uint256 indexed tokenId);

    constructor() ERC721("Saitoki: NFT Companions", "SAITOKI") {
    }

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(address[] calldata addresses, bool allowed) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = allowed;
        }
    }

    function isAllowedToMint(address addr) external view returns (bool) {
        return _allowList[addr];
    }

    function mintAllowList(uint8 numberOfTokens) external payable nonReentrant {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(_allowList[msg.sender], "Address not allowed to purchase");
        require(numberOfTokens <= MAX_TX_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_WL_SUPPLY, "Purchase would exceed max tokens");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");

        if (isDiscountEnabled) {
            if (hasDiscount(msg.sender)) {
                require(PRICE_PER_TOKEN_FOR_HOLDERS * numberOfTokens <= msg.value, "Ether value sent is not correct");
            } else {
                require(PRICE_PER_TOKEN_PRE_SALE * numberOfTokens <= msg.value, "Ether value sent is not correct");   
            }
        } else {
            require(PRICE_PER_TOKEN_PRE_SALE * numberOfTokens <= msg.value, "Ether value sent is not correct");
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint tokenId = ts + i;
            _safeMint(msg.sender, tokenId);
            emit TokenMinted(tokenId);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserve(uint256 n) public onlyOwner {
      uint ts = totalSupply();
      uint i;
      for (i = 0; i < n; i++) {
            uint tokenId = ts + i;
            _safeMint(msg.sender, tokenId);
            emit TokenMinted(tokenId);
      }
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function setPrices(uint256 pPublic, uint256 pPresale, uint256 pHolders) public onlyOwner {
        require(pPublic >= 0 && pPresale >= 0 && pHolders >= 0, "Prices should be higher or equal than zero.");
        PRICE_PER_TOKEN_PUBLIC_SALE = pPublic;
        PRICE_PER_TOKEN_PRE_SALE = pPresale;
        PRICE_PER_TOKEN_FOR_HOLDERS = pHolders;
    }

    function setLimits(uint256 mSupply, uint256 mWLSupply, uint256 mTx) public onlyOwner {
        require(mSupply >= totalSupply(), "MAX_SUPPLY should be higher or equal than total supply.");
        require(mWLSupply <= mSupply, "MAX_WL_SUPPLY should be less or equal than total supply.");
        require(mTx >= 0, "MAX_TX_MINT should be higher or equal than zero.");
        MAX_SUPPLY = mSupply;
        MAX_WL_SUPPLY = mWLSupply;
        MAX_TX_MINT = mTx;
    }

    function setTokens(address mono, address fort, address saito) public onlyOwner {
        MononokeInu = mono;
        Fortune = fort;
        SaitokiInu = saito;
    }

    function setMinimumHoldAmount(uint256 amount) public onlyOwner {
        MINIMUM_HOLD_AMOUNT = amount;
    }

    function mint(uint numberOfTokens) public payable nonReentrant {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_TX_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        if (isDiscountEnabled) {
            if (hasDiscount(msg.sender)) {
                require(PRICE_PER_TOKEN_FOR_HOLDERS * numberOfTokens <= msg.value, "Ether value sent is not correct");
            } else {
                require(PRICE_PER_TOKEN_PUBLIC_SALE * numberOfTokens <= msg.value, "Ether value sent is not correct");    
            }
        } else {
            require(PRICE_PER_TOKEN_PUBLIC_SALE * numberOfTokens <= msg.value, "Ether value sent is not correct");    
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint tokenId = ts + i;
            _safeMint(msg.sender, tokenId);
            emit TokenMinted(tokenId);
        }
    }

    function hasDiscount(address account) public view returns (bool) {
        uint256 monoBalance = IERC20(MononokeInu).balanceOf(account);
        uint256 ethAmountMononoke = 0;
        if (monoBalance > 0) {
            ethAmountMononoke = getTokenAmountPrice(monoBalance, MononokeInu);
        }
        uint256 fortuneBalance = IERC20(Fortune).balanceOf(account);
        uint256 ethAmountFortune = 0;
        if (fortuneBalance > 0) {
            ethAmountFortune = getTokenAmountPrice(fortuneBalance, Fortune);
        }
        uint256 saitokiBalance = IERC20(SaitokiInu).balanceOf(account);
        uint256 ethAmountSaitoki = 0;
        if (saitokiBalance > 0) {
            ethAmountSaitoki = getTokenAmountPrice(saitokiBalance, SaitokiInu);
        }
        return (ethAmountMononoke.add(ethAmountFortune).add(ethAmountSaitoki) >= MINIMUM_HOLD_AMOUNT);
    }

    function setDiscountState(bool newState) public onlyOwner {
        isDiscountEnabled = newState;
    }

    function getTokenAmountPrice(uint256 tokenAmount, address tokenContract) private view returns(uint) {
        address[] memory path = new address[](2);
        path[0] = tokenContract;
        path[1] = uniswapV2Router.WETH();
        
        uint[] memory returnedParam = uniswapV2Router.getAmountsOut(tokenAmount, path);
        
        return returnedParam[1];
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}