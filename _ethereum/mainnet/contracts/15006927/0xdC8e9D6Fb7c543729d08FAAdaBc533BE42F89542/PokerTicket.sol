// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ECDSA.sol";

/*
    __________       __               ___________                   __  .__                  
    \______   \____ |  | __ __________\__    ___/___   ____   _____/  |_|  |__   ___________ 
    |     ___/  _ \|  |/ // __ \_  __ \|    | /  _ \ / ___\_/ __ \   __\  |  \_/ __ \_  __ \
    |    |  (  <_> )    <\  ___/|  | \/|    |(  <_> ) /_/  >  ___/|  | |   Y  \  ___/|  | \/
    |____|   \____/|__|_ \\___  >__|   |____| \____/\___  / \___  >__| |___|  /\___  >__|   
                        \/    \/                   /_____/      \/          \/     \/       
 */

contract PokerTicket is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    event BaseURIChanged(string newBaseURI);
    event Withdraw(address indexed account, uint256 amount);

    enum Status {
        Pause,
        Alpha,
        WhitelistSale,
        PublicSale
    }

    enum TreeRootType {
        Alpha,
        Whitelist
    }

    struct MerkleRootConfig {
        bytes32 alphaRoot;
        bytes32 whitelistRoot;
    }

    uint64 public constant MAX_TOKEN = 10000;
    uint64 public constant MAX_TOKEN_PER_MINT = 3;

    uint256 public constant WHITELIST_PRICE = 0.03 ether;
    uint256 public constant PUBLIC_PRICE = 0.05 ether;

    MerkleRootConfig public merkleRootConfig;

    Status public status;
    string public baseURI;

    mapping (address => bool) public freeMintMark;

    address signer;

    constructor(string memory baseURI_, address signer_, MerkleRootConfig memory merkleRootConfig_) ERC721A("PokerTogether Pass", "PTP") {
        baseURI = baseURI_;
        signer = signer_;
        merkleRootConfig = merkleRootConfig_;
        status = Status.Alpha;
    }

    function giveaway(address[] calldata recipients_, uint64 numberOfTokens_) external onlyOwner nonReentrant {
        uint256 recipientsLength = recipients_.length;
        require(recipientsLength != 0 && numberOfTokens_ != 0);
        require(totalMinted() + recipientsLength * numberOfTokens_ <= MAX_TOKEN, "E10");
        for (uint256 i = 0; i < recipientsLength; ++i) {
            _safeMint(recipients_[i], numberOfTokens_);
        }
    }

    function alphaSale(bytes32[] calldata proof_) external callerIsUser nonReentrant {
        require(status == Status.Alpha, "E01");
        require(verifyAddress(_msgSender(), proof_, TreeRootType.Alpha), "E02");
        require(!freeMintMark[_msgSender()], "E03");
        _sale(1, 0);
        freeMintMark[_msgSender()] = true;
    }

    function whitelistSale(uint64 numberOfTokens_, bytes32[] calldata proof_) external payable callerIsUser nonReentrant {
        require(status == Status.WhitelistSale, "E04");
        require(verifyAddress(_msgSender(), proof_, TreeRootType.Whitelist), "E05");
        uint64 whitelistMinted = _getAux(_msgSender()) + numberOfTokens_;
        require(whitelistMinted <= 3, "E03");
        _sale(numberOfTokens_, WHITELIST_PRICE);
        _setAux(_msgSender(), whitelistMinted);
    }

    function publicSale(uint64 numberOfTokens_) external payable callerIsUser nonReentrant {
        require(status == Status.PublicSale, "E06");
        _sale(numberOfTokens_, PUBLIC_PRICE);
    }

    function _sale(uint64 numberOfTokens_, uint256 price_) internal {
        require(numberOfTokens_ > 0, "E07");
        require(numberOfTokens_ <= MAX_TOKEN_PER_MINT, "E08");
        require(totalMinted() + numberOfTokens_ <= MAX_TOKEN, "E10");
        uint256 amount = price_ * numberOfTokens_;
        require(amount <= msg.value, "E09");
        _safeMint(_msgSender(), numberOfTokens_);
        refundExcessPayment(amount);
    }

    function upgradePass(uint256 tokenId_, uint64 updatedLevel_, bytes memory signature_) external callerIsUser nonReentrant{
        require(_exists(tokenId_),"E11");
        TokenOwnership memory ownership = _ownerships[tokenId_];
        require(ownership.addr == _msgSender(), "E12");
        require(ownership.level < updatedLevel_, "E13");
        require(verfiySignature(tokenId_, updatedLevel_, signature_), "E14");
        _ownerships[tokenId_].level = updatedLevel_;
    }

    function refundExcessPayment(uint256 amount_) private {
        if (msg.value > amount_) {
            payable(_msgSender()).transfer(msg.value - amount_);
        }
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
        emit Withdraw(_msgSender(), balance);
    }

    function verifyAddress(address address_, bytes32[] calldata proof_, TreeRootType type_) public view returns (bool) {

        bytes32 root;

        if (type_ == TreeRootType.Alpha)
        {
            root = merkleRootConfig.alphaRoot;

        }else if (type_ == TreeRootType.Whitelist){

            root = merkleRootConfig.whitelistRoot;
        }

        if (root == 0) {
            return false;
        }

        return MerkleProof.verify(proof_, root , keccak256(abi.encodePacked(address_)));
    }

    function verfiySignature(uint256 tokenId_, uint64 updatedLevel_, bytes memory signature_) internal view returns (bool) {
        bytes32 message = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(tokenId_, updatedLevel_, _msgSender(), this)));
         return (ECDSA.recover(message, signature_) == signer);
    }


    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        TokenOwnership memory ownership = _ownerships[tokenId];
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, Strings.toString(ownership.level))) : '';
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit BaseURIChanged(baseURI_);
    }

    function setMerkleRootConfig(MerkleRootConfig calldata merkleRootConfig_) external onlyOwner {
        merkleRootConfig = merkleRootConfig_;
    }

    function setSignerAddress(address signer_) external onlyOwner {
        signer = signer_;
    }

    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "E15");
        _;
    }

    function setStatue(Status statue_) external onlyOwner {
        status = statue_;
    }
}