// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./SafeMath.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./ERC165Checker.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";

/** 
  * @author Atlas Corporation
  * @title NFT Gated Faucet 
  */
contract KevinAirdrop is Ownable {

    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private approvedContracts;

    IERC20 public tokenContract;
    mapping(address => mapping(uint256 => bool)) public tokensClaimedByContract;
    uint256 public maxClaimPerTransaction;
    uint256 public numTokensPerNFT;

    event TokensClaimed(address _sender, address _contract, uint256 _claimAmount);
    event ContractApproved(address _contract);
    event ContractUnapproved(address _contract);

    constructor(address _tokenAddress) {

        tokenContract = IERC20(_tokenAddress);
        maxClaimPerTransaction = 100;
        numTokensPerNFT = 5000000000 ether;

    }

    /**
      * @notice claim Kevin Tokens stored in this airdrop contract using Kevin NFTs on approved collections
      * @dev maximum of 100 tokenIds can be used per claim transaction
      * @param _contractAddress address of ERC721 contract for tokenId references 
      * @param _tokenIds array of token numbers owned by sender
      */
    function claim(address _contractAddress, uint256[] calldata _tokenIds) public {
        require(_tokenIds.length > 0,"Must hold at least 1 Kevin NFT");
        require(_tokenIds.length <= maxClaimPerTransaction,"Must provide 100 or less tokens per transaction");
        require(isContractApproved(_contractAddress),"Contract address not approved for the faucet");

        IERC721 contract_ = IERC721(_contractAddress); 
        
        for(uint256 i = 0; i < _tokenIds.length; i++){
            require(contract_.ownerOf(_tokenIds[i])==msg.sender,"Sender does not own all tokens submitted");
            require(!tokensClaimedByContract[_contractAddress][_tokenIds[i]],"Token already claimed");
            tokensClaimedByContract[_contractAddress][_tokenIds[i]] = true;
        }

        uint256 numBadTokens = _tokenIds.length.mul(numTokensPerNFT);
        require(tokenContract.balanceOf(address(this)) >= numBadTokens, "Not enough tokens remaining in faucet");
        require(tokenContract.transfer(msg.sender,numBadTokens),"Error sending coins to caller");
        
        emit TokensClaimed(msg.sender, _contractAddress, numBadTokens);
    }

    /**
      * @notice add ERC721 contract to the approved list for the airdrop
      * @param _contractAddress address of ERC721 contract
      */
    function addContract(address _contractAddress) public onlyOwner {
        require(_contractAddress != address(this), "Cannot add smart to itself");
        require(ERC165Checker.supportsInterface(_contractAddress, type(IERC721).interfaceId), "Contract must support IERC721");
        require(approvedContracts.add(_contractAddress), "Contract already approved");

        emit ContractApproved(_contractAddress);
    }

    /**
      * @notice remove ERC721 contract from the approved list for the airdrop
      * @param _contractAddress address of ERC721 contract
      */
    function removeContract(address _contractAddress) public onlyOwner {
        require(approvedContracts.remove(_contractAddress),"Contract not on the approved list");
        
        emit ContractUnapproved(_contractAddress);
    }

    /**
      * @notice check if a contract is approved
      * @param _contractAddress address of ERC721 contract
      */
    function isContractApproved(address _contractAddress) public view returns (bool) {
        return approvedContracts.contains(_contractAddress);
    }

    /**
      * @notice get list of approved contracts
      * @dev unbounded and to be used for read-only
      */
    function getApprovedContracts() public view returns (address[] memory){
        return approvedContracts.values();
    }

}