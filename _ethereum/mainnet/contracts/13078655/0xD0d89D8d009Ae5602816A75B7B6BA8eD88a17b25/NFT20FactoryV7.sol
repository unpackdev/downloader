// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.0;

import "./Initializable.sol";

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20.sol";
import "./AddressUpgradeable.sol";

import "./INFT20Pair.sol";

import "./BeaconProxy.sol";

interface Uni {
    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external returns (uint256[] memory amounts);
}

contract NFT20FactoryV7 is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    // keep track of nft address to pair address
    mapping(address => address) public nftToToken;
    mapping(uint256 => address) public indexToNft;

    uint256 public counter;
    uint256 public fee;

    event pairCreated(
        address indexed originalNFT,
        address newPair,
        uint256 _type
    );

    using AddressUpgradeable for address;
    address public logic;

    // new store V5
    bool public flashLoansEnabled;

    //New Store v6
    address public tokenToSell;
    uint256 public amountToSell;

    constructor() public {}

    function nft20Pair(
        string memory name,
        string memory _symbol,
        address _nftOrigin,
        uint256 _nftType
    ) public payable {
        require(nftToToken[_nftOrigin] == address(0));
        bytes memory initData = abi.encodeWithSignature(
            "init(string,string,address,uint256)",
            name,
            _symbol,
            _nftOrigin,
            _nftType
        );

        address instance = address(new BeaconProxy(logic, ""));

        instance.functionCallWithValue(initData, msg.value);

        nftToToken[_nftOrigin] = instance;
        indexToNft[counter] = _nftOrigin;
        counter = counter + 1;
        emit pairCreated(_nftOrigin, instance, _nftType);
    }

    function getPairByNftAddress(uint256 index)
        public
        view
        returns (
            address _nft20pair,
            address _originalNft,
            uint256 _type,
            string memory _name,
            string memory _symbol,
            uint256 _supply
        )
    {
        _originalNft = indexToNft[index];
        _nft20pair = nftToToken[_originalNft];
        (_type, _name, _symbol, _supply) = INFT20Pair(_nft20pair).getInfos();
    }

    // this is to sset value in case we decided to change tokens given to a tokenizing project.
    function setValue(
        address _pair,
        uint256 _nftType,
        string calldata _name,
        string calldata _symbol,
        uint256 _value
    ) external onlyOwner {
        INFT20Pair(_pair).setParams(_nftType, _name, _symbol, _value);
    }

    function setFactorySettings(uint256 _fee, bool _allowFlashLoans)
        external
        onlyOwner
    {
        fee = _fee;
        flashLoansEnabled = _allowFlashLoans;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        public
        onlyOwner
    {
        IERC20(tokenAddress).transfer(
            address(0x6fBa46974b2b1bEfefA034e236A32e1f10C5A148), //send to multisig
            tokenAmount
        );
    }

    function changeLogic(address _newLogic) external onlyOwner {
        logic = _newLogic;
    }

    // NEW functions v6
    receive() external payable {} //lol 2 hours

    // anyone can call this, no params.
    function swapTokensForMuse()
        public
        virtual
        returns (uint256[] memory amounts)
    {
        address[] memory _path = new address[](3);
        _path[0] = tokenToSell;
        _path[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //weth
        _path[2] = 0xB6Ca7399B4F9CA56FC27cBfF44F4d2e4Eef1fc81; //muse

        uint256 amount = IERC20(tokenToSell).balanceOf(address(this)).div(10);

        return
            Uni(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
                .swapExactTokensForTokens(
                    amount,
                    uint256(0),
                    _path,
                    address(0x9Cfc1d1A45F79246e8E074Cfdfc3f4AacddE8d9a), //send to multisig directly,
                    block.timestamp + 1800
                );
    }

    /* Put token to 0x0 if you want to disable selling */
    function set20TokenForSale(address _tokenToSell) external onlyOwner {
        amountToSell = 10;
        tokenToSell = _tokenToSell;
        if (tokenToSell != address(0x0)) {
            IERC20(tokenToSell).approve(
                0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
                uint256(-1)
            );
        }
    }

    function sellTokens() external {
        if (
            tokenToSell == address(0x0) ||
            IERC20(tokenToSell).balanceOf(address(this)) < amountToSell
        ) {
            return;
        }

        // TODO I already deployed, in future we can remove this require as it doesn't matter if anyone calls this as he would jsut help us buy muse.
        require(
            owner() == msg.sender ||
                nftToToken[INFT20Pair(msg.sender).nftAddress()] == msg.sender
        ); // This function can only be called by a pool or the owner

        swapTokensForMuse();
    }
}
