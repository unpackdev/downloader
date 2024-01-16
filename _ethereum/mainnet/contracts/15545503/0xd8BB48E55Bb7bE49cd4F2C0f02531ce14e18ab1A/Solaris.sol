/**
 *



                                               ...
                                            :*#%@%#
                                          :%@@@@@@@@.
                                        -#@@@@@@@@@@=
        .=#######*=.           .:*#######**@@@@@@@@@* .                      :-*+-.           .=#########*:.        .#@*         .=#######*-.
      .#@@@@@@@@@@@@#-        +%@@@@@@@@@@@@#:+@@@@@#.@                     +@@@@@@:         .@@@@@@@@@@@@@@*       *@@@-      :#@@@@@@@@@@@@*.
      @@@@@@@@@@@@@@@@.      =@@@@@@@@@@@@@@@# *@@@@*.@:                    @@@@@@@+         :@@@@@@@@@@@@@@@#      *@@@-     .@@@@@@@@@@@@@@@#
     *@@@@@@@@@@@@@@@@#      @@@@@@@@@@@@@@@@@:.@@@@==@:                   :@@@@@@@@         :@@@@@@@@@@@@@@@@=     *@@@-     *@@@@@@@@@@@@@@@@=
     #@@@%.       %@@@@     =@@@@++@@+   -@@@@=.@@@@=%@:                   #@@@+@@@@.        :@@@@       .%@@@@     *@@@-     @@@@=        #@@@@
    .%@@@-         @@@@:    %@@@%+@%:     *@@@+.@@@@:@@:                   %@@@-*@@@#        :@@@@        .@@@@     *@@@-     @@@@          @@@@
    .@@@@:         %@@@:    %@@@@@@       *@@@*+@@@%=@@:                  :@@@%..@@@%        :@@@@         @@@@     *@@@-     @@@@          @@@@
    .@@@@:         %@@@:    %@@@@%.       *@@@*@@@@:#@@:                  =@@@# .%@@@-       :@@@@         @@@@     *@@@-     @@@@          @@@@
    .@@@@:         #@@@.    %@@@@         *@@@%@@@#.@@@:                  @@@@=  *@@@=       :@@@@         @@@@     *@@@-     @@@@          @@@%
    .@@@@:         :==-     %@@@=         *@@@@@@@-#@@@:                 :@@@@   =@@@%       :@@@@         @@@@     *@@@-     @@@@          .--
    .%@@@-                  %@@@*         *@@@@@@% @@@@:                 #@@@*    @@@@.      :@@@@         @@@@     *@@@-     @@@@.
     #@@@#========:        .%@@@*         *@@@@@@. @@@@:                .%@@@-    #@@@#      :@@@@        .@@@@     *@@@-     @@@@#========.
     +@@@@@@@@@@@@@@-      #%@@@*         *@@@@@=  @@@@:                :@@@%.    .@@@@      :@@@@       .%@@@@     *@@@-     +@@@@@@@@@@@@@@.
      *@@@@@@@@@@@@@@#    ##%@@@*         *@@@@%   @@@@:                +@@@#     .%@@@-     :@@@@ -@@@@@@@@@@=     *@@@-     .#@@@@@@@@@@@@@@+
       :@@@@@@@@@@@@@@*  =@#%@@@+         *@@@@    @@@@:                @@@@=      *@@@=     :@@@@ =@@@@@@@@@#      *@@@-       =@@@@@@@@@@@@@@:
         .-------=#@@@@  %@-%@@@=        .%@@@-    @@@@:               .@@@@  -==. +@@@%     :@@@@ -@@@@@@@@+       *@@@-         .-------=@@@@%
                   @@@@.#@@ %@@@=        #@@@*     @@@@:               #@@@% =@@@#  @@@@     :@@@@     :@@@@:       *@@@-                  :@@@@
                   %@@@=@@: %@@@=       *@@@* -    @@@@:               %@@@: #@@@@. %@@@*    :@@@@      +@@@%       *@@@-                   @@@@
     *@@#          %@@@#@%  %@@@=      *@@@% #+    @@@@:              -@@@@: #@@@@. .@@@@    :@@@@       @@@@+      *@@@-     *@@=          @@@@
    .%@@@:         %@@@@@*  %@@@=    .#@@@# +@+    @@@@:              =@@@#  =@@@#  .@@@@-   :@@@@       -@@@%.     *@@@-     @@@@          @@@@
    .@@@@:         %@@@@@+  %@@@=    @@@@% =@@+    @@@@:              @@@@+   :@*    *@@@=   :@@@@        %@@@=     *@@@-     @@@@          @@@@
    .%@@@:         %@@@@@+  %@@@+  -%@@@# =@@@+    @@@@:             .@@@@           =@@@%   :@@@@        -@@@@:    *@@@-     @@@@          @@@@
    .%@@@-         @@@@@@+  #@@@% #@@@@#  *@@@+    @@@@:             #@@@%            @@@@   :@@@@         *@@@#    *@@@-     @@@@.        .@@@@
     #@@@#--------*@@@@@@#  :@@@@@@@@@* -=@@@@-    @@@@=-----------  %@@@-            %@@@*  :@@@@         :@@@@:   *@@@-     @@@@*--------@@@@%
     +@@@@@@@@@@@@@@@@@@@@%+-@@@@@@@@- %@@@@@@.    @@@@@@@@@@@@@@@@%-@@@@:            :@@@@  :@@@@          #@@@@   *@@@-     +@@@@@@@@@@@@@@@@:
      *@@@@@@@@@@@@@@@@@@@@@@@@@@@@%:.%@@@@@@=     %@@@@@@@@@@@@@@@@-@@@#             .@@@@: :@@@%           @@@@   *@@@-     .#@@@@@@@@@@@@@@+
       :@@@@@@@@@@@@:+@@@@@@@@@@@@= =@@@@@@#.      :@@@@@@@@@@@@@@@@:@@@=              *@@@   @@@+           -@@+   *@@@-       =@@@@@@@@@@@%:
         .:-------.  -@@@@@@@@@@#:  -----:          .-------------:   +=                +-     =:             =-     =*=          :--------.
                      *@@@@@@@*.
                       =###*+.






*/

