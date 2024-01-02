// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Importing ERC1155 and ERC721 interfaces
import "./IERC1155.sol";
import "./IERC721.sol";
import "./Ownable.sol";

contract Apothecary is Ownable {

    // Mapping owner address to token count
    mapping(address => bool) private _whitelistAvatarCollection;
    mapping(address => bool) private _whitelistPotionCollection;

    // Not using 0 address to distinguish between burn on potion and consume
    // Could be also changed to address(0) and use only event log as source of truth
    address constant DEAD_ADDRESS = address(0); // 0x000000000000000000000000000000000000dEaD;
    bool private _isDisabled = false;

    event Consume(
        address avatarAddress,
        uint256 avatarID,
        address potionAddress,
        uint256 potionID,
        uint256 amount,
        address user
    );

    event MultiConsume(
        address avatarAddress,
        uint256 avatarID,
        address[] potionAddresses,
        uint256[][] potionIDs,
        uint256[][] amounts,
        address user
    );

    function setAvatarWhitelist(address avatarAddress, bool isWhitelist) public onlyOwner{
        _whitelistAvatarCollection[avatarAddress] = isWhitelist;
    }

    function setPotionWhitelist(address potionAddress, bool isWhitelist) public onlyOwner{
        _whitelistPotionCollection[potionAddress] = isWhitelist;
    }    

    function setIsDisabled(bool disabled) public onlyOwner{
        _isDisabled = disabled;
    }

    function isDisabled() public view returns(bool) {
        return _isDisabled;
    }

    function isAvatarWhitelisted(address avatarAddress) public view returns(bool){
        return _whitelistAvatarCollection[avatarAddress];
    }

    function isPotionWhitelist(address potionAddress) public view returns(bool){
        return _whitelistPotionCollection[potionAddress];
    }

    function singleConsume(
        address avatarAddress,
        uint256 avatarID,
        address potionAddress,
        uint256 potionID,
        uint256 amount
    ) public {
        IERC721 avatarCollection = IERC721(avatarAddress);
        IERC1155 potionContract = IERC1155(potionAddress);
        require(!_isDisabled, "Apothecary disabled");
        require(_whitelistAvatarCollection[avatarAddress], "Avatar not whitelisted");
        require(_whitelistPotionCollection[potionAddress], "Potion not whitelisted");

        try avatarCollection.ownerOf(avatarID) returns (address avatarOwnerAddress) {
            require(avatarOwnerAddress == msg.sender, "Not owner of avatarID");
        } catch {
            revert("avatarID does not exist in the avatar contract");
        }

        try potionContract.safeTransferFrom(
            msg.sender,
            DEAD_ADDRESS,
            potionID,
            amount,
            ""
        ) {} catch Error(string memory errorMessage)  {
            revert(errorMessage);
        }

        emit Consume(
            avatarAddress,
            avatarID,
            potionAddress,
            potionID,
            amount,
            msg.sender
        );
    }

    function multiConsume(
        address avatarAddress,
        uint256 avatarID,
        address[] calldata potionAddresses,
        uint256[][] calldata potionIDs,
        uint256[][] calldata amounts
    ) public {
        IERC721 avatarCollection = IERC721(avatarAddress);
        require(!_isDisabled, "Apothecary disabled");
        require(
            potionAddresses.length == potionIDs.length &&
                potionAddresses.length == amounts.length,
            "Length of contracts, tokenIds, and amounts arrays must be the same"
        );
        require(_whitelistAvatarCollection[avatarAddress], "Avatar not whitelisted");
        for (uint i = 0; i < potionAddresses.length; i++) {
            require(_whitelistPotionCollection[potionAddresses[i]], "Potion not whitelisted");
            require(
                potionIDs[i].length == amounts[i].length,
                "Length of tokenIds and amounts sub-arrays must be the same"
            );
        }

        try avatarCollection.ownerOf(avatarID) returns (address avatarOwnerAddress) {
            require(avatarOwnerAddress == msg.sender, "Not owner of avatarID");
        } catch Error(string memory errorMessage){
            revert(errorMessage);
        }

        for (uint i = 0; i < potionAddresses.length; i++) {
            for (uint j = 0; j < potionIDs[i].length; j++) {
                try IERC1155(potionAddresses[i]).safeTransferFrom(
                    msg.sender,
                    DEAD_ADDRESS,
                    potionIDs[i][j],
                    amounts[i][j],
                    ""
                ) {} catch Error(string memory errorMessage){
                    revert(errorMessage);
                }
            }
        }

        emit MultiConsume(
            avatarAddress,
            avatarID,
            potionAddresses,
            potionIDs,
            amounts,
            msg.sender
        );
    }
}