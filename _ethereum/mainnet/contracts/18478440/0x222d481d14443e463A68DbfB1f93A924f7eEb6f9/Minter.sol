// contracts/Minter.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./ECDSA.sol";
import "./Waitlist.sol";

interface IToken {
    function mint(address owner, uint256 quantity, uint256 setId, uint256[] calldata options) external;
    function minterMint(address owner, uint256 quantity, uint256 setId, uint256[] calldata options) external;
    function totalSupply() external view returns (uint256);
}

contract Minter is Pausable, AccessControl {
    enum Stage{ CLOSED, PRIVATE, PUBLIC, PRESALE }

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant TWEED_CLAIMER_ROLE = keccak256("TWEED_CLAIMER_ROLE");
    uint256 public price;
    uint256 public erc20price;
    mapping(address => uint32) public privateMinted;
    mapping(address => uint32) public publicMinted;
    address public tokenAddress;
    address public forwarderAddress;
    address public erc20Address;
    bytes32 private domainSeparator;
    uint32 public maxPublicMintedPerAccount;
    Stage public stage;

    // Additional events for logging
    event ChangeStage(Stage _stage);
    event ChangePrice(uint256 _price);
    event ChangeERC20Price(uint256 _price);
    event ChangeERC20Address(address _address);
    event ChangeMaxPublicMintedPerAccount(uint32 _value);

    constructor(
        uint256 _price,
        uint256 _erc20price,
        uint32  _maxPublicMinted,
        address _tokenAddress,
        address _forwarderAddress,
        address _erc20Address,
        string memory _appName,
        string memory _version
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        tokenAddress = _tokenAddress;
        forwarderAddress = _forwarderAddress;
        erc20Address = _erc20Address;
        price = _price;
        maxPublicMintedPerAccount = _maxPublicMinted;
        erc20price = _erc20price;
        stage = Stage.CLOSED;

        domainSeparator = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(_appName)),
            keccak256(bytes(_version)),
            block.chainid,
            address(this)
        ));
    }

    function setAdmin(address _newAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newAdmin != address(0), 'empty address');

        _grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addMinter(address _minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, _minter);
    }

    function addSigner(address _signer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(SIGNER_ROLE, _signer);
    }

    function addTweedClaimer(address _tweedClaimer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(TWEED_CLAIMER_ROLE, _tweedClaimer);
    }

    function setPrice(uint256 _price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        price = _price;
        emit ChangePrice(_price);
    }

    function setERC20Price(uint256 _price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        erc20price = _price;
        emit ChangeERC20Price(_price);
    }

    function setERC20Address(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        erc20Address = _address;
        emit ChangeERC20Address(_address);
    }

    function setMaxPublicMintedPerAccount(uint32 _maxPublicMintedPerAccount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxPublicMintedPerAccount = _maxPublicMintedPerAccount;
        emit ChangeMaxPublicMintedPerAccount(_maxPublicMintedPerAccount);
    }

    function setStage(Stage _stage) public onlyRole(DEFAULT_ADMIN_ROLE) {
        stage = _stage;
        emit ChangeStage(_stage);
    }
    
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unPause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function withdraw(address _to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(_to).transfer(address(this).balance);
    }

    function withdrawERC20(address _to, address _tokenContract, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(_tokenContract).transfer(_to, _amount);
    }

    function withdrawERC721(address _to, address _tokenContract, uint256 _tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC721(_tokenContract).transferFrom(address(this), _to, _tokenId);
    }

    function minterMint(address _owner, uint32 _amount, uint32 _setId, uint256[] calldata _options) external whenNotPaused onlyRole(MINTER_ROLE) passingStage(Stage.PRESALE) {
        IToken(tokenAddress).minterMint(_owner, _amount, _setId, _options);
    }

    function privateMint(uint32 _amount, LibWaitlist.Waitlist calldata _waitlist, bytes calldata _signature, uint256[] calldata _options) external payable whenNotPaused passingStage(Stage.PRIVATE) {
        require(verifyTypedDataHash(domainSeparator, _waitlist, _signature), "bad sig");
        require(_waitlist.owner == msg.sender, "bad sender");
        require(msg.value >= _amount * price, "bad value");
        require(privateMinted[msg.sender] + _amount <= _waitlist.amount, "bad amount");

        privateMinted[msg.sender] += _amount;

        IToken(tokenAddress).mint(msg.sender, _amount, _waitlist.setId, _options);

        payable(forwarderAddress).transfer(msg.value);
    }

    // minterPrivateMint is used by owner for minting tokens that were bought for fiat money
    function minterPrivateMint(address _wallet, uint32 _amount, uint32 _maxAmount, uint32 _setId, uint256[] calldata _options) external onlyRole(MINTER_ROLE) whenNotPaused passingStage(Stage.PRIVATE) {
        require(privateMinted[_wallet] + _amount <= _maxAmount, "bad amount");

        privateMinted[_wallet] += _amount;

        IToken(tokenAddress).mint(_wallet, _amount, _setId, _options);
    }

    function publicMint(uint32 _amount, uint256[] calldata _options) external payable whenNotPaused passingStage(Stage.PUBLIC) {
        require(msg.value >= _amount * price, "bad value");
        require(publicMinted[msg.sender] + _amount <= maxPublicMintedPerAccount, "bad amount");

        publicMinted[msg.sender] += _amount;

        IToken(tokenAddress).mint(msg.sender, _amount, 0, _options);

        payable(forwarderAddress).transfer(msg.value);
    }

    // minterPublicMint is used by owner for minting tokens that were bought for fiat money
    function minterPublicMint(address _wallet, uint32 _amount, uint256[] calldata _options) external onlyRole(MINTER_ROLE) whenNotPaused passingStage(Stage.PUBLIC) {
        require(publicMinted[_wallet] + _amount <= maxPublicMintedPerAccount, "bad amount");

        publicMinted[_wallet] += _amount;

        IToken(tokenAddress).mint(_wallet, _amount, 0, _options);
    }

    function privateMintERC20(uint32 _amount, LibWaitlist.Waitlist calldata _waitlist, bytes calldata _signature, uint256[] calldata _options) external whenNotPaused passingStage(Stage.PRIVATE) {
        require(erc20Address != address(0), 'erc20 disabled');
        require(verifyTypedDataHash(domainSeparator, _waitlist, _signature), "bad sig");
        require(_waitlist.owner == msg.sender, "bad sender");
        require(privateMinted[msg.sender] + _amount <= _waitlist.amount, "bad amount");

        privateMinted[msg.sender] += _amount;

        IERC20(erc20Address).transferFrom(msg.sender, forwarderAddress, _amount * erc20price);
        IToken(tokenAddress).mint(msg.sender, _amount, _waitlist.setId, _options);
    }

    function publicMintERC20(uint32 _amount, uint256[] calldata _options) external whenNotPaused passingStage(Stage.PUBLIC) {
        require(erc20Address != address(0), 'erc20 disabled');
        require(publicMinted[msg.sender] +_amount <= maxPublicMintedPerAccount, "bad amount");

        publicMinted[msg.sender] += _amount;

        IERC20(erc20Address).transferFrom(msg.sender, forwarderAddress, _amount * erc20price);
        IToken(tokenAddress).mint(msg.sender, _amount, 0, _options);
    }

    modifier passingStage(Stage _stage) {
        require(stage == _stage, "bad stage");

        _;
    }     

    function verifyTypedDataHash(bytes32 _domainSeparator, LibWaitlist.Waitlist calldata _waitlist, bytes calldata _signature) internal view returns (bool) {
        bytes32 digest = ECDSA.toTypedDataHash(_domainSeparator, LibWaitlist.hash(_waitlist));
        address signer = ECDSA.recover(digest, _signature);

        return hasRole(SIGNER_ROLE, signer);
    }

    function tweedMint(address _wallet, string calldata _tokenUri) external onlyRole(TWEED_CLAIMER_ROLE) whenNotPaused passingStage(Stage.PUBLIC) {
        require(publicMinted[_wallet] < maxPublicMintedPerAccount, "bad amount");

        publicMinted[_wallet]++;

        IToken(tokenAddress).mint(_wallet, 1, 0, new uint256[](1));
    }
}