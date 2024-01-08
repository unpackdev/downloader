pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./DeezNuts.sol";

contract DeezNutsPrinter is Ownable {
    using Strings for string;
    using SafeMath for uint256;

    address public nftAddress;
    uint256 public MAX_SUPPLY;
    uint256 public mintPrice;
    bool public public_minting;


    constructor(address _nftAddress) {
        MAX_SUPPLY = 10000;
        mintPrice = 69000000000000000; // 0.069 ETH
        nftAddress = _nftAddress;
        public_minting = false;
    }

    function name() external pure returns (string memory) {
        return "Deez Nuts Factory";
    }

    function symbol() external pure returns (string memory) {
        return "NTS";
    }

    function mint(uint256 amount, address _toAddress) external payable {
        require(public_minting, "Public minting isn't allowed yet");
        require(mintPrice.mul(amount) <= msg.value, "Ether value sent is not correct");
        require(amount <= 100, "Too many mints! Max is 100.");

        DeezNuts deezNuts = DeezNuts(nftAddress);
        uint256 currentSupply = deezNuts.totalSupply();

        uint256 balanceOfMinter = deezNuts.balanceOf(_msgSender());
        require(balanceOfMinter + amount <= 101, "Minting would exceed 10 mints for user");

        require(currentSupply + amount <= MAX_SUPPLY, "Purchase would exceed max supply");
        
        for (uint256 i = 0; i < amount; i++) {
            deezNuts.factoryMint(_toAddress);
        }
    }

    function presaleMint(uint256 amount, address _toAddress) external payable {
        require(mintPrice.mul(amount) <= msg.value, "Ether value sent is not correct");
        require(amount <= 10, "Too many mints! Max is 10.");

        DeezNuts deezNuts = DeezNuts(nftAddress);
        uint256 currentSupply = deezNuts.totalSupply();

        uint256 balanceOfMinter = deezNuts.balanceOf(_msgSender());
        require(balanceOfMinter + amount <= 10, "Minting would exceed 10 mints for user");
        
        require(currentSupply >= 100, "Private sale still in progress");
        require(currentSupply + amount <= MAX_SUPPLY, "Purchase would exceed max supply");
        
        for (uint256 i = 0; i < amount; i++) {
            deezNuts.factoryMint(_toAddress);
        }

    }

    function privateMint(uint256 amount, address _toAddress) external onlyOwner {
        DeezNuts deezNuts = DeezNuts(nftAddress);
        uint256 currentSupply = deezNuts.totalSupply();
        require(currentSupply + amount <= 100, "Purchase would exceed allocated private sale");

        for (uint256 i = 0; i < amount; i++) {
            deezNuts.factoryMint(_toAddress);
        }

    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 amount069 = balance.mul(69).div(1000);
        uint256 amount022 = balance.mul(22).div(1000);
        uint256 amount4545 = balance.mul(4545).div(10000);
        
        address wallet069 = 0x8eB97Fca1b0B22807C5d44da43D6C116E74e4DB1;
        address wallet022 = 0xB7FdE283dEE1f7484365f3b06E0f3E1D61304CC4;
        address wallet4545 = 0x82815C90D40073Ad14e1D0cB5bccbf8883862483;
        address wallet45451 = 0x274a5F5Ea6a2E0D184800FE891C4Aa5bCc715347;

        payable(wallet069).transfer(amount069);
        payable(wallet022).transfer(amount022);
        payable(wallet4545).transfer(amount4545);
        payable(wallet45451).transfer(amount4545);
    }

    function setPublicMinting(bool isEnabled) public onlyOwner {
        public_minting = isEnabled;
    }

}