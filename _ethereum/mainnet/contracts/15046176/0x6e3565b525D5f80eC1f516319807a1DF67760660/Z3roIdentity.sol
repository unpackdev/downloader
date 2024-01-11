// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";

import "./Z3roOwnership.sol";
import "./Z3roUtility.sol";

contract Z3roIdentity is Ownable, ERC721A, ReentrancyGuard {
    using ECDSA for bytes32;

    address public immutable contractOwner;
    address private immutable multiSig;
    uint256 public STAGE_MAX_SUPPLY_1;
    uint256 public STAGE_MAX_SUPPLY_2;
    uint256 public STAGE_MAX_SUPPLY_3;

    string private baseTokenURI;

    bytes32 public whitelist;
    bytes32 public freelist;

    struct Configs {
        bool revealed;
        bool onlyWhitelist;
        bool allowFl;
        uint8 stage;
        uint8 max_wallet_sets;
        uint8 max_wallet_sets_2;
        uint8 max_wallet_sets_3;
        uint8 max_fl_sets;
        uint16 max_wl_supply;
        uint256 mint_cost;
    }

    Configs public configs;

    Z3roOwnership public z3roOwnership;
    Z3roUtility public z3roUtility;

    constructor(
        uint256 stageSupply,
        uint8 maxWalletSets,
        address _multiSig
    ) ERC721A("z3rocollective", "Z3RO") {
        contractOwner = _msgSenderERC721A();
        STAGE_MAX_SUPPLY_1 = stageSupply;

        multiSig = _multiSig;

        z3roOwnership = new Z3roOwnership(address(this), multiSig);
        z3roUtility = new Z3roUtility(address(this), multiSig);

        configs = Configs(
            false, // revealed
            true, // onlyWhitelist
            true, // allowFl
            1, // stage
            maxWalletSets, // max_wallet_sets
            0, // max_wallet_sets_2
            0, // max_wallet_sets_3
            1, // max_fl_sets
            1111, // max_wl_supply
            0.1 ether // mint_cost
        );

        emit zo(address(z3roOwnership));
        emit zu(address(z3roUtility));
    }

    /* EVENTS & MODIFIERS*/
    event minted(address to, uint256 qty);

    event zo(address zo);
    event zu(address zu);

    modifier isUser() {
        require(
            tx.origin == _msgSenderERC721A(),
            "The caller is another contract, must be user."
        );
        _;
    }

    function stage1Owned() internal view returns (uint256 counter) {
        for (uint256 i = 0; i < STAGE_MAX_SUPPLY_1; i++) {
            if (ownerOf(i) == _msgSenderERC721A()) {
                counter++;
            }
        }
    }

    function stage1and2Owned() internal view returns (uint256 counter) {
        for (uint256 i = 0; i < STAGE_MAX_SUPPLY_1 + STAGE_MAX_SUPPLY_2; i++) {
            if (ownerOf(i) == _msgSenderERC721A()) {
                counter++;
            }
        }
    }

    modifier isEligibleMint(uint256 batchQty) {
        require(configs.revealed, "Not revealed yet.");

        /* Configs sanity check */
        require(configs.stage > 0, "Minting not started yet.");
        require(configs.mint_cost > 0, "Awkward...");
        require(configs.max_wallet_sets > 0, "Max wallet sets not defined.");
        require(configs.max_wl_supply > 0, "Max Whitelist supply not defined.");

        if (configs.stage == 1) {
            // there is a limit to the supply
            require(
                _totalMinted() + batchQty <= STAGE_MAX_SUPPLY_1,
                "Stage 1 sold out"
            );
        } else if (configs.stage == 2) {
            require(
                _totalMinted() + batchQty <=
                    STAGE_MAX_SUPPLY_1 + STAGE_MAX_SUPPLY_2,
                "Stage 2 sold out"
            );
        } else if (configs.stage == 3) {
            require(
                _totalMinted() + batchQty <=
                    STAGE_MAX_SUPPLY_1 +
                        STAGE_MAX_SUPPLY_2 +
                        STAGE_MAX_SUPPLY_3,
                "Stage 3 sold out"
            );
        }
        _;
    }

    modifier isEligibleMintFl(uint256 batchQty) {
        require(configs.revealed, "Not revealed yet.");

        if (configs.stage == 1) {
            // there is a limit to the supply
            require(
                _totalMinted() + batchQty <= STAGE_MAX_SUPPLY_1,
                "Stage 1 sold out"
            );
        } else if (configs.stage == 2) {
            require(
                _totalMinted() + batchQty <=
                    STAGE_MAX_SUPPLY_1 + STAGE_MAX_SUPPLY_2,
                "Stage 2 sold out"
            );
        } else if (configs.stage == 3) {
            require(
                _totalMinted() + batchQty <=
                    STAGE_MAX_SUPPLY_1 +
                        STAGE_MAX_SUPPLY_2 +
                        STAGE_MAX_SUPPLY_3,
                "Stage 3 sold out"
            );
        }
        _;
    }

    modifier isOnList(
        uint256 batchQty,
        bytes32[] calldata proof,
        bytes32 leaf
    ) {
        if (configs.onlyWhitelist) {
            require(whitelist != "", "wl root not set");
            require(
                _totalMinted() + batchQty <= configs.max_wl_supply,
                "You tried to mint more than the currently available supply."
            );

            require(
                MerkleProof.verify(proof, whitelist, leaf),
                "You are not on the whitelist"
            );
        }
        _;
    }

    modifier isAllowFl(
        uint256 batchQty,
        bytes32[] calldata proof,
        bytes32 leaf
    ) {
        require(configs.allowFl);
        require(freelist != "", "fl root not set");
        require(_totalMinted() + batchQty <= configs.max_fl_sets);
        require(
            MerkleProof.verify(proof, freelist, leaf),
            "You are not on the fl"
        );
        _;
    }

    modifier isUnderWalletLimit(uint256 batchQty) {
        if (configs.stage == 1) {
            // user cannot go over max mints per wallet
            require(
                batchQty + _numberMinted(_msgSenderERC721A()) <=
                    configs.max_wallet_sets,
                "Tried to mint more than permited per wallet"
            );
        } else if (configs.stage == 2) {
            // check amout of tokens between 0 <= STAGE_MAX_SUPPLY_1
            uint256 previousMints = stage1Owned();
            require(
                (batchQty + _numberMinted(_msgSenderERC721A())) -
                    previousMints <=
                    configs.max_wallet_sets_2,
                "Tried to mint more than permited per wallet"
            );
        } else if (configs.stage == 3) {
            // check amout of tokens between 0 <= STAGE_MAX_SUPPLY_1 + STAGE_MAX_SUPPLY_2
            uint256 previousMints = stage1and2Owned();
            require(
                (batchQty + _numberMinted(_msgSenderERC721A())) -
                    previousMints <=
                    configs.max_wallet_sets_3,
                "Tried to mint more than permited per wallet"
            );
        }
        _;
    }

    /* FUNCTIONS */

    /* external */
    function enterZ3ro(
        uint256 qty,
        bytes32[] calldata proof,
        bytes32 leaf
    )
        external
        payable
        nonReentrant
        isUser
        isEligibleMint(qty)
        isUnderWalletLimit(qty)
        isOnList(qty, proof, leaf)
    {
        require(msg.value >= configs.mint_cost, "Not enough eth sent");
        //mint Identity
        _safeMint(_msgSenderERC721A(), qty);
        //mint Ownership
        Z3roOwnership(z3roOwnership).identifyZ3ro(qty);
        //mint Utility
        Z3roUtility(z3roUtility).useZ3ro(qty);

        emit minted(_msgSenderERC721A(), qty);
    }

    function enterZ3rofl(
        uint256 qty,
        bytes32[] calldata proof,
        bytes32 leaf
    )
        external
        nonReentrant
        isUser
        isEligibleMintFl(qty)
        isUnderWalletLimit(qty)
        isAllowFl(qty, proof, leaf)
    {
        //mint Identity
        _safeMint(_msgSenderERC721A(), qty);
        //mint Ownership
        Z3roOwnership(z3roOwnership).identifyZ3ro(qty);
        //mint Utility
        Z3roUtility(z3roUtility).useZ3ro(qty);

        emit minted(_msgSenderERC721A(), qty);
    }

    /* GETTERS AND SETTERS */

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function setRevealed(bool isRevealed) external onlyOwner {
        configs.revealed = isRevealed;
    }

    function setOnlyWhitelist(bool isOnlyWl) external onlyOwner {
        configs.onlyWhitelist = isOnlyWl;
    }

    function setStage(uint8 stage) external onlyOwner {
        configs.stage = stage;
    }

    function setStageSupply1(uint256 supply) external onlyOwner {
        require(configs.stage == 1);
        STAGE_MAX_SUPPLY_1 = supply;
    }

    function setStageSupply2(uint256 supply) external onlyOwner {
        require(configs.stage == 2);
        STAGE_MAX_SUPPLY_2 = supply;
    }

    function setStageSupply3(uint256 supply) external onlyOwner {
        require(configs.stage == 3);
        STAGE_MAX_SUPPLY_3 = supply;
    }

    function setMaxWalletSets(uint8 max) external onlyOwner {
        configs.max_wallet_sets = max;
    }

    function setMaxWalletSets2(uint8 max) external onlyOwner {
        configs.max_wallet_sets_2 = max;
    }

    function setMaxWalletSets3(uint8 max) external onlyOwner {
        configs.max_wallet_sets_3 = max;
    }

    function setMaxWlSupply(uint16 max) external onlyOwner {
        configs.max_wl_supply = max;
    }

    function setMintCost(uint256 cost) external onlyOwner {
        configs.mint_cost = cost;
    }

    function setWhitelistMerkleRoot(bytes32 root) external onlyOwner {
        whitelist = root;
    }

    function setFlMerkleRoot(bytes32 root) external onlyOwner {
        freelist = root;
    }

    function setAllowFl(bool allow) external onlyOwner {
        configs.allowFl = allow;
    }

    function withdrawFunds() external nonReentrant onlyOwner {
        (bool success, ) = payable(multiSig).call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed.");
    }

    function getZ3roOwnership() external view returns (Z3roOwnership) {
        return z3roOwnership;
    }

    function getZ3roUtility() external view returns (Z3roUtility) {
        return z3roUtility;
    }

    function getRevealed() external view returns (bool) {
        return configs.revealed;
    }

    function getStage() external view returns (uint8) {
        return configs.stage;
    }

    function getTotalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() external view returns (uint256) {
        return _totalBurned();
    }

    function numberBurned(address owner) external view returns (uint256) {
        return _numberBurned(owner);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    /* internal */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}
