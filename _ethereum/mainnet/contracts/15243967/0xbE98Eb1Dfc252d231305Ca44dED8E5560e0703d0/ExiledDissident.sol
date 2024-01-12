// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC2981.sol";
import "./ERC721AQueryable.sol";
import "./ERC721ABurnable.sol";
import "./IERC721A.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";

contract ExiledDissident is ERC721AQueryable, ERC721ABurnable, Ownable, EIP712, IERC2981 {
    using Address for address;

    error NotHuman(address caller);
    error ExccededTotalSupply();
    error ExccededMaxMintPerAccount(uint256 mint, uint256 max);
    error NotYetStarted();
    error ZeroAmount();
    error InsufficientFunds(uint256 recieved, uint256 expected);
    error InvalidSigner();

    uint256 constant public PUBLIC_MINT_PRICE = 0.019 ether;
    uint256 constant public MAX_MINT_PER_ACCOUNT_PUB = 5;
    uint256 constant public MAX_MINT_PER_ACCOUNT_WB = 10;
    uint256 immutable public maxTokenCount;

    uint256[2] public oneFreeRemain;
    uint256 constant public INDEX_PUBLIC_ONE_FREE = 0;
    uint256 constant public INDEX_ALLOWLIST_ONE_FREE = 1;

    modifier commonCheck(uint256 amount) {
        if (block.timestamp < startTime) {
            revert NotYetStarted();
        }
        if (tx.origin != msg.sender) {
            revert NotHuman(msg.sender);
        }
        if (amount == 0) {
            revert ZeroAmount();
        }
        _;
        if (totalSupply() > maxTokenCount) {
            revert ExccededTotalSupply();
        }
    }

    function checkMinted(uint256 amount, uint256 max) private view returns(uint256) {
        uint256 minted = _numberMinted(msg.sender);
        if (minted + amount > max) {
            revert ExccededMaxMintPerAccount(minted + amount, max);
        }
        return minted;
    }

    function getDigest(bytes32 hashType, address target) public view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(hashType, target)));
    }

    function checkSignature(uint8 v, bytes32 r, bytes32 s, bytes32 hashType, address who) public view returns(bool) {
        address acturalSigner = ecrecover(getDigest(hashType, who), v, r, s);
        if (acturalSigner != allowListSigner) {
            revert InvalidSigner();
        }
        return true;
    }

    // --------------- mint -------------

    function mintFromPool(uint256 amount, uint256 index, uint256 remain) private {
        uint256 minted = checkMinted(amount, MAX_MINT_PER_ACCOUNT_PUB);
        uint256 money;
        if (remain > 0 && minted == 0 ) {
            --oneFreeRemain[index];
            money = (amount - 1) * PUBLIC_MINT_PRICE;
        } else {
            money = amount * PUBLIC_MINT_PRICE;
        }
        if (msg.value < money) {
            revert InsufficientFunds(msg.value, money);
        }
        _mint(msg.sender, amount);
        if (msg.value > money) {
            Address.sendValue(payable(msg.sender), msg.value - money);
        }
    }

    function publicMint(uint256 amount) external payable commonCheck(amount) {
        mintFromPool(amount, INDEX_PUBLIC_ONE_FREE, oneFreeRemain[INDEX_PUBLIC_ONE_FREE]);
    }

    function allowListOneFreeMint(uint8 v, bytes32 r, bytes32 s, uint256 amount) external payable commonCheck(amount) {
        uint256 remain = oneFreeRemain[INDEX_ALLOWLIST_ONE_FREE];
        if ( block.timestamp < endTime && remain > 0 ) {
            checkSignature(v, r, s, ALLOWLIST_ONE_FREEMINT_HASH_TYPE, msg.sender);
            mintFromPool(amount, INDEX_ALLOWLIST_ONE_FREE, remain);
        } else {
            mintFromPool(amount, INDEX_PUBLIC_ONE_FREE, oneFreeRemain[INDEX_PUBLIC_ONE_FREE]);
        }
    }

    function allowListTenFreeMint(uint8 v, bytes32 r, bytes32 s) external commonCheck(MAX_MINT_PER_ACCOUNT_WB) {
        checkSignature(v, r, s, ALLOWLIST_TEN_FREEMINT_HASH_TYPE, msg.sender);
        checkMinted(MAX_MINT_PER_ACCOUNT_WB, MAX_MINT_PER_ACCOUNT_WB);
        _mint(msg.sender, MAX_MINT_PER_ACCOUNT_WB);
    }

    // --------------- read only -------------
    function numberMinted(address who) external view returns (uint256) {
        return _numberMinted(who);
    }

    function numberBurned(address who) external view returns (uint256) {
        return _numberBurned(who);
    }

    // --------------- maintain -------------

    bytes32 constant public ALLOWLIST_ONE_FREEMINT_HASH_TYPE = keccak256("allowListOneFreeMint(address receiver)");
    bytes32 constant public ALLOWLIST_TEN_FREEMINT_HASH_TYPE = keccak256("allowListTenFreeMint(address receiver)");
    bool lockedBaseURI = false;
    address immutable public allowListSigner;
    uint48 public startTime;
    uint48 public endTime;
    address immutable public treasury4;
    address immutable public treasury6;
    address immutable public treasurySplitter;
    string public baseURI;
    string public contractURI = "ipfs://QmdkKvdihZwqhs6q1pjbyP5CbnAqccvVm529rcjRCE8ivV";

    constructor(
        address[] memory addrs,
        address allowListSigner_,
        uint48 startTime_,
        uint48 endTime_,
        string memory baseURI_,
        uint256 maxTokenCount_,
        uint256 oneFreeRemainPUB_,
        uint256 oneFreeRemainWLA_
    ) ERC721A("Exiled Dissident", "ExiledD") EIP712("Exiled Dissident", "1.0.0") {
        treasury4 = addrs[0];
        treasury6 = addrs[1];
        treasurySplitter = addrs[2];
        startTime = startTime_;
        endTime = endTime_;
        baseURI = baseURI_;
        allowListSigner = allowListSigner_;
        maxTokenCount = maxTokenCount_;
        oneFreeRemain[INDEX_PUBLIC_ONE_FREE] = oneFreeRemainPUB_;
        oneFreeRemain[INDEX_ALLOWLIST_ONE_FREE] = oneFreeRemainWLA_;
        _mint(msg.sender, 1);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert IERC721A.URIQueryForNonexistentToken();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        require(!lockedBaseURI, "Base URI is locked");
        baseURI = baseURI_;
    }

    function lockBaseURI() external onlyOwner {
        lockedBaseURI = true;
    }

    function setTime(uint48 startTime_, uint48 endTime_) external onlyOwner {
        startTime = startTime_;
        endTime = endTime_;
    }

    function withdraw() external {
        uint256 total = address(this).balance;
        uint256 to6 = total * 60 / 100;
        Address.sendValue(payable(treasury6), to6);
        Address.sendValue(payable(treasury4), total - to6);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external override view returns (address receiver, uint256 royaltyAmount) {
        tokenId;
        receiver = treasurySplitter;
        royaltyAmount = salePrice * 85 / 1000;
    }

    function doCall(address target, bytes calldata data) external payable onlyOwner returns (bytes memory) {
        return target.functionCallWithValue(data, msg.value);
    }
}
