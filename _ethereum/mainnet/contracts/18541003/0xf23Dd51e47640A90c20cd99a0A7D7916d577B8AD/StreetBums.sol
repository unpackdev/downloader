// SPDX-License-Identifier: MIT
/*
4000 bums crawling the crypto streets at night
*/
pragma solidity ^0.8.18;

import "./ERC721A.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./OperatorFilterer.sol";
import "./ERC2981.sol";

contract StreetBums is ERC721A, Ownable, OperatorFilterer, ERC2981 {
    using Strings for *;
    using Counters for Counters.Counter;
    bool public operatorFilteringEnabled;
    string internal uri;
    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;
    uint256 public current = 0;
    bool public paused = true;
    address public feeReceiver;
    mapping(address => uint) public walletMints;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTrx
    ) ERC721A(_name, _symbol) {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 500);
        cost = _cost * 1000;
        maxSupply = _maxSupply;
        maxMintAmountPerTx = _maxMintAmountPerTrx;
    }

    function mint(uint256 _mintAmount) public payable {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
        require(current + _mintAmount <= maxSupply, "Max supply exceeded!");
        require(!paused, "Mint have not started yet");
        if (walletMints[msg.sender] == 0) {
            require(msg.value >= cost * (_mintAmount - 1), "Insufficient funds!");
        } else {
            require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        }
        require(walletMints[msg.sender] + _mintAmount <= maxMintAmountPerTx, "Maximum mints per wallet limit exceeded");

        walletMints[msg.sender] += _mintAmount;
        current += _mintAmount;
        _mint(msg.sender, _mintAmount);
    }

    function mintForMarketing(uint256 _mintAmount, address _receiver) public onlyOwner {
        require(_mintAmount > 0, "Invalid mint amount!");
        require(current + _mintAmount <= maxSupply, "Max supply exceeded!");

        current += _mintAmount;
        _mint(_receiver, _mintAmount);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;
        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
        bytes(currentBaseURI).length > 0
        ? string(
            abi.encodePacked(
                currentBaseURI,
                _tokenId.toString()
            )
        )
        : "";
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost * 1000;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setUri(string memory _uri) public onlyOwner {
        uri = _uri;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner {
        require(feeReceiver != address(0), 'Fee receiver unset');
        (bool os, ) = payable(feeReceiver).call{value: address(this).balance}("");
        require(os);
    }

    function setWithdrawReceiver(address _receiver) public onlyOwner {
        feeReceiver = _receiver;
    }

    function getMintedAmount(address _address) public view returns (uint256) {
        return walletMints[_address];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    receive() external payable {}

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}
