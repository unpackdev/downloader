// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Strings.sol";

abstract contract OGBlockBasedSale is Ownable {
    using SafeMath for uint256;

    enum SaleState {
        NotStarted,
        PublicSaleBeforeWithBlock,
        PublicSaleDuring
    }

    enum SalePhase {
        None,
        Public
    }

    address public operatorAddress;
    uint256 public maxPublicSalePerTx = 1;
    uint256 public totalPublicMinted = 0;
    uint256 public maxSupply = 10000;

    uint256 public publicSalePrice;

    uint256 public nextSubsequentSale = 0;
    uint256 public subsequentSaleBlockSize = 10; //Subject to change per production config
    uint256 public publicSaleCap = 1000;

   SalePhase public salePhase = SalePhase.None;

    modifier operatorOnly() {
        require(
            msg.sender == operatorAddress,
            "Only operator allowed."
        );
        _;
    }

    function enablePublicSale() external {
        salePhase = SalePhase.Public;
    }

    function disablePublicSale() external {
        salePhase = SalePhase.None;
    }

    function getState() public view virtual returns (SaleState) {
        return block.number >= nextSubsequentSale
                ? SaleState.PublicSaleDuring
                : SaleState.PublicSaleBeforeWithBlock;
    }
}

contract StudioProfile is
    Ownable,
    ERC721,
    ERC721Enumerable,
    OGBlockBasedSale
{
    using Address for address;
    using SafeMath for uint256;

    event Purchased(address indexed account, uint256 indexed index);
    event MintAttempt(address indexed account, bytes data);
    event WithdrawNonPurchaseFund(uint256 balance);
    uint256 public maxSaleCapped = 10000;

    mapping(address => uint256) public purchaseCount;

    struct RequestTime {
        address sender;
        uint blockTime;
        uint triggerTime;
        uint requestTime;
        bytes transactionHash;
    }

    mapping(address => mapping(uint => RequestTime[])) public requestTimeMap;

    event NewRequest(address, uint, uint, uint);

    constructor() ERC721("TestStudio", "TS") {
        maxSupply = 10000;
        publicSalePrice = 0;
        operatorAddress = msg.sender;
    }

    function getRequestTime(uint blockNumber) external view returns (RequestTime[] memory) {
        return requestTimeMap[msg.sender][blockNumber];
    }

    function doProfileRequest(uint triggerTime, uint requestTime, bytes calldata transactionHash) external {
        RequestTime[] storage requestTimes = requestTimeMap[msg.sender][block.number];

        RequestTime memory request = RequestTime(msg.sender, block.timestamp, triggerTime, requestTime, transactionHash);
        requestTimes.push(request);
        emit NewRequest(msg.sender, block.timestamp, triggerTime, requestTime);
    }

    function mintToken(uint256 amount, bytes calldata signature) external payable
    {
        require(msg.sender == tx.origin, "Contract is not allowed.");
        require(salePhase == SalePhase.Public, "Public sale is not enabled.");
        require(getState() == SaleState.PublicSaleDuring, "Sale not available.");
        require(amount <= maxPublicSalePerTx, "Mint exceed transaction limits.");

        require(
            purchaseCount[msg.sender] + amount <= maxSaleCapped,
            "Max purchase reached"
        );

        emit MintAttempt(msg.sender, signature);
        _mintToken(msg.sender, amount);
        totalPublicMinted = totalPublicMinted + amount;
            
        nextSubsequentSale = block.number + subsequentSaleBlockSize;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() external operatorOnly {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit WithdrawNonPurchaseFund(balance);
    }

    function _mintToken(address addr, uint256 amount) internal returns (bool) {
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenIndex = totalSupply();
            purchaseCount[addr] += 1;
            if (tokenIndex < maxSupply) {
                _safeMint(addr, tokenIndex + 1);
                emit Purchased(addr, tokenIndex);
            }
        }
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}