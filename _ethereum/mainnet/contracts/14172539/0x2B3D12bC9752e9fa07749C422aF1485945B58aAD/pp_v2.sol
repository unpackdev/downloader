// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract potatoPimps is ERC721, Ownable {

    using Counters for Counters.Counter;
    
    struct ConfigStateData {
        
        uint8 maxTokensPerTxn;
        uint16 maxTokens;
        saleState salestate;
        string baseUri;
        uint256 mintPrice;
        address projectWallet;
        
    }

    enum saleState { paused, presale, publicsale }
    ConfigStateData public potatoPimpsStateData;

    Counters.Counter private _tokenIdCounter;
    mapping(address => bool) public whitelistedAddresses;

    constructor( string memory _tokenName, string memory _tokenNameCode, uint16 _maxTokens, uint256 _mintPrice, address _project_wallet) 
        ERC721(  _tokenName, _tokenNameCode) {

            potatoPimpsStateData.maxTokens =  _maxTokens;
            potatoPimpsStateData.mintPrice =  _mintPrice;
            potatoPimpsStateData.projectWallet =  _project_wallet;

            potatoPimpsStateData.maxTokensPerTxn =  10;
            whitelistedAddresses[msg.sender] = true;
            _tokenIdCounter.increment();

    }

    function setDevWalletAddress(address _project_wallet) external onlyOwner {
        potatoPimpsStateData.projectWallet = _project_wallet;
    }

    function setSalePrice (uint256 _salePrice) external onlyOwner {
        potatoPimpsStateData.mintPrice = _salePrice;
    }

    function setSaleState(uint _statusId) external onlyOwner {
        potatoPimpsStateData.salestate = saleState(_statusId);
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        potatoPimpsStateData.baseUri = _baseUri;
    }

    function appendToWhitelist(address[] calldata _whitelist_addr_list) external onlyOwner {
        for (uint i = 0; i < _whitelist_addr_list.length; i++) {
            whitelistedAddresses[_whitelist_addr_list[i]] = true;
        }
    }

    function mint(uint8 _number_to_mint) public payable {

        uint256 nextMintId = _tokenIdCounter.current();
        uint256 activeSaleStateInt = uint(potatoPimpsStateData.salestate);

        require(activeSaleStateInt > 0, "Minting Paused");
        require(msg.value >= (potatoPimpsStateData.mintPrice * uint(_number_to_mint)), "Under paid");
        require(((_number_to_mint <= potatoPimpsStateData.maxTokensPerTxn) && (_number_to_mint > 0)), "Being greedy or silly");
        require(nextMintId <= (potatoPimpsStateData.maxTokens - uint(_number_to_mint)) , "Not enough supply");

        if (activeSaleStateInt == 1){

            require(whitelistedAddresses[msg.sender] == true, "Not whitelisted");

            for (uint i = 0; i < _number_to_mint; i++) {
                _mint(msg.sender, nextMintId + i);
                _tokenIdCounter.increment();
            }

            delete(whitelistedAddresses[msg.sender]);

        } else {

            for (uint i = 0; i < _number_to_mint; i++) {
                _mint(msg.sender, nextMintId + i);
                _tokenIdCounter.increment();
            }

        }

        delete nextMintId;
        delete activeSaleStateInt;
    }

    function withdraw() external onlyOwner {

        address payable _project_devs = payable(potatoPimpsStateData.projectWallet);

        _project_devs.transfer(address(this).balance);

    }

    function _baseURI() internal view override returns (string memory) {
        return potatoPimpsStateData.baseUri;
    }

}