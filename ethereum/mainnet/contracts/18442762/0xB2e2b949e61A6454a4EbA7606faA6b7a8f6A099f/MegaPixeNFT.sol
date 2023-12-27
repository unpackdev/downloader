// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

error ZeroAddress();
error NoWithdrawAddress();
error ZeroBalance();
error SaleNotActive();
error InvalidPayment();
error InvalidInput();
error ContractCaller();
error MaxSupplyReached();

interface MetadataInterface {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract MegaPixeNFT is ERC721A, Ownable, ReentrancyGuard {
    string private _contractURI = "ipfs://Qme2YS9v6qqQikPAybdciiVqNBPVERGPo5NpK6RKHqr3EF";

    uint256 public supply = 10000;
    uint256 public price = 0.0088 ether;
    bool public isSaleActive = false;
    address public withdrawAddress = 0x929f73f0521BeF72278b8e8d24E72F973EA1b3F5;
    string public baseURI = "ipfs://QmYqq69XSuaE5cEMxecBEb791igEGnouR2w2x2NCacr2Sk/";

    constructor() ERC721A("MegaPixe", "MPX") Ownable(msg.sender) {
        _mint(msg.sender, 1);
    }

    MetadataInterface public metadataInterface;

    modifier callerIsUser() {
        if (msg.sender != tx.origin) {
            revert ContractCaller();
        }
        _;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (address(metadataInterface) != address(0)) {
            return metadataInterface.tokenURI(tokenId);
        } else {
            return super.tokenURI(tokenId);
        }
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setContractURI(string memory newContractURI) public onlyOwner {
        _contractURI = newContractURI;
    }

    function setPrice(uint256 newprice) external onlyOwner {
        price = newprice;
    }

    function setSupply(uint256 newsupply) external onlyOwner {
        supply = newsupply;
    }

    function setWithdrawAddress(address newWithdrawAddress) external onlyOwner {
        if (newWithdrawAddress == address(0)) revert ZeroAddress();
        withdrawAddress = newWithdrawAddress;
    }

    function setSaleActive(bool newIsSaleActive) external onlyOwner {
        isSaleActive = newIsSaleActive;
    }

    function setMetadataInterface(MetadataInterface newMetadataInterface) public onlyOwner {
        metadataInterface = newMetadataInterface;
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) revert ZeroBalance();
        if (withdrawAddress == address(0)) revert NoWithdrawAddress();
        payable(withdrawAddress).transfer(balance);
    }

    function mint(uint16 mintAmount) external payable nonReentrant callerIsUser {
        if (!isSaleActive) revert SaleNotActive();
        if (mintAmount == 0) revert InvalidInput();
        if (totalSupply() + mintAmount > supply) revert MaxSupplyReached();
        if (msg.value != price * mintAmount) revert InvalidPayment();
        _mint(msg.sender, mintAmount);
    }
}
