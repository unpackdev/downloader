// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC2981.sol";
import "./ReentrancyGuard.sol";
import "./OperatorFilterer.sol";
import "./The8102Factory.sol";
import "./ERC1155Holder.sol";

    error MintClosed();
    error NotEnoughBlueprints();
    error CanNotExceedMaxSupply();
    error CanNotExceedMaxPerTransaction();
    error NothingToBurn();

contract The8102GearContract is ERC721A, Ownable, Pausable, ERC2981, OperatorFilterer, ReentrancyGuard, ERC1155Holder {
    uint16 constant public MAX_SUPPLY = 812;
    uint8 constant public MAX_PER_TRANSACTION = 20;

    bool public operatorFilteringEnabled;
    bool public mintEnabled;
    address private priorityOperator;
    string private baseTokenURI;

    The8102Factory private immutable factoryContract;
    uint256 private immutable factoryTokenId;

    constructor(address factoryAddress, address royaltyAddress, uint256 burnTokenId) ERC721A("The 8102: Gear Items", "8102GEAR") {
        factoryContract = The8102Factory(factoryAddress);
        factoryTokenId = burnTokenId;
        _registerForOperatorFiltering();
        operatorFilteringEnabled = false;
        priorityOperator = address(0x1E0049783F008A0085193E00003D00cd54003c71);
        mintEnabled = false;
        _setDefaultRoyalty(royaltyAddress, 250);
    }

    function mint(uint256 quantity) external nonReentrant {
        if (!mintEnabled) revert MintClosed();
        if (quantity > MAX_PER_TRANSACTION) revert CanNotExceedMaxPerTransaction();
        if ((_totalMinted() + quantity) > MAX_SUPPLY) revert CanNotExceedMaxSupply();
        if (factoryContract.balanceOf(msg.sender, factoryTokenId) < quantity) revert NotEnoughBlueprints();

        factoryContract.safeTransferFrom(msg.sender, address(this), factoryTokenId, quantity, "");
        factoryContract.burn(factoryTokenId, quantity);
        _mint(msg.sender, quantity);
    }

    function burnRemaining() external onlyOwner {
        uint256 balance = factoryContract.balanceOf(address(this), factoryTokenId);
        if (balance == 0) revert NothingToBurn();
        factoryContract.burn(factoryTokenId, balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseTokenURI = baseURI_;
    }

    function setMintEnabled(bool _mintEnabled) external onlyOwner {
        mintEnabled = _mintEnabled;
    }

    function setPriorityOperator(address _priorityOperator) external onlyOwner {
        priorityOperator = _priorityOperator;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721A, ERC2981, ERC1155Receiver) returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId) || ERC1155Receiver.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setApprovalForAll(address operator, bool approved) public override (ERC721A) onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override (ERC721A) onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A) onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A) onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override (ERC721A) onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool _operatorFilterEnabled) public onlyOwner {
        operatorFilteringEnabled = _operatorFilterEnabled;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal view override returns (bool) {
        return operator == priorityOperator;
    }
}
