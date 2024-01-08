// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: FVCKRENDER
/// @author: manifold.xyz

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//        _______    __________ __     ____________  ________________    __       __ __     //
//       / ____/ |  / / ____/ //_/    / ____/ __ \ \/ / ___/_  __/   |  / /     _/_//_/     //
//      / /_   | | / / /   / ,<      / /   / /_/ /\  /\__ \ / / / /| | / /    _/_//_/       //
//     / __/   | |/ / /___/ /| |    / /___/ _, _/ / /___/ // / / ___ |/ /____/_//_/         //
//    /_/      |___/\____/_/ |_|____\____/_/ |_| /_//____//_/ /_/  |_/_____/_//_/           //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                           69                             //
//                                                         #@,  @@*                         //
//                                                       @&        ,@@.                     //
//                                                    %@.              (@@                  //
//                                                 .@@%                    &@#              //
//                                                @%@%                         @@*          //
//                                              *@ @%                             ,@@.      //
//                                             @& @&                                 %@     //
//                                           ,@  @%                                  @@     //
//                                          @@%.@&                                  @#@     //
//                                          @/   @,                                *@ @     //
//                                          %&    #@                               @. @     //
//                                          *@      @&                            &&  @     //
//                                           @        @,                          @   @     //
//                                           @*        *@@*                      @/   @     //
//                                           @%         /@  %@@.4169,/%@@@@@@@&#*@    @     //
//                                           /@          @&    @(                @    @     //
//                                            @           @, &@                  @    @     //
//                                            @.           @@.                   @    @     //
//                                            @%           @&                    @    @     //
//                                            (@          .@@                    @    @     //
//                                            .@          &@@*                   @   .@     //
//                                             @          @./@                   @   .@     //
//                                             @(        .@  @.                  @   .@     //
//                                             %@        &&  &&                  @   .@     //
//                                              @@       @,   @                  @   (@.    //
//                                               @&@,   .@    @(                 @  @@@     //
//                                                %@.@( %@    *@                 @(@ @/     //
//                                                 .@  @@,     @,               @@# .@      //
//                                                   @( #@     #@              @.@@ &&      //
//                                                    %@ (@     @            .@   @&@       //
//                                                     .@ (@    @%          *@     @.       //
//                                                       @#/@   .@         (@    @&         //
//                                                        %@/@   @*       %@   @@           //
//                                                          @*@  (@      @&  (@             //
//                                                           @&@  @     @% ,@.              //
//                                                            %@@ &&   @/ @(                //
//                                                             .@@.@  @,@&                  //
//                                                               @FVCK@                     //
//                                                                %@@@                      //
//                                                                 69                       //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";
import "./ERC721BurnRedeem.sol";

import "./Strings.sol";
import "./ERC165.sol";

/**
 * FVCK_CRYSTAL//
 */
contract FVCKCRYSTAL is AdminControl, ERC721BurnRedeem, ICreatorExtensionTokenURI {

    using Strings for uint256;

    bool private _active;
    uint256 private _activeTime;
    string private _tokenURIPrefix;

    event Unveil(uint256 collectibleId, address tokenAddress, uint256 tokenId);

    constructor(address creator) ERC721BurnRedeem(creator, 1, 4169) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, ERC721BurnRedeem, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId) || ERC721BurnRedeem.supportsInterface(interfaceId);
    }

    /**
     * @dev Is contract active
     */
    function active() external view returns(bool) {
        return _active;
    }

    /**
     * @dev Time to sale (in seconds)
     */
    function timeToSale() external view returns(uint256) {
        require(_active, "Inactive");
        if (block.timestamp >= (_activeTime + 3600)) return 0;
        return (_activeTime + 3600) - block.timestamp;
    }

    /**
     * @dev Pre-mine
     */
    function premine(uint256 amount) external adminRequired {
        require(!_active, "Already active");
        for (uint i = 0; i < amount; i++) {
            uint256 tokenId = super._mintRedemption(owner());
            emit Unveil(_mintNumbers[tokenId], _creator, tokenId);
        }
    }

    /**
     * @dev Activate the contract
     */
    function activate() external adminRequired {
        require(!_active, "Already active");
        _activeTime = block.timestamp;
        _active = true;
    }

    /**
     * @dev Withdraw funds
     */
    function withdraw(address payable recipient, uint256 amount) external adminRequired {
        recipient.transfer(amount);
    }

    /**
     *  @dev set the tokenURI prefix
     */
    function setTokenURIPrefix(string calldata prefix) external adminRequired {
        _tokenURIPrefix = prefix;
    }

    /**
     * @dev purchase a crystal
     */
    function purchase(uint256 amount) external payable nonReentrant {
        require(_active, "Inactive");
        require(block.timestamp >= _activeTime + 3600, "Purchasing not active");
        require(amount <= redemptionRemaining() && amount <= 5, "Too many requested");
        require(msg.value == amount*416900000000000000, "Invalid purchase amount sent");
        for (uint i = 0; i < amount; i++) {
            uint256 tokenId = super._mintRedemption(msg.sender);
            emit Unveil(_mintNumbers[tokenId], _creator, tokenId);
        }
    }

    /**
     * @dev See {IRedeemBase-redeemable}.
     */
    function redeemable(address contract_, uint256 tokenId) public view virtual override returns(bool) {
        require(_active, "Inactive");
        return super.redeemable(contract_, tokenId);
    }

    /**
     * @dev See {ERC721RedeemBase-_mintRedemption}
     */
    function _mintRedemption(address to) internal override returns(uint256) {
       // Burn redemptions will result in two crystals
       uint256 tokenId;
       tokenId = super._mintRedemption(to);
       emit Unveil(_mintNumbers[tokenId], _creator, tokenId);
       tokenId = super._mintRedemption(to);
       emit Unveil(_mintNumbers[tokenId], _creator, tokenId);
       return 0;
    }

    /**
     * @dev See {ICreatorExtensionTokenURI-tokenURI}.
     */
    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator && _mintNumbers[tokenId] != 0, "Invalid token");
        return string(abi.encodePacked(_tokenURIPrefix, _mintNumbers[tokenId].toString()));
    }
}
