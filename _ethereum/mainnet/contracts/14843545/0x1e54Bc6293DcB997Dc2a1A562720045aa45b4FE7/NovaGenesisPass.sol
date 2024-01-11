//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./console.sol";
import "./ERC721A.sol";
import "./Ownable.sol";

contract NovaGenesisPass is ERC721A, Ownable {
    // base uri
    string private _contractBaseURI;

    // contract metadata hash
    string private _contractURI;

    // max NFt a user can mint
    uint8 private _nftPerUser;

    // maximum NFT can be minted
    uint16 private _nftThreshold;
    uint256 private _nftPrice = 100000000000000000 wei;

    // address of white listed user
    address private whitelistUser1;
    address private whitelistUser2;

    // wallet address
    address payable private wallet;
    // number of NFT user has minted
    mapping(address => uint8) private usersNFTQuantity;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_,
        uint8 nftPerUser_,
        uint16 nftThreshold_,
        address whitelist1,
        address whitelist2,
        address _wallet
    ) ERC721A(name_, symbol_) {
        _contractBaseURI = baseURI_;
        _contractURI = contractURI_;
        _nftPerUser = nftPerUser_;
        _nftThreshold = nftThreshold_;
        whitelistUser1 = whitelist1;
        whitelistUser2 = whitelist2;
        wallet = payable(_wallet);
    }

    modifier whitelistUser() {
        require(
            msg.sender == whitelistUser1 || msg.sender == whitelistUser2,
            "Genesis Pass: caller not a whitelisted user"
        );
        _;
    }

    function totalNftOf(address _address) public view returns (uint8) {
        return usersNFTQuantity[_address];
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory contractURI_) public onlyOwner {
        _contractURI = contractURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _contractBaseURI;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        _contractBaseURI = _baseUri;
    }

    function setNftThreshold(uint16 _threshold) public onlyOwner {
        _nftThreshold = _threshold;
    }

    function getNftThreshold() public view returns (uint16) {
        return _nftThreshold;
    }

    function setNftprice(uint16 _price) public onlyOwner {
        _nftPrice = _price;
    }

    function getNftPrice() public view returns (uint256) {
        return _nftPrice;
    }

    function setNftPerUser(uint8 nftPerUser_) public onlyOwner {
        _nftPerUser = nftPerUser_;
    }

    function getNftPerUser() public view returns (uint8) {
        return _nftPerUser;
    }

    function setWhitelistUser1(address whitelistAddress) public onlyOwner {
        whitelistUser1 = whitelistAddress;
    }

    function getWhitelistUser1() public view returns (address) {
        return whitelistUser1;
    }

    function setWhitelistUser2(address whitelistAddress) public onlyOwner {
        whitelistUser2 = whitelistAddress;
    }

    function getWhitelistUser2() public view returns (address) {
        return whitelistUser2;
    }

    function mint(uint8 _quantity) public payable {
        require(
            (totalSupply() + _quantity) <= _nftThreshold,
            "Genesis Pass: Reached MAX NFT supply"
        );

        require(
            msg.value >= (_nftPrice * _quantity),
            "Genesis Pass: Insufficient Ether sent"
        );

        if (msg.sender == whitelistUser1 || msg.sender == whitelistUser2) {
            _whiteMintPass(_quantity);
        } else {
            _mintPass(_quantity);
        }
    }

    function _whiteMintPass(uint8 _quantity) internal whitelistUser {
        wallet.transfer(msg.value);
        _safeMint(msg.sender, _quantity);
    }

    function _mintPass(uint8 _quantity) internal {
        require(
            (usersNFTQuantity[msg.sender] + _quantity) <= _nftPerUser,
            "Genesis Pass: user owns max number of NFT/s"
        );
        unchecked {
            usersNFTQuantity[msg.sender] += _quantity;
        }
        wallet.transfer(msg.value);
        _safeMint(msg.sender, _quantity);
    }

    function getWalletAddress() public view returns (address) {
        return wallet;
    }

    function setWalletAddress(address _wallet) public onlyOwner {
        wallet = payable(_wallet);
    }
}
