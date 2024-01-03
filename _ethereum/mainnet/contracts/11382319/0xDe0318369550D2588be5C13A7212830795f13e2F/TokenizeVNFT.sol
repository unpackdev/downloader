/*pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./ERC20PresetMinterPauser.sol";
import "./IMuseToken.sol";
import "./IVNFT.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract TokenizeNFT is Ownable, ERC20PresetMinterPauser {
    using SafeMath for uint256;

    IVNFT public vnft;
    IMuseToken public muse;
    uint256 public premint;
    address public creator;
    uint256 public MAXTOKENS = 20;
    uint256 public defaultGem;
    uint256 public startSale;
    uint256 public totalDays = 100;

    uint256 public currentVNFT;

    constructor(
        IVNFT _vnft,
        IMuseToken _muse,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _creator,
        uint256 _premint,
        uint256 _defaultGem
    ) public ERC20PresetMinterPauser(_tokenName, _tokenSymbol) {
        vnft = _vnft;
        muse = _muse;
        creator = _creator;
        premint = _premint * 1 ether;
        defaultGem = _defaultGem;
        if (premint > 0) {
            mint(_creator, premint);
        }
        startSale = now;
        muse.approve(address(vnft), MAX_INT);
        vnft.mint(address(this));
        currentVNFT = vnft.tokenOfOwnerByIndex(address(this), vnft.balanceOf(address(this)) - 1);
    }

    function join(address _to, uint256 _times) public {
        require(_times < MAXTOKENS, "Can't whale in");
        uint256 lastTimeMined = vnft.lastTimeMined(currentVNFT);
        muse.transferFrom(
            msg.sender,
            address(this),
            vnft.itemPrice(defaultGem) * _times
        );
        uint256 index = 0;
        while (index < _times) {
            vnft.buyAccesory(currentVNFT, defaultGem);
            index = index + 1;
        }
        if (lastTimeMined + 1 days < now) {
            vnft.claimMiningRewards(currentVNFT);
            tickets = 2;
        }
        mint(_to, getJoinReturn(_times));
    }

    function getMuseValue(uint256 _quantity) public view returns (uint256) {
        uint256 reward = totalSupply().div(_quantity);
        return reward;
    }

    function getJoinReturn(uint256 _times) public pure returns (uint256) {
        uint256 daysStarted = now.sub(startSale.div(1 days));
        if (daysStarted >= totalDays) // The reward starts at toalDay (100) and decrease from 1 token everyday
        {
            return 1 * _times * 1 ether;
        } else {
            return ((totalDays - daysStarted) * 1 ether * _times);
        }
    }

    function remove(address _to, uint256 _quantity) public {
        _burn(msg.sender, _quantity);
        muse.transfer(_to, getMuseValue(_quantity));
        if (totalSupply() == 0 && vnft.isVnftAlive(currentVNFT)) {
            vnft.safeTransferFrom(address(this), msg.sender, currentVNFT);
        }
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }
}*/