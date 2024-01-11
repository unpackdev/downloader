// SPDX-License-Identifier: UNLICENSED
//
//
//  .----------------.  .----------------.  .----------------.  .----------------.                                         
// | .--------------. || .--------------. || .--------------. || .--------------. |                                        
// | |  _________   | || |     ____     | || | _____  _____ | || |  _______     | |                                        
// | | |_   ___  |  | || |   .'    `.   | || ||_   _||_   _|| || | |_   __ \    | |                                        
// | |   | |_  \_|  | || |  /  .--.  \  | || |  | |    | |  | || |   | |__) |   | |                                        
// | |   |  _|      | || |  | |    | |  | || |  | '    ' |  | || |   |  __ /    | |                                        
// | |  _| |_       | || |  \  `--'  /  | || |   \ `--' /   | || |  _| |  \ \_  | |                                        
// | | |_____|      | || |   `.____.'   | || |    `.__.'    | || | |____| |___| | |                                        
// | |              | || |              | || |              | || |              | |                                        
// | '--------------' || '--------------' || '--------------' || '--------------' |                                        
//  '----------------'  '----------------'  '----------------'  '----------------'                                         
//  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
// | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
// | |   _____      | || |  _________   | || |  _________   | || |  _________   | || |  _________   | || |  _______     | |
// | |  |_   _|     | || | |_   ___  |  | || | |  _   _  |  | || | |  _   _  |  | || | |_   ___  |  | || | |_   __ \    | |
// | |    | |       | || |   | |_  \_|  | || | |_/ | | \_|  | || | |_/ | | \_|  | || |   | |_  \_|  | || |   | |__) |   | |
// | |    | |   _   | || |   |  _|  _   | || |     | |      | || |     | |      | || |   |  _|  _   | || |   |  __ /    | |
// | |   _| |__/ |  | || |  _| |___/ |  | || |    _| |_     | || |    _| |_     | || |  _| |___/ |  | || |  _| |  \ \_  | |
// | |  |________|  | || | |_________|  | || |   |_____|    | || |   |_____|    | || | |_________|  | || | |____| |___| | |
// | |              | || |              | || |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 
//  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.                     
// | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |                    
// | | _____  _____ | || |     ____     | || |  _______     | || |  ________    | || |    _______   | |                    
// | ||_   _||_   _|| || |   .'    `.   | || | |_   __ \    | || | |_   ___ `.  | || |   /  ___  |  | |                    
// | |  | | /\ | |  | || |  /  .--.  \  | || |   | |__) |   | || |   | |   `. \ | || |  |  (__ \_|  | |                    
// | |  | |/  \| |  | || |  | |    | |  | || |   |  __ /    | || |   | |    | | | || |   '.___`-.   | |                    
// | |  |   /\   |  | || |  \  `--'  /  | || |  _| |  \ \_  | || |  _| |___.' / | || |  |`\____) |  | |                    
// | |  |__/  \__|  | || |   `.____.'   | || | |____| |___| | || | |________.'  | || |  |_______.'  | |                    
// | |              | || |              | || |              | || |              | || |              | |                    
// | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |                    
//  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'                     
//
//

pragma solidity 0.8.6;

import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ECDSA.sol";

import "./ERC721A.sol";

import "./Split.sol";

