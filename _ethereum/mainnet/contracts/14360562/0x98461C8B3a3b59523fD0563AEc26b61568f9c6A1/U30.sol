// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./AbstractERC1155Factory.sol";
import "./Strings.sol";
import "./ECDSA.sol";

/*
* @title ERC1155 token for U30 DAO
* @author James L
*/
contract U30 is AbstractERC1155Factory {

    address addr_1 = 0x7909b2c97c657F548D467A74faD5C1de48E2da95;

    // Active status per token id.  Allows public uncontrolled sale.
    mapping(uint256 => bool) public isActive;

    // Max number of tokens that can be minted per token id
    mapping(uint256 => uint256) public maxSupply;
    
    // Mint price per token id
    mapping(uint256 => uint256) public mintPrice;
    
    // Max number of tokens that can be minted per transaction per token id
    mapping(uint256 => uint64) public maxPerTx;

    // Max number of tokens that can be minted per wallet address per token id
    mapping(uint256 => uint64) public maxPerWallet;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri) {
        name_ = _name;
        symbol_ = _symbol;
    }


    /**
    * Edit all params for a token id
    *
    * @param tokenId the token id to edit
    * @param _maxSupply the max total number of tokens that can be minted for this token id
    * @param _mintPrice the unit price in wei
    * @param _maxPerTx the number of tokens that can be minted per transaction
    * @param _isActive allow this token to be sellable
    */
    function setParams(uint256 tokenId, uint256 _maxSupply, uint256 _mintPrice, uint64 _maxPerTx, uint64 _maxPerWallet, bool _isActive) external onlyOwner {
        maxSupply[tokenId] = _maxSupply;
        mintPrice[tokenId] = _mintPrice;
        maxPerTx[tokenId] = _maxPerTx;
        maxPerWallet[tokenId] = _maxPerWallet;
        isActive[tokenId] = _isActive;
    }


    /**
    * @notice purchase tokens during public sale
    *
    * @param tokenId the token id
    * @param amount the amount of tokens to purchase
    */
    function purchase(uint256 tokenId, uint256 amount) external payable whenNotPaused {
        require(isActive[tokenId], "This token id is not active");
        _purchase(tokenId, amount);
    }

    /**
    * @notice purchase tokens using multi-signature, REGARDLESS of active status
    *
    */
    function signedPurchase(uint256 tokenId, uint256 amount, uint256 _timestamp, bytes memory _signature) external payable whenNotPaused {
        address signerOwner = _signatureWallet(msg.sender, tokenId, amount, _timestamp, _signature);
        require(signerOwner == owner(),             "Not authorized to mint");
        require(_timestamp >= block.timestamp - 60, "Signature expired, out of time");
        _purchase(tokenId, amount);
    }

    function _signatureWallet(address wallet, uint256 _tokenId, uint256 _amount, uint256 _timestamp, bytes memory _signature) internal pure returns (address) {
        return ECDSA.recover(_ethSignedMessage(keccak256(abi.encode(wallet, _tokenId, _amount, _timestamp))), _signature);
    }

    function _ethSignedMessage(bytes32 messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    /**
    * @notice global purchase function
    *
    * @param tokenId the token id
    * @param amount the amount of tokens to purchase
    */
    function _purchase(uint256 tokenId, uint256 amount) private {
        require(amount > 0 && amount <= maxPerTx[tokenId], "Purchase: amount prohibited");
        require(totalSupply(tokenId) + amount <= maxSupply[tokenId], "Purchase: Max supply reached");
        require(msg.value == amount * mintPrice[tokenId], "Purchase: Incorrect payment");
        require(maxPerWallet[tokenId] == 0 || balanceOf(msg.sender, tokenId) + amount <= maxPerWallet[tokenId], "Purchase: Max per-wallet ownership reached");

        _mint(msg.sender, tokenId, amount, "");
    }

    /**
    * Hatch to let owner mint on behalf of recipient
    */
    function ownerMint(address wallet, uint256 tokenId, uint256 amount) external onlyOwner {
        _mint(wallet, tokenId, amount, "");
    }

    /**
    * Hatch to let owner mint on behalf of recipient
    */
    function ownerMintBatch(address[] memory wallets, uint256[] memory tokenIds, uint256[] memory amounts) external onlyOwner {
        require(wallets.length == tokenIds.length, "ownerMintBatch: wallets and tokenIds length mismatch");
        require(wallets.length == amounts.length, "ownerMintBatch: wallets and amounts length mismatch");

        for (uint256 i = 0; i < wallets.length; ++i) {
            _mint(wallets[i], tokenIds[i], amounts[i], "");
        }
    }

    function ownerBurn(
        address wallet,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        _burn(wallet, tokenId, amount);
    }

    function withdrawAll() public payable onlyOwner {
        uint256 all = address(this).balance;
        require(payable(addr_1).send(all));
    }

}