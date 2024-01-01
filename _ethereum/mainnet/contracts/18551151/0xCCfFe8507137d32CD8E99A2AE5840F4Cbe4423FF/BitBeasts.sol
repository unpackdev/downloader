// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./ERC721A.sol";
import "./Ownable.sol";

error SaleIsNotActive();
error MaxSupplyReached();
error MaxMintPerTransactionExceeded();
error InsufficientPayment();
error CantIncreaseSupply();
error WithdrawalFailed();

contract BitBeasts is Ownable, ERC721A {

    uint256 public MAX_SUPPLY = 4444;
    uint256 public MAX_PER_TX = 10;
    uint256 public PRICE = 0.004 ether;

    bool public saleIsActive;
    string public baseURI;


    constructor() ERC721A("Bit Beasts", "BB") {}

    receive() external payable {}

    function mint(uint256 _amount) external payable {
        if (!saleIsActive) revert SaleIsNotActive();
        if (_totalMinted() + _amount > MAX_SUPPLY) revert MaxSupplyReached();
        if (_amount > MAX_PER_TX) revert MaxMintPerTransactionExceeded();

        uint256 payAmount = _amount;
        uint256 freeMintCount = _getAux(msg.sender);

        if (freeMintCount < 1) {
            payAmount = _amount - 1;
            _setAux(msg.sender, 1);
        }
       
        if (payAmount > 0) {
            if (msg.value < payAmount * PRICE) revert InsufficientPayment();
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
        baseURI = uri;
    }

    function lowerSupply(uint256 _newSupply) external onlyOwner {
        if (_newSupply > MAX_SUPPLY) revert CantIncreaseSupply();
        MAX_SUPPLY = _newSupply;
    }

    function setMaxTx(uint256 _newMaxTx) external onlyOwner {
        MAX_PER_TX = _newMaxTx;
    }
    
    function setPrice(uint256 _newPrice) external onlyOwner {
        PRICE = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

}
