// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./IMEMBERSHIP.sol";
import "./IPASSTOKENS.sol";

/**
 * @title NiftyzMinter
 */

contract NiftyzMinter is Ownable {
    mapping(address => bool) public allowedContracts;
    IMEMBERSHIP membershipInstance;
    event Minted(
        address nftcontract,
        uint256 membershipId,
        address creator,
        uint256 amount,
        string metadata,
        uint256 tokenId
    );

    constructor(address _membership) {
        membershipInstance = IMEMBERSHIP(_membership);
    }

    function setMembershipAddress(address newmembership) external onlyOwner {
        membershipInstance = IMEMBERSHIP(newmembership);
    }

    function setContractState(address _contractAddress, bool _contractState)
        external
        onlyOwner
    {
        allowedContracts[_contractAddress] = _contractState;
    }

    function mintNFT(
        address _contractAddress,
        uint256 _membershipId,
        string memory _metadata,
        uint256 _supply,
        uint256 _price,
        uint256 _deadline
    ) external payable {
        require(
            allowedContracts[_contractAddress],
            "Smart contract not allowed"
        );
        require(
            membershipInstance.ownerOf(_membershipId) == msg.sender,
            "Not the owner of membership"
        );
        // Mint nft to specific pass token contract
        uint256 tokenId = IPASSTOKENS(_contractAddress).mint{value: msg.value}(
            _membershipId,
            _metadata,
            _supply,
            _price,
            _deadline
        );
        // Emit event to track and store outside blockchain
        emit Minted(
            _contractAddress,
            _membershipId,
            membershipInstance.ownerOf(_membershipId),
            _supply,
            _metadata,
            tokenId
        );
    }
}
