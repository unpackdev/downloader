// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Math.sol";
import "./MerkleProof.sol";

contract VisionsOfFlight is ERC721, Ownable, Pausable {
    using Strings for uint256;

    event TokenMinted (
        address recipient,
        uint256 tokenId
    );

    uint NEXT_TOKEN_ID = 1;
    uint MAX_TOKEN_ID = 7200;

    uint8 MAX_MINTS = 10;
    uint8 MAX_TXS_PER_WALLET = 5;
    mapping (address => uint) txsPerWallet;

    // 0.1 ETH MINT PRICE
    uint MINT_PRICE = 12e16;

    mapping (address => uint) numVouchers;
    mapping (address => bool) claimedPOAPVoucher;
    uint public claimOpensAt;
    uint public saleStartsAt;
    uint public saleEndsAt;
    string baseURI;
   
    bytes32 public merkleRoot;

    address payable divisionStWallet;
    address payable athletesWallet;

    uint8 divisionStShare = 25;

    constructor(
        string memory metadataBaseURI,
        address payable _divisionStWallet,
        address payable _athletesWallet,
        uint _claimOpensAt,
        uint _saleStartsAt,
        uint _saleEndsAt,
        address[] memory athletePremints, 
        address[] memory ffTokenHolders, 
        address[] memory singleVoucherTokenHolders,
        bytes32 _merkleRoot
    ) ERC721("Visions of Flight", "VFLT") {
        divisionStWallet = _divisionStWallet;
        athletesWallet = _athletesWallet;

        claimOpensAt = _claimOpensAt;
        saleStartsAt = _saleStartsAt;
        saleEndsAt = _saleEndsAt;

        merkleRoot = _merkleRoot;

        // mint the first n NFTs directly to athletes on contract
        // instantiation
        for (uint16 i = 0; i < athletePremints.length; i++) {
            mintToken(athletePremints[i]);
        }

        // grant 2x vouchers for each FF NFT
        for (uint16 i = 0; i < ffTokenHolders.length; i++) {
            numVouchers[ffTokenHolders[i]] = numVouchers[ffTokenHolders[i]] + 2;
        }

        // grant single voucher to single-voucher greenlist
        for (uint16 i = 0; i < singleVoucherTokenHolders.length; i++) {
            numVouchers[singleVoucherTokenHolders[i]] = numVouchers[singleVoucherTokenHolders[i]] + 1;
        }

        baseURI = metadataBaseURI;

    }

    function freeMint(bytes32[] calldata proof) public whenNotPaused {
        require(block.timestamp >= claimOpensAt, "Visions of Flight: claim window has not opened");
        require(block.timestamp <= saleEndsAt, "Visions of Flight: sale has ended");
        require(numVouchers[msg.sender] > 0 || hasPOAPVoucher(proof), "Visions of Flight: No freemints available");


        for (uint8 i = 0; i < numVouchers[msg.sender]; i++) {
            mintToken(msg.sender);
        }
        numVouchers[msg.sender] = 0;

        if (hasPOAPVoucher(proof)) {
            mintToken(msg.sender);
            claimedPOAPVoucher[msg.sender] = true;
        }
    }

    function mint(address recipient, uint8 count) public payable whenNotPaused {
        require(block.timestamp >= saleStartsAt, "Visions of Flight: sale has not started");
        require(block.timestamp <= saleEndsAt, "Visions of Flight: sale has ended");

        // validate parameters and price
        require(count > 0 && count <= MAX_MINTS, "Visions of Flight: maximum mint per tx exceeded");
        require(msg.value == count*MINT_PRICE, "Visions of Flight: invalid mint fee");

        // validate txs per wallet
        require(txsPerWallet[msg.sender] < MAX_TXS_PER_WALLET, "Visions of Flight: User has exceeded 5 mint transactions per wallet");
        require(msg.sender == tx.origin, "Visions of Flight: Account is not an EOA");

        for (uint8 i = 0; i < count; i++) {
            mintToken(recipient);
        }

        txsPerWallet[msg.sender] = txsPerWallet[msg.sender] + 1;

        uint divisionStReceives = msg.value * divisionStShare / 100;
        uint athletesReceives = msg.value - divisionStReceives;

        divisionStWallet.transfer(divisionStReceives);
        athletesWallet.transfer(athletesReceives);
    }

    // ============ PUBLIC VIEW FUNCTIONS ============

    function getNumVouchers(address recipient) public view returns (uint) {
        if (block.timestamp <= saleEndsAt) {
            return numVouchers[recipient];
        } else {
            return 0;
        }
    }

    function hasClaimedPOAPVoucher(address recipient) public view returns (bool) {
        return claimedPOAPVoucher[recipient];
    }

    function totalSupply() public view returns (uint) {
        return NEXT_TOKEN_ID - 1;
    }

    // ============ OWNER INTERFACE ============

    function updatePaused(bool _paused) public onlyOwner {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function updateBaseURI(string calldata __baseURI) public onlyOwner {
        baseURI = __baseURI;
    }

    function updateClaimOpensAt(uint _claimOpensAt) public onlyOwner {
        claimOpensAt = _claimOpensAt;
    }

    function updateSaleStartsAt(uint _saleStartsAt) public onlyOwner {
        saleStartsAt = _saleStartsAt;
    }

    function updateSaleEndsAt(uint _saleEndsAt) public onlyOwner {
        saleEndsAt = _saleEndsAt;
    }

    // ============ INTERNAL INTERFACE ============

    function mintToken(address recipient) internal {
        require(NEXT_TOKEN_ID <= MAX_TOKEN_ID, "Visions of Flight: Sold out");

        _mint(recipient, NEXT_TOKEN_ID);
        emit TokenMinted(recipient, NEXT_TOKEN_ID);
        NEXT_TOKEN_ID = NEXT_TOKEN_ID + 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _generateMerkleLeaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function checkPOAPVoucher(address recipient, bytes32[] calldata proof) public view returns (bool) {
        require(!claimedPOAPVoucher[recipient], "Visions of Flight: POAP free mint already claimed");

        if (MerkleProof.verify(proof, merkleRoot, _generateMerkleLeaf(recipient))) {
            return true;
        } else {
            return false;
        }
    }

    function hasPOAPVoucher(bytes32[] calldata proof) internal view returns (bool) {
        require(!claimedPOAPVoucher[msg.sender], "Visions of Flight: POAP free mint already claimed");

        if (MerkleProof.verify(proof, merkleRoot, _generateMerkleLeaf(msg.sender))) {
            return true;
        } else {
            return false;
        }
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }
}