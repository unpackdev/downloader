// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @notice A struct defining public drop data.
 *         Designed to fit efficiently in one storage slot.
 * 
 * @param mintPrice                The mint price per token. (Up to 1.2m
 *                                 of native token, e.g. ETH, MATIC)
 * @param startTime                The start time, ensure this is not zero.
 * @param endTIme                  The end time, ensure this is not zero.
 * @param maxTotalMintableByWallet Maximum total number of mints a user is
 *                                 allowed. (The limit for this field is
 *                                 2^16 - 1)
 * @param feeBps                   Fee out of 10_000 basis points to be
 *                                 collected.
 * @param restrictFeeRecipients    If false, allow any fee recipient;
 *                                 if true, check fee recipient is allowed.
 */
struct PublicDrop {
    uint80 mintPrice; // 80/256 bits
    uint48 startTime; // 128/256 bits
    uint48 endTime; // 176/256 bits
    uint16 maxTotalMintableByWallet; // 224/256 bits
    uint16 feeBps; // 240/256 bits
    bool restrictFeeRecipients; // 248/256 bits
}

/**
 * @notice A struct defining token gated drop stage data.
 *         Designed to fit efficiently in one storage slot.
 * 
 * @param mintPrice                The mint price per token. (Up to 1.2m 
 *                                 of native token, e.g.: ETH, MATIC)
 * @param maxTotalMintableByWallet Maximum total number of mints a user is
 *                                 allowed. (The limit for this field is
 *                                 2^16 - 1)
 * @param startTime                The start time, ensure this is not zero.
 * @param endTime                  The end time, ensure this is not zero.
 * @param dropStageIndex           The drop stage index to emit with the event
 *                                 for analytical purposes. This should be 
 *                                 non-zero since the public mint emits
 *                                 with index zero.
 * @param maxTokenSupplyForStage   The limit of token supply this stage can
 *                                 mint within. (The limit for this field is
 *                                 2^16 - 1)
 * @param feeBps                   Fee out of 10_000 basis points to be
 *                                 collected.
 * @param restrictFeeRecipients    If false, allow any fee recipient;
 *                                 if true, check fee recipient is allowed.
 */
struct TokenGatedDropStage {
    uint80 mintPrice; // 80/256 bits
    uint16 maxTotalMintableByWallet; // 96/256 bits
    uint48 startTime; // 144/256 bits
    uint48 endTime; // 192/256 bits
    uint8 dropStageIndex; // non-zero. 200/256 bits
    uint32 maxTokenSupplyForStage; // 232/256 bits
    uint16 feeBps; // 248/256 bits
    bool restrictFeeRecipients; // 256/256 bits
}

/**
 * @notice A struct defining mint params for an allow list.
 *         An allow list leaf will be composed of `msg.sender` and
 *         the following params.
 * 
 *         Note: Since feeBps is encoded in the leaf, backend should ensure
 *         that feeBps is acceptable before generating a proof.
 * 
 * @param mintPrice                The mint price per token.
 * @param maxTotalMintableByWallet Maximum total number of mints a user is
 *                                 allowed.
 * @param startTime                The start time, ensure this is not zero.
 * @param endTime                  The end time, ensure this is not zero.
 * @param dropStageIndex           The drop stage index to emit with the event
 *                                 for analytical purposes. This should be
 *                                 non-zero since the public mint emits with
 *                                 index zero.
 * @param maxTokenSupplyForStage   The limit of token supply this stage can
 *                                 mint within.
 * @param feeBps                   Fee out of 10_000 basis points to be
 *                                 collected.
 * @param restrictFeeRecipients    If false, allow any fee recipient;
 *                                 if true, check fee recipient is allowed.
 */
struct MintParams {
    uint256 mintPrice; 
    uint256 maxTotalMintableByWallet;
    uint256 startTime;
    uint256 endTime;
    uint256 dropStageIndex; // non-zero
    uint256 maxTokenSupplyForStage;
    uint256 feeBps;
    bool restrictFeeRecipients;
}

