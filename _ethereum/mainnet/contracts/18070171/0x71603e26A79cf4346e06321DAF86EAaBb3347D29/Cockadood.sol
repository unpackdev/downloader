// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Strings.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ONFT721.sol";
import "./ICocks.sol";

/**
 * @title Cockadoods
 */

contract Cockadoods is ONFT721 {
    using Strings for uint;
    using SafeERC20 for IERC20;
    uint256 public MAX_MINT_PER_TX; //50
    uint256 public PRICE = 25000000; //25USDC default
    uint public airdropAmt;
    uint public nextMintId;
    uint public maxMintId;
    address public addr1;

    string public baseTokenURI;
    bool public REVEAL;
    bool public isMintChain;
    bool public saleIsActive;

    IERC20 public stablecoin;
    ICocks public cocks;

    mapping(address => uint) public airdropEligible; //Eligible address --> quantity

    constructor(
        string memory _uri,
        string memory _contractName,
        string memory _tokenSymbol,
        uint _startMintId,
        uint _endMintId,
        uint256 _maxMintPerTx,
        uint256 _minGasToTransfer,
        address _layerZeroEndpoint,
        bool _isMintChain
    ) ONFT721(_contractName, _tokenSymbol, _minGasToTransfer, _layerZeroEndpoint) {
        nextMintId = _startMintId;
        maxMintId = _endMintId;
        MAX_MINT_PER_TX = _maxMintPerTx;
        baseTokenURI = _uri;
        isMintChain = _isMintChain;
    }

    function mintONFT(uint256 _quantity) public {
        require(isMintChain == true, "mint unavailable");
        require(nextMintId <= maxMintId, "max mint limit");
        require(saleIsActive, "Sale Inactive");
        require(_quantity > 0, "Invalid Quantity");
        require(PRICE > 0, "price not set");
        require(_quantity <= MAX_MINT_PER_TX, "Exceed limit");
        uint256 mintIndex = nextMintId;
        stablecoin.safeTransferFrom(msg.sender, addr1, PRICE * _quantity);
        cocks.mintTokens(address(this), 12000 * 10 ** 18 * _quantity);

        for (uint256 i = 0; i < _quantity; i++) {
            if (mintIndex <= maxMintId) {
                _safeMint(msg.sender, mintIndex);
                mintIndex++;
            }
        }
        nextMintId = mintIndex;
    }

    function airdropOFT(address[] memory _addresses, uint[] memory _qty, uint _airdropAmt) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            cocks.transferFrom(address(this), _addresses[i], _airdropAmt * 10 ** 18 * _qty[i]);
        }
    }

    function claimOFT() public {
        require(airdropEligible[msg.sender] > 0, "Ineligible or claimed");
        cocks.transferFrom(address(this), msg.sender, airdropAmt * 10 ** 18 * airdropEligible[msg.sender]);
        airdropEligible[msg.sender] = 0;
    }

    //reveal can only be called once
    function revealOnft(string memory updatedURI) public onlyOwner {
        require(REVEAL == true, "already revealed");
        baseTokenURI = updatedURI;
        REVEAL = true;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "nonexistent token");

        string memory baseURI = _baseURI();

        if (REVEAL) {
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")) : "";
        }
        return baseTokenURI;
    }

    function withdrawAllETH(address payable _to) public onlyOwner {
        uint256 balance = address(this).balance;

        (bool success, ) = _to.call{value: balance}("");
        require(success, "Failed to send Eth");
    }

    function setStableCoin(address _stableToken) public onlyOwner {
        stablecoin = IERC20(_stableToken);
    }

    function setCocks(address _cocks) public onlyOwner {
        cocks = ICocks(_cocks);
    }

    function setAddr1(address _addr1) public onlyOwner {
        addr1 = _addr1;
    }

    function setAirdropAmt(uint _airdropAmt) public onlyOwner {
        airdropAmt = _airdropAmt;
    }

    function withdrawTokens(address payable _to, address _token) public onlyOwner {
        require(_to != address(0), "Zero Address");
        IERC20 token = IERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.safeTransfer(_to, balance);
    }

    function withdrawStableCoin(address payable _to) public onlyOwner {
        require(_to != address(0), "Zero Address");
        uint balance = stablecoin.balanceOf(address(this));
        stablecoin.safeTransfer(_to, balance);
    }

    function toggleSaleIsActive() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setPrice(uint256 _price) public onlyOwner {
        PRICE = _price;
    }

    receive() external payable {}
}
