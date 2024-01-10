//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "Ownable.sol";
import "Strings.sol";
import "ECDSA.sol";
import "ERC721A.sol";

contract HouseHeads is ERC721A, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    //private
    address private _signAddr;
    string private _baseTokenURI;

    //public
    uint256 public immutable collectionSize;
    uint256 public maxAmountWhitelist;
    uint256 public maxAmountPublic;
    uint256 public price;
    uint256 public wlMintLive;
    uint256 public publicMintLive;
    mapping(address => uint256) public _whitelistClaimed;
    mapping(address => uint256) public _publicClaimed;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _setBaseTokenURI,
        uint256 _whitelistMaxAmount,
        uint256 _publicMaxAmount,
        uint256 _maxSupply,
        uint256 _price
    ) ERC721A(_name, _symbol) {
        maxAmountWhitelist = _whitelistMaxAmount;
        maxAmountPublic = _publicMaxAmount;
        collectionSize = _maxSupply;
        price = _price;
        _baseTokenURI = _setBaseTokenURI;
    }

    //hash functions
    function _hashCheckForWhitelist(
        address _address,
        uint256 _maxAmountAllowedToMint,
        uint256 _mintPrice
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(_address, _maxAmountAllowedToMint, _mintPrice)
            );
    }

    function _verify(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return (_checkHash(hash, signature) == _getSigned());
    }

    function _checkHash(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(signature);
    }

    function _getSigned() internal view returns (address) {
        return _signAddr;
    }

    //mint functions
    function whitelistMint(
        bytes32 hash,
        bytes calldata signature,
        uint256 _amountToMint,
        uint256 _maxAmountAllowedToMint,
        uint256 _mintPrice
    ) external payable {
        require(wlMintLive == 1, "Whitelist Mint has ended");
        require(_verify(hash, signature), "Invalid Signature");
        require(
            _hashCheckForWhitelist(
                msg.sender,
                _maxAmountAllowedToMint,
                _mintPrice
            ) == hash,
            "Invalid Hash"
        );
        require(_amountToMint > 0, "Invalid amount requested");
        require(
            _whitelistClaimed[msg.sender] + _amountToMint <=
                _maxAmountAllowedToMint,
            "You cannot mint this many."
        );
        require(totalSupply() + _amountToMint <= collectionSize, "Sold Out");
        require(_amountToMint * _mintPrice == msg.value, "Invalid Funds");
        _safeMint(msg.sender, _amountToMint);
        _whitelistClaimed[msg.sender] += _amountToMint;
    }

    function publicMint(uint256 _numOfTokens) external payable {
        require(publicMintLive == 1, "Public Mint unavailable");
        require(_numOfTokens > 0, "Invalid amount requested");
        require(
            _publicClaimed[msg.sender] + _numOfTokens <= maxAmountPublic,
            "You cannot mint this many."
        );
        require(_numOfTokens * price == msg.value, "Invalid Funds");
        require(totalSupply() + _numOfTokens <= collectionSize, "Sold Out");

        _safeMint(msg.sender, _numOfTokens);
        _publicClaimed[msg.sender] += _numOfTokens;
    }

    //ownable functions
    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setPublicMax(uint256 _newLimit) external onlyOwner {
        maxAmountPublic = _newLimit;
    }

    function setWhitelistMax(uint256 _newLimit) external onlyOwner {
        maxAmountWhitelist = _newLimit;
    }

    function setSigned(address _newSign) external onlyOwner {
        _signAddr = _newSign;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function togglePublicMint() public onlyOwner {
        if (publicMintLive == 0) {
            publicMintLive = 1;
        } else {
            publicMintLive = 0;
        }
    }

    function toggleWLMint() public onlyOwner {
        if (wlMintLive == 0) {
            wlMintLive = 1;
        } else {
            wlMintLive = 0;
        }
    }

    function withdrawSetAmount(uint256 _amountToWithdraw) external onlyOwner {
        require(
            _amountToWithdraw < (address(this).balance),
            "Not enough funds to withdraw"
        );
        (bool success, ) = msg.sender.call{value: _amountToWithdraw}("");
        require(success, "Transfer Failed");
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }
}
