pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract HalloweenMinter is Ownable {
    using Strings for string;
    using SafeMath for uint256;

    uint256 public MAX_SUPPLY;
    uint256 public mintPrice;


    mapping(address => uint256) public addressAmountMapping;

    address[] public minters;

    event MintHalloween(address indexed _from, uint256 _value);

    constructor() {
        mintPrice = 60000000000000000; // 0.06 ETH
        MAX_SUPPLY = 3800;
    }

    function mint(uint256 amount, address _toAddress) external payable {
        require(amount <= 2, "Max two mints");
        require(
            mintPrice.mul(amount) <= msg.value,
            "Ether value sent is not correct"
        );
        require(
            addressAmountMapping[_toAddress] + amount <= 2,
            "Amount would exceed address allowance!"
        );



        addressAmountMapping[_toAddress] += amount;
        minters.push(_toAddress);

        emit MintHalloween(msg.sender, msg.value);
    }

    function getAddressAmount(address _address) public view returns(uint256) {
        return addressAmountMapping[_address];
    } 

    function getMinters() external view returns (address[] memory) {
        return minters;
    }

    function increaseMaxSupply(uint256 amount) external onlyOwner {
        MAX_SUPPLY = amount;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        address wallet = 0xb17C22EBb95Ad6150Ca649597Ee4C607319648F8;
        payable(wallet).transfer(balance);
    }
}
