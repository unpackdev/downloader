// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./Strings.sol";
import "./BitMaps.sol";
import "./ERC721A.sol";

contract LILPALS is ERC721A, EIP712, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;
    uint256 public collectionSize;
    uint256 public freeMintCount;
    string public baseURI;
    address private signerAddress;
    address private withdrawAddress;
    enum SalePhase {
        Paused,
        Free,
        AllowList,
        Public,
        WhiteList
    }

    struct WhiteListInfo {
            uint64 startTimestamp;
            uint64 price;
            uint64 maxMint;
            uint64 phase;
            uint256 whiteListMinted;    
        }

    struct SaleConfig {
        uint64 startTimestamp;
        uint64 price;
        uint64 maxMint;
        SalePhase phase;
    }

    mapping(SalePhase => mapping(address => uint256)) public mintedCount;

    SaleConfig public saleConfig;

    SaleConfig public whiteListConfig;

    constructor(
        address _signerAddress,
        address _withdrawAddress,
        uint16 _collectionSize
    ) ERC721A("LILPALS", "LILPALS") EIP712("LILPALS", "1") {
        signerAddress = _signerAddress;
        withdrawAddress = _withdrawAddress;
        collectionSize = _collectionSize;
        freeMintCount = 1000;
        _safeMint(owner(), 1);
    }

    function setSignerAddress(address newSignerAddress) external onlyOwner {
        signerAddress = newSignerAddress;
    }

    function setWithdrawAddress(address newWithdrawAddress) external onlyOwner {
        withdrawAddress = newWithdrawAddress;
    }

    modifier isAtSalePhase(SalePhase phase) {
        unchecked {
            require(
                saleConfig.phase == phase &&
                    block.timestamp >= saleConfig.startTimestamp,
                "Sale phase mismatch."
            );
        }
        _;
    }

    modifier isAtSalePhaseWhite(SalePhase phase) {
        unchecked {
            require(
                whiteListConfig.phase == phase &&
                    block.timestamp >= whiteListConfig.startTimestamp,
                "Sale phase mismatch."
            );
        }
        _;
    }

    function checkAndUpdateMintedCount(SalePhase phase, uint256 quantity)
        private
    {
        unchecked {
            require(
                mintedCount[phase][msg.sender] + quantity <= saleConfig.maxMint,
                "Too many lilpals to adopt."
            );

            mintedCount[phase][msg.sender] += quantity;
        }
    }

     function checkAndUpdateMintedCountWhite(SalePhase phase, uint256 quantity)
        private
    {
        unchecked {
            require(
                mintedCount[phase][msg.sender] + quantity <= whiteListConfig.maxMint,
                "Too many lilpals to adopt."
            );
            mintedCount[phase][msg.sender] += quantity;
        }
    }

    modifier checkPrice(SalePhase phase, uint256 quantity) {
        unchecked {
            require(
                msg.value == quantity * saleConfig.price,
                "Incorrect price."
            );
        }
        _;
    }

     modifier checkPriceWhite(SalePhase phase, uint256 quantity) {
        unchecked {
            require(
                msg.value == quantity * whiteListConfig.price,
                "Incorrect price."
            );
        }
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    modifier isWithdrawAddress() {
        require(
            withdrawAddress == msg.sender,
            "The caller is incorrect address."
        );
        _;
    }

    function _hash(string memory _prefix, address _address)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_prefix, address(this), _address));
    }

    function _verify(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return (_recover(hash, signature) == signerAddress);
    }

    function _recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(signature);
    }

    function whiteListAdopt(
        uint256 quantity,
        bytes32 hash,
        bytes calldata signature
    )
        external
        payable
        callerIsUser
        isAtSalePhaseWhite(SalePhase.WhiteList)
        checkPriceWhite(SalePhase.WhiteList, quantity)
    {
        checkAndUpdateMintedCountWhite(SalePhase.WhiteList, quantity);
        require(_hash("whiteList", msg.sender) == hash, "Invalid hash.");
        require(_verify(hash, signature), "Invalid signature.");
        unchecked {
            require(
                _totalMinted() + quantity <= collectionSize,
                "Max supply reached."
            );
        }

        _safeMint(msg.sender, quantity);
    }


    function allowListAdopt(
        uint256 quantity,
        bytes32 hash,
        bytes calldata signature
    )
        external
        payable
        callerIsUser
        isAtSalePhase(SalePhase.AllowList)
        checkPrice(SalePhase.AllowList, quantity)
    {
        checkAndUpdateMintedCount(SalePhase.AllowList, quantity);
        require(_hash("allowList", msg.sender) == hash, "Invalid hash.");
        require(_verify(hash, signature), "Invalid signature.");
        unchecked {
            require(
                _totalMinted() + quantity <= collectionSize,
                "Max supply reached."
            );
        }

        _safeMint(msg.sender, quantity);
    }

    function freeAdopt(
        uint256 quantity
    )
        external
        payable
        callerIsUser
        isAtSalePhase(SalePhase.Free)
        checkPrice(SalePhase.Free, quantity)
    {
        checkAndUpdateMintedCount(SalePhase.Free, quantity);
        unchecked {
            require(
                _totalMinted() + quantity <= collectionSize,
                "Max supply reached."
            );
        }
        unchecked {
            require(
                _totalMinted() + quantity <= freeMintCount,
                "Free mint supply reached."
            );
        }
        _safeMint(msg.sender, quantity);
    }

    function publicAdopt(
        uint256 quantity
    )
        external
        payable
        callerIsUser
        isAtSalePhase(SalePhase.Public)
        checkPrice(SalePhase.Public, quantity)
    {
        checkAndUpdateMintedCount(SalePhase.Public, quantity);        
        unchecked {
            require(
                _totalMinted() + quantity <= collectionSize,
                "Max supply reached."
            );
        }

        _safeMint(msg.sender, quantity);
    }

    function startFreeSale(uint64 startTime, uint64 maxMint)
        external
        onlyOwner
    {
        saleConfig = SaleConfig(startTime, 0, maxMint, SalePhase.Free);
    }

    function startAllowlistSale(
        uint64 price,
        uint64 startTime,
        uint64 maxMint
    ) external onlyOwner {
        saleConfig = SaleConfig(startTime, price, maxMint, SalePhase.AllowList);
    }

    function startPublicSale(
        uint64 price,
        uint64 startTime,
        uint64 maxMint
    ) external onlyOwner {
        saleConfig = SaleConfig(startTime, price, maxMint, SalePhase.Public);
    }

    function setSaleConfig(SaleConfig calldata _saleConfig) external onlyOwner {
        saleConfig = _saleConfig;
    }

    function startWhiteListSale(uint64 price,uint64 startTime, uint64 maxMint)
        external
        onlyOwner
    {
        whiteListConfig = SaleConfig(startTime, price, maxMint, SalePhase.WhiteList);
    }    

     function pauseWhiteListSale(uint64 price,uint64 startTime, uint64 maxMint)
        external
        onlyOwner
    {
        whiteListConfig = SaleConfig(startTime, price, maxMint, SalePhase.Paused);
    }   

    function setSaleConfigWhiteList(SaleConfig calldata _saleConfig) external onlyOwner {
        whiteListConfig = _saleConfig;
    }

    function setFreeMintCount(uint64 _freeMintCount)
        external
        onlyOwner
    {
        freeMintCount = _freeMintCount;
    }

  function setCollectionSize(uint64 _collectionSize)
        external
        onlyOwner
    {
        collectionSize = _collectionSize;
    }


    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function withdraw(address beneficiary) external onlyOwner {
        payable(beneficiary).transfer(address(this).balance);
    }

    function withdraw() external isWithdrawAddress  callerIsUser() {
        payable(withdrawAddress).transfer(address(this).balance);
    }

    function getMintedInfo(address _address)
        external
        view
        returns (
            uint256 freeMinted,
            uint256 allowListMinted,
            uint256 publicMinted,            
            uint256 totalMinted,
            uint256 _collectionSize,          
            uint64 startTimestamp,
            uint64 price,
            uint64 maxMint,
            uint64 phase,
            WhiteListInfo memory _whiteListInfo     
        )
    {
        uint256 _whiteListMinted = mintedCount[SalePhase.WhiteList][_address];
        return (
            mintedCount[SalePhase.Free][_address],
            mintedCount[SalePhase.AllowList][_address],
            mintedCount[SalePhase.Public][_address],
            _totalMinted(),
            collectionSize,           
            saleConfig.startTimestamp,
            saleConfig.price,
            saleConfig.maxMint,
            saleConfig.phase==SalePhase.Paused?0:saleConfig.phase==SalePhase.Free?1:saleConfig.phase==SalePhase.AllowList?2:3,
           WhiteListInfo(whiteListConfig.startTimestamp,whiteListConfig.price,whiteListConfig.maxMint,
           (whiteListConfig.phase==SalePhase.Paused?0:whiteListConfig.phase==SalePhase.Free?1:whiteListConfig.phase==SalePhase.AllowList?2:whiteListConfig.phase==SalePhase.Public?3:4)
           ,_whiteListMinted)
        );
    }
}
