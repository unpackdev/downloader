// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./SQV.sol";

/// @custom:security-contact support@spacequantum.io
contract SpaceQuantumInvestors is
    ERC721,
    ERC721Enumerable,
    Pausable,
    Ownable,
    ReentrancyGuard
{

    uint256 private MAX_QTY_SALES = 100000;

    uint256 public cost = 2 * 10**17; // default price 0.2 ether

    uint256 public qty_enabled_sales = 0;

    bool public _investmentPhase = false;

    address public SQVContractAddr;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    event NewSQIMinted(address from, address sender, uint256[] tokenId);

    string baseURI =
        "ipfs://QmUtk2pK4auYaEU6RugM9frQBWL3jiRG1jmu2xtANUUXa1/meta_sqi.json";

    constructor() ERC721("SpaceQuantumInvestors", "SQI") {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function availableSales() public view returns (uint256) {
        uint256 available = 0;
        // available = qty_enabled_sales - totalSupply();
        available = SafeMath.sub(qty_enabled_sales, totalSupply());

        return available;
    }

    function mintBatch(uint256 _mintsAmount)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(_investmentPhase == true, "Investment phase not active");

        require(SQVContractAddr != address(0), "SQV address not configured");

        require(_mintsAmount > 0, "Amount of mints is 0");

        require(availableSales() >= _mintsAmount, "Not enough sales available");

        if (msg.sender != owner()) {
            require(
                msg.value >= SafeMath.mul(_mintsAmount, cost),
                "Insufficient payment amount"
            );
        }

        uint256[] memory generatedIds = new uint256[](_mintsAmount);
        for (uint256 i = 0; i < _mintsAmount; i++) {
            uint256 tokenId = safeMint(msg.sender);
            generatedIds[i] = tokenId;
        }

        SpaceQuantumVision sqv = SpaceQuantumVision(SQVContractAddr);
        sqv.dropMint(msg.sender);

        emit NewSQIMinted(address(this), msg.sender, generatedIds);
    }

    function safeMint(address to) private returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        return tokenId;
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i = 0; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI))
                : "";
    }

    // Only owner
    function withdrawEthers(uint256 amount) external onlyOwner {
        require(
            address(this).balance >= amount,
            "No enough balance to withdraw"
        );
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setSQVContractAddr(address _addr) external onlyOwner {
        SQVContractAddr = _addr;
    }

    function setCost(uint256 _newCost) external onlyOwner {
        require(_newCost > 0, "Invalid amount");
        cost = _newCost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function activateInvestmentPhase() external onlyOwner {
        _investmentPhase = true;
    }

    function deactivateInvestmentPhase() external onlyOwner {
        _investmentPhase = false;
    }

    function setEnabledSalesByPercentage(uint256 _basisPoint)
        external
        onlyOwner
    {
        require(
            SafeMath.div(SafeMath.mul(MAX_QTY_SALES, _basisPoint), 10000) <=
                MAX_QTY_SALES,
            "Percentage too high"
        );
        qty_enabled_sales = SafeMath.div(
            SafeMath.mul(MAX_QTY_SALES, _basisPoint),
            10000
        );
    }
}
