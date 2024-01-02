// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./ECDSA.sol";
import "./MessageHashUtils.sol";

import "./IPaddysPass.sol";
import "./IRegistry.sol";

/**
 * @notice PaddysPass Token Contract
 * @author Uses Yuga Labs' registry for operator filtering (https://etherscan.io/address/0x4fC5Da4607934cC80A0C6257B1F36909C58dD622)
 */
contract PaddysPass is IPaddysPass, ERC1155Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    using ECDSA for bytes32;

    IRegistry public registry;

    mapping(uint256 => Token) public tokenData;
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public numberMinted;

    address private signer;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // initializer
    function initialize( string calldata metadataUri, address _registry, address _signer ) initializer public {

        __ERC1155_init(metadataUri);
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        registry = IRegistry(_registry);
        signer = _signer;

        _mint(msg.sender, 1, 1, "");

    }

    /**
     * @notice returns total supply for token id
     */
    function totalSupply(uint256 tokenId) public view returns(uint256) {
        return tokenData[tokenId].totalSupply;
    }

    /**
     * @notice returns max supply for token id
     */
    function maxSupply(uint256 tokenId) public view returns(uint256) {
        return tokenData[tokenId].maxSupply;
    }

    /**
     * @notice returns number minted by owner and token id
     */
    function tokenMintedByOwner(address owner, uint256 tokenId, uint256 phase) public view returns(uint256) {
        return numberMinted[owner][tokenId][phase];
    }

    /**
     * @notice changes the signer address
     */
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
        emit SignerAddressChanged(_signer);
    }

    /**
     * @notice changes the registry contract
     */
    function setRegistry(address _registry) external onlyOwner {
        registry = IRegistry(_registry);
        emit RegistryContractChanged(_registry);
    }

    /**
     * @notice sets tokendata for mint
     */
    function setTokenData(uint256 tokenId, uint256 _totalSupply, uint256 _maxSupply, uint256 publicPrice, uint256 publicStart, uint256 publicMaxMint) external onlyOwner {

        tokenData[tokenId] = Token(
            tokenId,
            _totalSupply,
            _maxSupply,
            publicPrice,
            publicStart,
            publicMaxMint
        );

        emit TokenDataChanged(tokenId, _totalSupply, _maxSupply, publicPrice, publicStart, publicMaxMint);
    }

    /**
     * @notice Sets a new metadata URI
     * @dev This function can only be called by the contract owner.
     */
    function setURI(string calldata metadataUri) external onlyOwner {
        _setURI(metadataUri);
        emit MetadataUriChanged(metadataUri);
    }

    /**
     * @notice Private mint of given token
     * @dev Needs a valid signature to pass
     */
    function privateMint(uint256 tokenId, uint256 amount, uint256 maxMint, uint256 phase, bytes calldata signature ) external payable nonReentrant {

        Token memory tokenInfo = tokenData[tokenId];
        uint256 alreadyMinted = numberMinted[msg.sender][tokenId][phase];

        if( tokenInfo.totalSupply + amount > tokenInfo.maxSupply ) revert SoldOut();
        if( !_verifySig(msg.sender, tokenId, msg.value, amount, maxMint, phase, signature) ) revert InvalidSignature();
        if( alreadyMinted + amount > maxMint ) revert AmountExceedsMintLimit();

        _mint(msg.sender, tokenId, amount, "");

        unchecked {
            numberMinted[msg.sender][tokenId][phase] += amount;
            tokenData[tokenId].totalSupply += amount;
        }

    }

    /**
     * @notice Public mint of given token
     */
    function publicMint(uint256 tokenId, uint256 amount) external payable nonReentrant {

        Token memory tokenInfo = tokenData[tokenId];
        uint256 alreadyMinted = numberMinted[msg.sender][tokenId][0];

        if( tx.origin != msg.sender ) revert ContractMintNotAllowed();
        if( tokenInfo.publicStart > block.timestamp ) revert PublicMintNotLive();
        if( tokenInfo.totalSupply + amount > tokenInfo.maxSupply ) revert SoldOut();
        if( alreadyMinted + amount > tokenInfo.publicMaxMint ) revert AmountExceedsMintLimit();
        if( msg.value < tokenInfo.publicPrice * amount ) revert InsufficientBalance();

        _mint(msg.sender, tokenId, amount, "");

        unchecked {
            numberMinted[msg.sender][tokenId][0] += amount;
            tokenData[tokenId].totalSupply += amount;
        }
    }

    /**
     * @notice Checks whether msg.sender is valid on the registry. If not, it will
     * block the approval of the token.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (_isValidAgainstRegistry(operator)) {
            super.setApprovalForAll(operator, approved );
        } else {
            revert IRegistry.NotAllowed();
        }
    }

    /**
     * @notice Checks whether msg.sender is valid on the registry. If not, it will
     * block the transfer of the token.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) public virtual override {
        if (_isValidAgainstRegistry(msg.sender)) {
            super.safeTransferFrom(from, to, id, value, data );
        } else {
            revert IRegistry.NotAllowed();
        }
    }

    /**
     * @notice Checks whether msg.sender is valid on the registry. If not, it will
     * block the transfer of the token.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory values, bytes memory data) public virtual override {
        if (_isValidAgainstRegistry(msg.sender)) {
            super.safeBatchTransferFrom(from, to, ids, values, data );
        } else {
            revert IRegistry.NotAllowed();
        }
    }

    /**
     * @notice Airdrop function
     */
    function airdrop(uint256 tokenId, address[] calldata receivers, uint256[] calldata amount) external onlyOwner {

        Token memory tokenInfo = tokenData[tokenId];
        uint256 totalAmount = 0;

        for( uint256 i = 0; i < amount.length; i++ ) {
            unchecked {
                totalAmount += amount[i];
            }
        }

        if( tokenInfo.totalSupply + totalAmount > tokenInfo.maxSupply ) revert SoldOut();

        for( uint256 i = 0; i < receivers.length; i++ ) {
            _mint(receivers[i], tokenId, amount[i], "");
        }

        unchecked {
            tokenData[tokenId].totalSupply += totalAmount;
        }
    }

    /**
     * @notice Function to withdraw the contract's ether balance. Only the contract owner can call this function.
     * @dev The contract must have a positive ether balance to execute the withdrawal.
     */
    function withdraw() external onlyOwner {
        // Get the current contract's ether balance.
        uint256 contractBalance = address(this).balance;

        // Ensure there's ether balance to withdraw.
        if (contractBalance == 0) {
            revert ZeroBalance();
        }

        // Attempt to transfer the contract's ether balance to the contract owner.
        (bool success, ) = msg.sender.call{value: contractBalance}("");
        if (!success) {
            revert TransferFailed();
        }

        // Emit an event to log the ether withdrawal.
        emit BalanceWithdrawn(msg.sender, contractBalance);
    }

    /**
     * @notice Checks whether operator is valid on the registry. Will return true if registry isn't active.
     */
    function _isValidAgainstRegistry(address operator) internal view returns (bool) {
        return registry.isAllowedOperator(operator);
    }

    /**
     * @notice Checks whether signature is valid
     */
    function _verifySig(address sender, uint256 tokenId, uint256 value, uint256 amount, uint256 maxMint, uint256 phase, bytes memory signature) internal view returns(bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(sender, tokenId, value, amount, maxMint, phase));
        return signer == MessageHashUtils.toEthSignedMessageHash(messageHash).recover(signature);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;

}