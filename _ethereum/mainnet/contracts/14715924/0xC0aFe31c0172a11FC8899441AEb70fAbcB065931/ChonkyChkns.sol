// SPDX-License-Identifier: MIT

/**


         /\
        _\/_
        \__/
       /    \
      ○      ○
     /   v    \
    /          \


 */

pragma solidity >=0.8.0 <0.9.0;

import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./Math.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./FeedToken.sol";
import "./TokenURIManager.sol";
import "./CustomTraitsManager.sol";

contract ChonkyChkns is ERC721A, ERC721AQueryable, Ownable, ReentrancyGuard {
    using MerkleProof for bytes32[];

    // MINTING STATE
    enum MintState {
        PRESALE,
        PUBLIC,
        CLOSED
    }
    MintState public mintState;

    // MintState-based variables. Index 0 = PRESALE, 1 = PUBLIC.
    uint256[2] mintCosts;

    // Membership lists with restricted access
    enum ExclusiveList {
        GENESIS,
        CHONKLIST
    }
    // ExclusiveList-based variables. . Index 0 = GENESIS, 1 = CHONKLIST.
    bytes32[2] private merkleRoots;

    uint256 public MAX_GENESIS_MINT_AMOUNT_PER_WALLET;
    uint256 public MAX_CHONKLIST_MINT_AMOUNT_PER_WALLET;

    // Supply specs by token type
    uint256 public MAX_SUPPLY;
    uint256 public MAX_GENESIS_SUPPLY;
    // Records the number of genesis tokens that have been minted.
    uint256 public totalGenesisSupply;

    // Mapping of tokenId to whether it's a genesis token.
    mapping(uint256 => bool) public isGenesis;

    // Map of wallet address -> number of genesis/chonklist tokens minted.
    // Used to enforce max mints per wallet.
    mapping(address => uint256) public numGenesisMinted;
    mapping(address => uint256) public numChonklistMinted;

    // Maps of wallet addresses => number of Genesis/Standard NFTs they own.
    // Used for feed balance calculations.
    mapping(address => uint256) public numGenesisOwned;
    mapping(address => uint256) public numStandardOwned;

    // Related contracts, for FEED token generation, user-customized traits,
    // and tokenURI construction based on custom traits
    IFeedToken public feedToken;
    ITraitsManager public customTraitsManager;
    ITokenURIManager public tokenURIManager;

    constructor() ERC721A("ChonkyChkns", "CHONKYCHKNS") {
        MAX_SUPPLY = 4994;
        MAX_GENESIS_SUPPLY = 250;

        MAX_GENESIS_MINT_AMOUNT_PER_WALLET = 1;
        MAX_CHONKLIST_MINT_AMOUNT_PER_WALLET = 3;

        mintCosts = [0.03 ether, 0.03 ether];

        mintState = MintState.CLOSED;
    }

    // GETTERS / QUERY FUNCTIONS

    function totalStandardSupply() external view returns (uint256) {
        // totalGenesisSupply will never exceed totalSupply minted.
        unchecked {
            return totalSupply() - totalGenesisSupply;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        // Role of determining tokenURI per token is delegated to tokenURIManager.
        // This allows the tokenURI format to flexibly change as new features
        // are added to the project, e.g. new traits that may affect metadata.
        return tokenURIManager.tokenURI(tokenId);
    }

    // CHECKS

    function mintPrechecks(uint256 _mintAmount, MintState _mintState)
        internal
        view
    {
        require(mintState == _mintState, "Mint stage not open");
        require(
            msg.value >= mintCosts[uint256(_mintState)] * _mintAmount,
            "Insufficient funds"
        );
    }

    function restrictedMintPrechecks(
        uint256 _mintAmount,
        MintState _mintState,
        ExclusiveList _exclusiveList,
        bytes32[] calldata proof
    ) internal view {
        mintPrechecks(_mintAmount, _mintState);

        require(
            proof.verify(
                merkleRoots[uint256(_exclusiveList)],
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "Not authorized"
        );
    }

    // MINT FUNCTIONS

    function genesisPresaleMint(uint256 _mintAmount, bytes32[] calldata proof)
        external
        payable
        nonReentrant
    {
        restrictedMintPrechecks(
            _mintAmount,
            MintState.PRESALE,
            ExclusiveList.GENESIS,
            proof
        );
        uint256 genesisQty = _calculateAndRegisterGenesisQuantity(_mintAmount);
        _registerPresaleStandardQuantity(_mintAmount - genesisQty);
        _mintAndUpdateBalance(_mintAmount, genesisQty);
    }

    function presaleMint(uint256 _mintAmount, bytes32[] calldata proof)
        external
        payable
        nonReentrant
    {
        restrictedMintPrechecks(
            _mintAmount,
            MintState.PRESALE,
            ExclusiveList.CHONKLIST,
            proof
        );
        _registerPresaleStandardQuantity(_mintAmount);
        _mintAndUpdateBalance(_mintAmount, 0);
    }

    // Call this function if/when MintState = PUBLIC and there are still remaining genesis tokens.
    // All users (including non-OG roles) will be able to mint up to the max per wallet of
    // genesis tokens on a first-come first-serve basis.
    // This function shouldn't be called after all genesis tokens have been minted -
    // it will function the same as publicMint but cost additional gas.
    function genesisPublicMint(uint256 _mintAmount)
        external
        payable
        nonReentrant
    {
        mintPrechecks(_mintAmount, MintState.PUBLIC);
        uint256 genesisQty = _calculateAndRegisterGenesisQuantity(_mintAmount);
        _mintAndUpdateBalance(_mintAmount, genesisQty);
    }

    function publicMint(uint256 _mintAmount) external payable nonReentrant {
        mintPrechecks(_mintAmount, MintState.PUBLIC);
        _mintAndUpdateBalance(_mintAmount, 0);
    }

    // TRANFER FUNCTION

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        ERC721A.safeTransferFrom(from, to, tokenId, _data);
        _updateBalancesOnTransfer(from, to, tokenId);
    }

    // OWNER UTILITIES

    function mintForAddresses(
        address[] calldata _receivers,
        uint256[] calldata _amounts
    ) external onlyOwner {
        for (uint256 i; i < _receivers.length; ) {
            _safeMint(_receivers[i], _amounts[i]);
            _updateBalancesOnStandardMint(_receivers[i], _amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdraw failed!");
    }

    // SETTERS

    function setFeedToken(address _yield) external onlyOwner {
        feedToken = IFeedToken(_yield);
    }

    function setCustomTraitsManager(address _traitsManager) external onlyOwner {
        customTraitsManager = ITraitsManager(_traitsManager);
    }

    function setTokenURIManager(address _tokenURIManager) external onlyOwner {
        ITokenURIManager newTokenURIManager = ITokenURIManager(
            _tokenURIManager
        );
        // If there was a pre-existing TokenURIManager, record the previous base URI
        // and set it in the new manager
        if (address(tokenURIManager) != address(0)) {
            newTokenURIManager.setBaseUri(tokenURIManager.baseURI());
        }
        tokenURIManager = newTokenURIManager;
    }

    function setBaseUri(string calldata _baseUri) external onlyOwner {
        if (address(tokenURIManager) != address(0)) {
            tokenURIManager.setBaseUri(_baseUri);
        }
    }

    function setMintState(MintState _state) external onlyOwner {
        mintState = _state;
    }

    function setMerkleRootForExclusiveList(
        bytes32 _root,
        ExclusiveList _exclusiveList
    ) external onlyOwner {
        merkleRoots[uint256(_exclusiveList)] = _root;
    }

    // NOTE: UNIT IS WEI!
    function setMintCostForMintState(uint256 _cost, MintState _mintState)
        external
        onlyOwner
    {
        mintCosts[uint256(_mintState)] = _cost;
    }

    function setMaxSupply(uint256 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setMaxGenesisSupply(uint256 _supply) external onlyOwner {
        MAX_GENESIS_SUPPLY = _supply;
    }

    function setMaxGenesisMintAmountPerWallet(uint256 _maxMintAmountPerWallet)
        external
        onlyOwner
    {
        MAX_GENESIS_MINT_AMOUNT_PER_WALLET = _maxMintAmountPerWallet;
    }

    function setMaxChonklistMintAmountPerWallet(uint256 _maxMintAmountPerWallet)
        external
        onlyOwner
    {
        MAX_CHONKLIST_MINT_AMOUNT_PER_WALLET = _maxMintAmountPerWallet;
    }

    // INTERNAL FUNCTIONS

    // Mint helpers

    function _calculateAndRegisterGenesisQuantity(uint256 _maxMintAmount)
        internal
        returns (uint256)
    {
        // Allocate as many of _maxMintAmount as possible to be genesis tokens,
        // under wallet and supply constraints.
        unchecked {
            uint256 genesisQty = Math.min(
                Math.min(
                    MAX_GENESIS_MINT_AMOUNT_PER_WALLET -
                        numGenesisMinted[_msgSender()],
                    _maxMintAmount
                ),
                MAX_GENESIS_SUPPLY - totalGenesisSupply
            );

            // If any genesis tokens are being minted in this transaction, perform pre-mint
            // registration steps for them (set isGenesis status for each tokenId,
            // increment numGenesisMinted for user, increment totalGenesisSupply)
            if (genesisQty > 0) {
                uint256 tokenId = _currentIndex;
                for (uint256 i = 0; i < genesisQty; ++i) {
                    isGenesis[tokenId + i] = true;
                }
                numGenesisMinted[_msgSender()] += genesisQty;
                totalGenesisSupply += genesisQty;
            }
            return genesisQty;
        }
    }

    function _registerPresaleStandardQuantity(uint256 _standardTokenQuantity)
        internal
    {
        // If any standard tokens are being minted in this presale transaction,
        // verify that the total minted quantity for the user is within max per wallet constraints,
        // then increment numChonkListMinted for user.
        if (_standardTokenQuantity > 0) {
            require(
                _standardTokenQuantity + numChonklistMinted[_msgSender()] <=
                    MAX_CHONKLIST_MINT_AMOUNT_PER_WALLET,
                "Exceeded max per wallet"
            );
            numChonklistMinted[_msgSender()] += _standardTokenQuantity;
        }
    }

    function _mintAndUpdateBalance(
        uint256 _mintAmount,
        uint256 _genesisMintAmount
    ) internal {
        _safeMint(_msgSender(), _mintAmount);

        _updateBalancesOnGenesisMint(_msgSender(), _genesisMintAmount);
        _updateBalancesOnStandardMint(
            _msgSender(),
            _mintAmount - _genesisMintAmount
        );
    }

    // Balance updates on transfers/mints

    function _updateBalancesOnTransfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        feedToken.updateFeedCountOnTransfer(from, to);
        // No risk of overflow or underflow:
        // num{Genesis,Standard}Owned[from] will always be > 0
        // All num{Genesis,Standard}Owned balances are <= MAX_SUPPLY
        unchecked {
            if (isGenesis[tokenId]) {
                numGenesisOwned[from]--;
                numGenesisOwned[to]++;
            } else {
                numStandardOwned[from]--;
                numStandardOwned[to]++;
            }
        }
    }

    function _updateBalancesOnGenesisMint(address _to, uint256 _mintAmount)
        private
    {
        if (_mintAmount > 0) {
            feedToken.updateFeedCountOnMint(_to);
            // No risk of overflow
            unchecked {
                numGenesisOwned[_to] += _mintAmount;
            }
        }
    }

    function _updateBalancesOnStandardMint(address _to, uint256 _mintAmount)
        private
    {
        if (_mintAmount > 0) {
            feedToken.updateFeedCountOnMint(_to);
            // No risk of overflow
            unchecked {
                numStandardOwned[_to] += _mintAmount;
            }
        }
    }

    // Before mint hook
    function _beforeTokenTransfers(
        address from,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        // Check for sufficient supply available before mints
        if (from == address(0)) {
            require(
                startTokenId + quantity <= MAX_SUPPLY,
                "Max supply exceeded"
            );
        }
    }
}
