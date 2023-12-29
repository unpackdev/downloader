// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./OperatorFilterer.sol";

error SaleIsNotActive();
error MaxSupplyReached();
error MaxMintPerTransactionExceeded();
error InsufficientPayment();
error CantIncreaseSupply();
error WithdrawalFailed();

contract Runekeepers is Ownable, OperatorFilterer, ERC721A {

    uint256 public supply = 8888;
    uint256 public maxTx = 10;
    uint256 public price = 0.005 ether;

    bool public saleIsActive;
    bool operatorFilteringEnabled;

    string public baseUri;


    constructor() ERC721A("Runekeepers", "RUNE") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
    }

    receive() external payable {}

    function mint(uint256 _amount) external payable {
        if (!saleIsActive) revert SaleIsNotActive();
        if (_totalMinted() + _amount > supply) revert MaxSupplyReached();
        if (_amount > maxTx) revert MaxMintPerTransactionExceeded();

        uint256 payAmount = _amount;
        uint256 freeMintCount = _getAux(msg.sender);

        if (freeMintCount < 1) {
            payAmount = _amount - 1;
            _setAux(msg.sender, 1);
        }
       
        if (payAmount > 0) {
            if (msg.value < payAmount * price) revert InsufficientPayment();
        }

        _mint(msg.sender, _amount);
    }

    function toggleSale() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: (address(this).balance)}("");
        if (!success) revert WithdrawalFailed();
    }
    
    function setBaseURI(string memory uri) external onlyOwner {
        baseUri = uri;
    }

    function lowerSupply(uint256 _newSupply) external onlyOwner {
        if (_newSupply > supply) revert CantIncreaseSupply();
        supply = _newSupply;
    }

    function setMaxTx(uint256 _newMaxTx) external onlyOwner {
        maxTx = _newMaxTx;
    }
    
    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

}
