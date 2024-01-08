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
    uint256 mintCount = 0;

    event MintHalloween(address indexed _from, uint256 _value);

    constructor() {
        mintPrice = 60000000000000000; // 0.06 ETH
        MAX_SUPPLY = 1500;
    }

    function mint(uint256 amount, address _toAddress) external payable {
        require(amount <= 1, "Max two mints");
        require(
            mintPrice.mul(amount) <= msg.value,
            "Ether value sent is not correct"
        );
        require(
            addressAmountMapping[_toAddress] + amount <= 1,
            "Amount would exceed address allowance!"
        );
        require(mintCount+1 <= MAX_SUPPLY, "minting would exceed current max supply");
        

        addressAmountMapping[_toAddress] += amount;
        minters.push(_toAddress);
        mintCount += 1;

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


//  Deploying 'HalloweenMinter'
//    ---------------------------
//    > transaction hash:    0xd03c01414970a3a2029b4a5b1a85d8172b7cffddecded5299d9b7ce805ca988d
//    > Blocks: 14           Seconds: 218
//    > contract address:    0xC51Cc05a5610ca2dFDF3a68Bf57392D51A170d95
//    > block number:        13552331
//    > block timestamp:     1636057598
//    > account:             0xCd1B5613E06A6d66F5106cF13E103C9B98253B0c
//    > balance:             0.41891187270528375
//    > gas used:            598261 (0x920f5)
//    > gas price:           130 gwei
//    > value sent:          0 ETH
//    > total cost:          0.07777393 ETH