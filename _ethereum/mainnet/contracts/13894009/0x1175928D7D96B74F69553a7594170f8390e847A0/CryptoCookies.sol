// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*

 _____ ________   _______ _____ _____   _____ _____  _____ _   _______ _____ _____ 
/  __ \| ___ \ \ / / ___ \_   _|  _  | /  __ \  _  ||  _  | | / /_   _|  ___/  ___|
| /  \/| |_/ /\ V /| |_/ / | | | | | | | /  \/ | | || | | | |/ /  | | | |__ \ `--. 
| |    |    /  \ / |  __/  | | | | | | | |   | | | || | | |    \  | | |  __| `--. \
| \__/\| |\ \  | | | |     | | \ \_/ / | \__/\ \_/ /\ \_/ / |\  \_| |_| |___/\__/ /
 \____/\_| \_| \_/ \_|     \_/  \___/   \____/\___/  \___/\_| \_/\___/\____/\____/ 
                                                                                   
                                                                                   
CRYPTO COOKIES

*/

import "./Ownable.sol";
import "./Strings.sol";

import "./Base64.sol";
import "./console.sol";

import "./ERC721Fast.sol";
import "./IRenderingFortunes.sol";

interface ISOSToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CryptoCookies is Ownable, ERC721 {
  
    using Strings for uint256;

    bool public isSaleLive;

    uint16 constant MAX_SUPPLY = 20000;
    uint256 public SOS_PER_MINT = 25000000 * 10 ** 18;
    
    ISOSToken public SOSContract;

    event SaleLive(bool onSale);

    constructor(address SOSADDRESS) 
        ERC721("Crypto Cookies", "COOKIES", MAX_SUPPLY) {
        SOSContract = ISOSToken(SOSADDRESS);
    }

    function Buy(uint256 amount) external {

        require(isSaleLive,"Sale not live");
        require(amount > 0,"Mint at least 1");
        require(_totalMinted + amount <= MAX_SUPPLY,"Max tokens minted");

        uint256 totalCost = SOS_PER_MINT * amount;

        //will revert if not enough balance or no allowance
        SOSContract.transferFrom(msg.sender, owner(), totalCost);

        for (uint256 i = 0; i < amount; i++ ){
            _mintinternal(msg.sender, _totalMinted + 1); //mint to sender's wallet
        }

    }

    function toggleSaleStatus() external onlyOwner {
        isSaleLive = !isSaleLive;
        emit SaleLive(isSaleLive);
    }

    function SetSOSContract(address _newSOS) external onlyOwner{
        SOSContract = ISOSToken(_newSOS);
    }

    function SetSOSPrice(uint256 newPrice) external onlyOwner {
        SOS_PER_MINT = newPrice;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawSOS() external onlyOwner {
        SOSContract.transfer(owner(), SOSContract.balanceOf(address(this)));
    }

}