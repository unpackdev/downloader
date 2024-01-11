// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

interface IGoldenPass {
    function burn(address from, uint256 amount) external;
}

contract FoodzParty is ERC721, Ownable {
    using Strings for uint160;
    using Strings for uint256;

    /// @dev 0x843ce46b
    error InvalidClaimAmount();
    /// @dev 0xb05e92fa
    error InvalidMerkleProof();
    /// @dev 0x5d25f4ec
    error MaxPerTx();
    /// @dev 0xb36c1284
    error MaxSupply();
    /// @dev 0xb9968551
    error PassSaleOff();
    /// @dev 0xa6802b50
    error PresaleOff();
    /// @dev 0x3afc8ce9
    error SaleOff();
    /// @dev 0xb52aa4c0
    error QueryForNonExistentToken();
    /// @dev 0x750b219c
    error WithdrawFailed();
    /// @dev 0x98d4901c
    error WrongValue();

    // Immutable

    /// @notice the max amount of tokens that can be minted via golden pass
    uint256 public constant GOLDEN_PASS_MAX_SUPPLY = 500;
    /// @notice the starting id for tokens minted via golden pass.
    ///         tokens minted via golden pass have ids from 9451 to 9950
    uint256 internal constant GOLDEN_PASS_START_INDEX = 9451;
    /// @notice the max amount of tokens that can be minted using eth
    uint256 public constant NON_GOLDEN_PASS_MAX_SUPPLY = 9451;
    /// @notice the price to mint each token on presale
    uint256 public constant PRESALE_PRICE = 0.07 ether;
    /// @notice the price to mint 1 token on public sale
    uint256 public constant SALE_SINGLE_PRICE = 0.1 ether;
    /// @notice the price to mint 3 tokens bundle on public sale
    uint256 public constant SALE_TRIPLE_PRICE = 0.24 ether;
    /// @notice the max amount of rare 1:1 tokens.
    uint256 internal constant RARE11_MAX_SUPPLY = 50;
    /// @notice the starting id for the handmade 1:1 tokens.
    uint256 internal constant RARE11_GOLDEN_PASS_START_INDEX = 9951;

    /// @notice the merkle root for the allow-list
    bytes32 internal immutable merkleRoot;
    /// @notice address of the golden pass contract
    IGoldenPass internal immutable goldenPass;
    /// @notice address to send the contract's eth to
    address internal immutable payoutAddress;

    // Mutable

    /// @notice if the presale via allow-list is active
    bool public isPresaleActive = false;
    /// @notice the current amount of tokens minted via golden pass
    uint256 public passSupply;
    /// @notice the current amount of tokens minted via eth
    /// @dev starts with 1 cuz bc mint #0 on constructor
    uint256 public nonpassSupply = 1;
    /// @notice if the public sale is active
    bool public isSaleActive = false;
    /// @notice the base url where the metadata is hosted
    string public baseURI;
    /// @notice if the golden pass sale is active
    bool public isPassSaleActive = false;
    /// @notice the current amount of rare 1:1 tokens minted
    uint256 public rare11Supply;

    /// @notice the amount of tokens a user claimed so far via allow-list.
    /// @dev this is used to prevent wallets that had N spots in the allow-list to mint N + 1
    mapping(address => uint256) public amountClaimedByUser;

    // Constructor

    constructor(
        IGoldenPass goldenPass_,
        string memory baseURI_,
        bytes32 merkleRoot_,
        address payoutAddress_
    ) ERC721("Foodz Party", "FP") {
        goldenPass = goldenPass_;
        baseURI = baseURI_;
        merkleRoot = merkleRoot_;
        // slither-disable-next-line missing-zero-check
        payoutAddress = payoutAddress_;
        _safeMint(0x067423C244442ca0Eb6d6fd6B747c2BD21414107, 0);
    }

    // Owner Only

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setIsSaleActive(bool newIsSaleActive) external onlyOwner {
        isSaleActive = newIsSaleActive;
    }

    function setIsPresaleActive(bool newIsPresaleActive) external onlyOwner {
        isPresaleActive = newIsPresaleActive;
    }

    function setIsPassSaleActive(bool newIsPassSaleActive) external onlyOwner {
        isPassSaleActive = newIsPassSaleActive;
    }

    function withdraw() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        // slither-disable-next-line low-level-calls missing-zero-check
        (bool payoutSent, ) = payable(payoutAddress).call{ // solhint-disable-line avoid-low-level-calls
            value: contractBalance
        }("");

        if (!payoutSent) revert WithdrawFailed();
    }

    function raremint(address to) external onlyOwner {
        unchecked {
            // slither-disable-next-line events-maths
            uint256 supply = ++rare11Supply;
            if (supply > RARE11_MAX_SUPPLY) revert MaxSupply();
            _safeMint(to, RARE11_GOLDEN_PASS_START_INDEX + supply - 1);
        }
    }

    // User

    function passmint(uint256 amount) external {
        if (!isPassSaleActive) revert PassSaleOff();
        uint256 supply = passSupply;
        unchecked {
            if (passSupply + amount > GOLDEN_PASS_MAX_SUPPLY)
                revert MaxSupply();
            // slither-disable-next-line events-maths
            passSupply += amount;
        }

        goldenPass.burn(msg.sender, amount);

        unchecked {
            uint256 baseIndex = GOLDEN_PASS_START_INDEX + supply;
            for (uint256 i = 0; i < amount; i++) {
                _safeMint(msg.sender, baseIndex + i);
            }
        }
    }

    function premint(
        uint256 amount,
        uint256 mintLimit,
        bytes32[] calldata proof
    ) external payable {
        if (!isPresaleActive) revert PresaleOff();
        unchecked {
            if (amountClaimedByUser[msg.sender] + amount > mintLimit)
                revert InvalidClaimAmount();
            if (msg.value != PRESALE_PRICE * amount) revert WrongValue();
            if (nonpassSupply + amount > NON_GOLDEN_PASS_MAX_SUPPLY)
                revert MaxSupply();
        }
        bytes32 leaf = keccak256(
            abi.encodePacked(
                uint160(msg.sender).toHexString(20),
                ":",
                mintLimit.toString()
            )
        );
        bool isProofValid = MerkleProof.verify(proof, merkleRoot, leaf);
        if (!isProofValid) revert InvalidMerkleProof();
        unchecked {
            amountClaimedByUser[msg.sender] += amount;
        }

        uint256 supply = nonpassSupply;
        unchecked {
            // slither-disable-next-line events-maths
            nonpassSupply += amount;
            for (uint256 i = 0; i < amount; i++) {
                _safeMint(msg.sender, supply + i);
            }
        }
    }

    function mintSingle() external payable {
        if (!isSaleActive) revert SaleOff();
        unchecked {
            // slither-disable-next-line events-maths
            uint256 updatedSupply = ++nonpassSupply;
            if (msg.value != SALE_SINGLE_PRICE) revert WrongValue();
            if (updatedSupply > NON_GOLDEN_PASS_MAX_SUPPLY) revert MaxSupply();
            _safeMint(msg.sender, updatedSupply - 1);
        }
    }

    function mintTriple() external payable {
        if (!isSaleActive) revert SaleOff();
        unchecked {
            if (msg.value != SALE_TRIPLE_PRICE) revert WrongValue();
            // slither-disable-next-line events-maths
            uint256 updatedSupply = (nonpassSupply += 3);
            if (updatedSupply > NON_GOLDEN_PASS_MAX_SUPPLY) revert MaxSupply();
            _safeMint(msg.sender, updatedSupply - 3);
            _safeMint(msg.sender, updatedSupply - 2);
            _safeMint(msg.sender, updatedSupply - 1);
        }
    }

    // View

    function currentSupply() external view returns (uint256) {
        unchecked {
            return passSupply + nonpassSupply + rare11Supply;
        }
    }

    // Overrides

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (_ownerOf[id] == address(0)) revert QueryForNonExistentToken();
        return string(abi.encodePacked(baseURI, id.toString()));
    }
}
