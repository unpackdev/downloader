//  SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

//import "./console.sol";

contract HOURAI is Ownable, ERC721A {

    string public baseURI;

    struct Config {
        uint256 maxBatchSize;
        uint256 maxSize;
        uint256 maxMintSize;
        uint256 maxReservedSize;
        uint256 startTimeOfWhiteListMint;
        uint256 startTimeOfPublicSale;
        uint256 priceOfWhiteListMintABC;
        uint256 priceOfWhiteListMintD;
        uint256 priceOfPublicSale;
    }

    uint256 public mintNum;
    uint256 public reservedMintNum;

    Config public config;

    uint8 constant TYPE_NOT_WHITELIST = 0;
    uint8 constant TYPE_A = 1;
    uint8 constant TYPE_B = 2;
    uint8 constant TYPE_C = 3;
    uint8 constant TYPE_D = 4;

    /// @dev 8 * remain + Type
    mapping(address=>uint8) public whiteListRemainType;
    mapping(address=>uint8) public publicSaleNum;

    bool public enable;

    address public ethReceiver;

    receive() external payable {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Contract Caller");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        Config memory config_,
        address ethReceiver_
    ) ERC721A(name_, symbol_, config_.maxBatchSize, config_.maxSize) {
        baseURI = baseURI_;
        mintNum = 0;
        reservedMintNum = 0;
        config = config_;
        config.maxReservedSize = config_.maxSize - config_.maxMintSize;
        enable = true;
        ethReceiver = ethReceiver_;
        require(config_.startTimeOfWhiteListMint < config_.startTimeOfPublicSale, "Whitelist First");
        require(ethReceiver != address(0), 'eth receiver cannot be zero');
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setWhiteListAddress(address[] calldata addrList, uint8 whiteListType) external onlyOwner {
        require(whiteListType > 0 && whiteListType < 5, 'whitelist Type Error');
        uint8 sizePerAddr = 1;
        if (whiteListType == TYPE_B) {
            sizePerAddr = 2;
        } else if (whiteListType == TYPE_C) {
            sizePerAddr = 10;
        }
        uint8 remainType = sizePerAddr * 8 + whiteListType;
        for (uint256 i = 0; i < addrList.length; i ++) {
            whiteListRemainType[addrList[i]] = remainType;
        }
    }

    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }

    function _checkPayableAndRefundIfOver(uint256 totalPrice) private {
        require(msg.value >= totalPrice, "Need ETH");
        if (msg.value > totalPrice) {
            _safeTransferETH(msg.sender, msg.value - totalPrice);
        }
    }

    function _mint721A(uint256 quantity, address to) internal {
        uint256 batch = quantity / config.maxBatchSize;
        uint256 remain = quantity % config.maxBatchSize;
        for (uint256 i = 0; i < batch; i ++) {
            _safeMint(to, config.maxBatchSize);
        }
        if (remain > 0) {
            _safeMint(to, remain);
        }
    }

    function getPrice(address user, uint256 timestamp) internal view returns(uint256) {
        if (timestamp >= config.startTimeOfPublicSale) {
            return config.priceOfPublicSale;
        }
        uint8 remainType = whiteListRemainType[user];
        if (remainType % 8 == TYPE_D) {
            return config.priceOfWhiteListMintD;
        }
        return config.priceOfWhiteListMintABC;
    }

    /// @notice Add the callerIsUser modifier to avoid potential attack by Multicall warpper or other malicious contracts.
    function mint(uint256 quantity) external payable callerIsUser {
        require(enable, "Not Enable");
        require(quantity > 0, "Quantity > 0");
        require(block.timestamp >= config.startTimeOfWhiteListMint, "Not Start");
        require(mintNum + quantity <= config.maxMintSize, "MINT NFT O");
        uint256 price = getPrice(msg.sender, block.timestamp);
        _checkPayableAndRefundIfOver(quantity * price);

        if (block.timestamp < config.startTimeOfPublicSale) {
            // time for white list mint
            // do not need to explitly check in 8.0
            uint256 remainType = uint256(whiteListRemainType[msg.sender]) - quantity * 8;
            whiteListRemainType[msg.sender] = uint8(remainType);
        } else {
            // time for public sale mint
            uint256 saleNum = uint256(publicSaleNum[msg.sender]);
            require(saleNum + quantity <= 1, "Public Sale Only 1 NFT");
            publicSaleNum[msg.sender] = uint8(saleNum + quantity);
        }
        mintNum += quantity;
        _mint721A(quantity, msg.sender);
    }

    function tokensOfUser(address user)
        public
        view
        returns (uint256[] memory tokenIdList)
    {
        uint256 size = balanceOf(user);
        if (size == 0) {
            return tokenIdList;
        }
        tokenIdList = new uint256[](size);
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdx = 0;
        address currOwnershipAddr = address(0);
        for (uint256 i = 0; i < numMintedSoFar; i++) {
            if (tokenIdx == size) {
                break;
            }
            TokenOwnership memory ownership = _ownerships[i];
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == user) {
                tokenIdList[tokenIdx] = i;
                tokenIdx ++;
            }
        }
        return tokenIdList;
    }

    // management interfaces

    function collectEther() external {
        require(msg.sender == ethReceiver, "Not Receiver");
        _safeTransferETH(msg.sender, address(this).balance);
    }

    function sendEther() external onlyOwner {
        _safeTransferETH(ethReceiver, address(this).balance);
    }

    function reservedMintFor(uint256 quantity, address recipient) external onlyOwner {
        require(reservedMintNum + quantity <= config.maxReservedSize, 'Reserved Mint O');
        _mint721A(quantity, recipient);
        reservedMintNum += quantity;
    }

    function modifyEnable(bool enable_) external onlyOwner {
        enable = enable_;
    }

    function modifyStartTimeOfWhiteListMint(uint256 startTimeOfWhiteListMint) external onlyOwner {
        require(block.timestamp < config.startTimeOfWhiteListMint, "White List Mint Has Started");
        require(block.timestamp <= startTimeOfWhiteListMint, "New Start Time Too Late");
        require(startTimeOfWhiteListMint < config.startTimeOfPublicSale, "White List Mint First");
        config.startTimeOfWhiteListMint = startTimeOfWhiteListMint;
    }

    function modifyStartTimeOfPublicSale(uint256 startTimeOfPublicSale) external onlyOwner {
        require(block.timestamp < config.startTimeOfPublicSale, "Public Sale Has Started");
        require(block.timestamp <= startTimeOfPublicSale, "New Start Time Too Late");
        require(config.startTimeOfWhiteListMint < startTimeOfPublicSale, "White List Mint First");
        config.startTimeOfPublicSale = startTimeOfPublicSale;
    }
}