contract FourLetterWords is ERC721A, Ownable {

    using Strings for uint256;
    using SafeERC20 for IERC20;

    // Events
    event RoyaltiesSet(uint256 oldAmount, uint256 newAmount, address recipient);

    // Error messages
    string private constant WRONG_PRICE = "Cash Wrong";
    string private constant LIMIT_EXCEEDED = "Mint Less";
    string private constant UNAUTHORIZED = "Nada Bruh";
    string private constant WHITELIST_PAUSED = "Need Wait";
    string private constant PUBLIC_PAUSED = "Need Wait";
    string private constant DOES_NOT_EXIST = "Nada Word";
    string private constant FROZEN = "Mint Over";
    string private constant NOT_FROZEN = "Nada Mint Over";
    string private constant HASH_NOT_SET = "Nada Hash Over";
    string private constant HASH_MISMATCH = "This Hash Awry";
    string private constant ALREADY_REVEALED = "Show Over";
    string private constant NO_SPLIT = "Nada Split";
    string private constant NO_CONTRACTS = "Nada Bots";

    // Limits and pricing
    uint256 public constant WHITELIST_PRICE = 0.04 ether;
    uint256 public constant PUBLIC_PRICE = 0.04 ether;
    uint256 public constant TOTAL_LIMIT = 666;
    uint256 public constant RESERVED = 222;
    uint256 public constant PER_WALLET_MINT = 8;
    mapping (address => uint256) public minted;

    // Contract that takes care of payments
    address public split;

    // Pausing
    bool public whitelistMintPaused = true;
    bool public publicMintPaused = true;

    // Reveal flags
    bool public frozen;
    bool public revealed;
    bytes32 public revealHash;
    bytes32 public shift;

    // NFT metadata configuration
    string public uriConfig;
    mapping (uint256 => string) public oneOffs;

    // Royalties
    uint256 public royalty = 75;
    address public royaltyRecipient = 0xC385211ea8D454269139108748C129a50B63CCf1;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;


    /**
     * Updates the shift, intended for minting methods
     */
    modifier updateShift(uint256 _back) {
        _;
        for (uint256 i = 0; i < _back; i++) {
            shift = keccak256(abi.encode(blockhash(block.number - i), shift));
        }
    }

    /**
     * Modifier for preventing smart contracts from participating
     * in the drop.
     */
    modifier onlyEOA() {
        require(msg.sender == tx.origin, NO_CONTRACTS);
        _;
    }

    /**
     * Constructor, no special features
     */
    constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) updateShift(0) {
    }

    /**
     * A method for public mint. Expects to receive ETH for every NFT
     * to be minted. Updates the shift variable as a side effect.
     *
     * _number The number of NFTs to be minted to the msg.sender
     */
    function mintPublic(uint256 _number) public payable onlyEOA updateShift(1) {
        // check pause and freeze
        require(!frozen, FROZEN);
        require(!publicMintPaused, PUBLIC_PAUSED);

        // check the price and limits
        require(msg.value == _number * PUBLIC_PRICE, WRONG_PRICE);

        // mint the NFTs
        minted[msg.sender] += _number;
        _safeMint(msg.sender, _number);

        // check supply and limits
        require(totalSupply() <= TOTAL_LIMIT, LIMIT_EXCEEDED);
        require(minted[msg.sender] <= PER_WALLET_MINT, LIMIT_EXCEEDED);
    }

    /**
     * A method for the whitelist mint. Expects to receive ETH for
     * every NFT to be minted. Updates the shift variable as a side 
     * effect. Uses owner's signature to validate caller's presence
     * on the whitelist.
     *
     * _signature The hash of the msg.sender signed by the owner
     * _number The number of NFTs to be minted to the msg.sender
     */
    function mintWhitelist(bytes calldata _signature, uint256 _number) public payable onlyEOA updateShift(1) {
        // check pause and freeze
        require(!whitelistMintPaused, WHITELIST_PAUSED);
        require(!frozen, FROZEN);

        // check whitelist authorization first
        bytes32 authorizationDigest = getWhitelistDigest(msg.sender);
        bytes32 message = ECDSA.toEthSignedMessageHash(authorizationDigest);
        address authority = recoverSigner(message, _signature);
        require(authority == owner(), UNAUTHORIZED);

        // check the price and limits
        require(msg.value == _number * WHITELIST_PRICE, WRONG_PRICE);

        // mint the NFTs
        minted[msg.sender] += _number;
        _safeMint(msg.sender, _number);

        // check supply
        require(totalSupply() <= TOTAL_LIMIT, LIMIT_EXCEEDED);
        require(minted[msg.sender] <= PER_WALLET_MINT, LIMIT_EXCEEDED);
    }

    /**
     * A method for gift mints by the owner. No ETH needed, but still
     * subject to the overall limit on the number of NFTs minted.
     * Updates the shift variable as a side effect.
     *
     * _recipient The address to mint the NFTs to
     * _number How many NFTs should be minted
     */
    function mintGift(address _recipient, uint256 _number) public onlyOwner updateShift(1) {
        // check freeze
        require(!frozen, FROZEN);

        _safeMint(_recipient, _number);
        
        // check supply
        require(totalSupply() <= TOTAL_LIMIT, LIMIT_EXCEEDED);
    }

    /**
     * Returns the digest to be signed using `await web3.eth.sign(digest, signer);`.
     */
    function getWhitelistDigest(address minter) public pure returns (bytes32) {
        return keccak256(abi.encode(minter));
    }

    /**
     * Extracts the signer from a digest and the signature. Can be used 
     * together with the `getWhitelistDigest()` method and `await web3.eth.sign()`.
     */
    function recoverSigner(bytes32 digest, bytes calldata _signature) public pure returns (address) {
        return ECDSA.recover(digest, _signature);
    }

    /**
     * Returns the base URI for the NFTs. The override method used by the
     * contract dependencies.
     */
    function _baseURI() internal view override returns (string memory) {
        return uriConfig;
    }

    /**
     * Returns the token metadata URI. If the reveal did not happen yet,
     * returns the same base URI for all the tokens. If the reveal happened
     * already, returns base URI with the shifted token ID, unless the
     * token has a one-off URI defined by the owner.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), DOES_NOT_EXIST);

        // If the drop is not revealed, returns the base URI for every NFT
        if (!revealed) {
            return _baseURI();
        }

        // If a custom URI is configured, return it
        if (bytes(oneOffs[_tokenId]).length > 0) {
            return oneOffs[_tokenId];
        }

        // Otherwise use the default behaviour, but skip the existence check
        string memory baseURI = _baseURI();
        uint256 shiftedId = shifted(_tokenId);
        return bytes(baseURI).length != 0 
            ? string(abi.encodePacked(baseURI, shiftedId.toString(), '.json')) 
            : '';
    }

    /**
     * Returns the shifted ID of the token. Shifting is frozen during the
     * reveal process and is intended to guarantee fairness in the distribution
     * of the NFTs.
     */
    function shifted(uint256 _tokenId) public view returns(uint256) {
        if (_tokenId < RESERVED) {
            return _tokenId;
        }
        uint256 mod = TOTAL_LIMIT - RESERVED;
        return (_tokenId + (uint256(shift) % mod)) % mod + RESERVED;
    }

    /**
     * An owner-only configuration method for setting the metadata URI for the
     * pre-reveal phase. In this phase, all the NFTs will have the same
     * metadata. The URI in this phase can be repeatedly changed by the owner.
     *
     * _uriConfig The metadata URI for the NFTs
     */
    function configurePrereveal(string calldata _uriConfig) public onlyOwner {
        require(!revealed, ALREADY_REVEALED);
        uriConfig = _uriConfig;
    }

    /**
     * The method for initiating the reveal process. It stores the hash of the
     * base URI that will be set for the NFT collection. The mint cannot be
     * frozen as freezing will again re-shuffle the metadata. However, the hash 
     * can be set repeatedly for the ability to correct errors.
     *
     * _hash The hash of the base URI for the NFT collection
     */
    function commitReveal(bytes32 _hash) public onlyOwner {
        require(!frozen, FROZEN);
        require(!revealed, ALREADY_REVEALED);
        revealHash = _hash;
    }

    /**
     * The method for freezing the minting process. Updates the shift one
     * last time based on the hashed in the past 32 blocks. No minting
     * will be possible after calling this method, and the shift will be
     * frozen as well. Hash of the base URI will be frozen too.
     */
    function freeze() public onlyOwner updateShift(32) {
        require(revealHash != bytes32(0), HASH_NOT_SET);
        frozen = true;
    }

    /**
     * A method for finalizing the reveal process. Sets the base URI that
     * matches the hash. The mint has to be frozen, otherwise the call
     * reverts.
     *
     * _uriConfig The base URI for the NFT collection
     */
    function reveal(string calldata _uriConfig) public onlyOwner {
        require(keccak256(abi.encodePacked(_uriConfig)) == revealHash, HASH_MISMATCH);
        require(frozen, NOT_FROZEN);
        require(!revealed, ALREADY_REVEALED);
        uriConfig = _uriConfig;
        revealed = true;
    }

    /**
     * Configures a custom metadata URI for a single token that the owner
     * owns. Allows the owner to create special gift and collaboration NFTs.
     *
     * _id The token ID to set the custom URI for
     * _customUri The URI for this NFT
     */
    function configureTokenURI(uint256 _id, string calldata _customUri) external onlyOwner {
        require(ownerOf(_id) == owner(), UNAUTHORIZED);

        oneOffs[_id] = _customUri;
    }

    /**
     * Pauses and unpauses the mint for the whitelist.
     */
    function pauseWhitelistMint(bool _pause) external onlyOwner {
        whitelistMintPaused = _pause;
    }

    /**
     * Pauses and unpauses the mint for the general public.
     */
    function pausePublicMint(bool _pause) external onlyOwner {
        publicMintPaused = _pause;
    }


    /**
     * Configures the payment smart contract. The contract
     * can be address(0).
     */
    function setSplit(address _split) public onlyOwner {
        split = _split;
    }

    /**
     * Sends funds to the payment smart contract.
     */
    function drain(address _token, uint256 _amount) public {
        require(split != address(0), NO_SPLIT);

        if (_token == address(0)) {
            Split(payable(split)).pay{value: _amount}(address(0), _amount);
        } else {
            IERC20(_token).safeApprove(split, 0);
            IERC20(_token).safeApprove(split, _amount);
            Split(payable(split)).pay(_token, _amount);
        }
    }

    /**
     * Sets royalties, with base 1000
     */
    function setRoyalties(uint256 _royalty, address _recipient) public onlyOwner {
        emit RoyaltiesSet(royalty, _royalty, _recipient);
        royalty = _royalty;
        royaltyRecipient = _recipient;
    }

    /**
     * EIP-2981 support, returns the royalty amount to be paid to this
     * address. Uses the splitter mechanism for distributing the funds
     * in order to save gas fees for the traders.
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view 
    returns (address, uint256) {
        return (address(royaltyRecipient), _salePrice * royalty / 1000);
    }

    /**
     * Indicates the support for the ERC2981 interface, plus super
     */
    function supportsInterface(bytes4 _interfaceId) public override view returns (bool) {
        if (_interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(_interfaceId);
    }
}

