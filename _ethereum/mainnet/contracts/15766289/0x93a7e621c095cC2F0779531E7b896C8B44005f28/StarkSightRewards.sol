// contracts/StarkSightRewards.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC1155Supply.sol";
import "./Ownable.sol";

import "./Strings.sol";
import "./ECDSA.sol";


/**
* @title StarkSight.xyz Rewards
* @author Trevis, Teandy SRL
*/
contract StarkSightRewards is ERC1155Supply, Ownable {

    /// @notice Base URI
    string private _baseURIextended;

    /// @notice First Reward Token is Awesome Beta Tester
    uint256 private constant _AWESOME_BETA_TESTER = 1;

    /// @notice Only allow 1 mint per event
    mapping(address => mapping(uint256 => bool)) private _userEventTracker;

    /**
    * @notice At creation of the contract, the first known beneficiaries get their rewards
    *  and metadata uri is provided.
    * @param baseUri base URI is used to make specific tokenId's URI with `uri`.
    * @param firstBeneficiaries Addresses of the first Awesome Beta Tester beneficiaries.
    */
    constructor(string memory baseUri, address[] memory firstBeneficiaries) ERC1155("") {

        for (uint addressIndex = 0; addressIndex < firstBeneficiaries.length; addressIndex++) {
            _mint(firstBeneficiaries[addressIndex], _AWESOME_BETA_TESTER, 1, "");
        }

        setBaseURI(baseUri);
    }

    /// @notice Returns uri formatted with non padded decimal integer representation.
    /// @return string 
    function uri(uint256 _tokenId) public view override returns (string memory) {
        return string(
            abi.encodePacked(_baseURIextended, Strings.toString(_tokenId), ".json")
        );
    }

    /**
    * @notice Allows to know if an address already collected a reward for a specific event (prevents replay).
    * @param userAddress Address of the recipient.
    * @param eventId "Nonce" used to ensure rewards are only collected once.
    * @return bool
    */
    function didAddressCollectEvent(address userAddress, uint256 eventId) public view returns (bool) {
        return _userEventTracker[userAddress][eventId];
    }

    /**
    * @notice Allow a wallet to collect their reward using the appropriate signature for the token, amount and eventId.
    *  Only if all arguments are valid with respect to the reward allocation will the reward be minted. 
    * @param tokenId ID of the token to collect.
    * @param amount The amount of token(s) allocated as part of the reward.
    * @param eventId "Nonce" used to ensure rewards are only collected once.
    * @param signature Proof of reward allocation for the other passed arguments (owner's signature). 
    */
    function collectReward(uint256 tokenId, uint256 amount, uint256 eventId, bytes memory signature) public {
        require(
            didAddressCollectEvent(msg.sender, eventId) == false, 
            "Address already minted token(s) for this event"
        );

        bytes32 messageHash = keccak256(
            abi.encode(
                msg.sender,
                tokenId,
                amount,
                eventId
            )
        );

        require(
            _isOwnerSigned(messageHash, signature),
            "Invalid owner signature"
        );

        _mint(msg.sender, tokenId, amount, "");
        _userEventTracker[msg.sender][eventId] = true;
    }

    /// @notice Change base URI.
    function setBaseURI(string memory newBaseUri) public onlyOwner {
        _baseURIextended = newBaseUri;
    }

    /**
    * @notice Used by StarkSight/Teandy to mint rewards.
    */
    function mint(address to_address, uint256 tokenId, uint256 amount)
        public
        onlyOwner
    {
        _mint(to_address, tokenId, amount, "");
    }

    /**
    * @notice Used by StarkSight/Teandy to mint rewards.
    */
    function batchMint(
        address[] memory to_addresses, 
        uint256[] memory tokenIds, 
        uint256[] memory amounts
    )
        public
        onlyOwner
    {
        require(
            to_addresses.length == tokenIds.length && tokenIds.length  == amounts.length,
            "Input arrays should have the same length"
        );
        for (uint mintIndex = 0; mintIndex < to_addresses.length; mintIndex++) {
            _mint(to_addresses[mintIndex], tokenIds[mintIndex], amounts[mintIndex], "");
        }
    }

    /// @dev Check that collectReward's signature argument was provided by owner. 
    function _isOwnerSigned(bytes32 messageHash, bytes memory signedMessage) private view returns (bool) {
        return ECDSA.recover(
            ECDSA.toEthSignedMessageHash(messageHash),
            signedMessage
        ) == owner();
    }
}
