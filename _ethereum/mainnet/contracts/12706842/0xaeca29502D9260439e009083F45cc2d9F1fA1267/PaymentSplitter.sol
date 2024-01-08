//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.0 <0.8.0;

import "./SafeMath.sol";

contract PaymentSplitter {
    
    using SafeMath for uint256;

    address payable public creator_wallet;
    address payable public owner_wallet;
    uint256 public creator_fee_percentage;

    constructor(
        address payable _owner_wallet,
        address payable _creator_wallet,
        uint256 _creator_fee
    ) {

        require(
            _owner_wallet != address(0),
            "Construct: Owner Wallet cannot be 0x"
        );
        require(
            _creator_wallet != address(0),
            "Construct: Creator Wallet cannot be 0x"
        );

        require(
            _creator_fee > 0 && _creator_fee < 100,
            "Construct: Fee should be between 0 and 100"
        );

        creator_wallet = _creator_wallet;
        owner_wallet = _owner_wallet;
        creator_fee_percentage = _creator_fee;
    }

    receive() external payable {
        uint256 creatorPart = msg.value.mul(creator_fee_percentage).div(100);
        uint256 ownerPart = msg.value.sub(creatorPart);
        creator_wallet.transfer(creatorPart);
        owner_wallet.transfer(ownerPart);
    }

}
