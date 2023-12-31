// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**  
 * @title Market Contract
 * @author akibe
 */

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Withdrawable.sol";
import "./ERC721Mintable.sol";

contract Market is Ownable, Withdrawable {

    // ==========-==========-==========-==========-==========-==========
    // Multi Sales
    // ==========-==========-==========-==========-==========-==========

    event ChangeSale(uint8 newId, uint216 newSupply);

    struct Sale {
        uint8 id;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        uint216 maxSupply;
        bytes32 merkleRoot;
    }

    Sale internal _currentSale;
    mapping(address => mapping(uint8 => uint256)) internal _salesOfOwner;

    function getCurrentSale() external view returns (Sale memory) {
        return _currentSale;
    }

    function setCurrentSale(
        uint8 id,
        uint256 startTime,
        uint256 endTime,
        uint256 price,
        uint216 maxSupply,
        bytes32 merkleRoot
    ) external onlyOwner {
        _currentSale = Sale({
            id: id,
            startTime: startTime,
            endTime: endTime,
            price: price,
            maxSupply: maxSupply,
            merkleRoot: merkleRoot
        });
        emit ChangeSale(id, maxSupply);
    }

    // ==========-==========-==========-==========-==========-==========
    // Token Mint
    // ==========-==========-==========-==========-==========-==========

    error InsufficientFunds();
    error InvalidTokenContract();
    error NotForSale();
    error InvalidTokenId();
    error TokenAlreadyMinted();
    error SaleHasNotStarted();
    error SaleHasEnded();
    error NotAllowlisted();
    error OverMintLimit();

    address public tokenContract;
    
    function setTokenContract(address cont) external onlyOwner {
        tokenContract = cont;
    }

    function mint(
        uint256 tokenId,
        uint256 maxMintAmount,
        bytes32[] memory merkleProof
    ) public payable {
        checkMint(msg.sender, tokenId, maxMintAmount, merkleProof);
        if (msg.value < _currentSale.price) revert InsufficientFunds();
        if (_currentSale.merkleRoot > 0) {
            _salesOfOwner[msg.sender][_currentSale.id] += 1;
        }
        ERC721Mintable(tokenContract).mint(msg.sender, tokenId);
    }

    function checkMint(
        address minter,
        uint256 tokenId,
        uint256 maxMintAmount,
        bytes32[] memory merkleProof
    ) public view returns (bool) {
        if (tokenContract == address(0)) revert InvalidTokenContract();
        if (_currentSale.id == 0) revert NotForSale();
        if (tokenId == 0 || _currentSale.maxSupply < tokenId) revert InvalidTokenId();
        if (ERC721Mintable(tokenContract).exists(tokenId)) revert TokenAlreadyMinted();
        if (_currentSale.startTime > block.timestamp) revert SaleHasNotStarted();
        if (_currentSale.endTime != 0 && _currentSale.endTime < block.timestamp) revert SaleHasEnded();
        if (_currentSale.merkleRoot > 0) {
            if (!checkMerkleProof(minter, maxMintAmount, merkleProof)) revert NotAllowlisted();
            if (_salesOfOwner[minter][_currentSale.id] >= maxMintAmount) revert OverMintLimit();
        }
        return true;
    }

    function checkMerkleProof(
        address minter,
        uint256 maxMintAmount,
        bytes32[] memory merkleProof
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(minter, maxMintAmount)))
        );
        return MerkleProof.verify(merkleProof, _currentSale.merkleRoot, leaf);
    }

    // ==========-==========-==========-==========-==========-==========
    // Withdraw
    // ==========-==========-==========-==========-==========-==========

    function withdraw() external onlyOwner {
        _withdraw(payable(owner()));
    }
}
