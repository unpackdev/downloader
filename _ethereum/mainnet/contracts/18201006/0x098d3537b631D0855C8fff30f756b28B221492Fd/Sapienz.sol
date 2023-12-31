// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC1155Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./BitMapsUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./ERC721AUpgradeable.sol";

import "./OperatorFilterer.sol";

import "./IERC6551Registry.sol";

import "./SapienzStorageV1.sol";
import "./SapienzStorageV2.sol";

/*

      .7PG55PPG##P7:                                                                                                              
     ?#@B^     :7P&@G?:                                                                                                           
    7@@@^         .?#@&?                                                                                                          
    Y@@@:            Y@@P.                                                                                                        
    ~@@@?             J@@B.                                                                                                       
     Y@@@!             J@@G                                                                                                       
      Y@@&!             G@@5                                                               Y#B^                                   
       7&@@J.           ~@@@!                                                              ^@@B                                   
        ^G@@B~           G@@G                                                               Y@@?                                  
          7#@@5:         !PP7    ~!7^                                                       .#@&:          .:~7JYYYY7             
           .J&@&J.              :&@@@~       :~~:                ..                          Y@@5     :~?5GBBGYJ@@@@?             
             :J&@&J.            ~@@@@#.     ~@@@&GGGGPY?!^.    .G&&5          .:^!?JJ?^.::   :&@@~   7BBGY7^.  Y@@#!      .:^!!!!^
               :Y&@&J.          ^@@@@@J   ^P#&@@@5~!!7YG#@&PJ^  Y@@@7 .?YYYY5PP5Y?~~~!G&@&5   J@@G           ~B@&Y. .^!J5GBBBBBGY!
 !P!             :Y&@&J:        ~@@@@@@~   ::^#@@B      .^P@@@~  B@@&PB@@@@Y^.  .~YB&GP@@@@B7  #@@7        ~P@@B??5GBBG5?!^.      
5@#                .J&@&J:      !@@@@@@#:     !@@@Y      .G@@J   ^&@@B.Y@@@J:75GBBY!. .#@@@@@B!J@@&:     !G@@@@&BPJ!:.            
J&@J                 .J&@&J.    !@@@@@@@B.   .:G@@@?   .7&@P^     ?@@@!7@@@@#GY!. 7P5. 5@@@PG@@&@@@5  ^J#@@&GJ~:                  
 :5@#!                 .?&@#7   !@@@@5B@@B?J5P5?5@@@?~YBG?:        5@@@P&@@&~  .7B@&?  !@@@J ~P@@@@@~.5G5?~.                      
   ^P@G~                 :5@@G^ !@@@@BB&@@@G:   ?@@@@&7:            G@@G!B@@&PGGGJ~.   .&@@5   ^JGG5!                             
     ~G@B?:                ~#@@?!@@@&7^.~G@@B7. :~Y@@@?             :#@@P.:~!~:.        ?Y7:                                      
       :Y&@G7:              .G@@#@@@G     ^Y#@&GJ~:7&@@P.            ^#@&~                                                        
         .7P&@BY~.           ^@@@5!~:        ^7Y5J! ^B@@5             .:.                                                         
            .!YG##B5?!^:.  ..!@@5                    .~:.                                                                         
                .~?5G####BBGP5?^                                                                                                  

Staple Pigeon started in 1997. It shook the entire streetwear industry and brought sneaker collabs
to the mainstream. STAPLEVERSE started in 2022 and it will show the world the power of co-creation.

Building the foundation that will inspire the next generation of creatives.

*/

