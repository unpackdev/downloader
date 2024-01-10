//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*

 ▐██▌ ▓█████▄ ▓█████  ███▄    █ ▒███████▒ ▄▄▄      ▓█████▄  ▒█████   ██▓
 ▐██▌ ▒██▀ ██▌▓█   ▀  ██ ▀█   █ ▒ ▒ ▒ ▄▀░▒████▄    ▒██▀ ██▌▒██▒  ██▒▓██▒
 ▐██▌ ░██   █▌▒███   ▓██  ▀█ ██▒░ ▒ ▄▀▒░ ▒██  ▀█▄  ░██   █▌▒██░  ██▒▒██░
 ▓██▒ ░▓█▄   ▌▒▓█  ▄ ▓██▒  ▐▌██▒  ▄▀▒   ░░██▄▄▄▄██ ░▓█▄   ▌▒██   ██░▒██░
 ▒▄▄  ░▒████▓ ░▒████▒▒██░   ▓██░▒███████▒ ▓█   ▓██▒░▒████▓ ░ ████▓▒░░██████
 ░▀▀▒  ▒▒▓  ▒ ░░ ▒░ ░░ ▒░   ▒ ▒ ░▒▒ ▓░▒░▒ ▒▒   ▓▒█░ ▒▒▓  ▒ ░ ▒░▒░▒░ ░ ▒░▓  ░░
 ░  ░  ░ ▒  ▒  ░ ░  ░░ ░░   ░ ▒░░░▒ ▒ ░ ▒  ▒   ▒▒ ░ ░ ▒  ▒   ░ ▒ ▒░ ░ ░ ▒  ░
    ░  ░ ░  ░    ░      ░   ░ ░ ░ ░ ░ ░ ░  ░   ▒    ░ ░  ░ ░ ░ ░ ▒    ░ ░
 ░       ░       ░  ░         ░   ░ ░          ░  ░   ░        ░ ░      ░  ░
       ░                        ░                   ░                               

*/

import "./ERC721.sol";
import "./IERC2981.sol";
import "./Counters.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";

contract Denzadol is ERC721, IERC2981, Pausable, AccessControl {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');
    uint256 public constant ARTIST_PROOF_COUNT = 46;
    uint256 public constant MAX_SUPPLY = 1024;
    string public _baseURIextended = 'https://denzadol.xyz/api/metadata/';
    bytes32 public _merkleRoot = 0x3e700b59b5d04328c2b0754bcc69f220525267e08a48a17d8b30f2d84266e29d;
    address payable private _withdrawalWallet;
    bool public presaleActive = false;
    bool public saleActive = false;
    mapping(address => uint256) private tickets;
    uint256 public constant ETH_PRICE = 0.069 ether;
    uint256 public constant PRESALE_ETH_PRICE = 0.069 ether;
    uint256 public constant MAX_MINT_COUNT = 2;
    uint256 public constant PRESALE_MAX_MINT_COUNT = 2;

    constructor() ERC721('Denzadol', 'DENZADOL') {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(MANAGER_ROLE, msg.sender);
        grantRole(MANAGER_ROLE, 0x05d7f554C4eDa12b70C7C41f44cCE865630148Bf);
    }

    function setWithdrawalWallet(address payable withdrawalWallet_) external onlyRole(MANAGER_ROLE) {
        _withdrawalWallet = (withdrawalWallet_);
    }

    function withdraw() external onlyRole(MANAGER_ROLE) {
        payable(_withdrawalWallet).transfer(address(this).balance);
    }

    function pause() public onlyRole(MANAGER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    function setBaseURI(string memory baseURI_) external onlyRole(MANAGER_ROLE) {
        _baseURIextended = baseURI_;
    }

    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked(_baseURIextended, 'metadata.json'));
    }

    function maxSupply() external pure returns (uint256) {
        return MAX_SUPPLY;
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIds.current();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId <= _tokenIds.current(), 'Nonexistent token');
        return string(abi.encodePacked(_baseURIextended, tokenId.toString(), '.json'));
    }

    function claimTicket(uint256 count) internal {
        uint256 claimed = tickets[msg.sender];

        require(claimed + count <= PRESALE_MAX_MINT_COUNT, "Can't mint more than allocated");

        tickets[msg.sender] = claimed + count;
    }

    function setPresaleActive(bool val) external onlyRole(MANAGER_ROLE) {
        presaleActive = val;
    }

    function setSaleActive(bool val) external onlyRole(MANAGER_ROLE) {
        saleActive = val;
    }

    function setMerkleRoot(bytes32 merkleRoot_) external onlyRole(MANAGER_ROLE) {
        _merkleRoot = merkleRoot_;
    }

    function presaleMint(
        uint256 count,
        uint256 index,
        bytes32[] calldata proof
    ) external payable whenNotPaused returns (uint256) {
        require(presaleActive, 'Presale has not begun');
        require((PRESALE_ETH_PRICE * count) == msg.value, 'Incorrect ETH sent; check price!');
        require(_tokenIds.current() + count <= MAX_SUPPLY, 'SOLD OUT');

        claimTicket(count);

        bytes32 leaf = keccak256(abi.encode(index, msg.sender));
        require(MerkleProof.verify(proof, _merkleRoot, leaf), 'Invalid proof');

        for (uint256 i = 0; i < count; i++) {
            _tokenIds.increment();
            _mint(msg.sender, _tokenIds.current());
        }
        return _tokenIds.current();
    }

    function mint(uint256 count) external payable whenNotPaused returns (uint256) {
        require(saleActive, 'Sale has not begun');
        require((ETH_PRICE * count) == msg.value, 'Incorrect ETH sent; check price!');
        require(count <= MAX_MINT_COUNT, 'Tried to mint too many NFTs at once');
        require(_tokenIds.current() + count <= MAX_SUPPLY, 'SOLD OUT');
        for (uint256 i = 0; i < count; i++) {
            _tokenIds.increment();
            _mint(msg.sender, _tokenIds.current());
        }
        return _tokenIds.current();
    }

    function artistMint(uint256 count, address recipient) external onlyRole(MANAGER_ROLE) returns (uint256) {
        require(_tokenIds.current() + count <= ARTIST_PROOF_COUNT, 'Exceeded max proofs');
        require(_tokenIds.current() + count <= MAX_SUPPLY, 'SOLD OUT');
        for (uint256 i = 0; i < count; i++) {
            _tokenIds.increment();
            _mint(recipient, _tokenIds.current());
        }
        return _tokenIds.current();
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), 'Nonexistent token');
        return (address(this), SafeMath.div(SafeMath.mul(salePrice, 10), 100));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165, AccessControl)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    receive() external payable {}
}
