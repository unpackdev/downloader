// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./AccessControl.sol";
import "./Strings.sol";

interface IGoldenMembers {
    function mint(address buyer) external returns (bool);

    function getCurrentTokenId() external view returns (uint256);

    function cap() external view returns (uint256);

}

contract GoldenEggis is ERC721Enumerable, AccessControl {
    
    using Strings for uint256;

    uint256 private constant BASE = 10000;
    string public uriSuffix = ".json";
    address public goldenMemberNFT;

    uint256 public tokenPricePreSale;
    uint256 public tokenPricePublicSale;
    uint256 public maxNftAllowedPresale;
    uint256 public maxNftAllowedPublicSale;

    uint256 public airdropLastTokenId;
    uint256 public airdropMaxTokenId;

    uint256 public preSaleLastTokenId;
    uint256 public preSaleMaxTokenId;

    uint256 public lastTokenId;
    uint256 public maxTokenId;

    uint256 public preSaleOpenTime;
    uint256 public preSaleCloseTime;
    uint256 public publicSaleStartTime;

    uint256 public totalMints;
    uint256 public presaleMints;

    uint256 public receiverPercentage;

    address public receiverWallet1 = 0x37ed71206D8e4B73158cd49307268c3d4C17F949;
    address public receiverWallet2 = 0xcC939619eD4A570174C5Dda5a7Ae1095451aA7ce;
    address public receiverWallet3 = 0x50672d7315787C3597C73FfE31e024e370ceeb91;

    bool public isMintingEnabled;

    string public _baseTokenURI;

    mapping(address => uint256) public userPresaleMintCount;
    mapping(address => uint256) public userPublicsaleMintCount;

    event MaxNftAllowedPresale(uint256 maxNFTAllowed);
    event MaxNftAllowedPublicSale(uint256 maxNFTAllowed);
    event PreSalePrice(uint256 preSalePrice);
    event PublicSalePrice(uint256 publicSalePrice);
    event PresaleOpenTime(uint256 preSaleOpenTime);
    event PresaleCloseTime(uint256 preSaleCloseTime);
    event PublicsaleStartTime(uint256 publicSaleStartTime);
    event PublicSaleTokenRange(uint256 lastTokenId, uint256 maxTokenId);
    event AirdropTokenRange(uint256 lastTokenId, uint256 maxTokenId);
    event WithdrawEthereum(address walletAddress, uint256 withdrawAmount);
    event Airdrop(address airdropWallet, uint256 tokenId);

    constructor() ERC721("GoldenEggis", "GoldenEggis") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        isMintingEnabled = true;
        maxNftAllowedPresale = 1;
        maxNftAllowedPublicSale = 2;
        preSaleLastTokenId = 198;
        preSaleMaxTokenId = 1198;
        maxTokenId = 9998;
        airdropMaxTokenId = 197;
        tokenPricePreSale = 0.09 ether;
        tokenPricePublicSale = 0.09 ether;
        receiverPercentage = 3333;
        preSaleOpenTime = 1656334800;
        preSaleCloseTime = 1658926800;
        publicSaleStartTime = 1658926801;
        _baseTokenURI = "https://goldenidclub.mypinata.cloud/ipfs/QmcNH32GWnJehq9XH4UGcMqtDXUgKdWsnGPn9bFe27ppod/";
    }

    // to receive ether in the contract on each nft minting sale
    receive() external payable {}

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "GoldenEggi: Caller is not a admin"
        );
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setGoldenMemberNFT(address _goldenMemberNFT) external onlyAdmin {
        require(_goldenMemberNFT != address(0), "invalid address");
        goldenMemberNFT = _goldenMemberNFT;
    }

    function setMaxNftAllowedPublicsale(uint256 _maxNfts) external onlyAdmin {
        require(_maxNfts > 0, "invalid value");
        maxNftAllowedPublicSale = _maxNfts;
        emit MaxNftAllowedPublicSale(_maxNfts);
    }

    function setMaxNftAllowedPresale(uint256 _maxNfts) external onlyAdmin {
        require(_maxNfts > 0, "invalid value");
        maxNftAllowedPresale = _maxNfts;
        emit MaxNftAllowedPresale(_maxNfts);
    }

    function setBaseURI(string memory baseURI) public onlyAdmin {
        _baseTokenURI = baseURI;
    }

    function changePresalePrice(uint256 _newtokenPrice) public onlyAdmin {
        tokenPricePreSale = _newtokenPrice;
        emit PreSalePrice(_newtokenPrice);
    }

    function changePublicsalePrice(uint256 _newtokenPrice) public onlyAdmin {
        tokenPricePublicSale = _newtokenPrice;
        emit PublicSalePrice(_newtokenPrice);
    }

    function setPresaleOpenTime(uint256 _presaleOpenTime) external onlyAdmin {
        preSaleOpenTime = _presaleOpenTime;
        emit PresaleOpenTime(_presaleOpenTime);
    }

    function setPreSaleCloseTime(uint256 _presaleCloseTime) external onlyAdmin {
        preSaleCloseTime = _presaleCloseTime;
        emit PresaleCloseTime(_presaleCloseTime);
    }

    function setPublicSaleStartTime(uint256 _publicSaleStartTime)
        external
        onlyAdmin
    {
        publicSaleStartTime = _publicSaleStartTime;
        emit PublicsaleStartTime(_publicSaleStartTime);
    }

    function setConfig_tokenrange(uint256 _lastTokenId, uint256 _maxTokenId)
        external
        onlyAdmin
    {
        lastTokenId = _lastTokenId;
        maxTokenId = _maxTokenId;

        emit PublicSaleTokenRange(_lastTokenId, _maxTokenId);
    }

    function setConfig_airdroptokenrange(
        uint256 _lastTokenId,
        uint256 _maxTokenId
    ) external onlyAdmin {
        airdropLastTokenId = _lastTokenId;
        airdropMaxTokenId = _maxTokenId;

        emit AirdropTokenRange(_lastTokenId, _maxTokenId);
    }

    function setReceiverPercentage(uint256 _receiverPer) external onlyAdmin {
        require(
            _receiverPer > 0 && _receiverPer <= 10000,
            "GoldenEggi: percentage error"
        );
        receiverPercentage = _receiverPer;
    }

    function setMintingEnabled(bool _isEnabled) public onlyAdmin {
        isMintingEnabled = _isEnabled;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyAdmin {
        uriSuffix = _uriSuffix;
    }
    
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function mint(address _user, uint256 _tokenId) internal {

        require(_user != address(0), "GoldenEggi: mint to the zero address");
        require(!_exists(_tokenId), "GoldenEggi: ERC721: token already minted");
        _safeMint(_user, _tokenId);
    }

    function preSale(uint256 _num) public payable returns (bool result) {
        require(
            block.timestamp >= preSaleOpenTime &&
                block.timestamp <= preSaleCloseTime,
            "preSale not started or ended"
        );
        require(_num != 0, "GoldenEggi: Number of tokens cannot be zero");
        require(isMintingEnabled, "GoldenEggi: Minting paused");
        require(
            userPresaleMintCount[msg.sender] + _num <= maxNftAllowedPresale,
            "mint count exceed"
        );
        uint256 totalPrice = tokenPricePreSale * _num;
        uint256 distPrice = (totalPrice * receiverPercentage) / BASE;
        require(
            msg.value >= totalPrice,
            "GoldenEggi: Insufficient amount provided"
        );

        payable(receiverWallet1).transfer(distPrice);
        payable(receiverWallet2).transfer(distPrice);
        payable(receiverWallet3).transfer(distPrice);

        require(
            preSaleLastTokenId + _num <= preSaleMaxTokenId,
            "GoldenEggi: Mint Maximum cap reached"
        );

        for (uint256 i = 0; i < _num; i++) {
            if(notAllowedToMint(preSaleLastTokenId)) {
                preSaleLastTokenId++;
            }
            IGoldenMembers(goldenMemberNFT).mint(msg.sender);
            mint(msg.sender, preSaleLastTokenId);
            preSaleLastTokenId++;
            totalMints++;
            presaleMints++;
        }

        userPresaleMintCount[msg.sender] += _num;

        return true;
    }

    function publicSale(uint256 _num) public payable returns (bool result) {
        require(_num != 0, "GoldenEggi: Number of tokens cannot be zero");
        require(isMintingEnabled, "GoldenEggi: Minting paused");
        require(
            block.timestamp > publicSaleStartTime,
            "public sale not started"
        );
        require(
            userPublicsaleMintCount[msg.sender] + _num <= maxNftAllowedPublicSale,
            "mint count exceed"
        );
        if((block.timestamp > preSaleCloseTime) && (lastTokenId == 0)) {
            lastTokenId = preSaleLastTokenId;
        }
        uint256 totalPrice = tokenPricePublicSale * _num;
        uint256 distPrice = (totalPrice * receiverPercentage) / BASE;
        require(
            msg.value >= totalPrice,
            "GoldenEggi: Insufficient amount provided"
        );
        payable(receiverWallet1).transfer(distPrice);
        payable(receiverWallet2).transfer(distPrice);
        payable(receiverWallet3).transfer(distPrice);

        require(
            lastTokenId + _num <= maxTokenId,
            "GoldenEggi: Mint Maximum cap reached"
        );

        for (uint256 i = 0; i < _num; i++) {
            uint256 diplomaCurrentTokenId = IGoldenMembers(goldenMemberNFT).getCurrentTokenId();
            uint256 goldenMemberNFTCap = IGoldenMembers(goldenMemberNFT).cap();
            uint256 remainingDiploma = goldenMemberNFTCap - diplomaCurrentTokenId;
            if((diplomaCurrentTokenId <= goldenMemberNFTCap) && (remainingDiploma != 0)) {
                IGoldenMembers(goldenMemberNFT).mint(msg.sender);
            }
            if(notAllowedToMint(lastTokenId)) {
                lastTokenId++;
            }
            mint(msg.sender, lastTokenId);
            lastTokenId++;
            totalMints++;
        }

        userPublicsaleMintCount[msg.sender] += _num;

        return true;
    }

    function Ambassadors(address[] memory _airdropAddresses) public onlyAdmin {
        uint256 walletsLength = _airdropAddresses.length;
        require(
            airdropLastTokenId + walletsLength <= airdropMaxTokenId,
            "GoldenEggi: Mint Maximum cap reached"
        );

        for (uint256 i = 0; i < walletsLength; i++) {
            airdropLastTokenId++;
            totalMints++;
            if(notAllowedToMint(airdropLastTokenId)) {
                airdropLastTokenId++;
            }
            mint(_airdropAddresses[i], airdropLastTokenId);
            emit Airdrop(_airdropAddresses[i], airdropLastTokenId);
        }
    }

    function EggisFoundation(address _walletAddress, uint256 _tokenId) public onlyAdmin {
        require(_tokenId == 9 || _tokenId == 99 || _tokenId == 999 || _tokenId == 9999, "9, 99, 999, 9999 allowed"); 
        mint(_walletAddress, _tokenId);
        totalMints++; 
    }


    //only admin can withdraw ethereum coins
    function withdrawEth(
        uint256 _withdrawAmount,
        address payable _walletAddress
    ) public onlyAdmin {
        require(
            _withdrawAmount <= address(this).balance,
            "GoldenEggi: Amount Invalid"
        );
        (bool success, ) = payable(_walletAddress).call{value: _withdrawAmount}(
            ""
        );
        require(success, "GoldenEggi: ETH transfer failed");
        emit WithdrawEthereum(_walletAddress, _withdrawAmount);
    }

    function notAllowedToMint(uint256 _tokenId) internal pure returns(bool) {
        if(_tokenId == 9 || _tokenId == 99 || _tokenId == 999 || _tokenId == 9999) {
            return true;
        } else {
            return false;
        }
    } 
}