/**
 * @notice A struct defining token gated mint params.
 * 
 * @param allowedNftToken    The allowed nft token contract address.
 * @param allowedNftTokenIds The token ids to redeem.
 */
struct TokenGatedMintParams {
    address allowedNftToken;
    uint256[] allowedNftTokenIds;
}

/**
 * @notice A struct defining allow list data (for minting an allow list).
 * 
 * @param merkleRoot    The merkle root for the allow list.
 * @param publicKeyURIs If the allowListURI is encrypted, a list of URIs
 *                      pointing to the public keys. Empty if unencrypted.
 * @param allowListURI  The URI for the allow list.
 */
struct AllowListData {
    bytes32 merkleRoot;
    string[] publicKeyURIs;
    string allowListURI;
}

/**
 * @notice A struct defining minimum and maximum parameters to validate for 
 *         signed mints, to minimize negative effects of a compromised signer.
 *
 * @param minMintPrice                The minimum mint price allowed.
 * @param maxMaxTotalMintableByWallet The maximum total number of mints allowed
 *                                    by a wallet.
 * @param minStartTime                The minimum start time allowed.
 * @param maxEndTime                  The maximum end time allowed.
 * @param maxMaxTokenSupplyForStage   The maximum token supply allowed.
 * @param minFeeBps                   The minimum fee allowed.
 * @param maxFeeBps                   The maximum fee allowed.
 */
struct SignedMintValidationParams {
    uint80 minMintPrice; // 80/256 bits
    uint24 maxMaxTotalMintableByWallet; // 104/256 bits
    uint40 minStartTime; // 144/256 bits
    uint40 maxEndTime; // 184/256 bits
    uint40 maxMaxTokenSupplyForStage; // 224/256 bits
    uint16 minFeeBps; // 240/256 bits
    uint16 maxFeeBps; // 256/256 bits
}

interface ERC721SeaDropStructsErrorsAndEvents {
  /**
   * @notice Revert with an error if mint exceeds the max supply.
   */
  error MintQuantityExceedsMaxSupply(uint256 total, uint256 maxSupply);

  /**
   * @notice Revert with an error if the number of token gated 
   *         allowedNftTokens doesn't match the length of supplied
   *         drop stages.
   */
  error TokenGatedMismatch();

  /**
   *  @notice Revert with an error if the number of signers doesn't match
   *          the length of supplied signedMintValidationParams
   */
  error SignersMismatch();

  /**
   * @notice An event to signify that a SeaDrop token contract was deployed.
   */
  event SeaDropTokenDeployed();

  /**
   * @notice A struct to configure multiple contract options at a time.
   */
  struct MultiConfigureStruct {
    uint256 maxSupply;
    string baseURI;
    string contractURI;
    address seaDropImpl;
    PublicDrop publicDrop;
    string dropURI;
    AllowListData allowListData;
    address creatorPayoutAddress;
    bytes32 provenanceHash;

    address[] allowedFeeRecipients;
    address[] disallowedFeeRecipients;

    address[] allowedPayers;
    address[] disallowedPayers;

    // Token-gated
    address[] tokenGatedAllowedNftTokens;
    TokenGatedDropStage[] tokenGatedDropStages;
    address[] disallowedTokenGatedAllowedNftTokens;

    // Server-signed
    address[] signers;
    SignedMintValidationParams[] signedMintValidationParams;
    address[] disallowedSigners;
  }
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

/**
 * @dev Interface of the QRC Protocol.
 */
interface IQRC {
    /**
     * @dev Emitted when receciving QRC Transaction.
     *
     * Note that `Q_signature` must be checked off-line.
     */
    event EntryQRC(uint256 indexed index, bytes32 indexed Q_address, bytes32 Q_message_hash, bytes Q_signature);


