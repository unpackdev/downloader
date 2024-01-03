// SPDX-License-Identifier: MIT
pragma solidity >0.6.0;
pragma experimental ABIEncoderV2;

import "./DNFTLibrary.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";
import "./IERC20Token.sol";
import "./SafeERC20.sol";

contract DNFTProduct is ERC721, Ownable {

    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeERC20 for IERC20;

    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    mapping(uint256 => Lib.ProductTokenDetail) private _tokenDetails;
    mapping(uint256 => Lib.ProductMintItem[]) private _tokenMintHistories;
    mapping(address => EnumerableSet.UintSet) private _tokenMints;

    address public dnftTokenAddr;
    address public uniswapAddr;
    address public mainAddr;

    uint256 public mintPerTimeValue;

    uint16 public pid;
    uint256 public maxMintTime;
    uint256 public maxTokenSize;
    address public costTokenAddr;
    uint256 public cost;
    uint32 public totalReturnRate;
    uint256 public mintTimeInterval;
    uint8 public costTokenDecimals;

    Counters.Counter private _tokenIds;
    bool private _init;

    modifier onlyMain() {
        require(mainAddr == msg.sender, "caller is not the main");
        _;
    }
    constructor (
        string memory _name,
        string memory _symbol,
        string memory baseURI
    )  ERC721(_name, _symbol) {
        _setBaseURI(string(abi.encodePacked(baseURI, _name, "/")));
    }

    function initProduct(
        address _mainAddr,
        address _dnftTokenAddr,
        address _uniswapAddr,
        uint16 _id,
        address _costTokenAddr,
        uint256 _cost,
        uint32 _totalReturnRate,
        uint256 _maxMintTime,
        uint256 _maxTokenSize
    ) external onlyOwner {
        require(!_init, "repeat init");
        require(_maxTokenSize < 1E6, "product total supply must be < 1E6");
        mainAddr = _mainAddr;
        pid = _id;
        costTokenAddr = _costTokenAddr;
        cost = _cost;
        maxTokenSize = _maxTokenSize;
        maxMintTime = _maxMintTime;
        totalReturnRate = _totalReturnRate;
        dnftTokenAddr = _dnftTokenAddr;
        uniswapAddr = _uniswapAddr;
        if (_costTokenAddr != address(0)) {
            costTokenDecimals = IERC20Token(_costTokenAddr).decimals();
        } else {
            costTokenDecimals = 18;
        }
        mintTimeInterval = 1 minutes;
        mintPerTimeValue = totalReturnRate.mul(cost).div(100).div(maxMintTime.div(mintTimeInterval));
    }


    function _onlyMinter(address from, uint256 tokenId) private view {
        require(_isApprovedOrOwner(address(this), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(_tokenDetails[tokenId].mining == true, "Token no mining.");
        require(_tokenDetails[tokenId].currMining.minter == from, "Token mine is not owner.");
    }

    function _getUniswapPrice(IUniswapV2Router02 r02, uint256 _tv1, address token1, address token2) private view returns (uint256){
        uint256 tv1 = _tv1;
        IUniswapV2Factory f = IUniswapV2Factory(r02.factory());
        address pairAddr = f.getPair(token1, token2);
        require(pairAddr != address(0), "DNFT uniswap pair not exists.");
        IERC20Token t1 = IERC20Token(token1);
        IERC20Token t2 = IERC20Token(token2);
        uint256 tb1 = t1.balanceOf(pairAddr);
        uint256 tb2 = t2.balanceOf(pairAddr);
        require(tb1 > 0 && tb2 > 0, "Pair token balance < 0");
        uint256 td1 = 10 ** t1.decimals();
        return td1.mul(tv1).div(tb1).mul(tb2).div(td1);
    }

    function _getDNFTPrice() private view returns (uint256){
        if (costTokenAddr == address(dnftTokenAddr))
            return 1E8;
        if (uniswapAddr == address(0)) {
            return 1000 * 1E8;
        }
        IUniswapV2Router02 r02 = IUniswapV2Router02(uniswapAddr);
        address wethAddr = r02.WETH();
        uint256 oneEthDnftPrice = _getUniswapPrice(r02, 1E18, wethAddr, address(dnftTokenAddr));
        if (costTokenAddr == address(0)) {
            return oneEthDnftPrice;
        } else {
            uint256 oneEthTokenPrice = _getUniswapPrice(r02, 1E18, wethAddr, costTokenAddr);
            if (costTokenDecimals == 8)
                return (oneEthDnftPrice * 1E8 / oneEthTokenPrice);
            if (costTokenDecimals < 8)
                return (oneEthDnftPrice * 1E8 / oneEthTokenPrice / (10 ** (8 - uint256(costTokenDecimals))));
            return (oneEthDnftPrice * 1E8 / oneEthTokenPrice) * (10 ** (uint256(costTokenDecimals) - 8));
        }
    }

    function _canWithdrawValue(uint256 tokenId) private view returns (uint256 timeNum, uint256 dnftNum){
        uint256 price = _getDNFTPrice();
        Lib.ProductTokenDetail storage detail = _tokenDetails[tokenId];
        uint256 freeTimeNum = (maxMintTime.sub(detail.totalTime)).div(mintTimeInterval);
        if (freeTimeNum <= 0) {
            return (0, 0);
        }
        timeNum = block.timestamp.sub(detail.currMining.withdrawTime).div(mintTimeInterval);
        if (timeNum > freeTimeNum) {
            timeNum = freeTimeNum;
        }
        if (timeNum <= 0) {
            return (0, 0);
        }
        uint256 decimal = 18;
        if (costTokenAddr != address(0))
            decimal = uint256(costTokenDecimals);
        dnftNum = mintPerTimeValue.mul(price).mul(timeNum).div(10 ** decimal);
        if (dnftNum <= 0) {
            return (0, 0);
        }
    }

    function _mintWithdraw(address player, uint256 tokenId) private returns (uint256, uint256){
        (uint256 timeNum, uint256 dnftNum) = _canWithdrawValue(tokenId);
        if (dnftNum <= 0)
            return (dnftNum, timeNum);
        Lib.ProductTokenDetail storage detail = _tokenDetails[tokenId];
        detail.totalValue = detail.totalValue.add(dnftNum);
        detail.currMining.totalValue = detail.currMining.totalValue.add(dnftNum);
        uint256 useTime = timeNum.mul(mintTimeInterval);
        detail.currMining.withdrawTime = detail.currMining.withdrawTime.add(useTime);
        detail.totalTime = detail.totalTime.add(useTime);
        IERC20Token(dnftTokenAddr).transfer(player, dnftNum);
        return (dnftNum, timeNum);
    }


    function getDNFTPrice() external view returns (uint256){
        return _getDNFTPrice();
    }

    function tokensOfOwner(address owner) external view returns (Lib.ProductTokenDetail[] memory){
        EnumerableSet.UintSet storage mintTokens = _tokenMints[owner];
        uint holdLength = balanceOf(owner);
        uint tokenLengthSize = mintTokens.length() + holdLength;
        if (tokenLengthSize == 0) {
            Lib.ProductTokenDetail[] memory zt = new Lib.ProductTokenDetail[](0);
            return zt;
        }
        Lib.ProductTokenDetail[] memory tokens = new Lib.ProductTokenDetail[](tokenLengthSize);
        uint i = 0;
        while (i < mintTokens.length()) {
            tokens[i] = _tokenDetails[mintTokens.at(i)];
            i++;
        }
        uint j = 0;
        while (j < holdLength) {
            tokens[i] = _tokenDetails[tokenOfOwnerByIndex(owner, j)];
            i++;
            j++;
        }
        return tokens;
    }

    function tokenDetailOf(uint256 tid) external view returns (Lib.ProductTokenDetail memory){
        return _tokenDetails[tid];
    }

    function tokenMintHistoryOf(uint256 tid) external view returns (Lib.ProductMintItem[] memory){
        return _tokenMintHistories[tid];
    }


    function withdrawToken(address payable to, address token, uint256 value) onlyMain external {
        if (token == address(0))
            to.transfer(value);
        else
            IERC20(token).safeTransfer(to, value);
    }

    // buy product
    function buy(address to) external onlyMain returns (uint256) {
        require(_tokenIds.current() < maxTokenSize, "product not enough");
        _tokenIds.increment();
        uint256 tid = pid * 1E6 + _tokenIds.current();
        Lib.ProductTokenDetail memory detail;
        detail.id = tid;
        detail.propA = Lib.random(0, 10000);
        detail.propB = Lib.random(0, 10000);
        detail.propC = Lib.random(0, 10000);
        _tokenDetails[tid] = detail;
        _safeMint(to, tid);
        _setTokenURI(tid, Strings.toString(tid));
        return tid;
    }


    function mintBegin(address from, uint256 tokenId) external onlyMain {
        require(_isApprovedOrOwner(from, tokenId), "ERC721: transfer caller is not owner nor approved");
        Lib.ProductTokenDetail storage detail = _tokenDetails[tokenId];
        require(detail.mining == false, "Token already mining.");
        require(detail.totalTime < maxMintTime, "Token already dead.");
        detail.mining = true;
        detail.currMining.minter = from;
        detail.currMining.beginTime = block.timestamp;
        detail.currMining.endTime = 0;
        detail.currMining.withdrawTime = detail.currMining.beginTime;
        _tokenMints[from].add(tokenId);
        _transfer(from, address(this), tokenId);
    }


    function canWithdrawValue(uint256 tokenId) external view returns (uint256 timeNum, uint256 dnftNum){
        return _canWithdrawValue(tokenId);
    }

    function mintWithdraw(address from, uint256 tokenId) external onlyMain returns (uint256, uint256) {
        _onlyMinter(from, tokenId);
        return _mintWithdraw(from, tokenId);
    }

    function redeem(address from, uint256 tokenId) external onlyMain returns (uint256, uint256){
        _onlyMinter(from, tokenId);
        (uint256 withdrawNum,uint256 timeNum) = _mintWithdraw(from, tokenId);

        Lib.ProductTokenDetail storage detail = _tokenDetails[tokenId];
        detail.mining = false;
        detail.currMining.endTime = block.timestamp;
        _tokenMintHistories[tokenId].push(detail.currMining);

        _tokenMints[from].remove(tokenId);
        Lib.ProductMintItem memory currItem;
        detail.currMining = currItem;

        _safeTransfer(address(this), from, tokenId, "");
        return (withdrawNum, timeNum);
    }

}