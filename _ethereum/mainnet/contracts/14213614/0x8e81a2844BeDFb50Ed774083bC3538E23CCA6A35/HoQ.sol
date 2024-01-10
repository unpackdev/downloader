// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A_start_at_one.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract HoQ is ContextMixin, ERC721A, NativeMetaTransaction, Ownable, ReentrancyGuard {

    enum ReleaseMode { CLOSED, OG_WHITELIST_MINT, WHITELIST_MINT, PUBLIC_MINT, REVEALED }
    ReleaseMode public currentMode;

    using SafeMath for uint256;

    string public contractURI;

    uint256 public maxSupply = 10000;
    uint256 public maxPublicSupply = 9800;
    uint256 public maxWhitelistMintsPerWallet = 5;

    bool public isMetaDataFrozen = false;

    string private _tokenURI;

    bytes32 private _whitelistMerkleRoot;

    address private developer;
    uint private developerPercentage = 2;

    uint256 public mintPricePublic = 0.07 ether;
    uint256 public mintPriceWL = 0.06 ether;
    uint256 public mintPriceOGWL = 0.06 ether;

    uint256 private developerBalance = 0 ether;

    uint256 private emergencyWithdrawAvailableTime = 2147462145;

    uint256 private yearInSeconds = 31556926;

    mapping(address => uint256) public whitelistMintedPerAddress;

    string private _name = "House of Queens";
    string private _symbol = "HoQ";

    modifier notFrozenMetaData {
        require(
            !isMetaDataFrozen,
            "metadata frozen"
        );
        _;
    }

    modifier canPublicMint {
        require(
            currentMode == ReleaseMode.PUBLIC_MINT || currentMode == ReleaseMode.REVEALED,
            "It's not time yet"
        );
        _;
    }

    modifier canWhitelistMint {
        require(
            currentMode == ReleaseMode.WHITELIST_MINT,
            "It's not time yet"
        );
        _;
    }

    modifier canOGWhitelistMint {
        require(
            currentMode == ReleaseMode.OG_WHITELIST_MINT,
            "It's not time yet"
        );
        _;
    }

    modifier onlyDeveloper {
        require(
            developer == _msgSender(),
            "dev only"
        );
        _;
    }

    constructor(string memory __tokenURI, address _developer) ERC721A(_name, _symbol) {
        _tokenURI = __tokenURI;
        developer = _developer;
        emergencyWithdrawAvailableTime = block.timestamp + yearInSeconds;
        _initializeEIP712(_name);
    }

    function setReleaseStatus(ReleaseMode newStatus) external onlyOwner {
        currentMode = newStatus;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _whitelistMerkleRoot = merkleRoot;
    }

    function publicMint(uint256 count) public payable canPublicMint {
        require(msg.value == (count * mintPricePublic), "Wrong amount");
        require(count > 0 && count <= 8, "Wrong amount");

        buyAmount(count);
        developerBalance += msg.value * developerPercentage / 100;
    }

    function whitelistMint(bytes32[] memory merkleProof, uint256 count) public payable canWhitelistMint {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, _whitelistMerkleRoot, leaf), "Not WL");
        require(msg.value == (count * mintPriceWL), "Wrong price");
        require(whitelistMintedPerAddress[msg.sender] + count <= maxWhitelistMintsPerWallet, "WL Wallet Max");
        require(count > 0 && count <= 8, "Wrong amount");

        buyAmount(count);
        whitelistMintedPerAddress[msg.sender] += count;
        developerBalance += msg.value * developerPercentage / 100;
    }

    function ogWhitelistMint(bytes32[] memory merkleProof, uint256 count) public payable canOGWhitelistMint {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, _whitelistMerkleRoot, leaf), "Not OG WL");
        require(msg.value == (count * mintPriceOGWL), "Wrong price");
        require(whitelistMintedPerAddress[msg.sender] + count <= maxWhitelistMintsPerWallet, "WL Wallet Max");
        require(count > 0 && count <= 8, "Wrong amount");

        buyAmount(count);
        whitelistMintedPerAddress[msg.sender] += count;
        developerBalance += msg.value * developerPercentage / 100;
    }

    function buyAmount(uint256 count) private {
        require(totalSupply() + count <= maxPublicSupply, "Max Public Supply");
        _safeMint(_msgSender(), count);
    }

    function mintMany(uint256 num, address _to) public onlyOwner {
        require(num <= 8, "Max 8 Per TX.");
        require(totalSupply() + num < maxSupply, "Max Supply");
        _safeMint(_to, num);
    }

    function mintTo(address _to) public onlyOwner {
        require(totalSupply() < maxSupply, "Max Supply");
        _safeMint(_to, 1);
    }

    // withdraw function for the contract owner
    function withdraw() external nonReentrant onlyOwner {
        payable(owner()).transfer(address(this).balance - developerBalance);
    }

    // withdraw function for the contract developer to retrieve royalties
    function withdrawDeveloper() external nonReentrant onlyDeveloper {
        payable(developer).transfer(developerBalance);
        developerBalance = 0 ether;
    }

    // if the funds are still in the contract a year after deploy they can all be taken by the owner
    function emergencyWithdraw() external nonReentrant onlyOwner {
        require(block.timestamp > emergencyWithdrawAvailableTime, "It's not time yet");
        payable(owner()).transfer(address(this).balance);
    }

    // in case the contract is not fully minted out have the ability to cut the supply
    function shrinkSupply(uint256 newMaxSupply, uint256 newMaxPublicSupply) external nonReentrant onlyOwner {
        require(newMaxSupply >= newMaxPublicSupply, "ERR: public > max!");
        require(totalSupply() <= newMaxSupply, "ERR: minted > new!");
        require(newMaxSupply <= maxSupply, "ERR: cant increase max supply");
        maxPublicSupply = newMaxPublicSupply;
        maxSupply = newMaxSupply;
    }

    function setTokenUri(string memory _uri, bool reveal) external onlyOwner notFrozenMetaData {
        _tokenURI = _uri;
        if (reveal) {
            currentMode = ReleaseMode.REVEALED;
        }
    }

    function setContractUri(string memory uri) public onlyOwner {
        contractURI = uri;
    }

    function freezeMetaData() public onlyOwner {
        require(currentMode == ReleaseMode.REVEALED, "Freeze after reveal");
        isMetaDataFrozen = true;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (currentMode != ReleaseMode.REVEALED) {
            return string(abi.encodePacked(_tokenURI));
        }
        return
            string(
                abi.encodePacked(
                    _tokenURI,
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}