    /**
     * @dev invoke an QRC transaction from `Q_address`, with message `Q_message` and signature `Q_signature`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {EntryQRC} event.
     */
    function entryQRC(bytes32 Q_address, bytes memory Q_message, bytes calldata Q_signature) payable external returns (bool);
}

interface IQRC20 is IQRC {
    /**
     * @dev calculate QRC minting amount.
     *
     * @param totalSupply current total supply of QRC20, given by calcultion from previous QRC txs.
     * @param Q_address bytes32 Q_address that sends the QRC tx.
     * @param nonce uint256 current nonce for the Q_address. (nonce for QRC tx instead of wrapped tx.)
     * @param value uint256 carried value of the corresponding wrapped tx. 
     *
     * @return amount uint256 value indicating the amount of minted token.
     *
     * THIS FUNCTION SHALL BE STATIC.
     */
    function mintQRC(uint256 totalSupply, bytes32 Q_address, uint256 nonce, uint256 value) view external returns (uint256 amount);
}



/**
 * @title WebQ - Web Q contract with gnosis {safe} account as fund receiver.
 * @author 0xTroll
 */
contract WebQ is IQRC20 {

    // Foundation address is safe account.
    address payable public safe;

    /**
     * @notice Constructor function sets address of fund receiver contract.
     * @param _safe safe account address.
     */
    constructor(address payable _safe) {

        require(_safe != address(0));

        safe = _safe;

    }

    /**
     * @dev Total donation donated to Web-Q.fundation.
     */
    uint256 public totalDonation;


    /**
     * @notice Current index for QRC transactions.
     */
    uint256 public qrcIndex;


    /**
     * @dev Current mintable specical NFT supply.
     */
    uint256 public mintableSupply;


    /**
     * @dev Allowner minter for given mintId.
     */
    mapping (uint256=>address) internal allowedMinterForMintId;

    /**
     * @dev Total donation donated to Web-Q.fundation.
     */
    event Donation(address donor, uint256 amount, uint256 totalDonation);

    /**
     * @dev Grant spNFT for donors who make considerable contribution.
     */
    event GrantSpNFT(address donor, uint256 mintId);


    /**
     * @dev Calculate how much donation required to mint {deltaAmount} spNFT when current supply is {supplyAmount} .
     */
    function donationForSpNfts(uint256 deltaAmount, uint256 supplyAmount) internal pure returns (uint256 donationRequired){

        uint256 nextAmount = deltaAmount + supplyAmount;

        
        donationRequired = ((nextAmount**2 - supplyAmount **2) * 25  + (nextAmount - supplyAmount) * 975) * 1e15;

    }

    /**
     * @dev Calculate how much donation required to mint {deltaAmount} spNFT .
     */
    function donationForSpNfts(uint256 deltaAmount) external view returns (uint256 donationRequired){
        donationRequired = donationForSpNfts(deltaAmount, mintableSupply);
    }

    /**
     * @dev Special NFT badges will be rewarded to initial donors to Web-Q.Foundation,
     * @dev {ownerOf} function is for compatiblity with tokenGated ERC721 SeaDrop contract,
     * @dev in order to remeber donors eligible to receive special NFT badges.
     * @dev Only allowedMinter can mint the corresponding NFT.
     * @dev Note that the snapshot of total donation is used as unique marker.
     * @dev Note that the acutal NFT id is decided by the sequence of SeaDrop mingting. 
     */
    function ownerOf(uint256 mintId) external view returns (address allowedMinter){

        allowedMinter = allowedMinterForMintId[mintId];

    }

    /**
     * @dev Grant {to} with pending special NFT, which can be accessed by ownerOf function with {uniqueMarker} as minting id.
     */
    function _grantSpecialNFT(address to, uint256 mintId) internal {

        require( to != address(0) );
        
        allowedMinterForMintId[mintId] = to;

        emit GrantSpNFT(to, mintId);

    }

    /**
     * @dev Handle donation, trying to grant special NFTs.
     * @dev visit https://web-q.foundation for more information.
     */
    function donate(address donor) payable public returns (uint256 donation, uint256 mintable){
        
        //storage -> memory
        mintable = mintableSupply;

        uint256 _value = msg.value;
        uint256 _threshold;

        if (_value > 0) {
            emit Donation(donor, _value, totalDonation);
        }

        while (mintable < 108) {
            _threshold = donationForSpNfts(1, mintable);
            if (_value >= _threshold){
                _value -= _threshold;
                mintable += 1;
                _grantSpecialNFT(donor, mintable);
            } else{
                break;
            }
        }
        
        totalDonation += msg.value;

        donation = totalDonation;

        //memory -> storage 
        mintableSupply = mintable;

        (bool success, ) = safe.call{value: msg.value}("");
        
        require(success);
    }

    /**
     * @dev Implementation of  QRC entry interface.
     * @dev visit https://web-q.foundation for more information.
     * Note that donation is triggered to handle donation.
     */

    function entryQRC(bytes32 Q_address, bytes memory Q_message, bytes calldata Q_signature) payable external returns (bool){

        donate(msg.sender);
        
        emit EntryQRC(qrcIndex, Q_address, keccak256(Q_message), Q_signature);

        qrcIndex += 1;

        return true;
    }


     /**
     * @dev Implementation of mintQRC, according to QRC-20 protocol.
     * @dev visit https://web-q.foundation for more information.
     */

    function mintQRC(uint256 totalSupply, bytes32 Q_address, uint256 nonce, uint256 value) pure external override returns (uint256 amount){
        Q_address;
        value;
        nonce;

        uint256 MaxSupply   = 21000000 ether;
        uint256 MintAmount  = 1000 ether; 
        uint256 HalveTimes  = 0;

        if (totalSupply >= MaxSupply){
            return 0;
        }
        while (totalSupply >= (MaxSupply - MaxSupply/(2**HalveTimes))){
            amount = MintAmount/(2**HalveTimes);
            HalveTimes += 1;
        }
        if (totalSupply + amount >= MaxSupply){
            amount = MaxSupply - totalSupply;
        }
    }

     /**
     * @dev Fund received will be transfered to {safe} account by default.
     */

    receive() external payable {
        safe.transfer(msg.value);
    }

}

/// @title IProxy - Helper interface to access masterCopy of the Proxy on-chain
/// @author Richard Meissner - <richard@gnosis.io>
interface IProxy {
    function masterCopy() external view returns (address);
}



interface ISeaDrop {
    function mintSigned(
        address nftContract,
        address feeRecipient,
        address minterIfNotPayer,
        uint256 quantity,
        MintParams calldata mintParams,
        uint256 salt,
        bytes calldata signature
    ) external payable;
    function mintAllowedTokenHolder(
        address nftContract,
        address feeRecipient,
        address minterIfNotPayer,
        TokenGatedMintParams calldata mintParams
    ) external payable;
    function getAllowedNftTokenIdIsRedeemed(
        address nftContract,
        address allowedNftToken,
        uint256 allowedNftTokenId
    ) external view returns (bool);
}

interface IERC721SeaDropClonable is ERC721SeaDropStructsErrorsAndEvents{
    function setBaseURI(string calldata tokenURI) external;
    function setContractURI(string calldata newContractURI) external;
    function setMaxSupply(uint256 newMaxSupply) external;
    function updateSignedMintValidationParams(
        address seaDropImpl,
        address signer,
        SignedMintValidationParams memory signedMintValidationParams
    ) external;
    function updatePayer(address seaDropImpl, address payer, bool allowed) external;
    function updateAllowedFeeRecipient(address seaDropImpl, address feeRecipient, bool allowed) external;
    function updateTokenGatedDrop(address seaDropImpl, address allowedNftToken, TokenGatedDropStage calldata dropStage) external;
    function getMintStats(address minter)
        external
        view
        returns (
            uint256 minterNumMinted,
            uint256 currentTotalSupply,
            uint256 maxSupply
        );
    function transferOwnership(address newPotentialOwner) external;
    function multiConfigure(MultiConfigureStruct calldata config) external;
    function initialize(
        string calldata __name,
        string calldata __symbol,
        address[] calldata allowedSeaDrop,
        address initialOwner
    ) external;
}

interface Safe {
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;
}


contract WebQDeployer is Ownable, ERC721SeaDropStructsErrorsAndEvents {

    IERC721SeaDropClonable public NFT;

    IERC721SeaDropClonable public spNFT;

    ISeaDrop public seaDrop;

    address payable public webQBase;

    event WebQDeployed(address webQ, address fundReceiver, address NFT, address spNFT);

    constructor(address seaDropImplementation, 
                address payable fundReceiver,
                address nftSigner,
                address seaDropCloneableImplementation,
                string memory contractURIforNFT,
                string memory baseURIforNFT,
                string memory contractURIforspNFT,
                string memory baseURIforspNFT
                ){

        address[] memory allowedSeaDrop = new address [] (1);

        seaDrop = ISeaDrop(seaDropImplementation);

        webQBase= payable(new WebQ(fundReceiver));

        allowedSeaDrop[0] = seaDropImplementation;

        NFT = IERC721SeaDropClonable(Clones.clone(seaDropCloneableImplementation));

        NFT.initialize(
                'Web-Q NFT Badger',
                'Web-Q NFT',
                allowedSeaDrop,
                address(this)
            );

        SignedMintValidationParams memory signValidationSetup = SignedMintValidationParams(
            0    ,//uint80 minMintPrice; 
            10000    ,//uint24 maxMaxTotalMintableByWallet; 
            0    ,//uint40 minStartTime; 
            uint40(type(uint40).max)    ,//uint40 maxEndTime; 
            10000    ,//uint40 maxMaxTokenSupplyForStage; 
            0    ,//uint16 minFeeBps; 
            0     //uint16 maxFeeBps; 
        );

        NFT.setContractURI(contractURIforNFT);

        NFT.setBaseURI(baseURIforNFT);

        NFT.setMaxSupply(10000);

        NFT.updateSignedMintValidationParams(
            seaDropImplementation,
            nftSigner,
            signValidationSetup
        );

        NFT.updatePayer(seaDropImplementation, address(this), true);
       
        NFT.updateAllowedFeeRecipient(seaDropImplementation, webQBase, true);

        spNFT = IERC721SeaDropClonable(Clones.clone(seaDropCloneableImplementation));

        spNFT.initialize(
            'Web-Q Special NFT Badger',
            'Web-Q spNFT',
            allowedSeaDrop,
            address(this)
        );

        TokenGatedDropStage memory tokenGatedSetup = TokenGatedDropStage(
            0    ,//uint80 mintPrice; 
            108    ,//uint16 maxTotalMintableByWallet; 
            0   ,//uint48 startTime; 
            uint48(type(uint48).max),//uint48 endTime; 
            1    ,//uint8 dropStageIndex; // non-zero. 
            108    ,//uint32 maxTokenSupplyForStage; 
            0    ,//uint16 feeBps; 
            false    //bool restrictFeeRecipients
        );

        spNFT.setMaxSupply(108);

        spNFT.updateTokenGatedDrop(
            seaDropImplementation,
            webQBase, 
            tokenGatedSetup
        );

        spNFT.setContractURI(contractURIforspNFT);

        spNFT.setBaseURI(baseURIforspNFT);

        spNFT.updatePayer(seaDropImplementation, address(this), true);

        spNFT.updateAllowedFeeRecipient(seaDropImplementation, webQBase, true);

        emit WebQDeployed(address(webQBase), address(fundReceiver), address(NFT), address(spNFT));

    }

    
    /**
     * @dev Check if salt is used for NFT minting.
     */
    mapping (uint256 => bool) public saltUsed;


    /**
     * @dev Record routed minting history.
     */
    event MintNFT(address from, address nftContract, uint256 spGrant);


    /**
     * @dev Mint NFTs and special NFTs in one function.
     *
     * @param grantedNFT last index of NFT to be minted.
     * @param signature server-side signature to mint NFT.
     * @param grantedSpNFTs ids of spNFT to be minted (not the final NFT id). Should be checked using claimableSpNFT.
     */
    function mintNFT(uint256 grantedNFT, bytes calldata signature, uint256[] calldata grantedSpNFTs) external {
        
        (uint256 _mintedNFT,,) = NFT.getMintStats(msg.sender); 

        if (grantedNFT > _mintedNFT){
            MintParams memory _mintParams = MintParams(
                0,grantedNFT,0,4070880000,1,10000,0,true
            );
            seaDrop.mintSigned(
                address(NFT), //nftContract
                webQBase, //feeRecipient
                msg.sender, //minter
                grantedNFT - _mintedNFT, //quantity
                _mintParams, //mintParams
                uint256(uint160(msg.sender)) + grantedNFT,  //salt
                signature
                );
        }

        if  (grantedSpNFTs.length > 0){
            seaDrop.mintAllowedTokenHolder(address(spNFT), webQBase, msg.sender, TokenGatedMintParams(webQBase, grantedSpNFTs));
        }
    }

    /**
     * @dev Donate to web-q.foundation and mint special NFTs within one transcation.
     *
     */
    function donationAndMint() external payable {
        uint256 oldMintable    = WebQ(webQBase).mintableSupply();
        
        (,uint256 newMintable) = WebQ(webQBase).donate{value: msg.value}(msg.sender);
        
        if (newMintable > oldMintable){
            uint256 [] memory grantedSpNFTs = new uint256[](newMintable - oldMintable);
            for (uint i = oldMintable; i < newMintable; i++){
                grantedSpNFTs[i-oldMintable] = i + 1;
            }

            seaDrop.mintAllowedTokenHolder(address(spNFT), webQBase, msg.sender, TokenGatedMintParams(webQBase, grantedSpNFTs));
        }
    }

    /**
     * @dev Check how many NFTs that have been minted by minter.
     *
     * @param minter whoever wants to mint spNFT.
     *
     * @return minted quantity of NFTs minted by minter.
     */
    function mintedNFT(address minter) external view returns(uint256 minted){
        (minted,,) = NFT.getMintStats(minter); 
    }

    /**
     * @dev Mint NFTs and special NFTs in one function.
     *
     * @param minter whoever wants to mint spNFT.
     * @param grantedSpNFTs ids of spNFT to be checked.
     *
     * @return mintableSpNFTs ids of spNFT can be minted (not the final NFT id).
     */
    function claimableSpNFT(address minter, uint256[] calldata grantedSpNFTs) external view returns(uint256[] memory mintableSpNFTs){
        uint256[] memory mintableSpNFTsPadded = new uint256[](grantedSpNFTs.length);
        uint256 mintableSpNFTsLength = 0;
        for (uint i=0; i<grantedSpNFTs.length; i++) {
            if (WebQ(webQBase).ownerOf(grantedSpNFTs[i]) == minter && 
                !seaDrop.getAllowedNftTokenIdIsRedeemed(
                    address(spNFT), webQBase, grantedSpNFTs[i]
                    )){
                        mintableSpNFTsPadded[mintableSpNFTsLength] = grantedSpNFTs[i];
                        mintableSpNFTsLength += 1;
                    }
        }
        mintableSpNFTs = new uint256[](mintableSpNFTsLength);
        for (uint i=0; i<mintableSpNFTsLength; i++){
            mintableSpNFTs[i] = mintableSpNFTsPadded[i];
        }
    }

    /**
     * @dev Transfer ownership of NFT contract in case of crtitial bugs.
     *
     * @param to to whom transfer ownership
     */
    function transferNftOwnership(address to)
        external
        onlyOwner{
            spNFT.transferOwnership(to);
            NFT.transferOwnership(to);
        }

    /**
     * @dev Configure multiple properties at a time.
     *
     * @param isSpNFT true: config spNFT, false: config NFT.
     * @param config The configuration struct.
     */
    function multiConfigure(bool isSpNFT,MultiConfigureStruct calldata config)
        external
        onlyOwner{
            if (isSpNFT){
                spNFT.multiConfigure(config);
            } else {
                NFT.multiConfigure(config);
            }
        }
    
}