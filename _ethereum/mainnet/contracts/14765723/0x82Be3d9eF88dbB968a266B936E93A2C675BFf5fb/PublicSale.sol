// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Ownable.sol";

contract PublicSale is Ownable {
    // sale switches
    bool public publicSaleActive;
    uint256 public saleStartTime;

    event PublicSaleStart(uint256 indexed _saleActiveTime);
    event PublicSalePaused(uint256 indexed _salePausedTime);
    event SaleStartSet(uint256 indexed _saleStartTime);

    modifier whenPublicSaleActive() {
        require(publicSaleActive, 'PublicSale: sale not active');
        require(saleStartTime > 0, 'PublicSale: saleStartTime not set');
        require(block.timestamp >= saleStartTime, 'PublicSale: not started');
        _;
    }

    function startPublicSale() external onlyOwner {
        require(!publicSaleActive, 'PublicSale: already active');
        publicSaleActive = true;
        emit PublicSaleStart(block.timestamp);
    }

    function pausePublicSale() external onlyOwner {
        require(publicSaleActive, 'PublicSale: already paused');
        publicSaleActive = false;
        emit PublicSalePaused(block.timestamp);
    }

    function setSaleStartAt(uint256 _saleStartTime) external onlyOwner {
        saleStartTime = _saleStartTime;
        emit SaleStartSet(_saleStartTime);
    }
}
