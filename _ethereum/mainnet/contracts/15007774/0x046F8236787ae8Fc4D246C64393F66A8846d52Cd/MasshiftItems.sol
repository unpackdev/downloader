// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./ERC721A.sol";
import "./MasshiftSubjects.sol";

//  .___  ___.      ___           _______.     _______. __    __   __   _______ .___________.
//  |   \/   |     /   \         /       |    /       ||  |  |  | |  | |   ____||           |
//  |  \  /  |    /  ^  \       |   (----`   |   (----`|  |__|  | |  | |  |__   `---|  |----`
//  |  |\/|  |   /  /_\  \       \   \        \   \    |   __   | |  | |   __|      |  |     
//  |  |  |  |  /  _____  \  .----)   |   .----)   |   |  |  |  | |  | |  |         |  |     
//  |__|  |__| /__/     \__\ |_______/    |_______/    |__|  |__| |__| |__|         |__|     
//                                                                                         
// dev:\_ Unzyp\ Technology,\ Inc.

contract MasshiftItems is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    bool public isPausable;
    bool public isSalePaused;
    bool public isPublicSalePaused;
    bool public isStakingPaused;

    string private name_;
    string private symbol_; 
    
    string private baseURI;

    address public subjectContract;
    address public cSigner;

    uint256 public immutable maxMintPerAddress;
    uint256 public maxPublicMintPerAddress;
    uint256 public constant PUBLIC_SALE_PRICE = 0.055 ether;

    constructor(
      string memory _name,
      string memory _symbol,
      uint256 _maxBatchMintSize,
      uint256 _collectionSize,
      address _cSigner
    ) ERC721A(_name, _symbol, _maxBatchMintSize, _collectionSize) {
      name_ = _name;
      symbol_ = _symbol;
      maxMintPerAddress = _maxBatchMintSize;
      isPublicSalePaused = true;
      cSigner = _cSigner;
    }

    modifier isSubjectsContract {
      require(msg.sender == subjectContract, "This method can only be called by Subject Contract.");
      _;
    }
    
    /**
     * ======================================================================================
     *
     *  Token Mint
     *
     * ======================================================================================
     */

    function claimItem(uint256 tokenNumbers) external payable isSubjectsContract {
      uint256 startTokenId = currentIndex;
      require(saleIsActive(), "The mint is not active");
      require(totalSupply() + tokenNumbers <= collectionSize, "Maximum supply reached");
      require(numberMinted(tx.origin) + tokenNumbers <= maxMintPerAddress, "Not allowed to mint that much");

      AddressData memory addressData = _addressData[tx.origin];
      _addressData[tx.origin] = AddressData(
        addressData.balance + uint128(tokenNumbers),
        addressData.numberMinted + uint128(tokenNumbers)
      );
      _ownerships[startTokenId] = TokenOwnership(tx.origin, uint64(block.timestamp));

      uint256 updatedIndex = startTokenId;

      for (uint256 i = 0; i < tokenNumbers; i++) {
        emit Transfer(address(0), tx.origin, updatedIndex);
        unchecked {
          updatedIndex++;
        }
      }

      currentIndex = updatedIndex;
    }

    function publicSaleItem(bytes memory _signature, uint256 tokenNumbers) external payable {
      uint256 startTokenId = currentIndex;
      require(publicSaleIsActive(), "The public mint is not active");
      require(totalSupply() + tokenNumbers <= collectionSize, "Maximum supply reached");
      require(numberMinted(msg.sender) + tokenNumbers <= maxPublicMintPerAddress, "Not allowed to mint that much");
      require(msg.value >= tokenNumbers * PUBLIC_SALE_PRICE, "Insufficient ETH");
      require(isMsgValid(_signature) == true, "Invalid Signature"); // To make sure mint only from the app

      AddressData memory addressData = _addressData[msg.sender];
      _addressData[msg.sender] = AddressData(
        addressData.balance + uint128(tokenNumbers),
        addressData.numberMinted + uint128(tokenNumbers)
      );
      _ownerships[startTokenId] = TokenOwnership(msg.sender, uint64(block.timestamp));

      uint256 updatedIndex = startTokenId;

      for (uint256 i = 0; i < tokenNumbers; i++) {
        emit Transfer(address(0), msg.sender, updatedIndex);
        unchecked {
          updatedIndex++;
        }
      }

      currentIndex = updatedIndex;
    }

    function devMint(address receiver, uint256 quantity) external onlyOwner {
      require(quantity % maxBatchSize == 0,
        "can only mint a multiple of the maxBatchSize"
      );
      uint256 startTokenId = currentIndex;
      uint256 numChunks = quantity / maxBatchSize;
      AddressData memory addressData = _addressData[receiver];
      _addressData[receiver] = AddressData(
        addressData.balance + uint128(quantity),
        addressData.numberMinted + uint128(quantity)
      );
      _ownerships[startTokenId] = TokenOwnership(receiver, uint64(block.timestamp));

      uint256 updatedIndex = startTokenId;

      for (uint256 i = 0; i < numChunks; i++) {
        emit Transfer(address(0), receiver, updatedIndex);
        unchecked {
          updatedIndex++;
        }
      }

      currentIndex = updatedIndex;
    }

    /**
     * ======================================================================================
     *
     *  Staking
     *
     * ======================================================================================
     */

    function getOwnedTokens(address _address)
        external
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(_address);
        uint256[] memory result = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
          result[i] = tokenOfOwnerByIndex(_address, i);
        }
        return result;
    }

    function stakeItem(uint256[] memory _tokenIds, uint256 _subjectId) external {
        require(!isPausable, "Contract Paused");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            bytes memory data = abi.encodePacked(_subjectId);
            safeTransferFrom(msg.sender, subjectContract, _tokenIds[i], data);
        }
    }

    function unstakeItem(address _to, uint256 _tokenId) external isSubjectsContract{
        require(!isPausable, "Contract Paused");
        safeTransferFrom(msg.sender, _to, _tokenId, '');
    }

    /**
     * ======================================================================================
     *
     *  Contract Configurations
     *
     * ======================================================================================
     */

    function saleIsActive() public view returns (bool) {
      if (isSalePaused) {
        return false;
      }
      return true;
    }

    function publicSaleIsActive() public view returns (bool) {
      if (isPublicSalePaused) {
        return false;
      }
      return true;
    }

    function withdraw() external onlyOwner nonReentrant {
      uint256 balance = address(this).balance;
      payable(owner()).transfer(balance);
    }

    function setSubjectContract(address _subjectContract) external onlyOwner {
      subjectContract = _subjectContract;
    }

    function setPublicBatchMint(uint256 _maxPublicMint) external onlyOwner {
      maxPublicMintPerAddress = _maxPublicMint;
    }

    function pause(bool _isPausable) external onlyOwner {
      isPausable = _isPausable;
    }

    function pauseSale(bool _isSalePaused) external onlyOwner {
      isSalePaused = _isSalePaused;
    }

    function pausePublicSale(bool _isPublicSalePaused) external onlyOwner {
      isPublicSalePaused = _isPublicSalePaused;
    }

    function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
    }

    function setBaseURI(string calldata _URI) external onlyOwner {
      baseURI = _URI;
    }

    function isMsgValid(bytes memory _signature) private view returns (bool) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(address(this), msg.sender)
        );
        address signer = messageHash.toEthSignedMessageHash().recover(
            _signature
        );
        return cSigner == signer;
    }

    function setSigner(address _signer) external onlyOwner {
        cSigner = _signer;
    }

    /**
     * ======================================================================================
     *
     *  Base Functions
     *
     * ======================================================================================
     */

    function numberMinted(address owner) public view returns (uint256) {
      return _numberMinted(owner);
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfers(
      address from,
      address to,
      uint256 startTokenId,
      uint256 quantity
    ) internal virtual override {
      super._beforeTokenTransfers(from, to, startTokenId, quantity);

      require(!isPausable, "ERC721A: token transfer while paused");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public override {
      super.setApprovalForAll(operator, approved);

      MasshiftSubjects ms = MasshiftSubjects(subjectContract);
      if(!ms.isFullyMinted()){
        revert("ERC721A: Subjects must be fully minted to be tradable");
      }
    }
}