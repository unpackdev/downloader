// PowerFan v1 to v2 bridge
// Version: PowerDao2
// Website: https://powerfan.io
// Developer: https://www.linkedin.com/in/albertahn/
// Twitter: https://twitter.com/powerfanio (@powerfanio)
// Discord: https://discord.com/invite/xrd2dMW6DP
// TG: https://t.me/powerfaninc
// Facebook: https://www.facebook.com/powerfanio
// Instagram: https://www.instagram.com/powerfanio/

pragma solidity >=0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract PowerFanSwap is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public pfan; // new token
    IERC20 public old_pfan; // old token

    constructor() public {
        //v1 0x35eee718C20ef361d75E1c7D57BDa9D1adB30302
        //v2 0x217BED0d3A967d063eb287445A1eccac5C2E09BC
        address v1Address = address(0x35eee718C20ef361d75E1c7D57BDa9D1adB30302); // old pfan
        address v2Address = address(0x217BED0d3A967d063eb287445A1eccac5C2E09BC); //pfan powerdao
        old_pfan = IERC20(v1Address);
        pfan = IERC20(v2Address);
        
    }

    event SWAP(address indexed user, uint256 amount);

    function swap(uint256 amount) public {
        require(old_pfan.balanceOf(msg.sender) >= amount);
        require(old_pfan.allowance(msg.sender, address(this)) >= amount);

        old_pfan.safeTransferFrom(msg.sender, address(this), amount);
        pfan.safeTransfer(msg.sender, amount);
        emit SWAP(msg.sender, amount);
    }

    function withdraw(IERC20 token, uint256 amount) public onlyOwner {
        require(token.balanceOf(address(this)) > amount);
        token.safeTransfer(msg.sender, amount);
    }

    function withdrawAll(IERC20 token) public onlyOwner {
        require(token.balanceOf(address(this)) > 0);
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function setOldPFAN(IERC20 token) public onlyOwner {
        old_pfan = token;
    }

    function setNewPFAN(IERC20 token) public onlyOwner {
        pfan = token;
    }
}
