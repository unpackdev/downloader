// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

interface IExLabsNFT {
	function balanceOf(address _user) external view returns(uint256);
}

interface IExploreToken {
    function checkMsg() external view returns(string memory);
    function mintReward(address) external;
    function updateRewardOnMint(address) external;
    function updateReward(address _from, address _to) external;
}

contract ExploreToken is ERC20, ERC20Burnable, Pausable, Ownable {
    using SafeMath for uint256;
	uint256 constant public baseYieldRate = 10 ether;

    // December 5, 2021 8:00:00 AM PST
    uint256 constant public START = 1638720000;
    // January 31, 2028 8:00:00 PM PST
    uint256 constant public END = 1832990400;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    IExLabsNFT public nftContract; 

    event RewardPaid(address indexed user, uint256 reward);

    string constant public TOKEN_NAME = "Explore Token";
    string constant public TOKEN_SYMBOL = "EXP";

    constructor(address _nftContract) ERC20(TOKEN_NAME, TOKEN_SYMBOL) {
        nftContract = IExLabsNFT(_nftContract);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	function updateRewardOnMint(address _user) public {
		require(msg.sender == address(nftContract), "Can't call this");
		uint256 time = min(block.timestamp, END);
		uint256 timerUser = lastUpdate[_user];

		if (timerUser > 0) {
			rewards[_user] = rewards[_user].add(nftContract.balanceOf(_user).mul(baseYieldRate.mul((time.sub(timerUser)))).div(86400));
        } else {
		    lastUpdate[_user] = time;
        }   
	}

    function updateReward(address _from, address _to) external {
        uint256 time = min(block.timestamp, END);
        uint256 timerFrom = lastUpdate[_from];

        if (timerFrom > 0) {
            rewards[_from] += nftContract
                .balanceOf(_from)
                .mul(baseYieldRate.mul((time.sub(timerFrom))))
                .div(86400);
        }

        if (timerFrom != END) {
			lastUpdate[_from] = time;
        }

        if (_to != address(0)) {
            uint256 timerTo = lastUpdate[_to];
            if (timerTo > 0) {
                rewards[_to] += nftContract
                    .balanceOf(_to)
                    .mul(baseYieldRate.mul((time.sub(timerTo))))
                    .div(86400);
            }
            if (timerTo != END) {
                lastUpdate[_to] = time;
            }
        }
    }

    function mintReward(address _to) external {
		require(msg.sender == address(nftContract), "Can only be called by ExLabs contract");

        uint256 exLabsBal = nftContract.balanceOf(_to);
        require(exLabsBal != 0, "Not a valid Exploration NFT owner");

        uint256 time = min(block.timestamp, END);
        uint256 reward = rewards[_to];
        uint256 unclaimed = this.getTotalClaimable(_to);

		if (reward > 0) {
		 	rewards[_to] = 0;
            lastUpdate[_to] = time;
		 	mint(_to, reward + unclaimed);
		 	emit RewardPaid(_to, reward + unclaimed);
		} else {
            lastUpdate[_to] = time;
            mint(_to, unclaimed);
		 	emit RewardPaid(_to, unclaimed);
        }
	}

    function getTotalClaimable (address _user) external view returns (uint256) {
        uint256 time = min(block.timestamp, END);
        uint256 unclaimed = nftContract.balanceOf(_user).mul(baseYieldRate.mul(time.sub(lastUpdate[_user]))).div(86400);

        return rewards[_user] + unclaimed;
    }    
    
    function burn(address _from, uint256 _amount) external {
		require(msg.sender == address(nftContract));
		_burn(_from, _amount);
	}

    function mint(address to, uint256 amount) internal {
        _mint(to, amount);
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}