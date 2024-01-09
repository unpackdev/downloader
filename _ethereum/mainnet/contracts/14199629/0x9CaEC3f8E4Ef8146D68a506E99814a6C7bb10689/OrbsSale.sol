// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./IOrbsNFT.sol";

contract OrbsSale is Ownable, ERC1155Holder {
    event MaxSaleAmountUpdated(uint64 maxSaleByEther, uint256 maxSaleBy888);
    event SaleRequested(address indexed user, uint256 amount, bool with888);
    event FlushETH(uint256 amount);
    event Flush888(address indexed to, uint256 amount);

    uint256 public constant ETH_MAX_PRICE = 1111 * 1e16;
    ///uint256 public constant ETH_MIN_PRICE = 888 * 1e16;
    uint256 public constant ETH_MIN_PRICE = 1;
    uint64 public constant ETH_SALE_COUNT = 2445;
    uint64 public constant ETH_PRICE_FREEZE_HR = 47;
    uint256 public constant EIGHT_TOKEN_ID = 888;
    uint256 public constant PRICE_IN_888_NFT = 3;

    IOrbsNFT public immutable orbsNft;
    address public immutable eigthEightEightNft;
    uint64 public immutable startTime;
    uint64 public immutable ethStartTime;
    uint64 public saledByEtherCount;
    uint64 public maxSaleByEther;
    uint64 public maxSaleBy888;

    constructor(
        address _orbsNft,
        address _eigthEightEightNft,
        uint64 _startTime,
        uint64 _maxSaleByEther,
        uint64 _maxSaleBy888
    ) {
        require(_orbsNft != address(0), "OrbsSale: orbsNft is address(0)");
        require(
            _eigthEightEightNft != address(0),
            "OrbsSale: 888NFT is address(0)"
        );
        require(
            _startTime >= block.timestamp,
            "OrbsSale: start time must be greater than now"
        );
        orbsNft = IOrbsNFT(_orbsNft);
        eigthEightEightNft = _eigthEightEightNft;
        startTime = _startTime;
        ethStartTime = _startTime + 1 days;

        setMaxSaleAmount(_maxSaleByEther, _maxSaleBy888);
    }

    function purchaseWithEther(uint64 amount) external payable {
        require(
            block.timestamp >= ethStartTime,
            "OrbsSale: eth sale not started"
        );

        require(amount <= maxSaleByEther, "OrbsSale: limit max sale amount");
        require(
            amount * currentPrice() == msg.value,
            "OrbsSale: invalid price"
        );
        saledByEtherCount += amount;
        require(
            saledByEtherCount <= ETH_SALE_COUNT,
            "OrbsSale: cannot sale with Ether"
        );
        orbsNft.requestMint(msg.sender, amount);

        emit SaleRequested(msg.sender, amount, false);
    }

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata
    ) public override returns (bytes4) {
        require(block.timestamp >= startTime, "OrbsSale: not started");

        require(msg.sender == eigthEightEightNft, "OrbsSale: not 888 NFT");
        require(id == EIGHT_TOKEN_ID, "OrbsSale: not 888 Token");
        require(value % PRICE_IN_888_NFT == 0, "OrbsSale: invalid value");
        require(from != address(0), "OrbsSale: from is address(0)");

        uint256 amount = value / PRICE_IN_888_NFT;

        require(amount <= maxSaleBy888, "OrbsSale: limit max sale amount");
        orbsNft.requestMint(from, amount);

        emit SaleRequested(from, amount, true);

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public override returns (bytes4) {
        revert("OrbsSale: Batch transfer is not allowed");
    }

    function currentPrice() public view returns (uint256) {
        if (ethStartTime >= block.timestamp) {
            return ETH_MAX_PRICE;
        }
        uint64 hrsSinceStart = (uint64(block.timestamp) - ethStartTime) /
            1 hours;

        if (hrsSinceStart > ETH_PRICE_FREEZE_HR) {
            return ETH_MIN_PRICE;
        }

        uint256 price = ETH_MAX_PRICE -
            (((ETH_MAX_PRICE - ETH_MIN_PRICE) * hrsSinceStart) /
                ETH_PRICE_FREEZE_HR);
        return ((price + 5e15) / 1e16) * 1e16;
    }

    function setMaxSaleAmount(uint64 _maxSaleByEther, uint64 _maxSaleBy888)
        public
        onlyOwner
    {
        maxSaleByEther = _maxSaleByEther;
        maxSaleBy888 = _maxSaleBy888;

        emit MaxSaleAmountUpdated(_maxSaleByEther, _maxSaleBy888);
    }

    function flushETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "OrbsSale: nothing to flush");
        payable(msg.sender).transfer(balance);

        emit FlushETH(balance);
    }

    function flush888(
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external onlyOwner {
        uint256 balance = IERC1155(eigthEightEightNft).balanceOf(
            address(this),
            EIGHT_TOKEN_ID
        );

        require(
            balance != 0 && balance >= _amount,
            "OrbsSale: nothing to flush"
        );

        uint256 amount = _amount == 0 ? balance : _amount;

        IERC1155(eigthEightEightNft).safeTransferFrom(
            address(this),
            _to,
            EIGHT_TOKEN_ID,
            amount,
            _data
        );

        emit Flush888(_to, amount);
    }
}
