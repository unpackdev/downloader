// SPDX-License-Identifier: MIT
// Creator: twitter.com/runo_dev

/* 
8888888b.          888               888               d8b               8888888b.  d8b                            d8b                   
888   Y88b         888               888               Y8P               888  "Y88b Y8P                            Y8P                   
888    888         888               888                                 888    888                                                      
888   d88P .d88b.  88888b.   .d88b.  888 .d8888b       888 88888b.       888    888 888 .d8888b   .d88b.  888  888 888 .d8888b   .d88b.  
8888888P" d8P  Y8b 888 "88b d8P  Y8b 888 88K           888 888 "88b      888    888 888 88K      d88P"88b 888  888 888 88K      d8P  Y8b 
888 T88b  88888888 888  888 88888888 888 "Y8888b.      888 888  888      888    888 888 "Y8888b. 888  888 888  888 888 "Y8888b. 88888888 
888  T88b Y8b.     888 d88P Y8b.     888      X88      888 888  888      888  .d88P 888      X88 Y88b 888 Y88b 888 888      X88 Y8b.     
888   T88b "Y8888  88888P"   "Y8888  888  88888P'      888 888  888      8888888P"  888  88888P'  "Y88888  "Y88888 888  88888P'  "Y8888  
                                                                                                      888                                
                                                                                                 Y8b d88P                                
                                                                                                  "Y88P"                                 
*/

// Rebels in Disguise - ERC-721A based NFT contract

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

error InvalidSign();
error FunctionLocked();
error SaleNotStarted();
error InvalidSignLength();
error InsufficientPayment();
error AmountExceedsSupply();
error AmountExceedsClaimLimit();
error AmountExceedsPresaleLimit();
error DevShareAlreadySet();
error AmountExceedsTransactionLimit();
error RequestedSupplyShouldExceedsCurrentSupply();
error OnlyExternallyOwnedAccountsAllowed();

