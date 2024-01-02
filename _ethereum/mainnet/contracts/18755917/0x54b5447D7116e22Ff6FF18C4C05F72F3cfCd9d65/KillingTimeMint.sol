// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17;

import "./KillingTime.sol";
import "./IERC721.sol";
import "./IERC20.sol";

contract KillingTimeMint {
    uint256 public _price = 0.034 ether;
    uint256 public _insurancePrice = 0.035 ether;
    uint256 public _maxInsurance = 20;
    uint256 public _insuranceCounter;

    address public _killingTimeAddress;
    address private _recipient;

    bool public _mintOpened;

    mapping(address => bool) public _isAdmin;

    constructor(address killingTimeAddress) {
        _insuranceCounter = 0;
        _killingTimeAddress = killingTimeAddress;
        _isAdmin[msg.sender] = true;
    }

    function toggleAdmin(address newAdmin) external {
        require(_isAdmin[msg.sender]);
        _isAdmin[newAdmin] = !_isAdmin[newAdmin];
    }

    function setRecipient(address recipient) external {
        require(_isAdmin[msg.sender]);
        _recipient = recipient;
    }

    function setKillingTimeAddress(address killingTimeAddress) external {
        require(_isAdmin[msg.sender]);
        _killingTimeAddress = killingTimeAddress;
    }

    function toggleMintOpened() external {
        require(_isAdmin[msg.sender]);
        _mintOpened = !_mintOpened;
    }

    function mint(bool isInsured) external payable {
        require(_mintOpened, "Mint closed");
        require(
            _insuranceCounter <= _maxInsurance,
            "Insurances no longer available"
        );
        uint256 price = isInsured ? _price + _insurancePrice : _price;
        require(msg.value >= price, "Not enough funds");
        bool success = payable(_recipient).send(price);
        require(success, "Funds could not transfer");
        KillingTime(_killingTimeAddress).mint(msg.sender, isInsured);
        if (isInsured) {
            _insuranceCounter++;
        }
    }
}
