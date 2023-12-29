/*
SPDX-License-Identifier: MIT
Treeangles by nix.eth                                                                                                                                                                         
                                                                                                   
                                                                                                   
 :+********=.                                                             *@%-                     
 -***%@@#**+.                                                             *@@-                     
     *@@:   +#+-*%: .=#%%#=.   :*%%#+:   +#%%%*-   *#+-*%%*:   .+#%#++#+. *@@-  .=#%%#=.  .+#%%#-  
     *@@:   *@@@#+.-%@+.:#@#. *@%:.=@@=  --:-*@@+  %@@#=+@@@: -%@%=-*@@#. *@@- :%@*.:*@%. %@@-:-.  
     *@@:   +@@=  .#@@@%%@@@-:@@@%%@@@# .*%@#%@@#  %@@.  *@@= *@@-  :%@#  *@@- +@@@%%@@@= =%@@%*:  
     *@@:   +@@-   *@@+...:. :@@%-...:. #@@: -@@*  %@@.  *@@= +@@*:.+@@#  *@@- =@@*:..::  ...-@@@  
     *@@:   +@@-    =#@@@@@+  :*%@@@@#. -%@@%#@@#  %@@.  *@@=  -#%@##%@#  *@@-  =#@@@@@* .%@%%@#=  
      ..     ..        ....      ....     ..   .    ..    ..   .:...+@@+   ..      ....    ....    
                                                               *@@@@@#=                            
                    ..............                                                                 
                  .+%@%%%@%%@@%%@%#-.                                                              
            .=+**#@@@@@@@@@@@@@@@@@@%#*+=:                                                         
         .-#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#+.                                                      
        +%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*:                                                    
      :*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%=                                                   
      .*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%-                                                   
      =%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*.                                                  
    -*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%=                                                 
   .*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%                                                 
   -#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                 
   =%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                 
   -#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                 
   =%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                 
   #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                 
   .*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%                                                 
    -*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*=                                                 
     :*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*-.                                                 
        :=%@@%%@@@@@@@@@@@@@@@@@@@@@@@@%%@@@+:.                                                    
          ... :#@%+=*%%*#@@@@%#%@#==#@%=....                                                       
               .:.   .. :%@@@+ ..    :.                                            =@#             
                        :%@@@+                                                                     
                        =@@@@#.                                          @@*#@@##  #@@ -@@* :@@=   
                        +@@@@%:                                          @@%  %@%  #@@  *@%.#@%    
                       .*@@@@@-                                          @@#  #@@  #@@    @@@      
                       :#@@@@@+.                                         @@#  #@@  #@@  *@%.#@%    
                       :%@@@@@*.                                         @@#  #@@  #@@ -@@* :@@=   

*/
pragma solidity 0.8.21;

import "./ERC721SeaDrop.sol";

import "./ERC721ContractMetadata.sol";

import "./StoryContract.sol";

import "./IStory.sol";

import "./IERC165.sol";

contract TreeanglesStorage{
    function tokenURI(uint256 tokenId) external view returns (string memory){}
    function getPiece(uint256 tokenId) external view returns (string memory, string memory){}
}

import "./Base64.sol";

/**
 * @title  Treeangles
 * @author nix.eth
 * @notice This is the non-fungible token contract for the fully onchain
 *         art collection Treeangles. The onchain storage is handled by the
 *         `TreeanglesStorage` contract.
 */
