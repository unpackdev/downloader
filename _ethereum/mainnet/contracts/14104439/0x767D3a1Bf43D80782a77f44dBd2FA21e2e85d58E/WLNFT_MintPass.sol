// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ChainlinkClient.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721A.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract NFT {
    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256 balance);
}

contract WLNFT_MintPass is ERC721A, ChainlinkClient, Ownable, ContextMixin, NativeMetaTransaction {

    using Chainlink for Chainlink.Request;
    using SafeMath for uint256;

    // erc721 variables
    address constant WALLET1 = 0xffe5CBCDdF2bd1b4Dc3c00455d4cdCcf20F77587;
    address constant WALLET2 = 0xe5c07AcF973Ccda3a141efbb2e829049591F938e;
    address constant WALLET3 = 0xC87C8BF777701ccFfB1230051E33f0524E5975b5;
    uint256 public basePrice = 0.1 * 10 ** 18;
    uint256 public maxPerWallet = 1;
    uint256 public maxPerTransaction = 5;
    uint256 public maxSupply = 10000;
    uint256 public preSalePhase = 1;
    bool public preSaleIsActive = true;
    bool public saleIsActive = false;
    address[] public contracts;
    address proxyRegistryAddress;
    string _baseTokenURI;
    bytes32[] public requestIds;


    // oracle variables
    string private apiUrl = "https://api.whitelistnft.xyz/isWhitelisted";
    bytes32 private oracleJob = "1fa257cfc5f943a6b55903de8628647a";
    address private oracleAddress = 0xbEa7893Bcc9B48126ad37648814a402EaBD2E5eD;
    uint256 private oraclePayment = 0.001 * 10 ** 18;

    constructor(address _proxyRegistryAddress) ERC721A("WhitelistNFT MintPass", "WxMINT", 100) {
        proxyRegistryAddress = _proxyRegistryAddress;
        setPublicChainlinkToken();
    }

    struct ContractWhitelist {
        bool exists;
        NFT nft;
        uint256 usedSpots;
        uint256 availSpots;
    }
    mapping(address => ContractWhitelist) public contractWhitelist;

    struct Minter {
        bool exists;
        uint256 hasMintedByAddress;
        uint256 hasMintedByContract;
        bytes32 requestId;

    }
    mapping(address => Minter) minters;

    struct Request {
        address addr;
        uint256 quantity;
        uint256 value;
    }
    mapping(bytes32 => Request) public requests;

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function baseTokenURI() virtual public view returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    function setOracleAddress(address _address) public onlyOwner {
        oracleAddress = _address;
    }

    function setOracleJob(bytes32 _job) public onlyOwner {
        oracleJob = _job;
    }

    function setApiUrl(string memory _url) public onlyOwner {
        apiUrl = _url;
    }

    function setOraclePayment(uint256 _amount) public onlyOwner {
        oraclePayment = _amount;
    }

    function addressToString(address _address) internal pure returns(string memory) {
        bytes memory data = abi.encodePacked(_address);
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function isWhitelistedByContract(address _address)
        public
        view
        returns (bool, uint256)
    {
        for (uint256 i = 0; i < contracts.length; i += 1) {
            if (
                contractWhitelist[contracts[i]].nft.balanceOf(_address) > 0 &&
                contractWhitelist[contracts[i]].usedSpots < contractWhitelist[contracts[i]].availSpots
            ) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function addContractToWhitelist(address _address, uint256 _availSpots)
        public
        onlyOwner
        returns (bool)
    {
        (bool _isWhitelisted, ) = isWhitelistedContract(_address);
        require(!_isWhitelisted,  "Contract already whitelisted.");
        contractWhitelist[_address].exists = true;
        contractWhitelist[_address].nft = NFT(_address);
        contractWhitelist[_address].availSpots = _availSpots;
        contracts.push(_address);
        return true;
    }

    function updateContractWhitelist(address _address, uint256 _availSpots)
        public
        onlyOwner
        returns (bool)
    {
        (bool _isWhitelisted, ) = isWhitelistedContract(_address);
        require(_isWhitelisted,  "Contract is not whitelisted.");
        contractWhitelist[_address].availSpots = _availSpots;
        return true;
    }

    function removeContractFromWhitelist(address _address)
        public
        onlyOwner
        returns (bool)
    {
        (bool _isWhitelisted, uint256 i) = isWhitelistedContract(_address);
        require(_isWhitelisted, "Contract is not whitelisted.");
        contracts[i] = contracts[contracts.length - 1];
        contracts.pop();
        delete contractWhitelist[_address];
        return true;
    }

    function isWhitelistedContract(address _address)
        internal
        view
        returns (bool, uint256)
    {
        for (uint256 i = 0; i < contracts.length; i += 1) {
            if (_address == contracts[i] && contractWhitelist[_address].exists) return (true, i);
        }
        return (false, 0);
    }


    function setPreSalePhase(uint8 _phase) public onlyOwner {
        require(_phase == 1 || _phase == 2, "Invalid presale phase.");
        preSalePhase = _phase;
    }

    function setBasePrice(uint256 _price) public onlyOwner {
        basePrice = _price;
    }

    function setMaxPerWallet(uint256 _maxToMint) public onlyOwner {
        maxPerWallet = _maxToMint;
    }

    function setMaxPerTransaction(uint256 _maxToMint) public onlyOwner {
        maxPerTransaction = _maxToMint;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function reserve(address _address, uint256 _quantity) public onlyOwner {
        _safeMint(_address, _quantity);
    }

    function isRefundable(address _address) public view returns (uint256) {
        uint256 amount = 0;
        for(uint i = 0; i < requestIds.length; i++) {
            if (requests[requestIds[i]].addr == _address && minters[_address].requestId != requestIds[i]) {
                amount = amount.add(requests[requestIds[i]].value);
            }
        }
        return amount;
    }

    function refund() public returns (bool) {
        for(uint i = 0; i < requestIds.length; i++) {
            if (requests[requestIds[i]].addr == msg.sender) {
                if (minters[msg.sender].requestId == requestIds[i]) {
                    removeRequest(requestIds[i]);
                    require(minters[msg.sender].requestId != requestIds[i], "Refund rejected. You successfully minted this request.");
                    return false;
                } else {
                    payable(msg.sender).transfer(requests[requestIds[i]].value.mul(75).div(100));
                    removeRequest(requestIds[i]);
                    return true;
                }
            }
        }
        return false;
    }

    function removeRequest(bytes32 _requestId)
        internal
        returns (bool)
    {
        require(requests[_requestId].value > 0, "Request does not exist.");
        for (uint256 i = 0; i < requestIds.length; i += 1) {
            if (_requestId == requestIds[i] && requests[_requestId].value > 0) {
                requestIds[i] = requestIds[requestIds.length - 1];
                requestIds.pop();
                delete requests[_requestId];
                return true;
            }
        }
        return false;
    }

    function preSalePrice() public view returns (uint256) {
        return getPrice();
    }

    function pubSalePrice() public view returns (uint256) {
        return getPrice();
    }

    function getPrice() public view returns (uint256) {
        if (totalSupply() >= 6101) {
            return basePrice * 4;
        } else if (totalSupply() >= 3101) {
            return basePrice * 3;
        } else if (totalSupply() >= 1101) {
            return basePrice * 2;
        } else {
            return basePrice;
        }
    }

    // whitelist minting
    function mintPhase1(uint256 _quantity, uint256 _value) internal returns (bytes32 requestId) {
        require(minters[msg.sender].hasMintedByAddress.add(_quantity) <= maxPerWallet, "Exceeds per wallet presale limit.");
        string[] memory params = new string[](4);
        params[0] = string("address");
        params[1] = addressToString(address(msg.sender));
        params[2] = string("collection");
        params[3] = "1";

        Chainlink.Request memory request = buildChainlinkRequest(oracleJob, address(this), this.fulfill.selector);  
        request.add("get", apiUrl);
        request.add("path", "isWhitelisted");
        request.addStringArray("queryParams", params);
        
        bytes32 id = sendChainlinkRequestTo(oracleAddress, request, oraclePayment);
        requests[id].addr = msg.sender;
        requests[id].quantity = _quantity;
        requests[id].value = _value;
        requestIds.push(id);
        return id;
    }

    function fulfill(bytes32 _requestId, bool _isWhitelisted) public recordChainlinkFulfillment(_requestId) {
        if (_isWhitelisted) {
            require(requests[_requestId].value > 0, "No pending transactions from this address.");
            address addr = requests[_requestId].addr;
            uint256 quantity = requests[_requestId].quantity;
            if (!minters[addr].exists) minters[addr].exists = true;
            minters[addr].hasMintedByAddress = minters[addr].hasMintedByAddress.add(quantity);
            minters[addr].requestId = _requestId;
            _safeMint(addr, quantity);
            removeRequest(_requestId);
        } else {
            require(requests[_requestId].value > 0, "No pending transactions from this address.");
            // this should never fire unless people are minting from contract, in which case they will pay a 25% gas pentalty
            payable(requests[_requestId].addr).transfer(requests[_requestId].value.mul(75).div(100));
            removeRequest(_requestId);
        }
    }

    // partner minting
    function mintPhase2(uint256 _quantity) internal {
        (bool _isWhitelisted, uint256 idx) = isWhitelistedByContract(msg.sender);
        require(_isWhitelisted, "You are not a holder of a whitelisted collection with available spots remaining.");
        require(minters[msg.sender].hasMintedByContract.add(_quantity) <= maxPerWallet, "Exceeds per wallet presale limit.");
        if (minters[msg.sender].exists) {
            if (minters[msg.sender].hasMintedByContract == 0) {
                contractWhitelist[contracts[idx]].usedSpots = contractWhitelist[contracts[idx]].usedSpots.add(1);
            }
            minters[msg.sender].hasMintedByContract = minters[msg.sender].hasMintedByContract.add(
                _quantity
            );
        } else {
            minters[msg.sender].exists = true;
            minters[msg.sender].hasMintedByContract = _quantity;
            contractWhitelist[contracts[idx]].usedSpots = contractWhitelist[contracts[idx]].usedSpots.add(1);
        }
        _safeMint(msg.sender, _quantity);
    }

    function mint(uint _quantity) public payable {
        uint256 currentSupply = totalSupply();
        require(saleIsActive, "Sale is not active.");
        require(msg.value > 0, "Must send ETH to mint.");
        require(currentSupply <= maxSupply, "Sold out.");
        require(currentSupply.add(_quantity) <= maxSupply, "Requested quantity would exceed total supply.");
        if(preSaleIsActive) {
            require(getPrice().mul(_quantity) <= msg.value, "ETH sent is incorrect.");
            require(_quantity <= maxPerWallet, "Exceeds wallet presale limit.");
            if (preSalePhase == 1) {
                mintPhase1(_quantity, msg.value);
            }
            if (preSalePhase == 2) {
                mintPhase2(_quantity);
            }
        } else {
            require(getPrice().mul(_quantity) <= msg.value, "ETH sent is incorrect.");
            require(_quantity <= maxPerTransaction, "Exceeds per transaction limit for public sale.");
            _safeMint(msg.sender, _quantity);
        }
    }

    function withdrawLINK() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        link.transfer(msg.sender, link.balanceOf(address(this)));
    }

    function withdraw() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        uint256 balance1 = totalBalance.mul(45).div(100);
        uint256 balance2 = totalBalance.mul(225).div(1000);
        uint256 balance3 = totalBalance.mul(225).div(1000);
        payable(WALLET1).transfer(balance1);
        payable(WALLET2).transfer(balance2);
        payable(WALLET3).transfer(balance3);
        uint256 balance4 = totalBalance.sub(balance1.add(balance2).add(balance3));
        payable(msg.sender).transfer(balance4);
    }
}

