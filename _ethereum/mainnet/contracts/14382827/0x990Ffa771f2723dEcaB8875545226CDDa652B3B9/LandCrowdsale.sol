// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract LANDPresaleCrowdsale is Ownable, Pausable {
    address public receiverAddress = 0x5Be192c0Be2521E7617594c2E8854f21C5a11967; // receiver address

    uint32 public cap; // Max cap of the sale
    uint32 public totalBought; // Total tokens bought from this sale

    uint64 public _startTime; // Time when crowdsale starts
    uint64 public _endTime; // Time when crowdsale ends

    bool public _whitelistDesactivated; // bool to control the use of whitelist

    mapping(uint32 => bool) public _idSale; // tokenIDs that are for sale.
    mapping(uint32 => bool) public _idSold; // tokenIDs that have been sold.
    mapping(uint32 => uint8) public _idType; // from token_id to idType
    mapping(uint8 => uint) public _typePrice; // Which is the price of the type of token_id
    mapping(address => bool) public _whitelist; // whitelisted addresses

    event LANDBought(uint32 _tokenID, address _buyer); // Event to capture which token Id has been bought per buyer.

    constructor(uint32 _cap) {
        cap = _cap;
        _startTime = 0;
        _endTime = 1671759098; // December 23th 2022 9:31:38
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
    * @dev buy LAND function
    */
    function buyLAND(uint32 _tokenID) external payable whenNotPaused {
        require(totalBought < cap, "LANDPresaleCrowdsale: Total cap already minted");
        require(_idSale[_tokenID] && !_idSold[_tokenID], "LANDPresaleCrowdsale: _tokenID not available for sale or already bought");
        require(_whitelistDesactivated || _whitelist[_msgSender()], "LANDPresaleCrowdsale: Sender is not whitelisted or whitelist active");
        require(_startTime < uint64(block.timestamp) && _endTime > uint64(block.timestamp), "LANDPresaleCrowdsale: Not correct Event time");

        uint salePrice = _typePrice[_idType[_tokenID]];
        require(msg.value >= salePrice, "LANDPresaleCrowdsale: Sent value is less than sale price for this _tokenID");

        // another token bought
        totalBought += 1;

        // mark tokenId that has been sold
        _idSale[_tokenID] = false;
        _idSold[_tokenID] = true;

        // Refund back the remaining to the receiver
        uint value = msg.value - salePrice;
        if (value > 0) {
            payable(_msgSender()).transfer(value);
        }

        // emit event to catch in the frontend to update grid and keep track of buyers.
        emit LANDBought(_tokenID, _msgSender());
    }

    /**
    * @dev Transfer all held by the contract to the owner.
    */
    function reclaimETH() external onlyOwner {
        payable(receiverAddress).transfer(address(this).balance);
    }

    /**
    * @dev Transfer all ERC20 of tokenContract held by contract to the owner.
    */
    function reclaimERC20(address _tokenContract) external onlyOwner {
        require(_tokenContract != address(0), "Invalid address");
        IERC20 token = IERC20(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(receiverAddress, balance);
    }

    /**
    * @dev Set status for whitelist, wether to use whitelist or not for the sale
    */
    function setWhitelistDesactivatedStatus(bool _status) external onlyOwner {
        _whitelistDesactivated = _status;
    }

    /**
    * @dev Set status for tokens IDs, set up which IDs are for sale
    */
    function setIDSale(uint32[] calldata _tokenID, bool _status) external onlyOwner {
        for (uint i = 0; i < _tokenID.length; i++) {
            _idSale[_tokenID[i]] = _status;
        }
    }

    /**
    * @dev Set which ID type is each token_id, don't need to do it with the type 0.
    */
    function setIDType(uint32[] calldata _tokenID, uint8 _type) external onlyOwner {
        for (uint i = 0; i < _tokenID.length; i++) {
            _idType[_tokenID[i]] = _type;
            _idSale[_tokenID[i]] = true;
        }
    }

    /**
    * @dev Set price for each type of tokenID, price has to be in weis.
    */
    function setTypePrice(uint8 _type, uint _price) external onlyOwner {
        {
            _typePrice[_type] = _price;
        }
    }

    /**
    * @dev Set start Time for the Sale
    */
    function setStartTime(uint64 _newTime) external onlyOwner {
        _startTime = _newTime;
    }

    /**
    * @dev Set end Time for the Sale
    */
    function setEndTime(uint64 _newTime) external onlyOwner {
        _endTime = _newTime;
    }

    /**
    * @dev Set whitelist address status true or false in bulk
    */
    function setWhitelist(address[] calldata _addresses, bool _status) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            _whitelist[_addresses[i]] = _status;
        }
    }

    /**
    * @dev Check address whitelist status
    */
    function isWhitelist() external view returns (bool) {
        return _whitelist[_msgSender()];
    }

    /**
    * @dev Get _tokenID price
    */
    function getTokenPrice(uint32 _tokenID) external view returns (uint) {
        return _typePrice[_idType[_tokenID]];
    }
}
