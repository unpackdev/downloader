// SPDX-License-Identifier: MIT
// Galaxy Heroes NFT game )
pragma solidity ^0.8.6;

import "Ownable.sol";
import "Strings.sol";
import "ERC1155Receiver.sol";
import "IERC1155.sol";
import "IHero.sol";
import "IRandom.sol";
import "IRarity.sol";


contract HeroesUpgraderV2  is ERC1155Receiver, Ownable {

    // F1, F2, F3 rarity types reserved for future game play
    enum Rarity {Simple, SimpleUpgraded, Rare, Legendary, F1, F2, F3}
    struct Modification {
        address sourceContract;
        Rarity  sourceRarity;
        address destinitionContract;
        Rarity  destinitionRarity;
        uint256 balanceForUpgrade;
        bool enabled;
    }

    bool internal chainLink;
    address public chainLinkAdapter;
    address internal whiteListBalancer = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public externalStorage;

    // Mapping of enabled modifications
    // From modifier contract address and tokenId to Modification
    mapping(address => mapping(uint256 => Modification)) public enabledModifications;

    // Mapping of enabled source conatracts
    mapping(address => bool) public sourceContracts;
    
    //Mapping from upgradING contract address and tokenId to token 
    //rarity. By default (token was not upgrade) any token has Simple rarity
    mapping(address => mapping(uint256 => Rarity)) public rarity;
    
    event Upgraded(address destinitionContract, uint256 oldHero, uint256 newHero, Rarity newRarity);
    event ModificationChange(address modifierContract, uint256 modifierId);
    

    
    function upgrade(uint256 oldHero, address modifierContract, uint256 modifierId) public virtual{
        //1.0 Check that modification is registered
        require(
            enabledModifications[modifierContract][modifierId].enabled
            , "Unknown modificator"
        );
        // 1.1. Check that this hero is not rare o legendary
        // In more common sence that modification from current oldHero rariry is enabled
        require(
            rarity[
              enabledModifications[modifierContract][modifierId].sourceContract
            ][oldHero] == enabledModifications[modifierContract][modifierId].sourceRarity,
            "Cant modify twice or from your rarity"
        );

        require(
            IHero(
               enabledModifications[modifierContract][modifierId].sourceContract
            ).ownerOf(oldHero) == msg.sender,
            "You need own hero for upgrade"
        );
        //2.Charge modificator from user
        IERC1155(modifierContract).safeTransferFrom(
            msg.sender,
            address(this),
            modifierId,
            enabledModifications[modifierContract][modifierId].balanceForUpgrade,
            '0'
        );

        //3.Mint new hero  and save rarity
        // get existing mint limit for this conatrct
        (uint256 limit, uint256 minted) =
            IHero(
               enabledModifications[modifierContract][modifierId].destinitionContract
            ).partnersLimit(address(this));
        
        // increase and set new free limit mint for this contract
        IHero(
            enabledModifications[modifierContract][modifierId].destinitionContract
        ).setPartner(address(this), limit + 1);
        
        
         
        //get tokenId of token thet will mint
        uint256 newToken = IHero(
            enabledModifications[modifierContract][modifierId].destinitionContract
        ).totalSupply();
        
        // mint with white list
        IHero(
            enabledModifications[modifierContract][modifierId].destinitionContract
        ).multiMint();
        
        // transfer new token to sender
        IHero(
            enabledModifications[modifierContract][modifierId].destinitionContract
        ).transferFrom(address(this), msg.sender, newToken);

        
        /////////////////////////////////////////////////////////////////////
        // correct whitelist balance
        // For use  this functionalite Heroes Owner must manualy set limit
        // for whiteListBalancer (two tx with same limit)
        // (uint256 wl_limit, uint256 wl_minted) = IHero(
        //        enabledModifications[modifierContract][modifierId].destinitionContract
        //    ).partnersLimit(whiteListBalancer); 

        //if (limit != 0) {
        IHero(
            enabledModifications[modifierContract][modifierId].destinitionContract
        ).setPartner(whiteListBalancer, limit);
        IHero(
            enabledModifications[modifierContract][modifierId].destinitionContract
        ).setPartner(whiteListBalancer, limit);
        IHero(
            enabledModifications[modifierContract][modifierId].destinitionContract
        ).setPartner(whiteListBalancer, limit);
        IHero(
            enabledModifications[modifierContract][modifierId].destinitionContract
        ).setPartner(whiteListBalancer, 0);
        //}
        /////////////////////////////////////////////////////////////////////

        
        //safe rarity of upgradING token
        rarity[
            enabledModifications[modifierContract][modifierId].sourceContract
        ][oldHero] = Rarity.SimpleUpgraded;

        //safe rarity of new minted token
        rarity[
            enabledModifications[modifierContract][modifierId].sourceContract
        ][newToken] = enabledModifications[modifierContract][modifierId].destinitionRarity;
        //4.transfer new hero to msg.sender
        emit Upgraded(
            enabledModifications[modifierContract][modifierId].destinitionContract, 
            oldHero,
            newToken, 
            enabledModifications[modifierContract][modifierId].destinitionRarity
        );
        
        if (chainLink) {
            IRandom(chainLinkAdapter).requestChainLinkEntropy();    
        }
        

    }

    function upgradeBatch(uint256[] memory oldHeroes, address modifierContract, uint256 modifierId) public virtual {
        require(oldHeroes.length <= 10, "Not more then 10");
        for (uint256 i; i < oldHeroes.length; i ++) {
            upgrade(oldHeroes[i], modifierContract, modifierId);
        }
    }


    /// Return rarity of given  token
    function getRarity(address _contract, uint256 _tokenId) public view returns(Rarity r) {
        r = rarity[_contract][_tokenId];
        if (externalStorage != address(0)) {
            uint8 extRar = IRarity(externalStorage).getRarity(_contract, _tokenId);
            if (Rarity(extRar) > r) {
                r = Rarity(extRar);
            }
        }
        return r;
    }


    /// Return rarity of given  token
    function getRarity2(address _contract, uint256 _tokenId) public view returns(Rarity r) {
        require(sourceContracts[_contract], "Unknown source contract");
        require(
            IHero(_contract).ownerOf(_tokenId) != address(0),
            "Seems like token not exist"
        );
        return getRarity(_contract, _tokenId);
        // r = rarity[_contract][_tokenId];
        //         if (externalStorage != address(0)) {
        //     Rarity extRar = IRarity(externalStorage).getRarity(_contract, _tokenId);
        //     if (extRar > r) {
        //         r = extRar;
        //     }
        // }
        // return r;
    }


    
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        override
        returns(bytes4)
    {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));  
    }    

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        override
        returns(bytes4)
    {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256,uint256,bytes)"));  
    }
    
    //////////////////////////////////////////////////////
    ///   Admin Functions                             ////
    //////////////////////////////////////////////////////
    function setModification(
        address _modifierContract,
        uint256 _modifierId,
        address _sourceContract,
        Rarity  _sourceRarity,
        address _destinitionContract,
        Rarity  _destinitionRarity,
        uint256 _balanceForUpgrade,
        bool    _isEnabled
    ) external onlyOwner {
        require(_modifierContract != address(0), "No zero");
        enabledModifications[_modifierContract][_modifierId].sourceContract = _sourceContract;
        enabledModifications[_modifierContract][_modifierId].sourceRarity = _sourceRarity;
        enabledModifications[_modifierContract][_modifierId].destinitionContract = _destinitionContract;
        enabledModifications[_modifierContract][_modifierId].destinitionRarity = _destinitionRarity;
        enabledModifications[_modifierContract][_modifierId].balanceForUpgrade = _balanceForUpgrade;
        enabledModifications[_modifierContract][_modifierId].enabled = _isEnabled;
        sourceContracts[_sourceContract] = _isEnabled;
        emit ModificationChange(_modifierContract, _modifierId);
    }

    function setModificationState(
        address _modifierContract,
        uint256 _modifierId,
        bool    _isEnabled
    ) external onlyOwner {
        require(_modifierContract != address(0), "No zero");
        enabledModifications[_modifierContract][_modifierId].enabled = _isEnabled;
        sourceContracts[
            enabledModifications[_modifierContract][_modifierId].sourceContract
        ] = _isEnabled;
        emit ModificationChange(_modifierContract, _modifierId);
    }

    function revokeOwnership(address _contract) external onlyOwner {
        IHero(_contract).transferOwnership(owner());
    }

    function setChainLink(bool _isOn) external onlyOwner {
        require(chainLinkAdapter != address(0), "Set adapter address first");
        chainLink = _isOn;
    }

    function setChainLinkAdapter(address _adapter) external onlyOwner {
        chainLinkAdapter = _adapter;
    } 

    function setPartnerProxy(
        address _contract, 
        address _partner, 
        uint256 _newLimit
    ) 
        external 
        onlyOwner 
    {
        IHero(_contract).setPartner(_partner, _newLimit);
    } 

    function setWLBalancer(address _balancer) external onlyOwner {
        require(_balancer != address(0));
        whiteListBalancer = _balancer;
    }

    function loadRaritiesBatch(address _contract, uint256[] memory _tokens, Rarity[] memory _rarities) external onlyOwner {
        require(_contract != address(0), "No Zero Address");
        require(_tokens.length == _rarities.length);
         for (uint256 i; i < _tokens.length; i ++) {
            rarity[_contract][_tokens[i]] = _rarities[i];
        }
    }

    function setExternalStorage(address _storage) external onlyOwner {
        externalStorage = _storage;
    }
}