contract Sapienz is
    ERC721AUpgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721HolderUpgradeable,
    ERC1155HolderUpgradeable,
    SapienzStorageV1,
    SapienzStorageV2,
    OperatorFilterer
{
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    error InvalidInputs();
    error AlreadyClaimed();
    error InvalidToken();
    error TokenNotFound();
    error NotClaimant();
    error ClaimDisabled();
    error MintDisabled();
    error MaxSupplyMinted();

    bytes4 private constant _INTERFACE_ID_ERC4906 = 0x49064906;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint256 constant MAX_SUPPLY = 15000;

    address royaltyReceiver;
    uint256 royaltyPercentage;

    // END V3 STORAGE

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    /// @dev Initializes the contract, setting the default merkle root and granting admin permissions to the caller
    function initialize(bytes32 _merkleRoot) public initializer {
        merkleRoot = _merkleRoot;

        __ERC721A_init("Sapienz", "SAPIENZ");

        __Ownable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Marks an ERC721/ERC1155 contract as eligible or ineligible to claim Sapienz
    function setAllowedContract(address tokenContract, bool allowed) external onlyRole(DEFAULT_ADMIN_ROLE) {
        allowedContracts[tokenContract] = allowed;
    }

    /// @dev Marks an ERC721/ERC1155 contract as controlled or uncontrolled
    function setControlledContract(address tokenContract, bool controlled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        controlledContracts[tokenContract] = controlled;
    }

    /// @dev Sets the merkle root for the tree of eligible ERC721/ERC1155 tokens
    function setMerkleRoot(bytes32 newMerkleRoot) public onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRoot = newMerkleRoot;
    }

    /// @dev Sets base URI for all token URIs
    function setBaseUri(string calldata baseUri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        BASE_URI = baseUri;
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    /// @dev Sets the address of the ERC6551 registry
    function setERC6551Registry(address registry) public onlyRole(DEFAULT_ADMIN_ROLE) {
        erc6551Registry = IERC6551Registry(registry);
    }

    /// @dev Sets the address of the ERC6551 account implementation
    function setERC6551Implementation(address implementation) public onlyRole(DEFAULT_ADMIN_ROLE) {
        erc6551AccountImplementation = implementation;
    }

    /// @dev Sets claim enabled status
    function setClaimEnabled(bool enabled) public onlyRole(DEFAULT_ADMIN_ROLE) {
        claimEnabled = enabled;
    }

    /// @dev Sets mint enabled status
    function setMintEnabled(bool enabled) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintEnabled = enabled;
    }

    function setRoyaltyReceiver(address newReceiver) public onlyRole(DEFAULT_ADMIN_ROLE) {
        royaltyReceiver = newReceiver;
    }

    function setRoyaltyPercentage(uint256 newRoyaltyPercentage) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newRoyaltyPercentage <= 100, "Royalty percentage cannot be greater than 100");
        royaltyPercentage = newRoyaltyPercentage;
    }

    function registerOperatorFilter() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _registerForOperatorFiltering();
    }

    function adminMintWithoutTokens(address[] calldata recipients, uint256[] calldata quantities)
        external
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 length = recipients.length;
        if (length != quantities.length) revert InvalidInputs();

        for (uint256 i = 0; i < length; i++) {
            uint256 quantity = quantities[i];
            if (_totalMinted() + quantity > MAX_SUPPLY) revert MaxSupplyMinted();
            _safeMint(recipients[i], quantity);
        }
    }

    function airdrop1155Batch(
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata balances,
        address[] calldata minters
    ) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        _airdropERC1155(tokenAddress, tokenIds, balances, minters);
    }

    /// @dev Allows admin to mint one Sapienz for each eligible controlled token on a user's behalf,
    ///      transferring the token to the Sapienz' ERC6551 account
    function airdropBatch(address[] calldata tokenAddresses, uint256[][] calldata tokenIds, address[] calldata minters)
        external
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 len = tokenAddresses.length;

        for (uint256 i = 0; i < len; i++) {
            _airdropERC721(tokenAddresses[i], tokenIds[i], minters[i]);
        }
    }

    /// @dev Allows admin to mint one Sapienz for each controlled token in a single collection on a
    ///      user's behalf, transferring the token to the Sapienz' ERC6551 account
    function airdrop(address tokenAddress, uint256[] memory tokenIds, address minter)
        external
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _airdropERC721(tokenAddress, tokenIds, minter);
    }

    /// @dev Mints one Sapienz for each eligible token across multiple collections, transferring
    ///      the token to the Sapienz' ERC6551 account
    function adminMintBatch(
        address[] calldata tokenAddresses,
        uint256[][] calldata tokenIds,
        address[] calldata recipients
    ) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 len = tokenAddresses.length;
        if (tokenIds.length != len) {
            revert InvalidInputs();
        }

        for (uint256 i = 0; i < len; i++) {
            _adminMintWithTokens(tokenAddresses[i], tokenIds[i], recipients[i]);
        }
    }

    /// @dev Mints one Sapienz for each eligible token in a single collection, transferring the
    ///      token to the Sapienz' ERC6551 account
    function adminMint(address tokenAddress, uint256[] memory tokenIds, address recipient)
        external
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _adminMintWithTokens(tokenAddress, tokenIds, recipient);
    }

    /// @dev Mints one Sapienz for each eligible token across multiple collections, transferring
    ///      the token to the Sapienz' ERC6551 account
    function mintBatch(address[] calldata tokenAddresses, uint256[][] calldata tokenIds, bytes32[][][] calldata proofs)
        external
        nonReentrant
    {
        if (!mintEnabled) revert MintDisabled();

        uint256 len = tokenAddresses.length;
        if (tokenIds.length != len || proofs.length != len) {
            revert InvalidInputs();
        }

        for (uint256 i = 0; i < len; i++) {
            _mintWithTokens(tokenAddresses[i], tokenIds[i], proofs[i], msg.sender);
        }
    }

    /// @dev Mints one Sapienz for each eligible token in a single collection, transferring the
    ///      token to the Sapienz' ERC6551 account
    function mint(address tokenAddress, uint256[] memory tokenIds, bytes32[][] memory proofs) external nonReentrant {
        if (!mintEnabled) revert MintDisabled();
        _mintWithTokens(tokenAddress, tokenIds, proofs, msg.sender);
    }

    /// @dev Claim for multiple tokens from multiple collections at once. Transfers each token to
    ///      this contract.
    function claimBatch(
        address[] calldata tokenAddresses,
        uint256[][] calldata tokenIds,
        uint256[][] calldata balances,
        bytes32[][][] calldata proofs
    ) external nonReentrant {
        if (!claimEnabled) revert ClaimDisabled();
        uint256 len = tokenAddresses.length;
        if (tokenIds.length != len || balances.length != len || proofs.length != len) {
            revert InvalidInputs();
        }

        for (uint256 i = 0; i < len; i++) {
            _claim(tokenAddresses[i], tokenIds[i], balances[i], proofs[i], msg.sender);
        }
    }

    /// @dev Claim for multiple tokens from a single collection. Transfers each token to this
    ///      contract.
    function claim(address tokenAddress, uint256[] memory tokenIds, uint256[] memory balances, bytes32[][] memory proof)
        external
        nonReentrant
    {
        if (!claimEnabled) revert ClaimDisabled();
        _claim(tokenAddress, tokenIds, balances, proof, msg.sender);
    }

    /// @dev Revoke claim for multiple tokens from multiple collections at once. Transfers each
    ///      token from this contract to the caller.
    function unclaimBatch(
        address[] calldata tokenAddresses,
        uint256[][] calldata tokenIds,
        uint256[][] calldata balances
    ) external nonReentrant {
        uint256 len = tokenAddresses.length;
        if (tokenIds.length != len || balances.length != len) {
            revert InvalidInputs();
        }

        for (uint256 i = 0; i < len; i++) {
            _unclaim(tokenAddresses[i], tokenIds[i], balances[i]);
        }
    }

    /// @dev Revoke claim for multiple tokens from a single collection. Transfers each token from
    ///      this contract to the caller.
    function unclaim(address tokenAddress, uint256[] memory tokenIds, uint256[] memory balances)
        external
        nonReentrant
    {
        _unclaim(tokenAddress, tokenIds, balances);
    }

    /// @dev Returns the minted status for a given token used to claim Sapienz
    function isMintedWith(address tokenAddress, uint256 tokenId) external view returns (bool) {
        return _erc721Minted[tokenAddress].get(tokenId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyReceiver, (_salePrice * royaltyPercentage) / 100);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC1155ReceiverUpgradeable, ERC721AUpgradeable)
        returns (bool)
    {
        return interfaceId == _INTERFACE_ID_ERC4906 || interfaceId == _INTERFACE_ID_ERC2981
            || super.supportsInterface(interfaceId);
    }

    // Operator Filter Registry Overrides

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // End Operator Filter Registry Overrides

    function _airdropERC721(address tokenAddress, uint256[] memory tokenIds, address minter) internal {
        uint256 quantity = tokenIds.length;

        uint256 startTokenId = _currentIndex;

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = tokenIds[i];

            // revert if token has not been claimed
            if (claimedBalances[tokenAddress][tokenId][minter] == 0) {
                revert InvalidToken();
            }

            // revert if token has already been minted
            if (_erc721Minted[tokenAddress].get(tokenId)) {
                revert InvalidToken();
            }

            // clear claimed slot
            claimedBalances[tokenAddress][tokenId][minter] = 0;

            // mark claimed token as minted
            _erc721Minted[tokenAddress].set(tokenId);

            // calculate ERC6551 account address
            address tba =
                erc6551Registry.account(erc6551AccountImplementation, block.chainid, address(this), startTokenId + i, 0);

            IERC721Upgradeable(tokenAddress).safeTransferFrom(address(this), tba, tokenId);
        }

        _safeMint(minter, quantity);
    }

    function _airdropERC1155(
        address tokenAddress,
        uint256[] memory tokenIds,
        uint256[] memory balances,
        address[] memory minters
    ) internal {
        uint256 len = minters.length;

        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = tokenIds[i];
            address minter = minters[i];
            uint256 balance = balances[i];

            // revert if balance has not been claimed
            if (claimedBalances[tokenAddress][tokenId][minter] != balance) {
                revert InvalidToken();
            }

            // clear claimed slot
            claimedBalances[tokenAddress][tokenId][minter] = 0;

            uint256 startTokenId = _currentIndex;

            for (uint256 n = 0; n < balance; n++) {
                // calculate ERC6551 account address
                address tba = erc6551Registry.account(
                    erc6551AccountImplementation, block.chainid, address(this), startTokenId + n, 0
                );

                IERC1155Upgradeable(tokenAddress).safeTransferFrom(address(this), tba, tokenId, 1, "");
            }

            _safeMint(minter, balance);
        }
    }

    function _adminMintWithTokens(address tokenAddress, uint256[] memory tokenIds, address recipient) internal {
        if (!allowedContracts[tokenAddress]) {
            revert InvalidToken();
        }

        uint256 quantity = tokenIds.length;

        uint256 startTokenId = _currentIndex;

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = tokenIds[i];

            address tba =
                erc6551Registry.account(erc6551AccountImplementation, block.chainid, address(this), startTokenId + i, 0);

            // revert if token has already been minted
            if (_erc721Minted[tokenAddress].get(tokenId)) {
                revert InvalidToken();
            }

            // mark claimed token as minted
            _erc721Minted[tokenAddress].set(tokenId);

            // transfer from sender to recipient
            IERC721Upgradeable(tokenAddress).safeTransferFrom(msg.sender, tba, tokenId);
        }

        _safeMint(recipient, quantity);
    }

    function _mintWithTokens(
        address tokenAddress,
        uint256[] memory tokenIds,
        bytes32[][] memory proof,
        address recipient
    ) internal {
        if (!allowedContracts[tokenAddress]) {
            revert InvalidToken();
        }

        uint256 quantity = tokenIds.length;
        bool isControlledContract = controlledContracts[tokenAddress];

        uint256 startTokenId = _currentIndex;

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = tokenIds[i];

            // revert if token isn't controlled or in merkle tree
            if (!isControlledContract && !verifyMerkleProof(tokenAddress, tokenId, proof[i])) {
                revert InvalidToken();
            }

            address tba =
                erc6551Registry.account(erc6551AccountImplementation, block.chainid, address(this), startTokenId + i, 0);

            // revert if token has already been minted
            if (_erc721Minted[tokenAddress].get(tokenId)) {
                revert InvalidToken();
            }

            // mark claimed token as minted
            _erc721Minted[tokenAddress].set(tokenId);

            // transfer from sender to recipient
            IERC721Upgradeable(tokenAddress).safeTransferFrom(msg.sender, tba, tokenId);
        }

        _safeMint(recipient, quantity);
    }

    function _claim(
        address tokenAddress,
        uint256[] memory tokenIds,
        uint256[] memory balances,
        bytes32[][] memory proof,
        address claimant
    ) internal {
        if (!allowedContracts[tokenAddress]) {
            revert InvalidToken();
        }

        bool isControlledContract = controlledContracts[tokenAddress];

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (!isControlledContract && !verifyMerkleProof(tokenAddress, tokenIds[i], proof[i])) {
                revert InvalidToken();
            }

            if (balances[i] == 0) {
                _claimERC721(tokenAddress, tokenIds[i], claimant);
            } else {
                _claimERC1155(tokenAddress, tokenIds[i], balances[i], claimant);
            }
        }
    }

    function _claimERC721(address tokenAddress, uint256 tokenId, address claimant) internal {
        if (claimedBalances[tokenAddress][tokenId][claimant] != 0) {
            revert AlreadyClaimed();
        }

        claimedBalances[tokenAddress][tokenId][claimant] = 1;

        IERC721Upgradeable(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId);
    }

    function _claimERC1155(address tokenAddress, uint256 tokenId, uint256 balance, address claimant) internal {
        claimedBalances[tokenAddress][tokenId][claimant] += balance;

        IERC1155Upgradeable(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId, balance, "");
    }

    function _unclaim(address tokenAddress, uint256[] memory tokenIds, uint256[] memory balances) internal {
        if (!allowedContracts[tokenAddress]) {
            revert InvalidToken();
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (balances[i] == 0) {
                _unclaimERC721(tokenAddress, tokenIds[i]);
            } else {
                _unclaimERC1155(tokenAddress, tokenIds[i], balances[i]);
            }
        }
    }

    function _unclaimERC721(address tokenAddress, uint256 tokenId) internal {
        if (claimedBalances[tokenAddress][tokenId][msg.sender] != 1) {
            revert TokenNotFound();
        }

        claimedBalances[tokenAddress][tokenId][msg.sender] = 0;

        IERC721Upgradeable(tokenAddress).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function _unclaimERC1155(address tokenAddress, uint256 tokenId, uint256 balance) internal {
        if (claimedBalances[tokenAddress][tokenId][msg.sender] < balance) {
            revert TokenNotFound();
        }

        claimedBalances[tokenAddress][tokenId][msg.sender] -= balance;

        IERC1155Upgradeable(tokenAddress).safeTransferFrom(address(this), msg.sender, tokenId, balance, "");
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function verifyMerkleProof(address tokenAddress, uint256 tokenId, bytes32[] memory proof)
        private
        view
        returns (bool)
    {
        bytes32 node = keccak256(bytes.concat(keccak256(abi.encode(tokenAddress, tokenId))));
        return MerkleProofUpgradeable.verify(proof, merkleRoot, node);
    }
}

// FUTURE PRIMITIVE ✍️
