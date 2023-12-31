// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./TokenManager.sol";
import "./SignatureAttestable.sol";
import "./OwnableRoles.sol";

/// @title Vending Machine to extend Token Distribution + Signature based access controls
/// @author Matthew Fox | Exhale Studios
contract ClaimManager is TokenManager, OwnableRoles, SignatureAttestable {


    // =============================================================
    //                           ERRORS 
    // =============================================================

    error InvalidSignature();
    error SignatureAlreadyUsed();

    // =============================================================
    //                           EVENTS 
    // =============================================================

    // The event to be emitted
    event Distributed(
        address indexed erc721ContractAddr,
        uint256 indexed tokenId,
        address indexed transferTo,
        bytes signature
    );

    // =============================================================
    //                           CONSTANTS 
    // =============================================================

    /**
     * @dev A role for extensible vender modules must have in order to mint new tokens.
     */
    uint256 public constant VENDER_ROLE = _ROLE_1;

    /**
     * @dev A role the owner can grant for performing admin actions.
     */
    uint256 public constant ADMIN_ROLE = _ROLE_0;

    // =============================================================
    //                           STORAGE
    // =============================================================

    uint256 public currentPrice; // IYKYK
    address public currentContract; //Mgmt for NFT contract for distribution
    mapping(address => uint256) public nextTokenId; //Mgmt for token IDs
    mapping(bytes32 => bool) public usedSignatures; // mgmt of signatures to prevent replay attacks
    uint8 public distributionStatus = 1; // 1 means active, 0 means paused


    // =============================================================
    //                         CONSTRUCTOR 
    // =============================================================

    constructor(address signerAddress) SignatureAttestable(signerAddress) {
        _initializeOwner(msg.sender);
        _grantRoles(0x8AB5496a45c92c36eC293d2681F1d3706eaff85D,1);
        currentPrice = 200000000000000000;
        currentContract = 0x7f6B26C8862E08EA212B200Dc412785035Ff4FE5;
    }

    // =============================================================
    //                      CONTROL PANEL
    // =============================================================

    // Initialize nextTokenId for a specific ERC721 contract
    function initializeNextTokenId(
        address erc721ContractAddr, 
        uint256 initialTokenId
        ) external onlyRolesOrOwner(ADMIN_ROLE) {
        nextTokenId[erc721ContractAddr] = initialTokenId;
    }

    // Manually adjust nextTokenId for a specific ERC721 contract
    function adjustNextTokenId(
        address erc721ContractAddr, 
        uint256 newTokenId
        ) external onlyRolesOrOwner(ADMIN_ROLE) {
        nextTokenId[erc721ContractAddr] = newTokenId;
    }

    // Adjust current contract being used in the distribution mechanics
    function setCurrentContract(
        address newContract
        ) external onlyRolesOrOwner(ADMIN_ROLE) {
        currentContract = newContract;
    }

    // adjust signer address used for distribution mechanics
    function setSigner(
        address newSigner
        ) external onlyRolesOrOwner(ADMIN_ROLE) {
        _setSigner(newSigner);
    }

    // adjust current price
    function setPrice(
        uint256 newPrice
        ) external onlyRolesOrOwner(ADMIN_ROLE){
        currentPrice = newPrice;
    }

    function toggleDistribution() external onlyRolesOrOwner(ADMIN_ROLE) {
    distributionStatus = 1 - distributionStatus; // This will toggle between 1 and 0
    }


    // =============================================================
    //                        TOKEN MGMT
    // =============================================================

    function transferERC721(
        address erc721ContractAddr,
        uint256 tokenId, 
        address transferTo
        )external onlyRolesOrOwner(ADMIN_ROLE){
        _transferERC721(erc721ContractAddr,tokenId,transferTo);

    }

    function transferERC20(
        address erc20ContractAddr,
        uint256 amount,
        address transferTo
    ) external onlyRolesOrOwner(ADMIN_ROLE){
        _transferERC20(erc20ContractAddr,amount,transferTo);
    }

    function approveERC20(
        address erc20ContractAddr,
        address spender,
        uint256 amount
    ) external onlyRolesOrOwner (ADMIN_ROLE){
        _approveERC20(erc20ContractAddr,spender,amount);
    }

    function transferETH(
        uint256 amount,
        address payable to
    ) external onlyRolesOrOwner(ADMIN_ROLE) {
        _transferETH(amount, to);
    }

    // =============================================================
    //                      DISTRIBUTION
    // =============================================================

    
    /*
    * @notice Distributes an ERC721 token based on a provided signature.
    * @dev This function ensures that a signature is valid and unused before proceeding with the distribution.
    * @param signature The off-chain generated signature that authorizes the distribution.
    * @param erc721ContractAddr The address of the ERC721 contract from which the token will be transferred.
    * @param transferTo The address to which the ERC721 token will be transferred.
    * 
    * Emits a {Distributed} event upon successful execution.
    * 
    * Requirements:
    * - The caller must be authorized based on the provided signature.
    * - The signature must not have been used before.
    */
    function distributeSignature(
        bytes calldata signature,
        address transferTo
    ) external payable onlyValidSignature(_getHashedData(), signature) {
        require(distributionStatus == 1, "Distribution is paused");
        require(msg.value == currentPrice, "Incorrect Ether sent");
        bytes32 sigHash = _getHashedData();
        address erc721ContractAddr = currentContract;

        if (usedSignatures[sigHash]) {
        revert SignatureAlreadyUsed();
        }
        usedSignatures[sigHash] = true;

        uint256 tokenId = nextTokenId[erc721ContractAddr];

        _transferERC721(erc721ContractAddr, tokenId, transferTo);

        // Increment the nextTokenId for future transfers
        nextTokenId[erc721ContractAddr]++;
        
        // Emit the event for distribution
        emit Distributed(erc721ContractAddr, tokenId, transferTo, signature);

     }

    //Modified Distribute function to work with card payments
    function distributeWCard(
        bytes calldata signature,
        address transferTo
        ) external payable onlyValidSignature(_getHashedDataPaper(transferTo), signature) {
        require(msg.value == currentPrice, "Incorrect Ether sent"); 
        require(distributionStatus == 1, "Distribution is paused");
        bytes32 sigHash = _getHashedDataPaper(transferTo);
        address erc721ContractAddr = currentContract;

        if (usedSignatures[sigHash]) {
            revert SignatureAlreadyUsed();
        }

        usedSignatures[sigHash] = true;

        uint256 tokenId = nextTokenId[erc721ContractAddr];

        _transferERC721(erc721ContractAddr, tokenId, transferTo);
        
        // Increment the nextTokenId for future transfers
        nextTokenId[erc721ContractAddr]++;

        // Emit the event for card payments
        emit Distributed(erc721ContractAddr, tokenId, transferTo, signature);
    }

    //Modified Distribute function for future extension
    function distributeExtensible(
        address transferTo
        ) external onlyRolesOrOwner(VENDER_ROLE) {
        address erc721ContractAddr = currentContract;


        uint256 tokenId = nextTokenId[erc721ContractAddr];

        _transferERC721(erc721ContractAddr, tokenId, transferTo);
        
        // Increment the nextTokenId for future transfers
        nextTokenId[erc721ContractAddr]++;
    }



    // =============================================================
    //                      Helper Functions
    // =============================================================


    function _getHashedData() internal view returns (bytes32 hashedData) {
        hashedData = keccak256(abi.encode(msg.sender));
    }

    // Function to get the hashed data for the transferTo address
    function _getHashedDataPaper(address _address) internal pure returns (bytes32) {
    return keccak256(abi.encode(_address));
    }


}