contract Treeangles is ERC721SeaDrop, StoryContract {
    TreeanglesStorage private _store;
    bool private _useStore = false;
    bool private _useContractOnchainMeta = false;
    string private _contractMetaProps;
    address private _storyCreator;
    address private _storyCreatorDelegate;

    constructor()
        ERC721SeaDrop('Treeangles', 'TREES', new address[](0))
        StoryContract(true)
    {
        _storyCreator = msg.sender;
    }

    /**
     * @notice Sets the location of the deployed onchain contract.
     */
    function setStorageAddress(address _t) external{
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();
        
        _store = TreeanglesStorage(_t);
        _useStore = true;
        if (totalSupply() != 0) {
            emit BatchMetadataUpdate(1, _nextTokenId() - 1);
        }
    }

    /**
     * @notice Disables directly serving onchain storage as the
     *         `tokenURI()` to fall back on standard ERC721 metadata.
     *         This is a fail-safe for unforeseen future changes.
     *         Even if this is used the art is permanently onchain,
     *         and can be retrieved with `onchainArt()` or from the
     *         storage contract.
     */
    function disableStorageAddress() external{
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();
        
        _useStore = false;
        if (totalSupply() != 0) {
            emit BatchMetadataUpdate(1, _nextTokenId() - 1);
        }
    }

    /**
     * @notice Disables directly serving onchain contract-level metadata
     *         as the `contractURI()` to fall back on standard URI metadata.
     *         This is a fail-safe for unforeseen future changes.
     */
    function disableContractOnchainMeta() external{
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();
        
        _useContractOnchainMeta = false;
        emit ContractURIUpdated(contractURI());
    }

    /**
     * @notice Sets the onchain contract-level metadata
     *         This is a JSON object without the open or close curls ({})
     */
    function setOnchainContractMetadata(string calldata _almostJson) external{
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();
        
        _contractMetaProps = _almostJson;
        _useContractOnchainMeta = true;
    }


    /**
     * @notice Emit an event notifying of contract-level metadata
     *         This couldn't be emitted on `setOnchainContractMetadata()`
     *         because building the onchain URI is too gas heavy. To use this
     *         first call `contractURI()` then pass the response as _uri
     */
    function emitContractMetadata(string calldata _uri)
        external
    {
        // Ensure the sender is only the owner or contract itself.
        _onlyOwnerOrSelf();

        // Emit an event with the update.
        emit ContractURIUpdated(_uri);
    }

    /**
     * @notice Retrieve the onchain SVG art for a given ID. This is a more
     *         friendly format than the standard encoded `tokenURI()` and
     *         designed to be future-proof, providing access to the art forever.
     */
    function onchainArt(uint256 tokenId) external view returns (string memory){
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        (, string memory svg) = _store.getPiece(tokenId);

        return svg;
    }

    /**
     * @notice Retrieve the onchain metadata for a given ID. This is a more
     *         friendly format than the standard encoded `tokenURI()`.
     *         Returns a 721 style JSON object (see `onchainArt()` for the image).
     */
    function onchainMetadata(uint256 tokenId) external view returns (string memory){
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        (string memory metadata, ) = _store.getPiece(tokenId);

        return metadata;
    }

    /**
     * @notice Retrieve the onchain contract-level SVG logo of the Treeangles
     *         collection. This is a more friendly format than the standard 
     *         encoded `contractURI()`.
     */
    function onchainCollectionImage() external view returns (string memory){
        (, string memory logo) = _store.getPiece(0);

        return logo;
    }

    /**
     * @notice Retrieve the onchain contract-level metadata for the Treeangles
     *         collection. This is a more friendly format than the standard encoded
     *         `contractURI()`. Returns a JSON object.
     */
    function onchainCollectionMetadata() external view returns (string memory){
        return string(abi.encodePacked(
            '{',
                _contractMetaProps,
            '"}'
        ));
    }

    /**
     * @dev Overrides the `tokenURI()` function from ERC721SeaDrop
     *      to return from onchain storage contract if enabled.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if(_useStore) {
            return _store.tokenURI(tokenId);
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Overrides the `contractURI()` function to return 
     *      from onchain contrat-level metadata.
     */
    function contractURI()
        public
        view
        override(ERC721ContractMetadata, ISeaDropTokenContractMetadata)
        returns (string memory)
    {
        if(!_useContractOnchainMeta || !_useStore) {
            return _contractURI;
        }

        (, string memory piece) = _store.getPiece(0);
        

        bytes memory metadata = abi.encodePacked(
            '{',
                _contractMetaProps,
                ',"image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(piece)),
            '"}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(metadata)
            )
        );
    }

    /**
     * @notice Returns whether the interface is supported.
     *
     * @param interfaceId The interface id to check against.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721SeaDrop, StoryContract)
        returns (bool)
    {
        return interfaceId == type(IStory).interfaceId || ERC721SeaDrop.supportsInterface(interfaceId);
    }

    /**
     * @notice Sets the creator of the contract for story inscription purposes
     *         This is kept separate from `owner` to allow for revoking
     *         ownership without revoking future creator story inscribing.
     */
    function setCreatorAddress(address _t) external{
        // Ensure only the current creator can set this
        if (msg.sender != _storyCreator) {
            revert NotTokenCreator();
        }
        
        _storyCreator = _t;
    }

    /**
     * @notice Sets the creator delegate of the contract for story inscriptions
     *         The purpose of the delegate is to allow automated story
     *         inscriptions on behalf of the creator.
     */
    function setCreatorDelegateAddress(address _t) external{
        // Ensure only the current creator can set this
        if (msg.sender != _storyCreator) {
            revert NotTokenCreator();
        }
        
        _storyCreatorDelegate = _t;
    }

    /**
     * @notice This allows the creator delegate to perform the same action
     *         as `addCreatorStory()` It preserves the true `creatorAddress`
     */
    function addCreatorStoryAsDelegate(uint256 tokenId, string calldata creatorName, string calldata story)
        public
        storyMustBeEnabled
    {
        if (!_tokenExists(tokenId)) revert TokenDoesNotExist();
        if (msg.sender != _storyCreatorDelegate) revert NotTokenCreator();

        emit CreatorStory(tokenId, _storyCreator, creatorName, story);
    }

    /**
     * @notice This allows the creator to add the same story to more than one token
     */
    function bulkAddCreatorStory(uint256[] calldata tokenIds, string calldata creatorName, string calldata story)
        external
    {
        for (uint i; i < tokenIds.length; i++) {
            StoryContract.addCreatorStory(tokenIds[i], creatorName, story);
        }
    }

    /**
     * @notice This allows the creator delegate to perform the same action
     *         as `bulkAddCreatorStory()` It preserves the true `creatorAddress`
     */
    function bulkAddCreatorStoryAsDelegate(uint256[] calldata tokenIds, string calldata creatorName, string calldata story)
        external
    {
        for (uint i; i < tokenIds.length; i++) {
            addCreatorStoryAsDelegate(tokenIds[i], creatorName, story);
        }
    }

    /// @inheritdoc StoryContract
    function _isStoryAdmin(address potentialAdmin) internal view override(StoryContract) returns (bool) {
        return potentialAdmin == owner();
    }

    /// @inheritdoc StoryContract
    function _tokenExists(uint256 tokenId) internal view override(StoryContract) returns (bool) {
        return _exists(tokenId);
    }

    /// @inheritdoc StoryContract
    function _isTokenOwner(address potentialOwner, uint256 tokenId)
        internal
        view
        override(StoryContract)
        returns (bool)
    {
        address tokenOwner = ownerOf(tokenId);
        return tokenOwner == potentialOwner;
    }

    /// @inheritdoc StoryContract
    function _isCreator(address potentialCreator, uint256 /* tokenId */ )
        internal
        view
        override(StoryContract)
        returns (bool)
    {
        return potentialCreator == _storyCreator;
    }
}