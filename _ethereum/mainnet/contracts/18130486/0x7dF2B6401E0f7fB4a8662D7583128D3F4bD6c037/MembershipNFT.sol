// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";


error TokenNonTransferable();
error TokenBurnableOwnerOnly();
error InvalidToken(uint256 tokenId);
error TokenAlreadyExists();
error EmptyBaseURI();
error EmptyReceiversArray();
error InvalidExpirationDate();
error InvalidPermissions();
error InvalidAddress();
error AlreadyHasMembership(address _address);


contract MembershipNFT is Initializable, ERC721Upgradeable, ERC721BurnableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter public totalSupply;
    string public baseURI;

    struct Membership {
        uint256 tokenId;
        uint256 expirationDate;
        address owner;
        bool currentMember;
    }

    mapping(uint256 => Membership) private memberships;

    event MembershipsCreated(address[] _receivers);
    event MembershipRenewed(uint256 tokenId, uint256 expirationDate);
    event MembershipDeactivated(uint256 tokenId);
    event MembershipActivated(uint256 tokenId);
    event BaseURIUpdated(string _baseURI);

    modifier onlyIfExist(uint256 tokenId) {
        if (!_exists(tokenId)) {
            revert InvalidToken(tokenId);
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("Serotonin", "SERO");
        __ERC721Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    // MANAGE MEMBERSHIPS

    /**
     * @dev Mints a new membership to the `_receivers` with the given `daysUntilExpiration`.
     * @param _receivers address[] array of addresses to receive the membership. If the array is empty, it reverts.
     * @param _daysUntilExpiration uint256 number of days until the membership expires. If the number is 0, it reverts.
     * Only the contract owner can mint memberships.
     * The membership is minted with the current block timestamp + `daysUntilExpiration` as the expiration date.
     * A member can only have one membership.
     */
    function createMemberships(address[] calldata _receivers, uint256 _daysUntilExpiration) public onlyOwner {
        // Check if receivers array is not empty
        if (_receivers.length == 0) {
            revert EmptyReceiversArray();
        }
        // Check that the daysUntilExpiration is positive
        if (_daysUntilExpiration <= 0) {
            revert InvalidExpirationDate();
        }

        // Send the memberships to the receivers
        for (uint256 i = 0; i < _receivers.length; ) {
            // Check if the receiver already has a membership
            if (balanceOf(_receivers[i]) > 0) {
                revert AlreadyHasMembership(_receivers[i]);
            }
            totalSupply.increment();
            uint256 tokenId = totalSupply.current();
            _safeMint(_receivers[i], tokenId);
            memberships[tokenId] = Membership(tokenId, block.timestamp + (_daysUntilExpiration * 1 days), _receivers[i], true);

            unchecked {
                i++;
            }
        }
        emit MembershipsCreated(_receivers);
    }

    /**
     * @dev Set a new expiration date for a membership.
     * @param tokenId uint256 ID of the token to be extended. If the token ID does not exist, it reverts.
     * @param daysUntilExpiration uint256 number of days until the membership expires. If the number is 0, it reverts.
     * Only the contract owner can renew a membership
     */
    function renewMembership(uint256 tokenId, uint256 daysUntilExpiration) public onlyOwner onlyIfExist(tokenId) {
        // Make sure the daysUntilExpiration is positive
        if (daysUntilExpiration == 0) {
            revert InvalidExpirationDate();
        }
        memberships[tokenId].expirationDate = block.timestamp + (daysUntilExpiration * 1 days);
        emit MembershipRenewed(tokenId, memberships[tokenId].expirationDate);
    }

    /**
     * @dev Unactivate a membership by setting the currentMember to false
     * @param tokenId uint256 ID of the token to be unactivated. If the token ID does not exist, it reverts.
     * Only the contract owner can unactivate a membership
     */
    function deactivateMembership(uint256 tokenId) external onlyOwner onlyIfExist(tokenId) {
        // Set the currentMember to false
        memberships[tokenId].currentMember = false;
        emit MembershipDeactivated(tokenId);
    }

    /**
     * @dev Activate a membership by setting the currentMember to true
     * @param tokenId uint256 ID of the token to be activated. If the token ID does not exist, it reverts.
     * Only the contract owner can activate a membership
     */
    function activateMembership(uint256 tokenId) external onlyOwner onlyIfExist(tokenId) {
        // Set the currentMember to true
        memberships[tokenId].currentMember = true;
        emit MembershipActivated(tokenId);
    }

    // MANAGE CONTRACT

    /**
     * @dev Sets the base URI for all token IDs.
     * @param _baseURI string URI prefix. If the URI is empty, it reverts.
     */
    function setBaseURI(string calldata _baseURI) public onlyOwner {
        // Make sure the base URI is not empty
        if (bytes(_baseURI).length == 0) {
            revert EmptyBaseURI();
        }
        baseURI = _baseURI;
        emit BaseURIUpdated(_baseURI);
    }

    // GETTERS

    /**
     * @dev Returns the URI for a given token ID.
     * @param tokenId uint256 ID of the token to query. If the token ID does not exist, it reverts.
     * The URI points to a JSON file that conforms to the "ERC721 Metadata JSON Schema".
     * The URI depends on `baseURI` and the membership's parameters: expiration date and currentMember.
     */
    function tokenURI(uint256 tokenId) public view onlyIfExist(tokenId) override returns (string memory)  {
        // Return the correct URI based on the membership's parameters
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, isMembershipActive(tokenId) ? "1" : "0", ".json")) : "";
    }

    /**
     * @dev Returns the membership for a given token ID.
     * @param tokenId uint256 ID of the token to query. If the token ID does not exist, it reverts.
     */
    function getMembership(uint256 tokenId) onlyIfExist(tokenId) public view returns (Membership memory)   {
        return memberships[tokenId];
    }

    /**
     * @dev Returns the membership status for a given address.
     * @param tokenId uint256 ID of the token to query. If the token ID does not exist, it reverts.
     * The membership status is true if the member is a currentMember and the expiration date is greater than the current block timestamp.
     */
    function isMembershipActive(uint256 tokenId) onlyIfExist(tokenId) public view returns (bool) {
        return memberships[tokenId].currentMember && memberships[tokenId].expirationDate > block.timestamp;
    }

    // INTERNAL FUNCTIONS

    function _authorizeUpgrade(address newImplementation)
        internal
        view
        onlyOwner
        override
    {}

    /**
     * @dev Override _beforeTokenTransfer to only allow the contract owner to transfer tokens except for burning,
     * which can be done by the token owner.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    override {
        if (_msgSender() != owner() && from != address(0) && to != address(0)) {
          revert TokenNonTransferable();
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @dev Override _afterTokenTransfer to approve the contract owner to transfer the token.
     */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override {
        super._afterTokenTransfer(from, to, firstTokenId, batchSize);
        for (uint256 i = 0; i < batchSize; i++) {
            if (to != owner() && to != address(0)) {
                // Approve the contract owner to transfer the token if not a burn
                _approve(owner(), firstTokenId + i);
            }
            // update membership owner
            memberships[firstTokenId + i].owner = to;
        }
    }
}