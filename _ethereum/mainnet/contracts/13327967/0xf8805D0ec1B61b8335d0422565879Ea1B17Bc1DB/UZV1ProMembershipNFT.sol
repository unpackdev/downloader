// contracts/interfaces/UZV1ProMembershipNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./IUZV1ProMembershipNFT.sol";
import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";

contract UZV1ProMembershipNFT is
    ERC721Upgradeable,
    OwnableUpgradeable,
    IUZV1ProMembershipNFT
{
    // we need to be able to exclude addresses from
    // owning memberships
    mapping(address => uint256) internal _blacklist;
    // address of minter user. usually the sale contract
    address internal _minter;
    // counter for token ids
    uint256 internal _tokenCounter;
    // flag if trading / transferring of memberships is allowed.
    // by default this is not an option
    bool public isTransferable;

    function initialize() public initializer {
        __ERC721_init("Unizen Pro Membership", "UZP");
        __Ownable_init();
        // by default the token is not transferable
        isTransferable = false;
        // we start with token id 1
        _tokenCounter = 1;
    }

    /* === VIEW FUNCTIONS === */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        // check that the token exists
        require(_exists(tokenId), "INVALID_TOKEN");
        // get default token uri
        return ERC721Upgradeable.tokenURI(tokenId);
    }

    // not needed, remove
    function baseURI() public view override returns (string memory) {}

    /* === MUTATING FUNCTIONS === */
    function mint(address receiver) external override onlyMinter {
        // no need to check receiver, will be taken care of by
        // underlying mint function
        _safeMint(receiver, _tokenCounter);
        // increment token counter
        _tokenCounter++;
    }

    function isAddressBanned(address user) public view returns (bool banned) {
        // check if user is banned
        banned = (_blacklist[user] > 0);
    }

    /* === INTERNAL FUNCTIONS === */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal view override {
        // verify its a valid token
        require(tokenId > 0 && tokenId <= _tokenCounter, "INVALID_TOKEN_ID");
        // check that address is not blacklisted
        require(isAddressBanned(from) == false, "BLACKLISTED_SENDER");
        require(isAddressBanned(to) == false, "BLACKLISTED_RECIPIENT");
        // check if transfers are allowed
        if (isTransferable == false) {
            // only allow transfer by minting / burning
            require(
                from == address(0) || to == address(0),
                "TRANSFER_DISABLED"
            );
        }
        // only one token allowed per address
        if (to != address(0)) {
            require(balanceOf(to) == 0, "MEMBERSHIP_LIMIT_REACHED");
        }
    }

    /* === CONTROL FUNCTIONS === */
    function setMinterAddress(address newMinterAddress)
        external
        override
        onlyOwner
    {
        require(newMinterAddress != _minter, "SAME_ADDRESS");
        _minter = newMinterAddress;
    }

    function switchTransferable() external override onlyOwner {
        isTransferable = !isTransferable;
        emit TransferRightsChanged(isTransferable);
    }

    function banAddress(address userAddress) external onlyOwner {
        // check that user has a membership
        require(balanceOf(userAddress) > 0, "USER_NO_MEMBERSHIP");
        // check that user is not already banned
        require(isAddressBanned(userAddress) == false, "USER_BANNED");

        // get tokenId of user at index 0. as we only allow
        // 1 token per address, this is the correct one
        uint256 tokenId = tokenOfOwnerByIndex(userAddress, 0);
        require(tokenId > 0, "INVALID_TOKEN");

        // burn the token
        _burn(tokenId);
        // add user to blacklist with the tokenId
        // as value, since we might have to revert it
        // in the future.
        _blacklist[userAddress] = tokenId;
    }

    function revertBan(address userAddress) external onlyOwner {
        // check that user does not have any tokens
        require(balanceOf(userAddress) == 0, "MEMBERSHIP_LIMIT_REACHED");
        // check that user is currently banned
        require(isAddressBanned(userAddress) == true, "USER_NOT_BANNED");

        // get the old tokenId of the banned user, to restore
        // all eventually saved data. Since we know the user was
        // banned, tokenId cant be 0
        uint256 tokenId = _blacklist[userAddress];
        // remove user from blacklist, so a new token can be
        // minted for his address
        _blacklist[userAddress] = 0;
        // mint the new token
        _safeMint(userAddress, tokenId);
    }

    /* === MODIFIERS === */
    modifier onlyMinter {
        require(_msgSender() == _minter);
        _;
    }

    /* === EVENTS === */
    event TransferRightsChanged(bool allowed);
}
