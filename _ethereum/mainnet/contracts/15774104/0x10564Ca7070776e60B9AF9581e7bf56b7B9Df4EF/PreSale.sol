// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./MerkleProofUpgradeable.sol";

import "./BaseWhitelist.sol";

abstract contract PreSale is BaseWhitelist {
    // total quantity of NFTs available for presale
    uint256 public presaleQuantity;

    // tracks the number of NFTs minted on presale
    uint256 public presaleSupply;

    // presale minting price
    uint256 public presaleMintPrice;

    // maximum mints per whitelisted wallet
    uint256 public presaleMaxMintPerWallet;

    // maximum mints per transaction
    uint256 public presaleMaxMintPerTx;

    // presale start time
    uint256 public presaleStartingTimestamp;

    // presale end time
    uint256 public presaleEndingTimestamp;

    // merklee root
    bytes32 public merkleRoot;

    // presale status
    bool public isPreSaleActive;

    // tracks number of times a whitelisted address has minted
    mapping(address => uint256) public presaleMintCountPerWallet;

    struct PreSaleConfig {
        uint256 quantity;
        uint256 maxMint;
        uint256 maxMintTx;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
    }

    function __BasePreSale_init(PreSaleConfig memory presale)
        internal
        onlyInitializing
    {
        __BasePreSale_init_unchained(presale);
    }

    function __BasePreSale_init_unchained(PreSaleConfig memory presale)
        internal
        onlyInitializing
    {
        _setPresaleState();
        presaleQuantity = presale.quantity;
        presaleMaxMintPerWallet = presale.maxMint;
        presaleMaxMintPerTx = presale.maxMintTx;
        presaleMintPrice = presale.price;
        presaleStartingTimestamp = presale.startTime;
        presaleEndingTimestamp = presale.endTime;
    }

    /***********************************************************************
                                    MODIFIERS
     *************************************************************************/

    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "The caller is another contract");
        _;
    }

    modifier whenPreSaleIsActive() {
        require(isPreSaleActive, "Presale is not active");
        _;
    }

    function hasPreSaleStarted() public view returns (bool) {
        return
            block.timestamp >= presaleStartingTimestamp &&
            block.timestamp <= presaleEndingTimestamp;
    }

    /***********************************************************************
                                PUBLIC FUNCTIONS
     *************************************************************************/

    function preSaleMint(bytes32[] calldata _merkleProof, uint8 quantity)
        external
        payable
        callerIsUser
        whenPreSaleIsActive
        nonReentrant
    {
        require(hasPreSaleStarted(), "Presale is yet to start or its over");
        require(
            _isWhitelisted(_merkleProof, _msgSender()),
            "Address is not whitelisted"
        );
        require(presaleSupply < presaleQuantity, "Presale has sold out");
        require(
            presaleSupply + quantity <= presaleQuantity,
            "Exceeds presale NFTs remaining"
        );

        if (presaleMaxMintPerTx > 0) {
            require(
                quantity <= presaleMaxMintPerTx,
                "Exceeds mints allowed per transaction"
            );
        }

        if (presaleMaxMintPerWallet > 0) {
            require(
                presaleMintCountPerWallet[_msgSender()] + quantity <=
                    presaleMaxMintPerWallet,
                "Exceeds mints allowed per wallet"
            );
        }

        presaleMintCountPerWallet[_msgSender()] += quantity;
        presaleSupply += quantity;
        _safeMint(_msgSender(), quantity);
        _refundIfOver(presaleMintPrice * quantity);
    }

    /***********************************************************************
                                ONLY OWNER FUNCTIONS
     *************************************************************************/
    function airdrop(uint8 quantity, address recipient)
        external
        onlyOwner
        nonReentrant
    {
        uint256 publicSaleQuantity = totalQuantity - presaleQuantity;
        require(
            supply + quantity <= publicSaleQuantity,
            "Not enough NFTs to airdrop"
        );
        supply += quantity;
        _safeMint(recipient, quantity);
    }

    // /**===========================================================================
    //                                 Setter Functions
    // ============================================================================== */

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function _setPresaleState() internal onlyInitializing {
        isPreSaleActive = true;
    }

    function setPresaleQuantity(uint256 quantity) external onlyOwner {
        presaleQuantity = quantity;
    }

    function setPresaleMaxMint(uint256 maxMint) external onlyOwner {
        presaleMaxMintPerWallet = maxMint;
    }

    function setPresaleMaxMintTx(uint256 maxMintTx) external onlyOwner {
        presaleMaxMintPerTx = maxMintTx;
    }

    function setPresaleMintPrice(uint256 price) external onlyOwner {
        presaleMintPrice = price;
    }

    function setPresaleStartTime(uint256 startTime) external onlyOwner {
        presaleStartingTimestamp = startTime;
    }

    function setPresaleEndTime(uint256 endTime) external onlyOwner {
        presaleEndingTimestamp = endTime;
    }

    function setPresaleStatus() external onlyOwner {
        isPreSaleActive = !isPreSaleActive;
    }

    /***********************************************************************
                                INTERNAL FUNCTIONS
     *************************************************************************/
    function _isWhitelisted(bytes32[] calldata _merkleProof, address sender)
        private
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(sender));
        return MerkleProofUpgradeable.verify(_merkleProof, merkleRoot, leaf);
    }
}
