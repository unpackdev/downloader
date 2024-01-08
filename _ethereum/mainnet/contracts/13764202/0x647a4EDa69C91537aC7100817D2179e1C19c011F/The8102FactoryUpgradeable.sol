// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract The8102FactoryUpgradeable is Initializable, ERC1155SupplyUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable  {
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;

    string public name;
    string public symbol;

    Counters.Counter private the8102TokenCounter;

    mapping(uint256 => The8102Token) public the8102Tokens;

    event Minted(uint tokenId, address account, uint amount);
    event Burned(uint tokenId, uint amount);

    struct The8102Token {
        bytes32 merkleRoot;
        bool saleIsOpen;
        uint256 preSale;
        uint256 publicSale;
        uint256 price;
        uint256 maxSupply;
        uint256 maxPerWallet;
        uint256 maxPerTxn;
        string uri;
        address contractAddress;
        mapping(address => uint256) claimedTokens;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(string memory _name, string memory _symbol) public initializer  {
        __ERC1155Supply_init();
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        name = _name;
        symbol = _symbol;
    }

    function addToken(
        bytes32 _merkleRoot, uint256 _preSale, uint256 _publicSale, uint256 _price, uint256 _maxSupply,
        uint256 _maxPerWallet, uint256 _maxPerTxn, string memory _uri, address _contractAddress
    ) external onlyOwner {
        The8102Token storage t = the8102Tokens[the8102TokenCounter.current()];
        t.saleIsOpen = true;
        t.merkleRoot = _merkleRoot;
        t.preSale = _preSale;
        t.publicSale = _publicSale;
        t.price = _price;
        t.maxSupply = _maxSupply;
        t.maxPerWallet = _maxPerWallet;
        t.maxPerTxn = _maxPerTxn;
        t.uri = _uri;
        t.contractAddress = _contractAddress;
        the8102TokenCounter.increment();
    }

    function editToken(
        uint256 _id, uint256 _preSale, uint256 _publicSale, uint256 _price, uint256 _maxSupply,
        uint256 _maxPerWallet, uint256 _maxPerTxn, string memory _uri
    ) external onlyOwner {
        the8102Tokens[_id].preSale = _preSale;
        the8102Tokens[_id].publicSale = _publicSale;
        the8102Tokens[_id].price = _price;
        the8102Tokens[_id].maxPerWallet = _maxPerWallet;
        the8102Tokens[_id].maxPerTxn = _maxPerTxn;
        the8102Tokens[_id].uri = _uri;

        if (totalSupply(_id) == 0) {
            the8102Tokens[_id].maxSupply = _maxSupply;
        }
    }

    function reserve(uint256 _id, uint256 _amount) external onlyOwner {
        require(totalSupply(_id) + _amount <= the8102Tokens[_id].maxSupply, "Exceeds max supply");
        _mint(msg.sender, _id, _amount, "");
        emit Minted(_id, msg.sender, _amount);
    }

    function setSaleState(uint256 _id, bool _isSaleOpen) external onlyOwner {
        the8102Tokens[_id].saleIsOpen = _isSaleOpen;
    }

    function setMerkleRoot(uint256 _id, bytes32 _merkleRoot) external onlyOwner {
        the8102Tokens[_id].merkleRoot = _merkleRoot;
    }

    function setContractAddress(uint256 _id, address _contractAddress) external onlyOwner {
        the8102Tokens[_id].contractAddress = _contractAddress;
    }

    function mint(uint256 _amount, uint256 _id, bytes32[] calldata _merkleProof) external payable nonReentrant {
        require(isValidClaim(_amount, _id, _merkleProof));

        the8102Tokens[_id].claimedTokens[msg.sender] = the8102Tokens[_id].claimedTokens[msg.sender].add(_amount);
        _mint(msg.sender, _id, _amount, "");
        emit Minted(_id, msg.sender, _amount);

        if (totalSupply(_id) >= the8102Tokens[_id].maxSupply) {
            the8102Tokens[_id].saleIsOpen = false;
        }
    }

    function isValidClaim(uint256 _amount, uint256 _id, bytes32[] calldata _merkleProof) internal view returns (bool) {
        require(the8102Tokens[_id].saleIsOpen, "Sale is paused");
        require(block.timestamp > the8102Tokens[_id].preSale, "Sale not open yet");
        require(msg.value >= _amount.mul(the8102Tokens[_id].price), "Eth value incorrect");
        require(the8102Tokens[_id].claimedTokens[msg.sender].add(_amount) <= the8102Tokens[_id].maxPerWallet, "Exceeds wallet limit");
        require(_amount <= the8102Tokens[_id].maxPerTxn, "Exceeds txn limit");
        require(totalSupply(_id) + _amount <= the8102Tokens[_id].maxSupply, "Exceeds max supply");

        if (block.timestamp > the8102Tokens[_id].preSale && block.timestamp < the8102Tokens[_id].publicSale) {
            bool isValid = verifyMerkleProof(_merkleProof, _id, msg.sender);
            require(isValid, "Invalid merkle proof.");
            return isValid;
        }

        return true;
    }

    function verifyMerkleProof(bytes32[] calldata _merkleProof, uint256 _id, address _sender) public view returns (bool) {
        string memory leaf = string(abi.encodePacked("0x", toAsciiString(_sender)));
        bytes32 node = keccak256(abi.encodePacked(leaf));
        return MerkleProof.verify(_merkleProof, the8102Tokens[_id].merkleRoot, node);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function burn(uint256 _id, uint256 _amount) external {
        require(msg.sender == the8102Tokens[_id].contractAddress, "Invalid burn address");
        _burn(msg.sender, _id, _amount);
        emit Burned(_id, _amount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(totalSupply(_id) > 0, "URI: nonexistent token");
        return the8102Tokens[_id].uri;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /** @notice Override ERC1155 to prevent token transfers with amount zero. */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public override {
        require(amount > 0, "ERC1155: zero token transfer not allowed");
        return super.safeTransferFrom(from, to, id, amount, data);
    }

    /** @notice Override ERC1155 to prevent token transfers if contract is paused. */
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal whenNotPaused override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
