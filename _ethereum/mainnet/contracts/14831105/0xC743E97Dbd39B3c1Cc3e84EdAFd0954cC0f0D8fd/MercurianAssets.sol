// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./Strings.sol";

import "./AbstractERC1155Factory.sol";

contract MercurianAssets is AbstractERC1155Factory {
    mapping (uint256 => uint256) supplyByTokenId; // tokenId -> supply
    mapping (uint256 => mapping (address => uint256)) private priceTable; // [id][currency address] => price
    mapping (uint256 => uint256) private walletMintLimitForAsset; // to save gas, values are 1 by default, as this mapping is only exposed through getwalletMintLimitForAsset
    mapping (uint256 => uint256) public saleState; // 0 = paused , 1 = activeType1 , 2+ = future-proof sale states

    mapping (address=> mapping (uint256 => uint256)) private addressMintAmount; // track how many of a tokenId a wallet has minted

    // a mapping from an address to whether or not it can mint / burn keys (Melange Labs contracts only)
    mapping(address => bool) controllers;

    event TokenMinted(address _to, uint256 _tokenId, uint256 _amount);
    
    constructor(address _magnesiumAddress, string memory _uri) ERC1155(_uri) {
        name_ = "Mercurian Assets";
        symbol_ = "MERCURIAN ASSETS";
        supplyByTokenId[0] = 1631;
        for(uint256 i = 1; i < 5; i++){
            supplyByTokenId[i] = 200;
        }
        priceTable[0][_magnesiumAddress] = 35000000000000000000; // 35 $MAG
    }

    // GETTERS

    function getPrice(uint256 _tokenId, address _currency) external view returns (uint256) {
        return priceTable[_tokenId][_currency];
    }

    function getWalletMintLimitForAsset(uint256 _tokenId) public view returns (uint256) {
        return walletMintLimitForAsset[_tokenId] + 1; // add 1 to reduce storage writes
    }

    // SETTERS

    function setSupplyByTokenID(uint256 _tokenId, uint256 _newSupply) external onlyOwnerOrAdmin {
        supplyByTokenId[_tokenId] = _newSupply;
    }

    function setPriceByIdAndCurrency(uint256 _tokenId, address _currency, uint256 _price) external onlyOwnerOrAdmin {
        require(_price != 0, "Making price 0 will invalidate logic");
        priceTable[_tokenId][_currency] = _price;
    }

    function setSaleStateForToken(uint256 _tokenId, uint256 _intended) external onlyOwnerOrAdmin {
        require(saleState[_tokenId] != _intended, "This is already the value");
        saleState[_tokenId] = _intended;
    }

    /** 
     * The value is 1 by default, as it is only exposed through getwalletMintLimitForAsset(id)
     * @dev Input the correct number to set as the new per-wallet mint limit of an asset
     */
    function setWalletMintLimitForAsset(uint256 _tokenId, uint256 _limit) external onlyOwnerOrAdmin {
        require(_limit > 0, "_limit must be input > 0");
        walletMintLimitForAsset[_tokenId] = _limit - 1; // subtract 1 to keep accurate and reduce storage writes
    }


    function addController(address controller) external onlyOwnerOrAdmin {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwnerOrAdmin {
        controllers[controller] = false;
    }

    // MINT / BURN

    function mint(address _to, uint256 _tokenId, uint256 _amount) external whenNotPaused {
        require(totalSupply(_tokenId) + _amount <= supplyByTokenId[_tokenId], "Total supply reached for this token"); // call first as it has highest chance of failing on-chain
        require(saleState[_tokenId] == 1, "Wrong sale state for this token"); // to call this function, sale state must be 1 for _tokenId
        require(addressMintAmount[_to][_tokenId] + _amount <= getWalletMintLimitForAsset(_tokenId), "Minting limit exceeded");
        require(controllers[_msgSender()], "Only controller contracts can call this function");
        addressMintAmount[_to][_tokenId] += _amount;
        _mint(_to, _tokenId, _amount, "");
        emit TokenMinted(_to, _tokenId, _amount);
    }

    function mintFutureProof(address _to, uint256 _tokenId, uint256 _amount, uint256 _futureProofSaleState) external whenNotPaused {
        require(totalSupply(_tokenId) + _amount <= supplyByTokenId[_tokenId], "Total supply reached for this token"); // call first as it has highest chance of failing on-chain
        require(saleState[_tokenId] == _futureProofSaleState, "Wrong sale state for this token");
        require(addressMintAmount[_to][_tokenId] + _amount <= getWalletMintLimitForAsset(_tokenId), "Minting limit exceeded");
        require(controllers[_msgSender()], "Only controller contracts can call this function");
        addressMintAmount[_to][_tokenId] += _amount;
        _mint(_to, _tokenId, _amount, "");
        emit TokenMinted(_to, _tokenId, _amount);
    }

    function devMint(address _to, uint256 _tokenId, uint256 _amount) external onlyOwnerOrAdmin {
        require(totalSupply(_tokenId) + _amount <= supplyByTokenId[_tokenId], "Total supply reached for this token");
        _mint(_to, _tokenId, _amount, "");
        emit TokenMinted(_to, _tokenId, _amount);
    }

    function burn(address account, uint256 id, uint256 value) public virtual override {
        require(account == _msgSender() || isApprovedForAll(account, _msgSender()), "ERC1155: caller is not owner nor approved");
        _burn(account, id, value);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public virtual override {
        require(account == _msgSender() || isApprovedForAll(account, _msgSender()), "ERC1155: caller is not owner nor approved");
        _burnBatch(account, ids, values);
    }

    // OVERRIDES

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }

}