contract RebelsInDisguise3D is ERC721A, Ownable, ReentrancyGuard {
    // Payout addresses
    address private constant creator1 =
        0x3F838Fb407b750655632088bDf1D0430F53AC8F3;
    address private constant creator2 =
        0xCdC82eE2cbC9168e7DA4CD3EeF49705C5610839b;
    address private constant creator3 =
        0x35364A2B2c2DC73bEdF16e7fBCd29D2dA27E04D4;
    address private constant creator4 =
        0xDf82600D2fA71B2Cb9406EEF582114b395729d23;
    address private constant creator5 =
        0x9D35BaDbC2300003B5CF077262e7Ef389a89e981;
    address private constant creator6 =
        0x13205830f2bf6f1197D057f145454CE99A955A6d;
    address private constant creator7 =
        0xdBdFdB5a3c50BE2481cC021828b6815B46d2f2f8;
    address private constant dev = 0x4E309329764DFb001d52c08FAe14e46a745Df506;

    uint256 public MAX_SUPPLY = 7;
    uint256 private MAX_MINTS_PER_TX = 0;
    uint256 private MAX_MINTS_PER_WHITELIST = 0;

    bool private _lock = false;
    bool private _saleStatus = false;
    bool private _claimStatus = false;
    bool private _presaleStatus = false;
    uint256 private _salePrice = 0 ether;

    uint256 private _devShare;
    address private _validator;
    address private _validator2;
    string private _baseTokenURI;
    mapping(address => bool) private _mintedClaim;
    mapping(address => uint256) private _whitelistMints;

    constructor() ERC721A("RebelsInDisguise3D", "RBLS3D") {}

    function isClaimActive() public view returns (bool) {
        return _claimStatus;
    }

    function isPresaleActive() public view returns (bool) {
        return _presaleStatus;
    }

    function isSaleActive() public view returns (bool) {
        return _saleStatus;
    }

    function getSalePrice() public view returns (uint256) {
        return _salePrice;
    }

    function hasMintedClaim(address account) public view returns (bool) {
        return _mintedClaim[account];
    }

    function claimMint(bytes memory sign, uint256 quantity)
        external
        nonReentrant
        onlyEOA
        verify(msg.sender, sign, _validator)
    {
        if (!isClaimActive()) revert SaleNotStarted();
        if (hasMintedClaim(msg.sender)) revert AmountExceedsClaimLimit();
        if (totalSupply() + quantity > MAX_SUPPLY) revert AmountExceedsSupply();

        _mintedClaim[msg.sender] = true;
        _safeMint(msg.sender, quantity);
    }

    function presaleMint(bytes memory sign, uint256 quantity)
        external
        payable
        nonReentrant
        onlyEOA
        verify(msg.sender, sign, _validator2)
    {
        if (!isPresaleActive()) revert SaleNotStarted();
        if (quantity > MAX_MINTS_PER_WHITELIST)
            revert AmountExceedsPresaleLimit();
        if (_whitelistMints[msg.sender] + quantity > MAX_MINTS_PER_WHITELIST)
            revert AmountExceedsPresaleLimit();
        if (totalSupply() + quantity > MAX_SUPPLY) revert AmountExceedsSupply();
        if (getSalePrice() * quantity > msg.value) revert InsufficientPayment();

        _whitelistMints[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function saleMint(uint256 quantity) external payable nonReentrant onlyEOA {
        if (!isSaleActive()) revert SaleNotStarted();
        if (totalSupply() + quantity > MAX_SUPPLY) revert AmountExceedsSupply();
        if (getSalePrice() * quantity > msg.value) revert InsufficientPayment();
        if (quantity > MAX_MINTS_PER_TX) revert AmountExceedsTransactionLimit();

        _safeMint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;
        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= totalSupply()
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function mintToAddress(address to, uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > MAX_SUPPLY) revert AmountExceedsSupply();

        _safeMint(to, quantity);
    }

    function setValidator(address validator) external onlyOwner {
        _validator = validator;
    }

    function setValidator2(address validator) external onlyOwner {
        _validator2 = validator;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function toggleClaimStatus() external onlyOwner {
        _claimStatus = !_claimStatus;
    }

    function togglePresaleStatus() external onlyOwner {
        _presaleStatus = !_presaleStatus;
    }

    function toggleSaleStatus() external onlyOwner {
        _saleStatus = !_saleStatus;
    }

    function setMaxSupply(uint256 supply) external onlyOwner {
        if (_lock) revert FunctionLocked();
        if (totalSupply() >= supply)
            revert RequestedSupplyShouldExceedsCurrentSupply();
        MAX_SUPPLY = supply;
    }

    function setMaxMintPerWhitelist(uint256 maxMint) external onlyOwner {
        if (_lock) revert FunctionLocked();
        MAX_MINTS_PER_WHITELIST = maxMint;
    }

    function setMaxMintPerTx(uint256 maxMint) external onlyOwner {
        if (_lock) revert FunctionLocked();
        MAX_MINTS_PER_TX = maxMint;
    }

    function setSalePrice(uint256 price) external onlyOwner {
        if (_lock) revert FunctionLocked();
        _salePrice = price;
    }

    function lock() external onlyOwner {
        _lock = true;
    }

    function setDevShare(uint256 share) external onlyOwner {
        if (_devShare != 0) revert DevShareAlreadySet();
        _devShare = share;
    }

    function withdrawAll() external onlyOwner {
        uint256 amountToCreator1 = (address(this).balance * 15) / 100;
        uint256 amountToCreator2 = (address(this).balance * 15) / 100;
        uint256 amountToCreator3 = (address(this).balance * 15) / 100;
        uint256 amountToCreator4 = (address(this).balance * 15) / 100;
        uint256 amountToCreator5 = (address(this).balance * 15) / 100;
        uint256 amountToCreator6 = (address(this).balance * (125 - _devShare)) /
            1000;
        uint256 amountToCreator7 = (address(this).balance * 125) / 1000;

        if (_devShare > 0) {
            uint256 amountToDev = (address(this).balance * _devShare) / 1000;

            withdraw(dev, amountToDev);
        }

        withdraw(creator1, amountToCreator1);
        withdraw(creator2, amountToCreator2);
        withdraw(creator3, amountToCreator3);
        withdraw(creator4, amountToCreator4);
        withdraw(creator5, amountToCreator5);
        withdraw(creator6, amountToCreator6);
        withdraw(creator7, amountToCreator7);
    }

    function withdraw(address account, uint256 amount) internal {
        (bool os, ) = payable(account).call{value: amount}("");
        require(os, "Failed to send ether");
    }

    modifier onlyEOA() {
        if (tx.origin != msg.sender)
            revert OnlyExternallyOwnedAccountsAllowed();
        _;
    }

    modifier verify(
        address account,
        bytes memory sign,
        address validator
    ) {
        if (sign.length != 65) revert InvalidSignLength();

        bytes memory addressBytes = toBytes(account);

        bytes32 _hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked("rebelsindisguise", addressBytes))
            )
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sign, 32))
            s := mload(add(sign, 64))
            v := byte(0, mload(add(sign, 96)))
        }

        if (ecrecover(_hash, v, r, s) != validator) revert InvalidSign();
        _;
    }

    function toBytes(address a) internal pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(
                add(m, 20),
                xor(0x140000000000000000000000000000000000000000, a)
            )
            mstore(0x40, add(m, 52))
            b := m
        }
    }
}
