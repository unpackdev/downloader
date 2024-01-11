// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SignedAllowance.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./NeoLocker.sol";

/// @title NeoAnunnaki
/// @author aceplxx (https://twitter.com/aceplxx)

enum SaleState {
    Paused,
    Presale,
    Public
}

contract NeoAnunnaki is ERC721A, Ownable, SignedAllowance, PaymentSplitter {
    /* ========== STORAGE ========== */

    SaleState public saleState;
    NeoLocker private neoLocker;

    string public baseURI;
    string public lockedURI;
    string public contractURI;

    uint256 public maxPerTx = 3;
    uint256 public constant MAX_SUPPLY = 3690;
    uint256 public constant TEAM_RESERVES = 30;

    uint256 public price = 0.06 ether;

    bool public notRevealed = true;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        string memory baseURI_, 
        address allowancesSigner_, 
        address[] memory _payees, 
        uint256[] memory _shares
    )
        ERC721A("Neo Anunnaki", "NEO-ANUNNAKI")
        PaymentSplitter(_payees, _shares)
    {
        baseURI = baseURI_;
        _setAllowancesSigner(allowancesSigner_);
    }

    /* ========== MODIFIERS ========== */

    modifier mintCompliance(uint256 _amount){
        require(_amount > 0, "Bad mints");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Exceeds max supply");
        require(_amount <= maxPerTx, "Exceeds max amount");
        _;
    }

    modifier notPaused(){
        require(saleState != SaleState.Paused, "Minting paused");
        _;
    }

    /* ========== OWNER FUNCTIONS ========== */

    /// @notice set the state of the sale
    /// @param _state the state in int accordingly
    function setSaleState(SaleState _state) external onlyOwner {
        saleState = _state;
    }

    /// @notice toggle the reveal / unreveal status
    function toggleReveal() external onlyOwner {
        notRevealed = !notRevealed;
    }

    function setLocker(address _locker) external onlyOwner {
        neoLocker = NeoLocker(_locker);
    }

    function mintConfig(
        uint256 _price, 
        uint256 _maxPerTx
    ) external onlyOwner {
        price = _price;
        maxPerTx = _maxPerTx;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    /// @notice set lockedURI. If NFT is locked, lockedURI will be displayed instead of baseURI
    /// @param _lockedURI uri string for the locked NFT
    function setLockedURI(string memory _lockedURI) external onlyOwner {
        lockedURI = _lockedURI;
    }

    /// @notice sets allowance signer, this can be used to revoke all unused allowances already out there
    /// @param newSigner the new signer
    function setAllowancesSigner(address newSigner) external onlyOwner {
        _setAllowancesSigner(newSigner);
    }

    function mintReserves() external onlyOwner {
        require(saleState == SaleState.Paused, "Not paused");
        _safeMint(msg.sender, TEAM_RESERVES);
    }

    function withdraw() public virtual override {
        require(msg.sender == owner(), "Only owner!");
        super.withdraw();
    }

    /* ========== PUBLIC READ FUNCTIONS ========== */

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist.");

        if(neoLocker.lockedBy(tokenId) == address(0)) {
            return
                notRevealed ? baseURI : bytes(baseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            baseURI,
                            Strings.toString(tokenId),
                            ".json"
                        )
                    )
                    : "";
        } else {
            return lockedURI;
        }
        
    }

    /* ========== PUBLIC MUTATIVE FUNCTIONS ========== */

    /// @notice public mint function
    /// @param _amount amount of token to mint
    function mint(uint256 _amount) external payable notPaused mintCompliance(_amount) {
        require(saleState == SaleState.Public, "Public sale not started");
        require(msg.value >= _amount * price, "Insufficient fund");
        _safeMint(msg.sender, _amount);
    }

    /// @notice presale mint function
    /// @param nonce the nonce
    /// @param signature ECDSA based signed whitelist
    /// @param _amount amount of token to mint
    function presaleMint(uint256 nonce, bytes memory signature, uint256 _amount) 
        external 
        payable 
        notPaused 
        mintCompliance(_amount) {
        require(saleState == SaleState.Presale, "Presale not started");
        require(msg.value >= _amount * price, "Insufficient fund");

        validateSignature(msg.sender, nonce, signature);
        _safeMint(msg.sender, _amount);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (neoLocker.lockedBy(startTokenId) != to) {
            require(
                neoLocker.lockedBy(startTokenId) == address(0),
                "Transfer while locked"
            );
        } else {
            neoLocker.clearLock(startTokenId);
        }

        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}
