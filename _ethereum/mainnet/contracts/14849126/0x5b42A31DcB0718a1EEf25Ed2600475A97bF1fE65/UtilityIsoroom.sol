// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

import "./IsoroomVault.sol";

contract UtilityIsoroom is ERC721A, Ownable {
    // @dev refer to setProvenance and randomSeedIndex function
    event Provenance(uint256 indexed proveType, bytes32 proveData);

    string private _baseURIextended;

    string private constant ERR_ONLY_EOA = "Only EOA";
    string private constant ERR_MINT_END = "Minting ended";
    string private constant ERR_MINT_NOT_START = "Not started yet";
    string private constant ERR_LIMIT_EXCEED = "Limit exceeded";
    string private constant ERR_WRONG_VALUE = "Value not correct";
    string private constant ERR_NOT_WHITELIST = "Not whitelisted";
    string private constant ERR_INTERNAL = "Internal error";
    string private constant ERR_NOT_TARGET = "Not target address";
    string private constant ERR_NOT_SET_VAULT = "Vault not found";

    uint256 public constant PUBLIC_MINTING_LIMIT = 20;
    uint256 public mintingPrice = 0.0688 ether;
    address public signer = 0x8168e7d3a63b08f8E4609cA74547e911809140d7;
    address public vaultAddress;
    bool public sealVaultAddress = false;

    uint8 public activeStage = 0;
    uint256 public maxSupply = 6000;

    mapping(address => uint16) public whitelistRecord;

    constructor() ERC721A("UtilityIsoroom", "UISOROOM") {}

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setActiveStage(uint8 _stage) external onlyOwner {
        activeStage = _stage;
    }

    function whitelistMint(
        bytes calldata _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint16 _numberOfTokens,
        bool stake
    ) external payable {
        require(activeStage >= 1, ERR_MINT_NOT_START);
        if (stake) require(vaultAddress != address(0x0), ERR_NOT_SET_VAULT);

        address targetAddress = bytesToAddress(_message[:20]);
        require(msg.sender == targetAddress, ERR_NOT_TARGET);

        uint256 totalSupply = totalSupply();
        require(totalSupply + _numberOfTokens <= maxSupply, ERR_LIMIT_EXCEED);
        require(mintingPrice * _numberOfTokens <= msg.value, ERR_WRONG_VALUE);

        uint32 whitelistQuota = uint32(bytes4(_message[20:24]));
        require(
            whitelistRecord[msg.sender] + _numberOfTokens <= whitelistQuota,
            ERR_LIMIT_EXCEED
        );

        address recoveredSigner = recoverSigner(_message, _v, _r, _s);
        require(signer == recoveredSigner, "Not correct signer");

        whitelistRecord[msg.sender] += _numberOfTokens;

        _safeMint(
            stake ? vaultAddress : msg.sender,
            _numberOfTokens
        );

        if (stake) {
            uint256[] memory toStake = new uint256[](_numberOfTokens);
            for (uint256 i = 0; i < _numberOfTokens; i++) {
                toStake[i] = totalSupply + i;
            }
            IsoroomVault(vaultAddress).stakeDuringMint(msg.sender, address(this), toStake);
        }
    }

    function publicMint(uint256 _numberOfTokens, bool stake) public payable {
        require(msg.sender == tx.origin, ERR_ONLY_EOA);
        if (stake) require(vaultAddress != address(0x0), ERR_NOT_SET_VAULT);

        require(activeStage >= 2, ERR_MINT_NOT_START);

        uint256 totalSupply = totalSupply();
        require(totalSupply + _numberOfTokens <= maxSupply, ERR_LIMIT_EXCEED);
        require(_numberOfTokens <= PUBLIC_MINTING_LIMIT, ERR_LIMIT_EXCEED);
        require(mintingPrice * _numberOfTokens <= msg.value, ERR_WRONG_VALUE);

        _safeMint(
            stake ? vaultAddress : msg.sender,
            _numberOfTokens
        );

        if (stake) {
            uint256[] memory toStake = new uint256[](_numberOfTokens);
            for (uint256 i = 0; i < _numberOfTokens; i++) {
                toStake[i] = totalSupply + i;
            }
            IsoroomVault(vaultAddress).stakeDuringMint(msg.sender, address(this), toStake);
        }
    }

    function setVaultAddress(address _valueAddress) external onlyOwner {
        require(!sealVaultAddress, ERR_INTERNAL);
        vaultAddress = _valueAddress;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        /**
         * Approval for isoroom vault for skiping transaction
         */
        if (operator == vaultAddress) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserve(uint256 _numberOfTokens) external onlyOwner {
        _safeMint(msg.sender, _numberOfTokens);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setProvenance(bytes32 _proveData) external onlyOwner {
        emit Provenance(1, _proveData);
    }

    function randomSeedIndex() external onlyOwner {
        uint256 number = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp))
        );

        bytes32 n = bytes32(number % maxSupply);
        emit Provenance(2, n);
    }

    function bytesToAddress(bytes memory bys)
        private
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function recoverSigner(
        bytes calldata _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) private pure returns (address addr) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n24";
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(prefix, _message)
        );
        address recoveredSigner = ecrecover(prefixedHashMessage, _v, _r, _s);
        return recoveredSigner;
    }

    function setSealVaultAddress() external onlyOwner {
        require(vaultAddress != address(0x0), ERR_NOT_SET_VAULT);
        sealVaultAddress = true;
    }

    // @dev: to be not using, by dao
    function setMintingPrice(uint256 _price) external onlyOwner {
        mintingPrice = _price;
    }

    // @dev: to be not using, by dao
    function reduceMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply >= totalSupply(), ERR_LIMIT_EXCEED);
        require(_maxSupply < maxSupply, ERR_INTERNAL);
        maxSupply = _maxSupply;
    }
}
