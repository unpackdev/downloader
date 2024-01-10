// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";

import "./AggregatorV3Interface.sol";

import "./IOffscriptNFT.sol";

import "./console.sol";

contract OffscriptPayment is Ownable {
    //
    // Libraries
    //
    using SafeERC20 for IERC20;

    //
    // Events
    //

    //Save some info?
    event Payment(
        address indexed payer,
        uint256 indexed nftId,
        address indexed tokenId,
        bool extended,
        uint256 amount
    );

    //
    // State
    //
    IERC20 public dai;
    IERC20 public usdt;
    IERC20 public usdc;

    // NFT contract
    IOffscriptNFT public nft;

    event SupplyUpdated(uint256 newSupply);

    // base ticket price, in USD
    uint16 public basePrice;
    uint16 public extendedPrice;

    //Ticket Supply
    uint16 public supply;
    uint16 public sold;

    mapping(address => AggregatorV3Interface) public oracles;

    mapping(uint256 => bool) public used;

    constructor(
        IERC20 _dai,
        IERC20 _usdt,
        IERC20 _usdc,
        AggregatorV3Interface _oracleEth,
        AggregatorV3Interface _oracleDai,
        AggregatorV3Interface _oracleUsdt,
        AggregatorV3Interface _oracleUsdc,
        IOffscriptNFT _nft,
        uint16 _basePrice,
        uint16 _extendedPrice,
        uint16 _supply
    ) Ownable() {
        require(address(_dai) != address(0));
        require(address(_usdt) != address(0));
        require(address(_usdc) != address(0));
        require(address(_oracleEth) != address(0));
        require(address(_oracleUsdt) != address(0));
        require(address(_oracleDai) != address(0));
        require(address(_oracleUsdc) != address(0));

        nft = _nft;
        dai = _dai;
        usdt = _usdt;
        usdc = _usdc;

        oracles[address(0x0)] = _oracleEth;
        oracles[address(_dai)] = _oracleDai;
        oracles[address(_usdt)] = _oracleUsdt;
        oracles[address(_usdc)] = _oracleUsdc;

        basePrice = _basePrice;
        extendedPrice = _extendedPrice;

        supply = _supply;

        emit SupplyUpdated(_supply);
    }

    function checkForNft(uint256 tokenId) internal view returns (uint256) {
        if (tokenId == 0) {
            return 0;
        }

        (uint16 discount, ) = nft.getMetadata(tokenId);
        return discount;
    }

    function payWithEth(uint256 tokenId, bool _extended) external payable {
        require(sold < supply, "no tickets available");
        if (tokenId > 0) {
            require(nft.ownerOf(tokenId) == msg.sender, "is not the owner");
            require(!used[tokenId], "nft already used");
            used[tokenId] = true;
        }

        uint256 finalValue = getPriceEth(tokenId, _extended);

        require(msg.value >= finalValue, "not enough sent");

        sold++;
        if (msg.value > finalValue) {
            payable(msg.sender).transfer(msg.value - finalValue);
        }

        emit Payment(msg.sender, tokenId, address(0), _extended, finalValue);
    }

    function payWithERC20(
        address _token,
        uint256 tokenId,
        bool _extended
    ) external {
        require(sold < supply, "no tickets available");
        require(_token != address(0x0));
        AggregatorV3Interface oracle = oracles[_token];

        require(address(oracle) != address(0x0), "token not supported");

        if (tokenId > 0) {
            require(nft.ownerOf(tokenId) == msg.sender, "is not the owner");
            require(!used[tokenId], "nft already used");
            used[tokenId] = true;
        }
        uint256 finalValue = getPriceERC20(_token, tokenId, _extended);
        sold++;

        IERC20(_token).safeTransferFrom(msg.sender, address(this), finalValue);

        emit Payment(msg.sender, tokenId, _token, _extended, finalValue);
    }

    function getPriceEth(uint256 tokenId, bool _extended)
        public
        view
        returns (uint256)
    {
        AggregatorV3Interface oracle = oracles[address(0x0)];

        (, int256 price, , , ) = oracle.latestRoundData();

        uint256 finalValue = getPriceUSD(tokenId, _extended);

        return
            (((finalValue * 10**(oracle.decimals() * 2)) / uint256(price)) *
                10**18) / 10**oracle.decimals();
    }

    function getPriceERC20(
        address token,
        uint256 tokenId,
        bool _extended
    ) public view returns (uint256) {
        AggregatorV3Interface oracle = oracles[token];

        uint256 decimals = IERC20Metadata(token).decimals();

        (, int256 price, , , ) = oracle.latestRoundData();

        uint256 finalValue = getPriceUSD(tokenId, _extended);

        return
            (((finalValue * 10**(oracle.decimals() * 2)) / uint256(price)) *
                10**decimals) / 10**oracle.decimals();
    }

    function getPriceUSD(uint256 tokenId, bool _extended)
        public
        view
        returns (uint256)
    {
        uint256 usdPrice = _extended ? extendedPrice : basePrice;
        uint256 discount = checkForNft(tokenId);
        uint256 discountValue = (usdPrice * discount) / 100;
        return usdPrice - discountValue;
    }

    function sweep() external onlyOwner {
        if (dai.balanceOf(address(this)) > 0) {
            dai.safeTransfer(msg.sender, dai.balanceOf(address(this)));
        }

        if (usdt.balanceOf(address(this)) > 0) {
            usdt.safeTransfer(msg.sender, usdt.balanceOf(address(this)));
        }

        if (usdc.balanceOf(address(this)) > 0) {
            usdc.safeTransfer(msg.sender, usdc.balanceOf(address(this)));
        }

        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function remainingSupply() public view returns (uint16) {
        // may happen if we later change the supply to a lower value
        if (sold >= supply) {
            return 0;
        }

        return supply - sold;
    }

    function setSupply(uint16 _newSupply) public onlyOwner {
        supply = _newSupply;

        emit SupplyUpdated(_newSupply);
    }
}
