// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./ERC721B.sol";
import "./IStrongService.sol";

/**
 * @title SNN contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

contract SNN is Ownable, ERC721B {
    IStrongService strongService = IStrongService(0xFbdDaDD80fe7bda00B901FbAf73803F2238Ae655);
    IERC20 strongToken = IERC20(0x990f341946A3fdB507aE7e52d17851B87168017c);

    using Strings for uint256;

    string private _tokenBaseURI;
    uint256 public MAX_SNN_SUPPLY;
    bool public isSale;

    constructor() ERC721B("STRONG NODE NFT Test", "SNNTest") {
        MAX_SNN_SUPPLY = 10000;
        strongToken.approve(address(strongService), 2**256 - 1);
    }

    /**
     * Check if certain token id is exists.
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }

    /**
     * Get the array of token for owner.
     */
    function tokensOfOwner(address owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 id = 0;
            for (uint256 index = 0; index < _owners.length; index++) {
                if(_owners[index] == owner)
                result[id++] = index;
            }
            return result;
        }
    }
    
    function getRewardByBlock(uint128 tokenId, uint256 blockNumber)
        public
        view
        returns (uint256)
    {
        return strongService.getRewardByBlock(address(this), tokenId + 1, blockNumber);
    }

    function getReward(uint128 tokenId)
        external
        view
        returns (uint256)
    {
        return strongService.getReward(address(this), tokenId + 1);
    }

    function getClaimFee(uint128 tokenId, uint256 blockNumber)
        public
        view
        returns (uint256)
    {
        uint256 reward = getRewardByBlock(tokenId, blockNumber);
        return reward * strongService.claimingFeeNumerator() / strongService.claimingFeeDenominator();
    }

    /*
    * Set base URI
    */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _tokenBaseURI = baseURI;
    }

    /*
    * Set sale status
    */
    function setSaleStatus(bool _isSale) external onlyOwner {
        isSale = _isSale;
    }

    /**
    * Create Strong Node & Mint SNN 
    */
    function mint()
        external
        payable
    {
        require(isSale, "Sale must be active to mint");
        
        uint256 supply = _owners.length;
        uint256 naasRequestingFeeInWei = strongService.naasRequestingFeeInWei();
        uint256 naasStrongFeeInWei = strongService.naasStrongFeeInWei();

        require(msg.value == naasRequestingFeeInWei, "invalid requesting fee");
        require(supply + 1 <= MAX_SNN_SUPPLY, "Purchase would exceed max supply");

        strongToken.transferFrom(msg.sender, address(this), naasStrongFeeInWei);
        strongService.requestAccess{value: naasRequestingFeeInWei}(true);
        _mint( msg.sender, supply++);
    }

    function claim(uint128 tokenId, uint256 blockNumber)
        external
        payable
    {
        require(msg.sender == ownerOf(tokenId) || msg.sender == owner(), "invalid owner.");

        uint256 fee = getClaimFee(tokenId, blockNumber);

        require (msg.value >= fee, "invalid fee.");
        uint256 oldBalance = address(this).balance - msg.value;
        strongService.claim{value: msg.value}(tokenId + 1, blockNumber, false);
        uint256 reward = address(this).balance - oldBalance;
        payable(ownerOf(tokenId)).transfer(reward);
    }

    function payFee(uint128 tokenId)
        external
        payable
    {
        require(msg.sender == ownerOf(tokenId) || msg.sender == owner() , "invalid owner.");
        require(msg.value == strongService.recurringNaaSFeeInWei(), "invalid fee");
        strongService.payFee{value: msg.value}(tokenId + 1);
    }

    function payAll()
        external
        payable
    {
        require(msg.value == strongService.recurringNaaSFeeInWei() * _owners.length, "invalid fee");
        strongService.payAll{value: msg.value}(_owners.length);
    }

    function getNaasRequestingFeeInWei()
        external
        view
        returns (uint256)
    {
        return strongService.naasRequestingFeeInWei();
    }

    function getNaasStrongFeeInWei()
        external
        view
        returns (uint256)
    {
        return strongService.naasStrongFeeInWei();
    }

    function getRecurringNaaSFeeInWei()
        external
        view
        returns (uint256)
    {
        return strongService.recurringNaaSFeeInWei();
    }
}