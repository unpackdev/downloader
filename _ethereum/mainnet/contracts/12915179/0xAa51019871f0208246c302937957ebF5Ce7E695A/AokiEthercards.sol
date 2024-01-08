// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";

import "./ERC721CreatorExtensionApproveTransfer.sol";


import "./ERC721OwnerEnumerableSingleCreatorExtension.sol";
import "./ICreatorExtensionTokenURI.sol";
import "./ERC721RedeemBase.sol";

import "./IERC721.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * Aoki Redeem
 */
contract AokiEthercards is AdminControl, ERC721OwnerEnumerableSingleCreatorBase, ERC721RedeemBase, ICreatorExtensionTokenURI {

    uint16 constant max = 1000;

    using Strings for uint256;

    
    uint256 _end   = 1627790400;
   

    bool    private _active;
    int256  private _offset;
    string  private _endpoint;
    mapping(address => uint16)  public allowed;

    mapping(address => mapping(uint256 => bool)) public _redeemedTokens;


    constructor(address creator_,
                address _ethercards, 
                uint16 ecMax, 
                address[] memory unlimitedContracts,
                bool[]    memory unlimitedOK,
                address          limtedContract,
                uint256[] memory tokenMinimums,
                uint256[] memory tokenMaximums) ERC721RedeemBase(creator_, 1, max) {
        require(unlimitedContracts.length == unlimitedOK.length && unlimitedOK.length == 3,"There should be 3 unlimited Contracts");
        

        allowed[_ethercards] = ecMax;       
        updateApprovedContracts(unlimitedContracts, unlimitedOK);
        updateApprovedTokenRanges(limtedContract, tokenMinimums,tokenMaximums );
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721RedeemBase, AdminControl, IERC165, ERC721CreatorExtensionApproveTransfer) returns (bool) {
        return interfaceId == 
            type(ICreatorExtensionTokenURI).interfaceId || 
            ERC721RedeemBase.supportsInterface(interfaceId) || 
            AdminControl.supportsInterface(interfaceId) ||
            ERC721CreatorExtensionApproveTransfer.supportsInterface(interfaceId);
    }

    /**
     * @dev Activate the contract and mint the first few tokens to a specific address
     *
     * @param initialMintCount     - Number of tokens to initially mint
     * @param initialMintRecipient - Recipient of the initial minted tokens
     */
    function activate(uint256 initialMintCount, address initialMintRecipient) public adminRequired {
        require(!_active, "Already active");
        IERC721CreatorCore(_creator).setApproveTransferExtension(true);
        _active = true;
        
        // Set the offset only if you want to start the numbering to the ether cards api at a number other than 1
        _offset = 0;

        _endpoint = 'https://client-metadata.ether.cards/api/aoki/DistortedReality/';

        // Mint the first tokens
        for (uint i = 0; i < initialMintCount; i++) {
            _mintRedemption(initialMintRecipient);
        }
    }

    function setEndpoint(string calldata endpoint) public adminRequired {
        _endpoint = endpoint;
    }

    function setEndOfRedeem(uint256 _newEnd) public adminRequired {
        _end = _newEnd;
    }

    function additionalNFTBonus(address nft, uint16 additional) public adminRequired {
        allowed[nft] += additional;
    }

    function redeem(address tokenContract, uint256 tokenId) public {
        require(_active, "Inactive");
        require(_end > block.timestamp, "Redemption is over");
        bool canBeRedeemed = redeemable(tokenContract, tokenId) || allowed[tokenContract] > 0;
        if  (allowed[tokenContract] > 0) {
            allowed[tokenContract] -= 1;
        }
        require(canBeRedeemed && !_redeemedTokens[tokenContract][tokenId], "Invalid token or already redeemed");
        require(IERC721(tokenContract).ownerOf(tokenId) == msg.sender, "You do not own this token");
        _redeemedTokens[tokenContract][tokenId] = true;
        _mintRedemption(msg.sender);
    }

    // tokenURI extension
    function tokenURI(address creator, uint256 tokenId) public view override returns (string memory) {
        require(creator == _creator && _mintNumbers[tokenId] != 0, "Invalid token");
        return string(abi.encodePacked(_endpoint,uint256(int256(_mintNumbers[tokenId])+_offset).toString()));
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return tokenURI(_creator, tokenId);
    }

}
