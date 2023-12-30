/**
 *Submitted for verification at Etherscan.io on 2020-06-05
*/
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.5.15;

contract ADVTokenAbstract {
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function mint(address account, uint256 amount) public;
    function burn(address account, uint256 amount) public;
}
contract EasyMain {
    
    address draftMainAddr;
    ADVTokenAbstract  public advToken =
        ADVTokenAbstract(0x19EA6aCd7604cF8e1271818143573B6Fc16EFd27);
    address payable public owner;
    
    uint256     private ethusdLive;
    
    event SEND_ADV(address indexed _account, uint _amount, bool _bSuccess);
    event LogPriceUpdated(string price);
    event LogNewProvableQuery(string description);
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        require(msg.sender != address(0));
        ethusdLive = 50000;
        owner = msg.sender;
    }
    
    function updateEthUsdLive(uint _ethusdLive) public onlyOwner {
        require(_ethusdLive > 0);
        ethusdLive = _ethusdLive;
    }
    
    function setDraftMainAddr(address _addr) external onlyOwner {
        require(_addr != address(0));
        draftMainAddr = _addr;
    }
    
    function buyToken(uint256 ethusd) external payable {
        require(ethusd > 0 && ethusd < ethusdLive);
        uint256 amount = msg.value * ethusd / 100;
        advToken.mint(msg.sender, amount);
        emit SEND_ADV(msg.sender, amount, true);
    }
    
    function () external payable {
        
    }
    function mintADVToken(address to, uint amount) external {
        require(msg.sender == draftMainAddr);
        advToken.mint(to, amount);
    }
    
    function burnADVToken() external {
        require(msg.sender == draftMainAddr);
        advToken.burn(address(this), advToken.balanceOf(address(this)));
    }
    
    function sendADVToken(uint amount) public payable {
        require(amount > 0);
        advToken.mint(msg.sender, amount);
        emit SEND_ADV(msg.sender, amount, true);
    }
    
    function withdrawBalance(uint amount) public onlyOwner {
        require(amount <= address(this).balance);
        (owner).transfer(amount);
    }
}