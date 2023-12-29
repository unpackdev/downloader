// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./AccessControlUpgradeable.sol";
import "./IERC2981Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";
import "./IERC165Upgradeable.sol";
import "./IERC721AUpgradeable.sol";
import "./ERC721Royalty.sol";

/**
 * @dev Need 10 Part NFTs to assemble a Mech NFT. 
 * A Mech NFT can be disassembled back to 10 Part NFTs. 
 */
contract Mech is 
    ERC721Royalty, 
    AccessControlUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    OwnableUpgradeable, 
    UUPSUpgradeable, 
    IERC721ReceiverUpgradeable,  
    ReentrancyGuardUpgradeable {
    /**
     * @dev Roles
     * DEFAULT_ADMIN_ROLE
     * - can update royalty of each NFT
     * - can update role of each account
     * - can withdraw ERC20 tokens, matic from this contract
     * - can update prices of assemble/disassemble
     *
     * OPERATOR_ROLE
     * - can update tokenURI
     * - can update required part nft count to assemble a Mech
     * - can update encryptor who is generating signatures
     * 
     * DEPLOYER_ROLE
     * - can update the logic contract
     */
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");    
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
    IERC721AUpgradeable public partContract;
    uint256 public requiredPartCountPerMech;
    uint256 public assemblePrice;
    uint256 public disassemblePrice;
    mapping(bytes32 => uint256) public mechTokenData;
    
    mapping(uint256 => string) private _tokenURIs;
    string private baseURI;
    uint256 private _tokenIds;
    address public encryptor;
    
    using StringsUpgradeable for uint256;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override only(DEPLOYER_ROLE) {}
    
    /**
     * @dev 
     * Params
     * - `adminAddress`: ownership and `DEFAULT_ADMIN_ROLE` will be granted, 
     * - `operatorAddress`: `OPERATOR_ROLE` will be granted,
     * - `encryptorAddress`: only this account can make signatures to assemble/disassemble
     * - `partAddress`: part nfts are materials of mech nfts
     * - `priceForAssemble`: matic amount that is needed to assemble a mech
     * - `priceForDisassemble`: matic amount that is needed to disassemble a mech
     * - `defaultRoyaltyReceiver`: default royalty fee receiver
     * - `defaultFeeNumerator`: default royalty fee
     */
    function initialize(
        string memory name, 
        string memory symbol, 
        address adminAddress, 
        address operatorAddress, 
        address encryptorAddress, 
        address partAddress, 
        uint256 priceForAssemble, 
        uint256 priceForDisassemble,
        address defaultRoyaltyReceiver,
        uint96 defaultFeeNumerator) initializer public {
        __ERC721_init(name, symbol);
        __ERC721Enumerable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __DefaultOperatorFilterer_init();
        
        _tokenIds = 0;
        requiredPartCountPerMech = 10;
        assemblePrice = priceForAssemble;
        disassemblePrice = priceForDisassemble;
        encryptor = encryptorAddress;
        partContract = IERC721AUpgradeable(partAddress);
        
        transferOwnership(adminAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _setupRole(OPERATOR_ROLE, operatorAddress);
        _setupRole(DEPLOYER_ROLE, _msgSender());
        _setDefaultRoyalty(defaultRoyaltyReceiver, defaultFeeNumerator);
    }
    
    modifier only(bytes32 role) {
        require(hasRole(role, _msgSender()), "Caller does not have permission");
       _;
    }

    // external
    /**
     * @dev Assembles(mint) a Mech NFT by using Parts NFTs. 
     * All parts NFTs that are used should be verified by the backend system.
     * To offer same Mech tokenId for the same Part NFTs, 
     * A Mech NFT has a unique hash value that is created from its Part NFTs.
     * So If the same Part NFTs are used for a Mech NFT, this unique hash will be same.
     *
     * Params
     * - `blockNumberLimit`: a transaction should end before blockNumberLimit
     * - `parts`: Part NFT list that are being assembled into a Mech NFT
     * - `signature`: signature to validate all parameters
     */
    function assemble(
        uint256 blockNumberLimit, 
        uint256[] calldata parts, 
        bytes calldata signature) external payable nonReentrant {
        require(block.number <= blockNumberLimit, "Transaction has expired");
        require(validateAssemble(blockNumberLimit, _msgSender(), parts, signature), "Invalid signature");
        require(parts.length == requiredPartCountPerMech, "Invalid number of parts for assembling");

        // payment
        checkPayment(assemblePrice);

        for(uint i=0; i<parts.length; i++) {
            partContract.safeTransferFrom(_msgSender(), address(this), parts[i]);
        }

        bytes32 partsKey = generateUniqueMechKey(parts);
        uint256 tokenId = generateTokenId(partsKey);

        _safeMint(_msgSender(), tokenId);
        emit Assembled(_msgSender(), tokenId, parts);
    }
    
    /**
     * @dev Disassembles(burn) a Mech NFT and return back Parts NFTs
     * Params
     * - `blockNumberLimit`: a transaction should end before blockNumberLimit
     * - `parts`: Part tokenId list that will be transferred to the owner after a Mech is disassembled 
     * - `tokenId`: a Mech NFT tokenId. msgSender should be the owner of this token
     * - `signature`: signature to validate all parameters
     */
    function disassemble(
        uint256 blockNumberLimit, 
        uint256[] calldata parts, 
        uint256 tokenId, 
        bytes calldata signature) external payable nonReentrant {
        require(ownerOf(tokenId) == _msgSender(), "Sender does not own a Mech");
        require(block.number <= blockNumberLimit, "Transaction has expired");
        require(validateDisassemble(blockNumberLimit, _msgSender(), tokenId, signature), "Invalid signature");
        bytes32 partsKey = generateUniqueMechKey(parts);
        require(tokenId == getMechTokenId(partsKey), "Part hash value does not match with a Mech tokenId");
        
        // payment
        checkPayment(disassemblePrice);
        _burn(tokenId);
        
        for (uint i=0; i< parts.length; i++) {
            partContract.safeTransferFrom(address(this), _msgSender(), parts[i]);
        }
        
        emit Disassembled(_msgSender(), tokenId, parts);
    }
    
    /**
     * @dev Checks payment and refund if the amount is exceeded
     * Params
     * - `price`: amount that is being paid
     */
    function checkPayment(uint256 price) private {
      require(msg.value >= price, "Insufficient fund");
      if (msg.value > price) {
        payable(msg.sender).transfer(msg.value - price);
      }
    }

    // viewer
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        string memory _tokenURI = _tokenURIs[tokenId];

        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    
    // operator
    /**
     * @dev Sets baseURI
     *
     * Requirements
     * - the caller must have the `OPERATOR_ROLE`
     */
    function setBaseURI(string memory uri) external only(OPERATOR_ROLE) {
        baseURI = uri;
    }
    
    /**
     * @dev Sets TokenURI of a token
     *
     * Requirements
     * - the caller must have the `OPERATOR_ROLE`
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external only(OPERATOR_ROLE) {
        _requireMinted(tokenId);
        _tokenURIs[tokenId] = _tokenURI;
    }
    
    /**
     * @dev Sets tokenURIs from `tokenIdFrom` to `tokenIdFrom + tokenURIs.length -1`
     *
     * Requirements
     * - the caller must have the `OPERATOR_ROLE`
     */
    function setTokenURIs(uint256 tokenIdFrom, string[] calldata tokenURIs) external only(OPERATOR_ROLE) {
        uint count = tokenURIs.length;
        uint256 tokenId = tokenIdFrom;
        for (uint i=0; i<count; i++) {
            _requireMinted(tokenId);
            _tokenURIs[tokenId] = tokenURIs[i];
            tokenId++;
        }
    }
    
    /**
     * @dev Sets required part count to assemble a Mech
     *
     * Requirements
     * - the caller must have the `OPERATOR_ROLE`
     */
    function setRequiredPartCountPerMech(uint256 count) external only(OPERATOR_ROLE) {
        require(count > 0, "Part count cannot be zero");
        requiredPartCountPerMech = count;
    }
    
    /**
     * @dev Sets Encryptor address
     * This encryptor will generate signatures in backend system for assembling/disassembling
     *
     * Requirements
     * - the caller must have the `OPERATOR_ROLE`
     */
    function setEncryptor(address encryptorAddress) external only(OPERATOR_ROLE) {
        require(encryptorAddress != address(0), "Zero address cannot be used");
        encryptor = encryptorAddress;
    }
    
    // admin
    /**
     * @dev Updates prices of assembling/disassembling
     *
     * Requirements
     * - the caller must have the `OPERATOR_ROLE`
     */
    function updatePrice(uint256 priceForAssemble, uint256 priceForDisassemble) external only(DEFAULT_ADMIN_ROLE) {
        assemblePrice = priceForAssemble;
        disassemblePrice = priceForDisassemble;
    }
    
    /**
     * @dev Withdraws matic from this contract to a recipient 
     *
     * Requirements
     * - the caller must have the `DEFAULT_ADMIN_ROLE`
     */
   function withdrawBalance(address payable recipient, uint256 amount) external only(DEFAULT_ADMIN_ROLE) nonReentrant {
        require(recipient != address(0), "Zero address cannot be used");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Unable to withdraw, recipient may have reverted");
    }
    
    // Royalty interface
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external only(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
    
    function deleteDefaultRoyalty() external only(DEFAULT_ADMIN_ROLE) {
        _deleteDefaultRoyalty();
    }
    
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external only(DEFAULT_ADMIN_ROLE){
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }
    
    function resetTokenRoyalty(uint256 tokenId) external only(DEFAULT_ADMIN_ROLE) {
        _resetTokenRoyalty(tokenId);
    }
    
    // libraries
    /**
     * @dev Returns unique key for each Part NFT set
     * To generate same key with the same Part list set, it conducts sorting before making key
     * This returned key should be unique among the Part list sets
     *
     * Params
     * - `parts`: Part NFT list
     *
     */
    function generateUniqueMechKey(uint256[] memory parts) public pure returns (bytes32) {
        require(parts.length > 0, "Parts list cannot be empty");
        sortUint256Array(parts);
        bytes memory buffer = abi.encodePacked(parts);
        
        return keccak256(buffer);
    }
    
    /**
     * @dev Sorts uint256 array
     */
    function sortUint256Array(uint256[] memory arr) internal pure {
        uint length = arr.length;
        for(uint i=0; i<length-1; i++) {
            bool swapped = false;
            for(uint j=0; j<length-1; j++) {
                if(arr[j] > arr[j+1]) {
                    uint256 tmp = arr[j];
                    arr[j] = arr[j+1];
                    arr[j+1] = tmp;
                    swapped = true;
                }
            }
            
            // If no two elements were swapped by inner loop, then the array is sorted.
            if (swapped == false) {
                break;
            }
        }
    }
    
    /**
     * @dev Validates parameters and signature of disassemble function
     *
     * Params
     * - `blockNumberLimit`: a transaction should end before blockNumberLimit
     * - `tokenOwner`: Mech NFT owner adderss
     * - `tokenId`: Mech NFT tokenId.
     * - `signature`: signature to validate all parameters
     */
    function validateDisassemble(
        uint256 blockNumberLimit,
        address tokenOwner,
        uint256 tokenId,
        bytes calldata signature
    ) internal view returns (bool) {
        bytes32 hashed = keccak256(abi.encode(blockNumberLimit, tokenOwner, tokenId));
        (address recovered, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable.tryRecover(hashed, signature);

        if (error == ECDSAUpgradeable.RecoverError.NoError && recovered == encryptor ) {
            return true;
        }

        return false;
    }
    
    /**
     * @dev Validates parameters and signature of assemble function
     *
     * Params
     * - `blockNumberLimit`: a transaction should end before blockNumberLimit
     * - `tokenOwner`: Part NFT owner
     * - `tokenIds`: Part NFT tokenIds
     * - `signature`: signature to validate all parameters
     */
    function validateAssemble(
        uint256 blockNumberLimit,
        address tokenOwner,
        uint256[] calldata tokenIds,
        bytes calldata signature
    ) internal view returns (bool) {
        bytes32 hashed = keccak256(abi.encode(blockNumberLimit, tokenOwner, tokenIds));
        (address recovered, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable.tryRecover(hashed, signature);

        if (error == ECDSAUpgradeable.RecoverError.NoError && recovered == encryptor ) {
            return true;
        }

        return false;
    }
    
    /**
     * @dev Stores associated information of part nft tokenIds and its Mech tokenId
     * Because the same set of part nft tokenIds should be associated with a mech tokenId
     * When it is disassembled and re-assembled with same part tokenIds, the Mech tokenId is always the same
     * So this function stores partsKey with Mech tokenId
     *  
     * Params
     * - `partsKey`: the unique key associated with those Part tokenIds 
     */
    function generateTokenId(bytes32 partsKey) internal returns (uint256) {
        uint256 tokenId;
        if (mechTokenData[partsKey] > 0) {
            tokenId = getMechTokenId(partsKey);
            require(!_exists(tokenId), "Mech ID already exists");
        } else {
            tokenId = _tokenIds;
            setMechTokenId(partsKey, tokenId);
            _tokenIds++;
        }
        
        return tokenId;
    }
    
    /**
     * @dev GetMechTokenId 
     */
    
    function getMechTokenId(bytes32 partsKey) internal returns (uint256) {
        require(mechTokenData[partsKey] > 0, "Given Parts list has never been assembled");
        uint256 tokenId = mechTokenData[partsKey] -1;
        return tokenId;
    }
    
    function setMechTokenId(bytes32 partsKey, uint256 tokenId) internal {
        mechTokenData[partsKey] = tokenId +1;
    }

    // this is required from IERC721Receiver spec.
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) override external returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    // OpenSea operator filter
    function setApprovalForAll(address operator, bool approved) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    
    // supportsInterface
    function supportsInterface(bytes4 interfaceId) 
        public view virtual 
        override(AccessControlUpgradeable, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId)
            || type(IERC721ReceiverUpgradeable).interfaceId == interfaceId;
    }
    
    // events
    event Assembled(address indexed owner, uint256 indexed tokenId, uint256[] parts);
    event Disassembled(address indexed owner, uint256 indexed tokenId, uint256[] parts);
    
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}