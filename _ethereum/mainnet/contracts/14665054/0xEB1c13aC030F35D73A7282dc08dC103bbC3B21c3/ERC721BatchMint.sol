// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/// @author: unimint.org

import "./OwnableUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./Initializable.sol";

import "./ERC721AUpgradeable.sol";
import "./ERC721ExtWhitelist.sol";
import "./ERC721ExtBatchTransfer.sol";

/**
 * @title ERC721BatchMint
 * @notice It is one of the core contract of the Unimint Protocol.

██╗   ██╗███╗   ██╗██╗███╗   ███╗██╗███╗   ██╗████████╗
██║   ██║████╗  ██║██║████╗ ████║██║████╗  ██║╚══██╔══╝
██║   ██║██╔██╗ ██║██║██╔████╔██║██║██╔██╗ ██║   ██║   
██║   ██║██║╚██╗██║██║██║╚██╔╝██║██║██║╚██╗██║   ██║   
╚██████╔╝██║ ╚████║██║██║ ╚═╝ ██║██║██║ ╚████║   ██║   
 ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝   
 ______   ______   ______  _______  ______   ______  ______   _       
| |  | \ | |  | \ / |  | \   | |   / |  | \ | |     / |  | \ | |      
| |__|_/ | |__| | | |  | |   | |   | |  | | | |     | |  | | | |   _  
|_|      |_|  \_\ \_|__|_/   |_|   \_|__|_/ |_|____ \_|__|_/ |_|__|_| 
                                                          
 */

