// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./Pausable.sol";
import "./Counters.sol";

/// @custom:security-contact leo@lehmansoft.com
contract GenesisAirDrop is ReentrancyGuard, Ownable, Pausable {
    using Address for address;
    using Address for address payable;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string public constant name = "LOOTaDOG Genesis AirDrop";

    string public constant version = "0.1";

    uint256 public fixed_price = 0;

    uint256 public fixed_limit = 0;

    address internal _tokenAddress;

    event CallClaimResponse(bool success, bytes data);

    constructor(
        address tokenAddress,
        uint256 price,
        uint256 limit
    ) {
        _tokenAddress = tokenAddress;
        fixed_price = price;
        fixed_limit = limit;
    }

    function setPrice(uint256 price) public onlyOwner {
        fixed_price = price;
    }

    function getLimit() public view returns (uint256) {
        return fixed_limit;
    }

    function setLimit(uint256 limit) public onlyOwner {
        fixed_limit = limit;
    }

    function getPrice() public view returns (uint256) {
        return fixed_price;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /*claim a Genesis NFT*/
    function claim() public payable nonReentrant whenNotPaused {
        require(msg.value >= fixed_price, "Not enough amount");
        (bool success1, bytes memory result1) = _tokenAddress.call(
            abi.encodeWithSignature("balanceOf(address)", msg.sender)
        );
        require(success1, "Query balanceOf fail");
        uint256 balance = abi.decode(result1, (uint256));
        require(balance == 0, "One address can only apply once");
        emit CallClaimResponse(success1, result1);
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= fixed_limit, "Sold out");

        (bool success2, bytes memory result2) = _tokenAddress.call(
            abi.encodeWithSignature(
                "safeMint(address,uint256)",
                msg.sender,
                tokenId
            )
        );
        require(success2, "Mint Failed");
        emit CallClaimResponse(success2, result2);
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        uint256 balance = address(this).balance;
        require(amount <= balance, "Transfer failed");
        payable(to).transfer(amount);
    }

    function withdrawERC20(
        IERC20 token,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(token.transfer(to, amount), "Transfer failed");
    }
}
