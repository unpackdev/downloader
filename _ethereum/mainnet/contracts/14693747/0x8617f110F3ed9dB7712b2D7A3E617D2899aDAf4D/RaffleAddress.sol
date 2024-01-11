// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IERC721Enumerable.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";

contract GiveawayWinner is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    address public winner;

	event AddToWhiteList(address _address);
    event RemovedFromWhiteList(address _address);
	event WhiteListMultipleAddress(address[] accounts);
    event RemoveWhiteListedMultipleAddress(address[] accounts);

    EnumerableSet.AddressSet whitelist;
    EnumerableSet.UintSet winnerIndices;

	event Winner(address winnerAddress, uint256 index);

    function findNewWinner() external onlyOwner {

        uint256 salt;
        uint256 n = whitelist.length();

        for (uint256 i; i < n; i++) {
            uint256 index = _random(salt) % n;
            if (!winnerIndices.contains(index)) {
                winner = whitelist.at(index);
                winnerIndices.add(index);
                emit Winner(winner, index);
                break;
            }
            salt++;
        }
    }

	function _random(uint256 salt) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, salt, whitelist._inner._values)));
    }

	function whiteListAddress(address _address) external onlyOwner {
       whitelist.add(_address);
	   emit AddToWhiteList(_address);
    }

	function removeWhiteListedAddress(address _address) external onlyOwner {
        whitelist.remove(_address);
	    emit RemovedFromWhiteList(_address);
	}

	function whiteListMultipleAddress(address[] calldata _address) external onlyOwner {
        uint256 n = _address.length;
        for (uint256 i = 0; i < n; i++) {
            whitelist.add(_address[i]);
        }
        emit WhiteListMultipleAddress(_address);
    }

	function removeAllAddress() external onlyOwner {
	   delete whitelist;
	}
}