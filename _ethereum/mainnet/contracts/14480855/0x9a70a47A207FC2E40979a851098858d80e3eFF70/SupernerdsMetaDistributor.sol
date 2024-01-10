// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721.sol";
import "./AccessControl.sol";
import "./ECDSA.sol";

interface SuperNerdIF {
    function totalSupply() external view returns (uint256);

    function cap() external view returns (uint256);

    function mint(address _mintTo) external returns (bool);

    function mintReserve(address _mintTo) external returns (bool);
}

contract SupernerdsMetaDistributor is AccessControl {
    SuperNerdIF public superNerd;

    bool public _mintingPaused = false;
    uint256 public tokenPrice = uint256(8 * 10**16); // = 0.08 ETH
    address public SUPERNERD_ADMIN_WALLET;

    //WHITELIST_START_TIME
    uint256 public WHITELIST_START_TIME;
    //PERSALE START TIME
    uint256 public PRE_SALE_START_TIME;
    //PUBLICSALE START TIME
    uint256 public PUBLIC_SALE_START_TIME;
    //ALPHA HOLDERS START TIME
    uint256 public ALPHA_HOLDERS_START_TIME;

    //WHITE LIST END TIME
    uint256 public WHITELIST_END_TIME; //should be in seconds

    uint256 public preSaleMintLimit;
    uint256 public whiteListMintLimit;
    uint256 public publicSaleMintLimit;

    mapping(address => bool) public whiteListUsers;

    mapping(address => uint256) public preSaleMintsPerAddress;
    mapping(address => uint256) public whiteListMintsPerAddress;
    mapping(address => uint256) public publicMintsPerAddress;
    mapping(address => uint256) public alphaHoldersMint;

    bytes32 public constant MINT_SIGNATURE = keccak256("MINT_SIGNATURE");

    constructor(SuperNerdIF _superNerd) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINT_SIGNATURE, msg.sender);

        superNerd = _superNerd;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Caller is not a admin"
        );
        _;
    }

    function changeSuperNerdAddress(SuperNerdIF _superNerd) public onlyAdmin {
        superNerd = _superNerd;
    }

    function setSuperNerdAminWallet(address _wallet) public onlyAdmin {
        require(_wallet != address(0), "address invalid");
        SUPERNERD_ADMIN_WALLET = _wallet;
    }

    function setWhitelistSaleStartTime(uint256 _whitelistStartTime)
        public
        onlyAdmin
    {
        WHITELIST_START_TIME = _whitelistStartTime;
    }

    function setPreSaleStartTime(uint256 _preSaleStartTime) public onlyAdmin {
        PRE_SALE_START_TIME = _preSaleStartTime;
    }

    function setPublicSaleStartTime(uint256 _publicSaleStartTime)
        public
        onlyAdmin
    {
        PUBLIC_SALE_START_TIME = _publicSaleStartTime;
    }

    function setAlphaHolderStartTime(uint256 _alphaHoldersSaleStartTime)
        public
        onlyAdmin
    {
        ALPHA_HOLDERS_START_TIME = _alphaHoldersSaleStartTime;
    }

    function setPreSaleMintLimit(uint256 _preSaleMintLimit) public onlyAdmin {
        preSaleMintLimit = _preSaleMintLimit;
    }

    function setPublicSaleMintLimit(uint256 _publicSaleMintLimit)
        public
        onlyAdmin
    {
        publicSaleMintLimit = _publicSaleMintLimit;
    }

    function setWhiteListMintLimit(uint256 _whiteListMintLimit)
        public
        onlyAdmin
    {
        whiteListMintLimit = _whiteListMintLimit;
    }

    function setWhiteListEndTime(uint256 _whiteListEndTime) public onlyAdmin {
        WHITELIST_END_TIME = _whiteListEndTime;
    }

    function setTokenPrice(uint256 _newPrice) public onlyAdmin {
        tokenPrice = _newPrice;
    }

    function changeMintState(bool _state) public onlyAdmin {
        _mintingPaused = _state;
    }

    /// @dev function only available for whitelist users
    function whiteListMint(uint256 _num) public payable returns (bool) {
        address wallet = _msgSender();

        require(
            block.timestamp >= WHITELIST_START_TIME &&
                block.timestamp < WHITELIST_START_TIME + WHITELIST_END_TIME,
            "Time is not suitable for whiteList"
        );

        require(whiteListUsers[wallet], "ONLY WHITELIST"); //WhiteList allowed
        require(_num > 0, "need to mint at least 1 NFT");

        require(
            msg.value >= (tokenPrice * _num),
            "Insufficient amount provided"
        );
        payable(SUPERNERD_ADMIN_WALLET).transfer(msg.value);

        uint256 ownerMintedCount = whiteListMintsPerAddress[wallet];
        require(
            ownerMintedCount + _num <= whiteListMintLimit,
            "max NFT per address exceeded"
        );

        for (uint256 i = 0; i < _num; i++) {
            superNerd.mint(wallet);
        }
        whiteListMintsPerAddress[wallet] += _num; //add the total mints per address in whitelist mapping

        return true;
    }

    function preSaleMint(uint256 _num) public payable returns (bool) {
        address wallet = _msgSender();

        require(
            block.timestamp >= PRE_SALE_START_TIME &&
                block.timestamp < PUBLIC_SALE_START_TIME,
            "Time is not suitable for presale"
        );
        require(_num > 0, "need to mint at least 1 NFT");

        require(
            msg.value >= (tokenPrice * _num),
            "Insufficient amount provided"
        );
        payable(SUPERNERD_ADMIN_WALLET).transfer(msg.value);

        uint256 ownerMintedCount = preSaleMintsPerAddress[wallet];
        require(
            ownerMintedCount + _num <= preSaleMintLimit,
            "max NFT per address exceeded"
        );

        for (uint256 i = 0; i < _num; i++) {
            superNerd.mint(wallet); //, tokenId + i + 1
        }
        preSaleMintsPerAddress[wallet] += _num; //log the total mints per address

        return true;
    }

    function publicSaleMint(uint256 _num) public payable returns (bool) {
        address wallet = _msgSender();

        require(
            block.timestamp >= PUBLIC_SALE_START_TIME,
            "Time is not suitable for Public Sale"
        );

        require(!_mintingPaused, "minting paused");
        require(_num > 0, "need to mint at least 1 NFT");
        require(
            msg.value >= (tokenPrice * _num),
            "Insufficient amount provided"
        );
        payable(SUPERNERD_ADMIN_WALLET).transfer(msg.value);

        uint256 ownerMintedCount = publicMintsPerAddress[wallet];
        require(
            ownerMintedCount + _num <= publicSaleMintLimit,
            "max NFT per address exceeded"
        );

        for (uint256 i = 0; i < _num; i++) {
            superNerd.mint(wallet); //, tokenId + i + 1
        }
        publicMintsPerAddress[wallet] += _num; //log the total mints per address

        return true;
    }

    function airdropForAlphaUsers(
        address wallet,
        uint256 _mintCount,
        uint256 _canMintTotal,
        uint256 _timestamp,
        bytes memory _signature
    ) public returns (bool) {
        require(wallet == msg.sender, "not alpha holder");
        require(!_mintingPaused, "minting paused");
        require(
            block.timestamp >= ALPHA_HOLDERS_START_TIME,
            "Time is not suitable for Alpha holders"
        );

        address signerOwner = signatureWallet(
            wallet,
            _mintCount,
            _canMintTotal,
            _timestamp,
            _signature
        );
        require(
            hasRole(MINT_SIGNATURE, signerOwner),
            "SUPERNERDNFT: Not authorized to mint"
        );

        uint256 minted = alphaHoldersMint[wallet];
        uint256 mintable = _canMintTotal - minted;

        require(mintable > 0, "already minted");
        require(_mintCount <= mintable, "quantity exceeds available mints");

        for (uint256 i = 0; i < _mintCount; i++) {
            superNerd.mintReserve(wallet);
        }
        alphaHoldersMint[wallet] += _mintCount;

        return true;
    }

    function signatureWallet(
        address wallet,
        uint256 _mintCount,
        uint256 _canMintTotal,
        uint256 _timestamp,
        bytes memory _signature
    ) public pure returns (address) {
        return
            ECDSA.recover(
                keccak256(
                    abi.encode(wallet, _mintCount, _canMintTotal, _timestamp)
                ),
                _signature
            );
    }

    function addToWhiteList(address[] calldata entries) public onlyAdmin {
        uint256 length = entries.length;
        for (uint256 i = 0; i < length; i++) {
            address entry = entries[i];
            require(entry != address(0), "Cannot add zero address");
            require(!whiteListUsers[entry], "Cannot add duplicate address");

            whiteListUsers[entry] = true;
        }
    }

    function removeFromwhiteListUsers(address[] calldata entries)
        public
        onlyAdmin
    {
        uint256 length = entries.length;

        for (uint256 i = 0; i < length; i++) {
            address entry = entries[i];
            require(entry != address(0), "Cannot remove zero address");

            whiteListUsers[entry] = false;
        }
    }
}