// Supported by Blockstars
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./ERC2981.sol";
import "./ERC721Burnable.sol";
import "./AccessControl.sol";

contract Solaris is ERC721, ERC2981, AccessControl, ERC721Burnable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    // Estimated cost per minting by public user
    uint256 public cost = 0.0114 ether;
    // Maximum amount of tokens supply
    uint256 public maxSupply = 3650;
    // Maximum number of tokens to be minted per transaction
    uint256 public maxMintAmountPerTx = 5;
    // Maximum number of tokens to be minted by a Wallet address
    uint256 public maxMintAmountPerWt = 10;
    // Maximum number of tokens to be minted by a minter/admin
    uint256 public maxNFTMintedByMinter = 10;
    // Switch to pause the minting process by public user
    bool public pausedPublic = true;
    // Switch to reveal the tokenURI
    bool public revealed = false;
    // Switch to enable or disable whitelist the users' addresses
    bool public whitelistEnabled = false;
    // Mapping of white list addresses
    mapping(address => bool) public whitelist;

    /// @dev event when external user mints the token(s)
    /// @param _mintAmount number of tokens minted
    /// @param _mintUserAddress a the address of minted user
    event MintedByUser(address indexed _mintUserAddress, uint256 _mintAmount);

    constructor(address royaltyAddress, uint96 feeNumerator)
        ERC721("SOLARIS", "SOLARIS")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, ADMIN);
        _grantRole(ADMIN, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _setDefaultRoyalty(royaltyAddress, feeNumerator);
        setHiddenMetadataUri(
            "https://solaris-production.sgp1.digitaloceanspaces.com/solaris-token/public/hidden/hidden.json"
        );
    }

    /**
     * @dev Modifier that checks the maximum supply is not exceeded to mint the _mintAmount
     * @param _mintAmount Number of tokens to be minted.
     */
    modifier mintCompliance(uint256 _mintAmount) {
        require(
            supply.current() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    /**
     * @dev Modifier that checks the size of the whitelist array is not exceeded than 1000
     * @param _whiteListSize The size of the whitelist addresses array
     */
    modifier whilteListCompliance(uint256 _whiteListSize) {
        require(
            _whiteListSize <= 1000,
            "The size of the whitelist array is exceeded"
        );
        _;
    }

    /**
     * @dev Returns the current amount of tokens supply
     */
    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    /**
     * @dev Allow public user to mint NFT
     * @param _mintAmount The number of tokens to be minted
     */
    function publicMint(uint256 _mintAmount)
        external
        payable
        mintCompliance(_mintAmount)
    {
        // Contract must have enabled for public minting
        require(!pausedPublic, "The contract is paused for public minting!");
        // At least one NFT should be minted at a time
        require(_mintAmount > 0, "Need to mint at least 1 NFT");
        // Number of tokens to be minted should not be exceeded the maxMintAmountPerTx value
        require(
            _mintAmount <= maxMintAmountPerTx,
            "Max mint amount per transaction exceeded!"
        );
        // Number of tokens to be minted should not be exceeded the maxMintAmountPerWt value
        require(
            (balanceOf(_msgSender()) + _mintAmount) <= maxMintAmountPerWt,
            "Max mint amount per wallet exceeded!"
        );
        // Sender must have sufficient fund to mint the number of tokens
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");

        _mintLoop(_msgSender(), _mintAmount);

        emit MintedByUser(_msgSender(), _mintAmount);
    }

    /**
     * @dev Allow whiteListed user to mint NFT
     * @param _mintAmount The number of tokens to be minted
     */
    function whiteListMint(uint256 _mintAmount)
        external
        payable
        mintCompliance(_mintAmount)
    {
        // Contract must have enabled for whiteList minting
        require(
            whitelistEnabled,
            "The contract is paused for whiteList minting!"
        );
        // The sender's address should be whitelisted
        require(whitelist[_msgSender()], "Address not whitelisted");
        // At least one NFT should be minted at a time
        require(_mintAmount > 0, "Need to mint at least 1 NFT");
        // Number of tokens to be minted should not be exceeded the maxMintAmountPerTx value
        require(
            _mintAmount <= maxMintAmountPerTx,
            "Max mint amount per transaction exceeded!"
        );
        // Number of tokens to be minted should not be exceeded the maxMintAmountPerWt value
        require(
            (balanceOf(_msgSender()) + _mintAmount) <= maxMintAmountPerWt,
            "Max mint amount per wallet exceeded!"
        );
        // Sender must have sufficient fund to mint the number of tokens
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");

        _mintLoop(_msgSender(), _mintAmount);

        emit MintedByUser(_msgSender(), _mintAmount);
    }

    /**
     * @dev Allow to mint more than one tokens for a receiver address by minter
     * @param _mintAmount The number of tokens to be minted
     * @param _receiver The receiver's address
     */
    function mintManyForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyRole(MINTER_ROLE)
    {
        require(
            _mintAmount <= maxNFTMintedByMinter,
            "The maximum number of NFTs to be minted exceeds the limit"
        );

        _mintLoop(_receiver, _mintAmount);
    }

    /**
     * @dev Allow to mint only one token for a receiver address by minter
     * @param _receiver The receiver's address
     */
    function mintOneForAddress(address _receiver)
        public
        mintCompliance(1)
        onlyRole(MINTER_ROLE)
    {
        _mintOne(_receiver);
    }

    /**
     * @dev Returns an array of token IDs for an owner's address
     * @param _owner The owner's address
     */
    function tokenIdsOfWallet(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    /**
     * @dev Returns tokenURI for a _tokenId
     * @param _tokenId The token Id of the token
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // Token id should be valid
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        // if revealed is not enabled, it should returns the hiddenMetadataUri
        if (revealed == false) {
            return hiddenMetadataUri;
        }

        // if revealed is enabled, it returns the tokenURI
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    /**
     * @dev Allow admin to set revealed tokenURI
     * @param _state True or false to set revealed value
     */
    function setRevealed(bool _state) public onlyRole(ADMIN) {
        revealed = _state;
    }

    /**
     * @dev Allow admin to set cost per mint
     * @param _cost The cost for minting an NFT
     */
    function setCost(uint256 _cost) public onlyRole(ADMIN) {
        cost = _cost;
    }

    /**
     * @dev Allow admin to set maximum number of tokens to be minted per transaction
     * @param _maxMintAmountPerTx The maximum number of tokens
     */
    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyRole(ADMIN)
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    /**
     * @dev Allow admin to set maximum number of tokens to be minted by a wallet address
     * @param _maxMintAmountPerWt The maximum number of tokens
     */
    function setMaxMintAmountPerWt(uint256 _maxMintAmountPerWt)
        public
        onlyRole(ADMIN)
    {
        maxMintAmountPerWt = _maxMintAmountPerWt;
    }

    /**
     * @dev Allow admin to set maximum number of tokens to be minted by admin role
     * @param _maxNFTMintedByMinter The maximum number of tokens
     */
    function setMaxNFTMintedByMinter(uint256 _maxNFTMintedByMinter)
        public
        onlyRole(ADMIN)
    {
        maxNFTMintedByMinter = _maxNFTMintedByMinter;
    }

    /**
     * @dev Allow admin to set hidden metadata URI
     * @param _hiddenMetadataUri Hidden meta data URI
     */
    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyRole(ADMIN)
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    /**
     * @dev Allow admin to set uri prefix value
     * @param _uriPrefix tokenURI prefix value
     */
    function setUriPrefix(string memory _uriPrefix) public onlyRole(ADMIN) {
        uriPrefix = _uriPrefix;
    }

    /**
     * @dev Allow admin to set uri suffix value
     * @param _uriSuffix tokenURI suffix value
     */
    function setUriSuffix(string memory _uriSuffix) public onlyRole(ADMIN) {
        uriSuffix = _uriSuffix;
    }

    /**
     * @dev Allow admin to enable or disable public minting
     * @param _state True or False value to enable or disable public minting
     */
    function setPausedPublic(bool _state) public onlyRole(ADMIN) {
        pausedPublic = _state;
    }

    /**
     * @dev Allow admin to enable or disable whitelist the addresses for minting
     * @param _state True or False value to enable or disable whitelist the addresses
     */
    function setWhitelistEnabled(bool _state) public onlyRole(ADMIN) {
        whitelistEnabled = _state;
    }

    /**
     * @dev Allow admin to whitelist the addresses. The size of the whitelist addresses array should not be exceeded the max value
     * @param newAddresses The array of addresses to be whitelisted
     */
    function setWhitelist(address[] calldata newAddresses)
        external
        whilteListCompliance(newAddresses.length)
        onlyRole(ADMIN)
    {
        for (uint256 i = 0; i < newAddresses.length; i++)
            whitelist[newAddresses[i]] = true;
    }

    /**
     * @dev Allow admin to remove the addresses from whitelist mapping. The size of the removal addresses array should not be exceeded the max value
     * @param currentAddresses The array of addresses to be whitelisted
     */
    function removeWhitelist(address[] calldata currentAddresses)
        external
        whilteListCompliance(currentAddresses.length)
        onlyRole(ADMIN)
    {
        for (uint256 i = 0; i < currentAddresses.length; i++)
            delete whitelist[currentAddresses[i]];
    }

    /**
     * @dev Allow admin to withdraw all the balance of tokens from the contract
     */
    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            address(this).balance > 0,
            "There is no balance in this contract"
        );
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(os);
    }

    /**
     * @dev Mint more than one number of tokens for a receiver address
     * @param _receiver The receiver's address
     * @param _mintAmount The number of tokens to be minted
     */
    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            _mintOne(_receiver);
        }
    }

    /**
     * @dev Mint one token for a receiver address
     * @param _receiver The receiver's address
     */
    function _mintOne(address _receiver) internal {
        supply.increment();
        _safeMint(_receiver, supply.current());
    }

    /**
     * @dev Returns baseURI that is uriPrefix value
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    /**
     * @dev Allow admin or minter to mint one token for many receivers' addresses
     * @param receiverAddresses The array of receivers' addresses
     */
    function bulkMintOneByOne(address[] calldata receiverAddresses)
        external
        mintCompliance(receiverAddresses.length)
        onlyRole(MINTER_ROLE)
    {
        require(
            receiverAddresses.length >= 0,
            "Address array should not be empty"
        );
        // The size of receivers' addresses array should not be exceeded to 100
        require(
            receiverAddresses.length <= 100,
            "The size of Receiver addresses array is exceeded"
        );

        for (uint256 i = 0; i < receiverAddresses.length; i++) {
            _mintOne(receiverAddresses[i]);
        }
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
