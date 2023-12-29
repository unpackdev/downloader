// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./AccessControl.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./INinjaOtomebyAkezie.sol";

contract NoaMinter is AccessControl, Ownable {
    using ECDSA for bytes32;

    event Minted(uint256 month, uint256 term, uint256 tokenId, address sender, address to, uint256 value);
    event PiementMinted(uint256 month, uint256 term,uint256 tokenId, address to, uint256 value);

    // Role
    bytes32 public constant ADMIN = "ADMIN";

    // Mint
    INinjaOtomebyAkezie public noaContract;
    uint256 public maxMintAmountPerTerm;
    mapping(uint256 => mapping(address => uint256)) public mintedAmountPerTerm;
    mapping(uint256 => mapping(address => uint256)) public mintedAmountPerMonth;
    address public withdrawAddress;
    address private signer;

    modifier isValidSignature (uint256 _month, uint256 _term, address _to, uint256 _maxTokenId, bytes calldata _signature) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                _month,
                _term,
                msg.sender,
                _to,
                _maxTokenId,
                msg.value
            )
        );
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        address recoveredAddress = ECDSA.recover(message, _signature);
        require(recoveredAddress == signer, "Invalid Signature");
        _;
    }
    modifier isValidSignaturePiement (uint256 _month, uint256 _term, address _to, uint256 _maxTokenId, bytes calldata _signature) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                _month,
                _term,
                _to,
                _maxTokenId,
                msg.value
            )
        );
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        address recoveredAddress = ECDSA.recover(message, _signature);
        require(recoveredAddress == signer, "Invalid Signature");
        _;
    }
    modifier withinMaxMintAmountPerTerm (uint256 _term, address _minter) {
        require(mintedAmountPerTerm[_term][_minter] < maxMintAmountPerTerm, "Exceeds Max Mint Amount");
        _;
    }
    modifier isValidTokenId (uint256 _maxTokenId) {
        uint256 tokenId = noaContract.getTotalSupply();
        require(tokenId <= _maxTokenId, "Invalid TokenId");
        _;
    }
    modifier isValidValue () {
        require(msg.value > 0, "Invalid Value");
        _;
    }

    constructor(address _withdrawAddress) Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
        withdrawAddress = _withdrawAddress;
    }

    // Setter
    function setNoaContract(address _value) external onlyRole(ADMIN) {
        noaContract = INinjaOtomebyAkezie(_value);
    }
    function setMaxMintAmountPerTerm(uint256 _value) external onlyRole(ADMIN) {
        maxMintAmountPerTerm = _value;
    }
    function setSigner(address _value) external onlyRole(ADMIN) {
        signer = _value;
    }

    // Mint
    function mint(uint256 _month, uint256 _term, address _to, uint256 _maxTokenId, bytes calldata _signature) external payable
        isValidSignature(_month, _term, _to, _maxTokenId, _signature)
        withinMaxMintAmountPerTerm(_term, msg.sender)
        isValidTokenId(_maxTokenId)
        isValidValue()
    {
        uint256 tokenId = noaContract.getTotalSupply();
        noaContract.mint(_to, tokenId);
        mintedAmountPerTerm[_term][msg.sender]++;
        mintedAmountPerMonth[_month][msg.sender]++;
        emit Minted(_month, _term, tokenId, msg.sender, _to, msg.value);
    }
    function piementMint(uint256 _month, uint256 _term, address _to, uint256 _maxTokenId, bytes calldata _signature) external payable
        isValidSignaturePiement(_month, _term, _to, _maxTokenId, _signature)
        withinMaxMintAmountPerTerm(_term, _to)
        isValidTokenId(_maxTokenId)
        isValidValue()
    {
        uint256 tokenId = noaContract.getTotalSupply();
        noaContract.mint(_to, tokenId);
        mintedAmountPerTerm[_term][_to]++;
        mintedAmountPerMonth[_month][_to]++;
        emit PiementMinted(_month, _term, tokenId, _to, msg.value);
    }

    function withdraw() public onlyRole(ADMIN) {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }
}