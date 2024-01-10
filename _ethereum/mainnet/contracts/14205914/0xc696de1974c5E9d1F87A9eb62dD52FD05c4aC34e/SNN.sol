// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./IERC20.sol";
import "./Initializable.sol";
import "./ERC721B.sol";
import "./IStrongService.sol";

/**
 * @title SNN contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

contract SNN is ERC721B, Initializable {
    IStrongService public strongService;
    IERC20 public strongToken;

    using Strings for uint256;

    address public _owner;
    string private _tokenBaseURI;
    uint256 public MAX_SNN_SUPPLY;
    bool public isSale;

    mapping(uint256 => uint256) public createdTime;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function initialize(
    ) public initializer {
        MAX_SNN_SUPPLY = 10000;
        _owner = 0x7E83F877A21D523a0a4a482083f7D27533289b52;
        _name = "Strong Squared NFT Genesis 1-100";
        _symbol = "SSN1";
        strongService = IStrongService(0xFbdDaDD80fe7bda00B901FbAf73803F2238Ae655);
        strongToken = IERC20(0x990f341946A3fdB507aE7e52d17851B87168017c);
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
        createdTime[supply] = block.timestamp;
        _mint( msg.sender, supply++);
    }

    function claim(uint128 tokenId, uint256 blockNumber)
        external
        payable
    {
        uint256 fee = getClaimFee(tokenId, blockNumber);

        require (msg.value >= fee, "invalid fee.");
        strongService.claim{value: msg.value}(tokenId + 1, blockNumber, false);
        strongToken.transfer(ownerOf(tokenId), strongToken.balanceOf(address(this)));
    }

    function payFee(uint128 tokenId)
        external
        payable
    {
        require(msg.value == strongService.recurringNaaSFeeInWei(), "invalid fee");
        strongService.payFee{value: msg.value}(tokenId + 1);
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

    function getNodePaidOn(uint128 tokenId)
        external
        view
        returns (uint256)
    {
        return strongService.getNodePaidOn(address(this), tokenId + 1);
    }

    function getNodeCalimedOn(uint128 tokenId)
        external
        view
        returns (uint256)
    {        
        return strongService.entityNodeClaimedOnBlock(strongService.getNodeId(address(this), tokenId + 1));
    }

    /*
    * Set owner
    */
    function setOwner(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}