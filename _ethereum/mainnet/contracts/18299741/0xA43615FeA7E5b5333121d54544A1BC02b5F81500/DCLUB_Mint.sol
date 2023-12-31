// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";

interface DCLUB_Token {
    function mint(address receiver, uint256 quantity) external;

    function maxSupply() external view returns (uint256);
}

contract DCLUB_Mint is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable
{
    DCLUB_Token public token;
    uint256 public totalMinted;

    address public paymentWallet;
    bytes32 public ogMerkleRoot;
    bytes32 public vipMerkleRoot;
    uint256 public ownerMinted;

    uint256[3] public roundPrice;
    uint256 public roundSupply;
    uint256 public roundMinted;
    uint256 public currentPhase;
    uint256 public maxOwnerMints;
    uint256 public maxPublicMints;

    mapping(address => uint256) public ogMinters;
    mapping(address => uint256) public vipMinters;
    mapping(address => uint256) public publicMinters;

    bytes32 public constant STAFF_ROLE = keccak256("STAFF_ROLE");

    event Minted(address indexed user, uint256 quantity, uint256 timestamp);
    event NewPhase(uint256 phase, uint256 timestamp);
    event NewRound(
        uint256 supply,
        uint256 lastRoundMinted,
        uint256 totalMinted,
        uint256 timestamp
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _token,
        address _paymentWallet,
        uint256 _maxOwnerMints,
        uint256 _maxPublicMints,
        address[] memory _admins
    ) external initializer {
        require(_token != address(0), "DCLUB: Token cannot be zero.");
        require(
            _paymentWallet != address(0),
            "DCLUB: Payment wallet cannot be zero."
        );
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __AccessControl_init_unchained();
        __ReentrancyGuard_init_unchained();
        token = DCLUB_Token(_token);
        paymentWallet = _paymentWallet;
        maxOwnerMints = _maxOwnerMints;
        maxPublicMints = _maxPublicMints;

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        for (uint256 i = 0; i < _admins.length; i++) {
            _grantRole(STAFF_ROLE, _admins[i]);
        }
    }

    modifier callerIsUser() {
        require(
            tx.origin == _msgSender(),
            "DCLUB: Contract calls not allowed."
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            hasRole(STAFF_ROLE, _msgSender()) || owner() == _msgSender(),
            "DCLUB: Caller is not the admin."
        );
        _;
    }

    modifier canMint(uint256 quantity) {
        require(quantity > 0, "DCLUB: Quantity must be larger than 0.");
        require(roundMinted + 1 <= roundSupply, "DCLUB: Mint has sold out.");
        require(
            roundMinted + quantity <= roundSupply,
            "DCLUB: Mint quantity will exceed max supply."
        );
        _;
    }

    modifier checkPhase(uint256 phase) {
        if (currentPhase < phase) {
            revert("DCLUB: Minting for this phase has not started yet.");
        } else if (currentPhase > phase) {
            revert("DCLUB: Minting for this phase has ended.");
        }
        _;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function ogMint(
        uint256 quantity,
        uint256 allocation,
        bytes32[] calldata proof
    )
        external
        payable
        nonReentrant
        callerIsUser
        whenNotPaused
        canMint(quantity)
        checkPhase(1)
    {
        require(ogMerkleRoot != 0, "DCLUB: OG merkle root not set.");
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(_msgSender(), allocation)))
        );
        require(
            MerkleProofUpgradeable.verify(proof, ogMerkleRoot, leaf),
            "DCLUB: Invalid proof."
        );
        require(
            ogMinters[_msgSender()] + 1 <= allocation,
            "DCLUB: Already max minted allocation."
        );
        require(
            ogMinters[_msgSender()] + quantity <= allocation,
            "DCLUB: Mint quantity will exceed allocation."
        );

        ogMinters[_msgSender()] += quantity;
        _processMint(_msgSender(), quantity);
    }

    function vipMint(
        uint256 quantity,
        uint256 allocation,
        bytes32[] calldata proof
    )
        external
        payable
        nonReentrant
        callerIsUser
        whenNotPaused
        canMint(quantity)
        checkPhase(2)
    {
        require(ogMerkleRoot != 0, "DCLUB: OG merkle root not set.");
        require(vipMerkleRoot != 0, "DCLUB: VIP merkle root not set.");
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(_msgSender(), allocation)))
        );
        if (MerkleProofUpgradeable.verify(proof, ogMerkleRoot, leaf)) {
            require(
                ogMinters[_msgSender()] + 1 <= allocation,
                "DCLUB: Already max minted allocation."
            );
            require(
                ogMinters[_msgSender()] + quantity <= allocation,
                "DCLUB: Mint quantity will exceed allocation."
            );

            ogMinters[_msgSender()] += quantity;
        } else if (MerkleProofUpgradeable.verify(proof, vipMerkleRoot, leaf)) {
            require(
                vipMinters[_msgSender()] + 1 <= allocation,
                "DCLUB: Already max minted allocation."
            );
            require(
                vipMinters[_msgSender()] + quantity <= allocation,
                "DCLUB: Mint quantity will exceed allocation."
            );

            vipMinters[_msgSender()] += quantity;
        } else {
            revert("DCLUB: Invalid proof.");
        }

        _processMint(_msgSender(), quantity);
    }

    function publicMint(
        uint256 quantity
    )
        external
        payable
        nonReentrant
        callerIsUser
        whenNotPaused
        canMint(quantity)
        checkPhase(3)
    {
        require(
            publicMinters[_msgSender()] + 1 <= maxPublicMints,
            "DCLUB: Already max minted public allocation."
        );
        require(
            publicMinters[_msgSender()] + quantity <= maxPublicMints,
            "DCLUB: Mint quantity will exceed public allocation."
        );

        publicMinters[_msgSender()] += quantity;
        _processMint(_msgSender(), quantity);
    }

    function ownerMint(
        uint256 quantity
    ) external callerIsUser onlyAdmin canMint(quantity) {
        ownerMint(quantity, _msgSender());
    }

    function ownerMint(
        uint256 quantity,
        address receiver
    ) public callerIsUser onlyAdmin canMint(quantity) {
        require(receiver != address(0), "DCLUB: Receiver cannot be zero.");
        require(
            ownerMinted + 1 <= maxOwnerMints,
            "DCLUB: Already max minted owner allocation."
        );
        require(
            ownerMinted + quantity <= maxOwnerMints,
            "DCLUB: Mint quantity will exceed max owner allocation."
        );

        ownerMinted += quantity;
        _processMint(receiver, quantity, true);
    }

    function getRoundPrice() public view returns (uint256) {
        require(currentPhase > 0, "DCLUB: Mint has not started yet.");
        return roundPrice[currentPhase - 1];
    }

    function setRoundPrice(uint256[3] calldata _price) external onlyAdmin {
        roundPrice = _price;
    }

    function setRoundSupply(uint256 _roundSupply) external onlyAdmin {
        require(
            _roundSupply >= roundMinted,
            "DCLUB: Round supply cannot be lower than total minted this round."
        );
        require(
            (totalMinted + _roundSupply - roundMinted) <= token.maxSupply(),
            "DCLUB: Round supply exceeds token max supply."
        );
        roundSupply = _roundSupply;
    }

    function incrementPhase() external onlyAdmin {
        require(
            currentPhase < 3,
            "DCLUB: Final phase for this round has been reached."
        );
        currentPhase += 1;
        emit NewPhase(currentPhase, block.timestamp);
    }

    function setMaxOwnerMints(uint256 _maxOwnerMints) external onlyAdmin {
        maxOwnerMints = _maxOwnerMints;
    }

    function setMaxPublicMints(uint256 _maxPublicMints) external onlyAdmin {
        maxPublicMints = _maxPublicMints;
    }

    function setOgMerkleRoot(bytes32 _ogMerkleRoot) external onlyAdmin {
        ogMerkleRoot = _ogMerkleRoot;
    }

    function setVipMerkleRoot(bytes32 _vipMerkleRoot) external onlyAdmin {
        vipMerkleRoot = _vipMerkleRoot;
    }

    function newRound(
        uint256 _roundSupply,
        uint256[3] calldata _price
    ) external onlyAdmin {
        require(
            (totalMinted + _roundSupply) <= token.maxSupply(),
            "DCLUB: New round supply exceeds max token supply."
        );
        uint256 lastRoundMinted = roundMinted;
        roundSupply = _roundSupply;
        roundPrice = _price;
        currentPhase = 0;
        roundMinted = 0;
        emit NewRound(
            roundSupply,
            lastRoundMinted,
            totalMinted,
            block.timestamp
        );
    }

    function _processMint(address receiver, uint256 quantity) internal {
        _processMint(receiver, quantity, false);
    }

    function _processMint(
        address receiver,
        uint256 quantity,
        bool freeMint
    ) internal {
        if (!freeMint) {
            uint256 ethAmount = getRoundPrice() * quantity;
            require(msg.value >= ethAmount, "DCLUB: Incorrect ether value.");
            _sendValue(payable(paymentWallet), ethAmount);
            uint256 excess = msg.value - ethAmount;
            if (excess > 0) _sendValue(payable(receiver), excess);
        }
        roundMinted += quantity;
        totalMinted += quantity;
        token.mint(receiver, quantity);
        emit Minted(receiver, quantity, block.timestamp);
    }

    function _sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "DCLUB: Insufficient balance."
        );
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "DCLUB: Unable to send value, recipient may have reverted."
        );
    }

    function setPaymentWallet(address _paymentWallet) external onlyOwner {
        require(
            _paymentWallet != address(0),
            "DCLUB: Payment wallet cannot be zero."
        );
        paymentWallet = _paymentWallet;
    }
}
