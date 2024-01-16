// SPDX-License-Identifier: MIT
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";

pragma solidity ^0.8.7;

contract AiReinRefund is Ownable, ReentrancyGuard {
    struct RefundConfig {
        uint256 startTime;
        uint256 stopTime;
        uint256 price;
        address NFTContract;
    }
    address public refundAddress;
    address public reclaimNFTAddress;
    address public adminAddress;
    RefundConfig public refundConfig;

    constructor(
        address _adminAddress,
        address _refundAddress,
        address _reclaimNFTAddress
    ) {
        adminAddress = _adminAddress;
        refundAddress = _refundAddress;
        reclaimNFTAddress = _reclaimNFTAddress;
    }

    function setAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0), "Admin address cannot be zero");
        adminAddress = _adminAddress;
    }

    // @notice NFT need to approve first
    function refund(uint256 tokenId) external callerIsUser nonReentrant {
        address NFTContract = refundConfig.NFTContract;
        require(NFTContract != address(0), "NFT Contract address cannot be zero");
        require(reclaimNFTAddress != address(0), "Reclaim address cannot be zero");
        require(_msgSender() == IERC721(NFTContract).ownerOf(tokenId), "Not NFT owner");
        require(_msgSender() != refundAddress, "Stock account refunds are not allowed");
        require(isRefundEnabled(), "Outside the refundable period");

        uint256 refundPrice = _refundPrice(tokenId);
        require(refundPrice > 0, "Only sale NFT can be refunded");
        require(address(this).balance >= refundPrice, "Insufficient contract funds");

        // Transfer NFT to refundAddress
        IERC721(NFTContract).safeTransferFrom(_msgSender(), reclaimNFTAddress, tokenId);

        // Refund to user
        payable(_msgSender()).transfer(refundPrice);
    }

    function setRefundAddress(address _refundAddress) external onlyAdmin {
        refundAddress = _refundAddress;
    }

    function setReclaimNFTAddress(address _reclaimNFTAddress) external onlyAdmin {
        reclaimNFTAddress = _reclaimNFTAddress;
    }

    function setRefundConfig(RefundConfig calldata cfg) external onlyAdmin {
        refundConfig = cfg;
    }

    function withdraw() external onlyAdmin {
        payable(refundAddress).transfer(address(this).balance);
    }

    function isRefundEnabled() public view virtual returns (bool) {
        return block.timestamp >= refundConfig.startTime && block.timestamp <= refundConfig.stopTime;
    }

    function _refundPrice(
        uint256 /*tokenId_*/
    ) internal view virtual returns (uint256) {
        return refundConfig.price;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Management: Not admin");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "Caller is another contract");
        _;
    }

    // @notice Will receive any eth sent to the contract
    receive() external payable {}
}