contract ERC721BatchMint is
    Initializable,
    ERC721ExtWhitelist,
    ERC721ExtBatchTransfer,
    ERC721AUpgradeable,
    ERC2981Upgradeable,
    OwnableUpgradeable
{
    // ------------------------------------------------------------------------
    // Constant
    // ------------------------------------------------------------------------
    bytes4 private constant _INTERFACE_ID_CONTRACT_URI = 0xe8a3d485;

    // ------------------------------------------------------------------------
    // Private
    // ------------------------------------------------------------------------
    string private _contractURI;
    string private _currentBaseURI;
    uint256 private _currentSupply;
    uint256 private _currentPrice;
    uint256 private _currentPriceStep;
    uint64 private _currentAmountLimit;
    bool private _mintable;
    bool private _preminted;

    // ------------------------------------------------------------------------
    // Struct
    // ------------------------------------------------------------------------
    struct ERC721BatchMintConfig {
        uint64 newMintAmountLimit;
        bool newMintable;
        address feeReciever;
        uint96 feeNumerator;
        uint256 newPrice;
        uint256 newPriceStep;
        uint256 newSupply;
        string newContractURI;
        string newBaseURI;
    }

    // ------------------------------------------------------------------------
    // Events
    // ------------------------------------------------------------------------
    event ERC721BatchMintMaintableUpdated(bool mintable);
    event ERC721BatchMintContractURIUpdated(string uri);
    event ERC721BatchMintBaseURIUpdated(string uri);
    event ERC721BatchMintAmountLimitUpdated(uint256 limit);
    event ERC721BatchMintPriceStepUpdated(uint256 step);
    event ERC721BatchMintSupplyPriceUpdated(uint256 supply, uint256 price);
    event ERC721BatchMintDefaultRoyaltyUpdated(address reciever, uint96 fee);

    // ------------------------------------------------------------------------
    // Initializer
    // ------------------------------------------------------------------------
    constructor() initializer {}

    function initialize(string memory _name, string memory _symbol)
        public
        initializer
    {
        __ERC721A_init(_name, _symbol);
        __Ownable_init();

        _currentSupply = 21000;
        _currentPrice = 0.02100 ether;
        _currentAmountLimit = 7799;
        _currentPriceStep = 0;
        _mintable = false;
        _preminted = false;
    }

    // ------------------------------------------------------------------------
    // External
    // ------------------------------------------------------------------------
    function mint(uint256 amount) external payable {
        require(_mintable, "Not Mintable");
        require(tx.origin == _msgSender(), "Only EOA");
        require(msg.value >= _currentPrice * amount, "Not Enough ETH");
        require(amount <= _currentSupply - _totalMinted(), "Amount > Supply");
        require(amount <= _currentAmountLimit, "Amount > Limit");

        _safeMint(_msgSender(), amount);

        if (_currentPriceStep > 0) {
            _currentPrice += _currentPriceStep;
        }
    }

    // ------------------------------------------------------------------------
    // External View
    // ------------------------------------------------------------------------
    function maxSupply() external view returns (uint256) {
        return _currentSupply;
    }

    function mintPrice() external view returns (uint256) {
        return _currentPrice;
    }

    function priceStep() external view returns (uint256) {
        return _currentPriceStep;
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // ------------------------------------------------------------------------
    // Owner
    // ------------------------------------------------------------------------
    function premint(uint256 _amount) external onlyOwner {
        require(!_preminted, "Premint Finished");
        require(_amount <= _currentSupply - _totalMinted(), "Amount > Supply");
        _safeMint(_msgSender(), _amount);
        _preminted = true;
    }

    function updateContractURI(string calldata _newContractURI)
        external
        onlyOwner
    {
        _contractURI = _newContractURI;
        emit ERC721BatchMintBaseURIUpdated(_contractURI);
    }

    function updateBaseURI(string calldata _newBaseURI) external onlyOwner {
        _currentBaseURI = _newBaseURI;
        emit ERC721BatchMintBaseURIUpdated(_currentBaseURI);
    }

    function updateMintAmountLimit(uint64 _newLimit) external onlyOwner {
        _currentAmountLimit = _newLimit;
        emit ERC721BatchMintAmountLimitUpdated(_currentAmountLimit);
    }

    function updateSupply(uint256 _newSupply) external onlyOwner {
        require(_newSupply > _totalMinted(), "Supply <= Minted");
        _currentSupply = _newSupply;
        emit ERC721BatchMintSupplyPriceUpdated(_currentSupply, _currentPrice);
    }

    function updatePrice(uint256 _newPrice) external onlyOwner {
        _currentPrice = _newPrice;
        emit ERC721BatchMintSupplyPriceUpdated(_currentSupply, _currentPrice);
    }

    function updateSupplyAndPrice(uint256 _newSupply, uint256 _newPrice)
        external
        onlyOwner
    {
        require(_newSupply > _totalMinted(), "Supply <= Minted");
        _currentSupply = _newSupply;
        _currentPrice = _newPrice;
        emit ERC721BatchMintSupplyPriceUpdated(_currentSupply, _currentPrice);
    }

    function updatePriceStep(uint256 _newStep) external onlyOwner {
        _currentPriceStep = _newStep;
        emit ERC721BatchMintPriceStepUpdated(_currentPriceStep);
    }

    function updateDefaultRoyalty(address _reciever, uint96 _feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_reciever, _feeNumerator);
        emit ERC721BatchMintDefaultRoyaltyUpdated(_reciever, _feeNumerator);
    }

    function updateMintable(bool _newMintable) external onlyOwner {
        _mintable = _newMintable;
        emit ERC721BatchMintMaintableUpdated(_mintable);
    }

    function updateConfig(ERC721BatchMintConfig calldata _config)
        external
        onlyOwner
    {
        _mintable = _config.newMintable;
        _currentAmountLimit = _config.newMintAmountLimit;
        _currentPrice = _config.newPrice;
        _currentPriceStep = _config.newPriceStep;
        _currentSupply = _config.newSupply;
        _currentBaseURI = _config.newBaseURI;
        _contractURI = _config.newContractURI;

        _setDefaultRoyalty(_config.feeReciever, _config.feeNumerator);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // ------------------------------------------------------------------------
    // Ext:Whitelist
    // ------------------------------------------------------------------------
    function mint(uint256 amount, bytes32[] calldata merkleProof)
        external
        payable
    {
        require(msg.value >= _currentPrice, "Value < Price");
        require(tx.origin == _msgSender(), "Whitelist Only EOA");
        require(amount <= _currentSupply - _totalMinted(), "Amount > Supply");
        require(
            _setClaimed(_msgSender(), amount, 0, merkleProof),
            "Set Claimed Failed"
        );

        _safeMint(_msgSender(), amount);

        if (_currentPriceStep > 0) {
            _currentPrice += _currentPriceStep;
        }
    }

    function claim(uint256 amount, bytes32[] calldata merkleProof)
        external
        payable
        override
    {
        require(msg.value > 0, "Not Enough ETH");
        require(tx.origin == _msgSender(), "Whitelist Only EOA");
        require(amount <= _currentSupply - _totalMinted(), "Amount > Supply");
        require(
            _setClaimed(_msgSender(), amount, msg.value, merkleProof),
            "Set Claimed Failed"
        );

        _safeMint(_msgSender(), amount);
    }

    function updateMerkleRoot(bytes32 _merkleRoot) external override onlyOwner {
        _updateMerkleRoot(_merkleRoot);
    }

    function clearMerkleRoot() external override onlyOwner {
        _clearMerkleRoot();
    }

    function updateEndTimestamp(uint256 newEndTimestamp)
        external
        override
        onlyOwner
    {
        _updateEndTimestamp(newEndTimestamp);
    }

    function updateMaxClaimAmount(uint96 newAmount)
        external
        override
        onlyOwner
    {
        _updateMaxClaimAmount(newAmount);
    }

    // ------------------------------------------------------------------------
    // Ext:BatchTransfer
    // ------------------------------------------------------------------------
    function batchTransfer(TransferInfo[] calldata list) external override {
        for (uint256 i = 0; i < list.length; i++) {
            safeTransferFrom(_msgSender(), list[i].reciever, list[i].tokenId);
        }
    }

    // ------------------------------------------------------------------------
    // Internal
    // ------------------------------------------------------------------------
    function _baseURI() internal view override returns (string memory) {
        return _currentBaseURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    // ------------------------------------------------------------------------
    // IERC165
    // ------------------------------------------------------------------------
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981Upgradeable, ERC721AUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(ERC2981Upgradeable).interfaceId ||
            interfaceId == _INTERFACE_ID_CONTRACT_URI ||
            super.supportsInterface(interfaceId);
    }
}
