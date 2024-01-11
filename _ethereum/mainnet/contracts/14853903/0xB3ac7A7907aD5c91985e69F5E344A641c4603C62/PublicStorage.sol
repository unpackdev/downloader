//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPublicStorage.sol";
import "./IERC721.sol";
import "./Ownable.sol";

/// @title Contract PublicStorage for storage info number
contract PublicStorage is IPublicStorage, Ownable {
    /// @notice interface DTO (IERC721)
    IERC721 public dto;
    
    /// @notice by token consist of address in different chains
    mapping(uint256 => mapping(uint256 => string)) private addressChain;
    
    /// @notice by token consist of address in different social networks
    mapping(uint256 => mapping(uint256 => string)) private userNameSocial;

    /// @notice User Information by token ID 
    mapping(uint256 => UserInfo) private userInfo;
    
    /// @notice Enable BlockChain
    mapping(uint256 => string) private nameBlockchain;
    
    /// @notice Enable BlockChain
    mapping(uint256 => string) private nameSocial;

    /**
     * @notice Construct a new contract
     * @param addressDto address contract DTO 
     */ 
    constructor(address addressDto) {
        dto = IERC721(addressDto);
    }
    
    modifier ownerNft(uint256 tokenId) {
        require(msg.sender == dto.ownerOf(tokenId), "Error: you don`t owner");
        _;
    }

    modifier lengthArray(uint256[] memory idArray) {
        require(idArray.length < 5, "Error: big counter idBLockchain");

        _;
    }

    /** @notice get address in BlockChain by token ID
     *  @param number token ID (PrefixNumberId)
     *  @param idChain id enable Chain
     *  @return address in Chain
    */
    function getAddressChain(uint256 number, uint256 idChain)
        external
        view
        returns (string memory)
    {
        return addressChain[number][idChain];
    }

    /** @notice get username in Social Network by token ID
     *  @param number token ID (PrefixNumberId)
     *  @param idSocial id enable Social Network
     *  @return username in Social Network
    */
    function getUserNameSocial(uint256 number, uint256 idSocial)
        external
        view
        returns (string memory)
    {
        return userNameSocial[number][idSocial];
    }

    /** @notice get Avatar by token ID
     *  @param number token ID (PrefixNumberId)
     *  @return link of Avatar or empty
    */
    function getUserAvatar(uint256 number)
        external
        view
        returns (string memory)
    {
        return userInfo[number].urlAvatar;
    }

    /** @notice get UserPhone by token ID
     *  @param number token ID (PrefixNumberId)
     *  @return real number phone or empty
    */
    function getUserPhone(uint256 number)
        external
        view
        returns (string memory)
    {
        return userInfo[number].numberPhone;
    }

    /** @notice get enable BlockChain
     *  @param idBlockchain id Block Chain
     *  @return name BlockChain or empty
    */
    function getNameBlockchain(uint256 idBlockchain)
        external
        view
        returns (string memory)
    {
        return nameBlockchain[idBlockchain];
    }

    /** @notice get enable Social Network
     *  @param idSocial id Social Network
     *  @return name Social Network or empty
    */
    function getNameSocial(uint256 idSocial)
        external
        view
        returns (string memory)
    {
        return nameSocial[idSocial];
    }

    /** @notice add enable list name BlockChain by id BlockChain 
     *  @param idBlockchain id Block Chain
     *  @param nameBlockchain_ name BlockChain
    */
    function addBlockchainOwner(
        uint256[] memory idBlockchain,
        string[] memory nameBlockchain_
    ) external override onlyOwner {
        for (uint256 i = 0; i < idBlockchain.length; i++) {
            nameBlockchain[idBlockchain[i]] = nameBlockchain_[i];
        }
    }

    /** @notice add list user address Wallet in different by token ID
     *  @param number id Token number
     *  @param idBlockchain id Block Chain
     *  @param addressUser addresses user 
    */
    function addWallet(
        uint256 number,
        uint256[] memory idBlockchain,
        string[] memory addressUser
    ) external override ownerNft(number) lengthArray(idBlockchain) {
        for (uint256 i = 0; i < idBlockchain.length; i++) {
            require(
                bytes(nameBlockchain[idBlockchain[i]]).length > 0,
                "Error: invalide id Blockchain"
            );
            addressChain[number][idBlockchain[i]] = addressUser[i];
        }
    }

    /** @notice add Avatar by token ID
     *  @param number token ID (PrefixNumberId)
     *  @param urlImage link of Avatar
    */
    function addAvatar(uint256 number, string memory urlImage)
        external
        override
        ownerNft(number)
    {
        userInfo[number].urlAvatar = urlImage;
    }

    /** @notice add Avatar by token ID
     *  @param number token ID (PrefixNumberId)
     *  @param phoneNumber real user phone
    */
    function addNumberPhone(uint256 number, string memory phoneNumber)
        external
        override
        ownerNft(number)
    {
        userInfo[number].numberPhone = phoneNumber;
    }

    /** @notice add enable list name Social Network by id Social Network 
     *  @param idSocial id Social Network
     *  @param nameSocial_ name Social Network
    */
    function addSocialOwner(
        uint256[] memory idSocial,
        string[] memory nameSocial_
    ) external override onlyOwner {
        for (uint256 i = 0; i < idSocial.length; i++) {
            nameSocial[idSocial[i]] = nameSocial_[i];
        }
    }

    /** @notice add list user address Wallet in different by token ID
     *  @param number id Token number
     *  @param idSocial id Social Network
     *  @param userName username of Social Network
    */
    function addSocial(
        uint256 number,
        uint256[] memory idSocial,
        string[] memory userName
    ) external override ownerNft(number) lengthArray(idSocial) {
        for (uint256 i = 0; i < idSocial.length; i++) {
            require(
                bytes(nameSocial[idSocial[i]]).length > 0,
                "Error: invalide id Social"
            );
            userNameSocial[number][idSocial[i]] = userName[i];
        }
    }
}
