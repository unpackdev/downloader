// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

/**
 * @title Women Life Freedom
 * @author Harry Anderson
 * @notice ERC1155 token
 */
contract WLF is ERC1155, Ownable {
    using Strings for uint256;

    address payable public paymentReceiver;
    uint256 public cost;
    uint8 public tokenSupply = 6;
    string public prefix = ".json";
    string public name;
    string public symbol;
    bool public pause = true;

    modifier isTokenIdsValid(uint256[] memory _ids) {
        for (uint256 i = 0; i < _ids.length; i++) {
            require(
                _ids[i] <= tokenSupply && _ids[i] > 0,
                "WLF: Token does not exist"
            );
        }
        _;
    }

    modifier isTokenIdValid(uint256 _id) {
        require(_id <= tokenSupply && _id > 0, "WLF: Token does not exist");
        _;
    }

    modifier isNotPause() {
        require(!pause, "WLF: The mint is paused");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri) Ownable(msg.sender) {
        name = _name;
        symbol = _symbol;
        paymentReceiver = payable(msg.sender);
        cost = 0.025 ether;
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public payable isTokenIdValid(_id) isNotPause {
        // Transfer funds
        _transferFunds(paymentReceiver, _amount);

        // Do mint
        _mint(_to, _id, _amount, _data);
    }

    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public payable isTokenIdsValid(_ids) isNotPause {
        require(
            _ids.length == _amounts.length,
            "WLF: Length of ids and amounts are must be same"
        );
        uint256 mintCount;
        for (uint256 i = 0; i < _amounts.length; i++) {
            mintCount += _amounts[i];
        }

        // Transfer funds
        _transferFunds(paymentReceiver, mintCount);

        // Do mint
        _mintBatch(_to, _ids, _amounts, _data);
    }

    function tokenURI(
        uint256 _tokenId
    ) external view isTokenIdValid(_tokenId) returns (string memory) {
        string memory baseURI = uri(_tokenId);
        return string(abi.encodePacked(baseURI, _tokenId.toString(), prefix));
    }

    function withdraw(
        address payable receiver,
        uint256 amount
    ) external onlyOwner {
        (bool sent, ) = receiver.call{value: amount}("");
        require(sent, "Failed to transfer to receiver");
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setTokenSupply(uint8 _tokenSupply) public onlyOwner {
        tokenSupply = _tokenSupply;
    }

    function setPaymentReceiver(address _newReceiver) public onlyOwner {
        paymentReceiver = payable(_newReceiver);
    }

    function setPause() public onlyOwner {
        pause = !pause;
    }

    function _transferFunds(
        address payable recipient,
        uint256 mintCount
    ) internal {
        uint256 payableCost = cost * mintCount;

        // Check price
        require(msg.value >= payableCost, "Invalid amount");

        (bool sent, ) = recipient.call{value: payableCost}("");
        require(sent, "Failed to transfer to receiver");
    }
}
